import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'rubric_upload_form.dart';

import '../../services/chat_service.dart';
import '../../services/rubric_service.dart';
import '../../core/utils/blocking_progress_dialog.dart';

class TeachersRubricSidebar extends StatefulWidget {
  final VoidCallback? onRubricApplied;
  final String? chatSessionId;

  const TeachersRubricSidebar(
      {super.key, this.onRubricApplied, this.chatSessionId});

  @override
  State<TeachersRubricSidebar> createState() => _TeachersRubricSidebarState();
}

class _TeachersRubricSidebarState extends State<TeachersRubricSidebar> {
  bool hasRubric = false;
  String? appliedRubricName;
  String? selectedRubricName;
  int? semantic, coverage, relevance;

  // Custom rubric state
  bool hasCustomRubric = false;
  int? customSemantic, customCoverage, customRelevance;

  static const String _rubricAppliedPrefix = 'hasRubric:';
  static const String _rubricNamePrefix = 'rubricName:';
  static const String _semanticPrefix = 'semantic:';
  static const String _coveragePrefix = 'coverage:';
  static const String _relevancePrefix = 'relevance:';

  static const String _customAppliedPrefix = 'hasCustomRubric:';
  static const String _customSemanticPrefix = 'custom_semantic:';
  static const String _customCoveragePrefix = 'custom_coverage:';
  static const String _customRelevancePrefix = 'custom_relevance:';

  String? get _sessionId => widget.chatSessionId;

  String _k(String prefix) => '$prefix${_sessionId ?? 'no-session'}';

  @override
  void initState() {
    super.initState();
    _loadRubric();
  }

  Future<void> _loadRubric() async {
    final prefs = await SharedPreferences.getInstance();

    // Backend is source of truth for whether a rubric is attached.
    bool attachedInBackend = false;
    if (_sessionId != null && _sessionId!.isNotEmpty) {
      try {
        final details = await ChatService.getChatSessionDetails(_sessionId!);
        attachedInBackend =
            (details.rubricId != null && details.rubricId!.isNotEmpty);
      } catch (e) {
        // ignore; fall back to local
        // ignore: avoid_print
        print('Failed to load rubric from backend: $e');
      }
    }

    // If backend has an attached rubric, persist the session-scoped flag so
    // the UI survives relaunch even when local prefs were cleared.
    if (attachedInBackend && _sessionId != null && _sessionId!.isNotEmpty) {
      await prefs.setBool(_k(_rubricAppliedPrefix), true);
      await prefs.setBool('hasRubric', true);
    }

    // Session-scoped local weights (fallback to legacy global keys).
    final exists = prefs.getBool(_k(_rubricAppliedPrefix)) ??
        (prefs.getBool('hasRubric') ?? false);
    final customExists = prefs.getBool(_k(_customAppliedPrefix)) ??
        (prefs.getBool('hasCustomRubric') ?? false);

    setState(() {
      if (attachedInBackend || exists) {
        hasRubric = true;
        appliedRubricName = prefs.getString(_k(_rubricNamePrefix)) ??
            prefs.getString('rubricName');
        semantic =
            prefs.getInt(_k(_semanticPrefix)) ?? prefs.getInt('semantic') ?? 0;
        coverage =
            prefs.getInt(_k(_coveragePrefix)) ?? prefs.getInt('coverage') ?? 0;
        relevance = prefs.getInt(_k(_relevancePrefix)) ??
            prefs.getInt('relevance') ??
            0;
      } else {
        hasRubric = false;
      }

      if (customExists) {
        hasCustomRubric = true;
        customSemantic = prefs.getInt(_k(_customSemanticPrefix)) ??
            prefs.getInt('custom_semantic') ??
            0;
        customCoverage = prefs.getInt(_k(_customCoveragePrefix)) ??
            prefs.getInt('custom_coverage') ??
            0;
        customRelevance = prefs.getInt(_k(_customRelevancePrefix)) ??
            prefs.getInt('custom_relevance') ??
            0;
      }
    });
  }

  Future<void> _applyRubric(String name, int s, int c, int r) async {
    final prefs = await SharedPreferences.getInstance();

    // Persist session-scoped, plus legacy globals for backward compatibility.
    await prefs.setBool(_k(_rubricAppliedPrefix), true);
    await prefs.setString(_k(_rubricNamePrefix), name);
    await prefs.setInt(_k(_semanticPrefix), s);
    await prefs.setInt(_k(_coveragePrefix), c);
    await prefs.setInt(_k(_relevancePrefix), r);

    await prefs.setBool('hasRubric', true);
    await prefs.setString('rubricName', name);
    await prefs.setInt('semantic', s);
    await prefs.setInt('coverage', c);
    await prefs.setInt('relevance', r);

    // Persist to backend for this chat session (so it survives logout/relogin)
    if (widget.chatSessionId != null) {
      try {
        unawaited(
          showBlockingProgressDialog(
            context,
            message: 'Applying rubric...',
          ),
        );
        final rubricId = await RubricService.createRubric(
          name: name,
          chatSessionId: widget.chatSessionId,
          semantic: s,
          coverage: c,
          relevance: r,
          source: 'weights',
        );
        await ChatService.attachRubricToSession(
          chatSessionId: widget.chatSessionId!,
          rubricId: rubricId,
        );
      } catch (e) {
        // ignore: avoid_print
        print('Failed to attach rubric to session: $e');
      } finally {
        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    } else {
      // ignore: avoid_print
      print('Skipping rubric attach: chatSessionId is null');
    }

    setState(() {
      hasRubric = true;
      appliedRubricName = name;
      semantic = s;
      coverage = c;
      relevance = r;
      selectedRubricName = null; // Clear selection after applying
    });

    if (widget.onRubricApplied != null) {
      widget.onRubricApplied!();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('question_paper.rubric_applied_success'.tr())),
      );
    }
  }

  Future<void> _removeRubric() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_k(_rubricNamePrefix));
    await prefs.remove(_k(_semanticPrefix));
    await prefs.remove(_k(_coveragePrefix));
    await prefs.remove(_k(_relevancePrefix));
    await prefs.setBool(_k(_rubricAppliedPrefix), false);

    await prefs.remove('rubricName');
    await prefs.remove('semantic');
    await prefs.remove('coverage');
    await prefs.remove('relevance');
    await prefs.setBool('hasRubric', false);

    setState(() {
      hasRubric = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rubric removed successfully")),
      );
    }
  }

  void _viewRubric() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Current Rubric"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Semantic: $semantic%"),
              Text("Coverage: $coverage%"),
              Text("Relevance: $relevance%"),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SizedBox(
        width: drawerW,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),

              // ----------- SHOW BUTTONS ONLY IF RUBRIC EXISTS -----------
              if (hasRubric) ...[
                _rubricButtonsRow(),
                const SizedBox(height: 20),
              ],

              if (hasCustomRubric) ...[
                _buildRubricCard(
                  theme,
                  'Custom Rubric',
                  'question_paper.content_semantic'.tr(),
                  customSemantic ?? 0,
                  'question_paper.content_coverage'.tr(),
                  customCoverage ?? 0,
                  'question_paper.content_relevance'.tr(),
                  customRelevance ?? 0,
                  isCustom: true,
                ),
                const SizedBox(height: 24),
                // Option to upload a new one
                Center(
                  child: Tooltip(
                    message: 'question_paper.or_upload_custom'.tr(),
                    waitDuration: const Duration(milliseconds: 250),
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => RubricUploadForm(
                            onRubricApplied: widget.onRubricApplied,
                            chatSessionId: widget.chatSessionId,
                          ),
                        ).then((_) => _loadRubric());
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text('question_paper.or_upload_custom'.tr()),
                    ),
                  ),
                ),
              ] else ...[
                _buildUploadCard(theme),
              ],

              const SizedBox(height: 24),

              // Normal Cards (unchanged)
              _buildRubricCard(
                theme,
                'question_paper.balanced_evaluation'.tr(),
                'question_paper.balanced_semantic'.tr(),
                40,
                'question_paper.balanced_coverage'.tr(),
                30,
                'question_paper.balanced_relevance'.tr(),
                30,
              ),

              const SizedBox(height: 24),

              _buildRubricCard(
                theme,
                'question_paper.understanding_focused'.tr(),
                'question_paper.understanding_semantic'.tr(),
                60,
                'question_paper.understanding_coverage'.tr(),
                20,
                'question_paper.understanding_relevance'.tr(),
                20,
              ),

              const SizedBox(height: 24),

              _buildRubricCard(
                theme,
                'question_paper.content_focused'.tr(),
                'question_paper.content_semantic'.tr(),
                30,
                'question_paper.content_coverage'.tr(),
                50,
                'question_paper.content_relevance'.tr(),
                20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _buildHeader(ThemeData theme) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          'question_paper.teacher_rubrics'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close))
      ]),
      Text(
        'question_paper.teacher_rubric_description'.tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 10,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    ]);
  }

  // ---------------- Upload Card ----------------
  Widget _buildUploadCard(ThemeData theme) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('question_paper.or_upload_custom'.tr(),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'question_paper.pdf_docx_excel'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                child: Text('question_paper.upload'.tr()),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RubricUploadForm(
                      onRubricApplied: widget.onRubricApplied,
                    ),
                  ).then((_) => _loadRubric());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Custom Card ----------------
  Widget _buildRubricCard(
    ThemeData theme,
    String rubricTitle,
    String semanticLabel,
    int semanticMark,
    String coverageLabel,
    int coverageMark,
    String relevanceLabel,
    int relevanceMark, {
    bool isCustom = false,
  }) {
    final bool isApplied = hasRubric && appliedRubricName == rubricTitle;

    return Card(
      elevation: isApplied ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isApplied
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(isCustom ? Icons.edit_document : Icons.description,
                  color: isApplied ? theme.colorScheme.primary : Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rubricTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isApplied ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (isApplied)
                Icon(Icons.check_circle,
                    color: theme.colorScheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _row(semanticLabel, '$semanticMark%'),
          _row(coverageLabel, '$coverageMark%'),
          _row(relevanceLabel, '$relevanceMark%'),
          const Divider(),
          _row('question_paper.total'.tr(), 'question_paper.marks_100'.tr()),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isApplied
                  ? null
                  : () => _applyRubric(
                        rubricTitle,
                        semanticMark,
                        coverageMark,
                        relevanceMark,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.colorScheme.primaryContainer,
                disabledForegroundColor: theme.colorScheme.primary,
              ),
              child: Text(isApplied
                  ? 'question_paper.applied_for_evaluation'.tr()
                  : 'question_paper.apply_selected_rubric'.tr()),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(String labelText, String valueText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(labelText, style: const TextStyle(fontSize: 12)),
        Text(valueText, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _rubricButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _viewRubric,
            icon: const Icon(Icons.visibility, size: 18),
            label: Text('question_paper.view_rubric'.tr()), // <-- localized
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _removeRubric,
            icon: const Icon(Icons.delete, size: 18),
            label: Text('question_paper.remove_rubric'.tr()), // <-- localized
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

void showTeachersRubricSidebar(BuildContext context,
    {VoidCallback? onRubricApplied, String? chatSessionId}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final theme = Theme.of(dialogContext);
      final screenWidth = MediaQuery.of(dialogContext).size.width;

      // SAFE drawer width (never NaN or null)
      final double drawerWidth = (screenWidth * 0.8).clamp(250.0, 350.0);

      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: drawerWidth,
            height: double.infinity,
            color: theme.colorScheme.surface,
            child: TeachersRubricSidebar(
              onRubricApplied: onRubricApplied,
              chatSessionId: chatSessionId,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, secondaryAnim, child) {
      final offsetAnim = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
      ));

      return SlideTransition(position: offsetAnim, child: child);
    },
  );
}

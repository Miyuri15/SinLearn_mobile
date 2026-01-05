import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../services/chat_service.dart';
import '../../services/rubric_service.dart';
import '../../core/utils/blocking_progress_dialog.dart';

class RubricSelectionSidebar extends StatefulWidget {
  final VoidCallback? onRubricApplied;
  final String? chatSessionId;

  const RubricSelectionSidebar(
      {super.key, this.onRubricApplied, this.chatSessionId});

  @override
  State<RubricSelectionSidebar> createState() => _RubricSelectionSidebarState();
}

class _RubricSelectionSidebarState extends State<RubricSelectionSidebar> {
  String? _selectedRubric;
  String? _appliedRubric;
  bool _isCustomRubric = false;

  // Session-scoped keys (fallback to legacy globals).
  static const String _rubricAppliedPrefix = 'hasRubric:';
  static const String _rubricNamePrefix = 'rubricName:';
  static const String _isCustomRubricPrefix = 'isCustomRubric:';

  String? get _sid => widget.chatSessionId;
  String _k(String prefix) => '$prefix${_sid ?? 'no-session'}';

  @override
  void initState() {
    super.initState();
    _loadSavedRubric();
  }

  Future<void> _loadSavedRubric() async {
    final prefs = await SharedPreferences.getInstance();

    // Backend is the source of truth for whether a rubric is attached.
    bool attachedInBackend = false;
    String? backendRubricId;
    if (_sid != null && _sid!.isNotEmpty) {
      try {
        final details = await ChatService.getChatSessionDetails(_sid!);
        backendRubricId = details.rubricId;
        attachedInBackend =
            backendRubricId != null && backendRubricId!.isNotEmpty;
      } catch (e) {
        // ignore: avoid_print
        print('Failed to load rubric from backend: $e');
      }
    }

    final hasRubric = (prefs.getBool(_k(_rubricAppliedPrefix)) ?? false) ||
        (prefs.getBool('hasRubric') ?? false) ||
        attachedInBackend;

    if (!hasRubric) return;

    // Ensure local session-scoped flag is set when backend has rubric.
    if (attachedInBackend && _sid != null && _sid!.isNotEmpty) {
      await prefs.setBool(_k(_rubricAppliedPrefix), true);
      await prefs.setBool('hasRubric', true);
    }

    final appliedName = prefs.getString(_k(_rubricNamePrefix)) ??
        prefs.getString('rubricName') ??
        prefs.getString('appliedRubricName') ??
        (backendRubricId?.toString());

    final isCustom = prefs.getBool(_k(_isCustomRubricPrefix)) ??
        (prefs.getBool('isCustomRubric') ?? false);

    if (!mounted) return;
    setState(() {
      _appliedRubric = appliedName;
      _isCustomRubric = isCustom;
      if (!_isCustomRubric && _standardRubrics.contains(_appliedRubric)) {
        _selectedRubric = _appliedRubric;
      }
    });
  }

  Future<void> _saveRubric(String name, bool isCustom) async {
    final prefs = await SharedPreferences.getInstance();

    // Persist session-scoped, plus legacy globals for backward compatibility.
    await prefs.setBool(_k(_rubricAppliedPrefix), true);
    await prefs.setString(_k(_rubricNamePrefix), name);
    await prefs.setBool(_k(_isCustomRubricPrefix), isCustom);

    await prefs.setBool('hasRubric', true);
    await prefs.setString('rubricName', name);
    await prefs.setString('appliedRubricName', name);
    await prefs.setBool('isCustomRubric', isCustom);

    // Best-effort: persist to backend for this chat session
    if (widget.chatSessionId != null) {
      try {
        unawaited(
          showBlockingProgressDialog(
            context,
            message: 'Applying rubric...',
          ),
        );
        final displayName = isCustom ? name : name.tr();
        final rubricId = await RubricService.createRubric(
          name: displayName,
          chatSessionId: widget.chatSessionId,
          source: isCustom ? 'custom' : 'standard',
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
    }

    if (widget.onRubricApplied != null) {
      widget.onRubricApplied!();
    }
  }

  // localization keys for standard rubrics (defined in JSON)
  final List<String> _standardRubrics = [
    'question_paper.rubric_general_writing',
    'question_paper.rubric_math_problem_solving',
    'question_paper.rubric_science_lab_report',
    'question_paper.rubric_language_arts',
    'question_paper.rubric_history_essay',
    'question_paper.rubric_creative_writing',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;

    return Drawer(
      backgroundColor: theme.colorScheme.surface, // was Colors.white
      child: SizedBox(
        width: drawerW,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                if (_appliedRubric != null) ...[
                  const SizedBox(height: 24),
                  _buildAppliedRubricCard(theme),
                ],
                const SizedBox(height: 24),
                Card(
                  elevation: theme.brightness == Brightness.light ? 2 : 0,
                  color: theme.cardColor, // was Colors.white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'choose_a_rubric'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'question_paper.standard_rubrics'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRubricsDropdown(theme),
                        const SizedBox(height: 16),
                        _buildApplyButton(theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: theme.brightness == Brightness.light ? 2 : 0,
                  color: theme.cardColor, // was Colors.white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'or_upload_custom'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'pdf_docx_excel'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Tooltip(
                            message: 'question_paper.or_upload_custom'.tr(),
                            waitDuration: const Duration(milliseconds: 250),
                            child: ElevatedButton(
                              onPressed: _handleUpload,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.surface,
                                foregroundColor: theme.colorScheme.onSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'upload'.tr(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'select_rubric'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'close'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'standard_rubrics'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16), // Add bottom padding for the border
        ],
      ),
    );
  }

  Widget _buildRubricsDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: _selectedRubric,
      decoration: InputDecoration(
        labelText: 'select_a_rubric'.tr(),
        labelStyle: TextStyle(
          fontSize: 10, // Custom label size
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      borderRadius: BorderRadius.circular(8),
      dropdownColor: theme.colorScheme.surface,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      items: _standardRubrics.map((String rubricKey) {
        return DropdownMenuItem<String>(
          value: rubricKey,
          child: Text(rubricKey.tr()),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedRubric = newValue;
        });
      },
      icon: Icon(
        Icons.arrow_drop_down,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }

  Widget _buildApplyButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedRubric != null
            ? () async {
                await _saveRubric(_selectedRubric!, false);
                setState(() {
                  _appliedRubric = _selectedRubric;
                  _isCustomRubric = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('question_paper.rubric_applied_success'.tr()),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  );
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          'question_paper.apply_selected_rubric'.tr(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleUpload() async {
    // Simulate file upload
    const fileName = "Custom_Rubric.pdf";
    await _saveRubric(fileName, true);

    setState(() {
      _selectedRubric = fileName; // Example file name
      _appliedRubric = _selectedRubric;
      _isCustomRubric = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('question_paper.upload_message'.tr()),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Widget _buildAppliedRubricCard(ThemeData theme) {
    return Card(
      elevation: theme.brightness == Brightness.light ? 2 : 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'question_paper.applied_rubric'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isCustomRubric ? _appliedRubric! : _appliedRubric!.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (_isCustomRubric) ...[
              const SizedBox(height: 4),
              Text(
                'question_paper.custom_uploaded_file'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showRubricSelectionSidebar(BuildContext context,
    {VoidCallback? onRubricApplied, String? chatSessionId}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final theme = Theme.of(buildContext);
      final screenW = MediaQuery.of(buildContext).size.width;
      final drawerW = screenW * 0.9 > 304 ? 304.0 : screenW * 0.9;
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: theme.colorScheme.surface, // was Colors.white
          borderRadius: BorderRadius.zero,
          child: SizedBox(
            width: drawerW,
            height: double.infinity,
            child: RubricSelectionSidebar(
              onRubricApplied: onRubricApplied,
              chatSessionId: chatSessionId,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  );
}

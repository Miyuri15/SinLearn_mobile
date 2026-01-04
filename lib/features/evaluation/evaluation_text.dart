// lib/features/evaluation/evaluation_text.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'learning_mode.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/utils/json_cast.dart';
import 'evaluation_process_page.dart';
import 'evaluation_doc_tokens.dart';
import '../../services/chat_service.dart';
import '../../services/resource_service.dart';
import '../../services/evaluation_service.dart';

// NEW PAGE
import 'paper_config_review_page.dart';

class EvaluationTextPage extends StatefulWidget {
  final String chatSessionId;

  const EvaluationTextPage({
    super.key,
    required this.chatSessionId,
  });

  @override
  State<EvaluationTextPage> createState() => _EvaluationTextPageState();
}

class _EvaluationTextPageState extends State<EvaluationTextPage> {
  int _selectedSegment = 1;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();

  String? _attachedFileName;

  static const String _attachmentKey = 'evaluation_attachment';
  static const String _evaluationStorageKey = 'evaluation_data';
  static const String _rubricKeyPrefix = 'hasRubric:';
  static const String _paperConfigConfirmedKey = 'paper_config_confirmed';

  // Question paper + syllabus are persisted per chat session.
  static const String _questionPaperKeyPrefix = 'question_paper_file:';
  static const String _syllabusKeyPrefix = 'syllabus_items:';
  static const String _answerSheetIdsKeyPrefix = 'answer_sheet_ids:';

  String get _questionPaperKey =>
      '${_questionPaperKeyPrefix}${widget.chatSessionId}';
  String get _syllabusKey => '${_syllabusKeyPrefix}${widget.chatSessionId}';
  String get _answerSheetIdsKey =>
      '${_answerSheetIdsKeyPrefix}${widget.chatSessionId}';
  String get _rubricKey => '${_rubricKeyPrefix}${widget.chatSessionId}';

  bool _hasRubrics = false;
  bool _hasMarks = false;
  bool _hasAttachment = false;
  bool _hasQuestionPaper = false;
  bool _hasSyllabus = false;

  bool _showProcessing = false;
  bool _isProcessing = false;
  bool _hasProcessedDocuments = false;

  final Map<_DocStep, _DocStepState> _docSteps = {
    _DocStep.answerSheets: const _DocStepState(),
    _DocStep.questionPaper: const _DocStepState(),
    _DocStep.syllabus: const _DocStepState(),
    _DocStep.rubric: const _DocStepState(),
    _DocStep.paperConfig: const _DocStepState(),
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD STATE
  // ---------------------------------------------------------------------------
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    _attachedFileName = prefs.getString(_attachmentKey);
    _hasAttachment = _attachedFileName != null;

    // Prefer backend truth (per chat session) so it survives logout/relogin.
    try {
      final details =
          await ChatService.getChatSessionDetails(widget.chatSessionId);
      _hasQuestionPaper = details.questionPaper != null;
      _hasSyllabus = details.syllabus != null;
      _hasRubrics = (details.rubricId != null && details.rubricId!.isNotEmpty);

      final answerSheets = details.answerSheets;
      _hasAttachment = answerSheets.isNotEmpty;
      if (_hasAttachment) {
        final firstName = answerSheets.first.filename;
        if (firstName.isNotEmpty) {
          _attachedFileName = firstName;
        }
        // Persist IDs locally for downstream processing.
        await prefs.setStringList(
          _answerSheetIdsKey,
          answerSheets
              .map((e) => e.resourceId)
              .where((e) => e.isNotEmpty)
              .toList(),
        );
      }

      // Some backends may not include answer sheets in session resources yet.
      // If we have locally cached answer sheet IDs for this chat, treat them
      // as attached so processing can proceed.
      if (!_hasAttachment) {
        final ids = prefs.getStringList(_answerSheetIdsKey);
        if (ids != null && ids.isNotEmpty) {
          _hasAttachment = true;
        }
      }
    } catch (_) {
      // Fallback to legacy local state if backend fetch fails.
      _hasRubrics = (prefs.getBool(_rubricKey) ?? false) ||
          (prefs.getBool('hasRubric') ?? false);

      final ids = prefs.getStringList(_answerSheetIdsKey);
      _hasAttachment = (ids != null && ids.isNotEmpty) || _hasAttachment;

      final questionPaperRaw = prefs.getString(_questionPaperKey);
      _hasQuestionPaper =
          questionPaperRaw != null && questionPaperRaw.isNotEmpty;

      final syllabusItems = prefs.getStringList(_syllabusKey);
      _hasSyllabus = syllabusItems != null && syllabusItems.isNotEmpty;
    }

    final legacyMarks = prefs.getString(_evaluationStorageKey);
    final paperConfirmed = prefs.getBool(_paperConfigConfirmedKey) ?? false;

    _hasMarks =
        (legacyMarks != null && legacyMarks.isNotEmpty) || paperConfirmed;

    // NOTE: question paper + syllabus are set above (backend preferred).

    // Documents are considered processed only if the current token snapshot
    // matches the last processed snapshot.
    final currentTokens =
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId);
    final processedTokens = EvalDocTokens.loadProcessed(prefs);
    _hasProcessedDocuments = _allDocumentsAvailable() &&
        processedTokens != null &&
        EvalDocTokens.equals(currentTokens, processedTokens);

    if (mounted) setState(() {});
  }

  bool _allDocumentsAvailable() {
    // Map the UX steps to existing stored state.
    // - Answer sheets: evaluation attachment
    // - Question paper: question_paper_file
    // - Syllabus: syllabus_items
    // - Rubric: hasRubric
    // - Paper config: paper_config_confirmed OR legacy marks
    return _hasAttachment &&
        _hasQuestionPaper &&
        _hasSyllabus &&
        _hasRubrics &&
        _hasMarks;
  }

  bool _isStepAvailable(_DocStep step) {
    switch (step) {
      case _DocStep.answerSheets:
        return _hasAttachment;
      case _DocStep.questionPaper:
        return _hasQuestionPaper;
      case _DocStep.syllabus:
        return _hasSyllabus;
      case _DocStep.rubric:
        return _hasRubrics;
      case _DocStep.paperConfig:
        return _hasMarks;
    }
  }

  String _stepTitle(_DocStep step) {
    switch (step) {
      case _DocStep.answerSheets:
        return 'evaluation.docStepAnswerSheetsProcessing'.tr();
      case _DocStep.questionPaper:
        return 'evaluation.docStepQuestionPaperProcessing'.tr();
      case _DocStep.syllabus:
        return 'evaluation.docStepSyllabusProcessing'.tr();
      case _DocStep.rubric:
        return 'evaluation.docStepRubricSet'.tr();
      case _DocStep.paperConfig:
        return 'evaluation.docStepPaperConfigSet'.tr();
    }
  }

  Future<void> _processDocuments() async {
    if (_isProcessing) return;

    // ignore: avoid_print
    print(
        'ProcessDocuments clicked for chatSessionId: ${widget.chatSessionId}');

    setState(() {
      _showProcessing = true;
      _isProcessing = true;
      _hasProcessedDocuments = false;
      for (final step in _docSteps.keys) {
        _docSteps[step] = const _DocStepState(status: _DocStepStatus.pending);
      }
    });

    // Refresh current availability before starting.
    await _loadAllData();

    final prefs = await SharedPreferences.getInstance();
    final answerIds =
        prefs.getStringList(_answerSheetIdsKey) ?? const <String>[];

    // ignore: avoid_print
    print('ProcessDocuments answer_resource_ids: $answerIds');

    // If other docs are missing, still allow processing of answer sheets.
    // Evaluation later remains gated by _allDocumentsAvailable().
    final ok = _allDocumentsAvailable();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Some required docs are missing; processing anyway')),
      );
    }
    if (answerIds.isEmpty) {
      setState(() {
        _isProcessing = false;
        _hasProcessedDocuments = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing answer sheet upload')),
        );
      }
      return;
    }

    // Show all steps as in-progress while backend processes.
    setState(() {
      for (final step in _docSteps.keys) {
        _docSteps[step] =
            const _DocStepState(status: _DocStepStatus.inProgress);
      }
    });

    try {
      await EvaluationService.processDocumentsStream(
        chatSessionId: widget.chatSessionId,
        answerResourceIds: answerIds,
      );

      await EvalDocTokens.saveProcessed(
        prefs,
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId),
      );

      if (!mounted) return;
      setState(() {
        for (final step in _docSteps.keys) {
          _docSteps[step] = const _DocStepState(status: _DocStepStatus.done);
        }
        _isProcessing = false;
        _hasProcessedDocuments = true;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Process documents failed: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _hasProcessedDocuments = false;
        for (final step in _docSteps.keys) {
          _docSteps[step] = const _DocStepState(status: _DocStepStatus.pending);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process documents')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ATTACHMENT
  // ---------------------------------------------------------------------------
  Future<void> _pickAndSaveAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;

    final file = result.files.first;
    final bytes = file.bytes;
    // On web, PlatformFile.path throws; use bytes instead.
    final String? path = kIsWeb ? null : file.path;

    setState(() {
      _attachedFileName = file.name;
      _hasAttachment = true;
    });

    try {
      if (bytes == null && (path == null || path.isEmpty)) {
        throw StateError('Unable to read file bytes/path');
      }

      final multipart = bytes != null
          ? MultipartFile.fromBytes(bytes, filename: file.name)
          : await MultipartFile.fromFile(path!, filename: file.name);

      final uploads = await ResourceService.uploadAnswerSheets(
        files: [multipart],
        chatSessionId: widget.chatSessionId,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_attachmentKey, file.name);
      await prefs.setStringList(
        _answerSheetIdsKey,
        uploads.map((u) => u.resourceId).where((id) => id.isNotEmpty).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('upload_success'.tr(args: [file.name]))),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to upload answer sheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('upload_error'.tr())),
        );
      }
    }
  }

  Future<void> _removeAttachment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attachmentKey);
    await prefs.remove(_answerSheetIdsKey);

    setState(() {
      _attachedFileName = null;
      _hasAttachment = false;
    });
  }

  // ---------------------------------------------------------------------------
  // SEND FLOW
  // ---------------------------------------------------------------------------
  Future<void> _sendToChat() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_allDocumentsAvailable() || !_hasProcessedDocuments) return;

    final legacyData = prefs.getString(_evaluationStorageKey);
    final decoded = legacyData != null ? jsonDecode(legacyData) : null;
    final evalData = asStringKeyedMap(decoded);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationProcessPage(
          chatSessionId: widget.chatSessionId,
          attachmentName: _attachedFileName,
          evaluationData: evalData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (index) {
          setState(() => _selectedSegment = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LearningModePage()),
            );
          }
        },
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
        onRubricApplied: _loadAllData,
        chatSessionId: widget.chatSessionId,
      ),
      drawer: const RecentChatsDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'evaluation.startNewEvaluation'.tr(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statusChip('Rubric', _hasRubrics),
                          _statusChip('Marks', _hasMarks),
                          _statusChip('Attachment', _hasAttachment),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isProcessing ? null : _processDocuments,
                          icon: const Icon(Icons.auto_awesome),
                          label: Text('evaluation.processDocuments'.tr()),
                        ),
                      ),
                      if (_showProcessing) ...[
                        const SizedBox(height: 18),
                        Card(
                          elevation: 0,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(0.35),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Column(
                              children: [
                                for (final step in [
                                  _DocStep.answerSheets,
                                  _DocStep.questionPaper,
                                  _DocStep.syllabus,
                                  _DocStep.rubric,
                                  _DocStep.paperConfig,
                                ])
                                  _DocStepRow(
                                    title: _stepTitle(step),
                                    state: _docSteps[step] ??
                                        const _DocStepState(),
                                  ),
                                const SizedBox(height: 6),
                                if (_isProcessing)
                                  const LinearProgressIndicator(minHeight: 3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // INPUT BAR
          _InputBar(
            controller: _inputController,
            isDark: isDark,
            attachedFileName: _attachedFileName,
            onAttachPressed: _pickAndSaveAttachment,
            onRemoveAttachment: _removeAttachment,
            onMarksPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaperConfigReviewPage(
                    sessionId: widget.chatSessionId,
                  ),
                ),
              );
              _loadAllData();
            },
            onSendPressed: (_hasProcessedDocuments && _allDocumentsAvailable())
                ? _sendToChat
                : null,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool ok) {
    return Chip(
      label: Text('$label: ${ok ? '✓' : '✗'}'),
      backgroundColor: ok ? Colors.green.shade100 : Colors.red.shade100,
    );
  }
}

enum _DocStep {
  answerSheets,
  questionPaper,
  syllabus,
  rubric,
  paperConfig,
}

enum _DocStepStatus {
  pending,
  inProgress,
  done,
}

class _DocStepState {
  final _DocStepStatus status;
  final bool alreadyProcessed;

  const _DocStepState({
    this.status = _DocStepStatus.pending,
    this.alreadyProcessed = false,
  });
}

class _DocStepRow extends StatelessWidget {
  const _DocStepRow({
    required this.title,
    required this.state,
  });

  final String title;
  final _DocStepState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget leading;
    switch (state.status) {
      case _DocStepStatus.done:
        leading = Icon(Icons.check_circle,
            color: theme.colorScheme.primary, size: 20);
        break;
      case _DocStepStatus.inProgress:
        leading = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary,
          ),
        );
        break;
      case _DocStepStatus.pending:
        leading = Icon(Icons.radio_button_unchecked,
            color: theme.colorScheme.onSurface.withOpacity(0.45), size: 20);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (state.alreadyProcessed)
            Chip(
              label: Text('evaluation.alreadyProcessed'.tr()),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: _DocStepPercentText(status: state.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocStepPercentText extends StatelessWidget {
  const _DocStepPercentText({
    required this.status,
  });

  final _DocStepStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Pending: show 0%, Done: show 100%, In progress: animate 0% -> 100%.
    if (status == _DocStepStatus.inProgress) {
      return TweenAnimationBuilder<double>(
        key: const ValueKey('inProgressPercent'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        builder: (context, value, _) {
          final pct = (value * 100).clamp(0, 100).round();
          return Text(
            '$pct%',
            style: theme.textTheme.bodySmall,
          );
        },
      );
    }

    final pct = status == _DocStepStatus.done ? 100 : 0;
    return Text(
      '$pct%',
      style: theme.textTheme.bodySmall,
    );
  }
}

// -----------------------------------------------------------------------------
// INPUT BAR WIDGET (FIXED + COMPLETE)
// -----------------------------------------------------------------------------
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.onAttachPressed,
    required this.attachedFileName,
    required this.onRemoveAttachment,
    required this.onMarksPressed,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onAttachPressed;
  final String? attachedFileName;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onMarksPressed;
  final VoidCallback? onSendPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAttachPressed,
                icon: const Icon(Icons.attach_file),
                label: Text('evaluation.attach'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMarksPressed,
                icon: const Icon(Icons.add),
                label: Text('evaluation.marks'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSendPressed,
                icon: const Icon(Icons.send),
                label: Text('evaluation.send'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onSendPressed != null ? null : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/evaluation/evaluation_text.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:easy_localization/easy_localization.dart';
import 'learning_mode.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/blocking_progress_dialog.dart';
import '../../core/utils/json_cast.dart';
import '../../models/chat_session_details.dart';
import 'evaluation_process_page.dart';
import 'evaluation_response.dart';
import 'evaluation_doc_tokens.dart';
import '../../services/chat_service.dart';
import '../../services/resource_service.dart';
import '../../services/evaluation_service.dart';

// NEW PAGE
import 'paper_config_review_page.dart';

class EvaluationTextPage extends StatefulWidget {
  final String chatSessionId;
  final bool initialShowProcessing;

  const EvaluationTextPage({
    super.key,
    required this.chatSessionId,
    this.initialShowProcessing = false,
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
  static const String _answerSheetClearedKeyPrefix =
      'active_answer_sheet_cleared:';

  String get _questionPaperKey =>
      '$_questionPaperKeyPrefix${widget.chatSessionId}';
  String get _syllabusKey => '$_syllabusKeyPrefix${widget.chatSessionId}';
  String get _answerSheetIdsKey =>
      '$_answerSheetIdsKeyPrefix${widget.chatSessionId}';
  String get _answerSheetClearedKey =>
      '$_answerSheetClearedKeyPrefix${widget.chatSessionId}';
  String get _rubricKey => '$_rubricKeyPrefix${widget.chatSessionId}';

  bool _hasRubrics = false;
  bool _hasMarks = false;
  bool _hasAttachment = false;
  bool _hasQuestionPaper = false;
  bool _hasSyllabus = false;

  bool _showProcessing = false;
  bool _isProcessing = false;
  bool _needsReprocess = false;

  List<_UploadedDoc> _answerSheetDocs = const <_UploadedDoc>[];

  final Map<_DocStep, _DocStepState> _docSteps = {
    _DocStep.answerSheets: const _DocStepState(),
    _DocStep.questionPaper: const _DocStepState(),
    _DocStep.syllabus: const _DocStepState(),
  };

  @override
  void initState() {
    super.initState();
    _showProcessing = widget.initialShowProcessing;
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

    final clearedByUser = prefs.getBool(_answerSheetClearedKey) ?? false;
    final storedIds =
        prefs.getStringList(_answerSheetIdsKey) ?? const <String>[];
    final storedLatestId = storedIds.where((e) => e.isNotEmpty).isNotEmpty
        ? storedIds.where((e) => e.isNotEmpty).last
        : '';

    _attachedFileName = prefs.getString(_attachmentKey);
    _hasAttachment = storedLatestId.isNotEmpty || _attachedFileName != null;

    // Prefer backend truth (per chat session) so it survives logout/relogin.
    try {
      final details =
          await ChatService.getChatSessionDetails(widget.chatSessionId);
      _hasQuestionPaper = details.questionPaper != null;
      _hasSyllabus = details.syllabus != null;
      final attachedInBackend =
          (details.rubricId != null && details.rubricId!.isNotEmpty);
      final attachedInPrefs = (prefs.getBool(_rubricKey) ?? false) ||
          (prefs.getBool('hasRubric') ?? false);
      _hasRubrics = attachedInBackend || attachedInPrefs;

      // Answer sheets: allow many to exist in backend, but for evaluation we
      // always use the latest uploaded one.
      final answerSheets = details.answerSheets
          .where((e) => e.resourceId.isNotEmpty)
          .toList(growable: false);
      // IMPORTANT: backend may have many answer sheets historically.
      // We only treat an answer sheet as "attached" if the user has an active
      // selection locally, OR we auto-pick it (when not explicitly cleared).
      _hasAttachment = storedLatestId.isNotEmpty || _attachedFileName != null;

      SessionResource? activeAnswer;
      if (storedLatestId.isNotEmpty) {
        for (final a in answerSheets) {
          if (a.resourceId == storedLatestId) {
            activeAnswer = a;
            break;
          }
        }
      }

      SessionResource? latestAnswer;
      if (!clearedByUser && activeAnswer == null && answerSheets.isNotEmpty) {
        // Prefer backend timestamps when available.
        try {
          final sessionResources =
              await ResourceService.fetchChatSessionResources(
                  widget.chatSessionId);
          final createdAtById = <String, DateTime>{};
          for (final item in sessionResources) {
            final id = (item['id'] ?? item['resource_id'])?.toString() ?? '';
            final createdRaw = item['created_at']?.toString() ?? '';
            if (id.isEmpty || createdRaw.isEmpty) continue;
            final dt = DateTime.tryParse(createdRaw);
            if (dt != null) createdAtById[id] = dt.toUtc();
          }

          if (createdAtById.isNotEmpty) {
            answerSheets.sort((a, b) {
              final da = createdAtById[a.resourceId] ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
              final db = createdAtById[b.resourceId] ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
              return da.compareTo(db);
            });
          }
        } catch (_) {
          // ignore - fallback to backend order
        }

        // Fallback assumption: backend list order is chronological.
        latestAnswer = answerSheets.isNotEmpty ? answerSheets.last : null;
      }

      final chosen = activeAnswer ?? latestAnswer;
      if (chosen != null) {
        final name = chosen.filename.isNotEmpty
            ? chosen.filename
            : 'Resource ${chosen.resourceId}';
        _answerSheetDocs = <_UploadedDoc>[
          _UploadedDoc(
            id: chosen.resourceId,
            name: name,
            sizeBytes: chosen.sizeBytes,
            mimeType: chosen.mimeType,
          ),
        ];
        _attachedFileName = name;

        _hasAttachment = true;

        // Persist only the chosen active ID locally for downstream processing.
        await prefs
            .setStringList(_answerSheetIdsKey, <String>[chosen.resourceId]);
        await prefs.setBool(_answerSheetClearedKey, false);
      } else {
        _answerSheetDocs = const <_UploadedDoc>[];
        _attachedFileName = null;
        _hasAttachment = false;
      }

      // Some backends may not include answer sheets in session resources yet.
      // If we have locally cached answer sheet IDs for this chat, treat them
      // as attached so processing can proceed.
      if (!_hasAttachment) {
        final ids = prefs.getStringList(_answerSheetIdsKey);
        if (ids != null && ids.isNotEmpty) {
          _hasAttachment = true;

          final latestId = ids.where((e) => e.isNotEmpty).isNotEmpty
              ? ids.where((e) => e.isNotEmpty).last
              : '';
          if (latestId.isNotEmpty) {
            // Show placeholder when we only have the ID locally.
            _answerSheetDocs = <_UploadedDoc>[
              _UploadedDoc(
                id: latestId,
                name: 'Resource $latestId',
                sizeBytes: 0,
                mimeType: '',
              ),
            ];
            _attachedFileName ??= 'Resource $latestId';
          }
        }
      }
    } catch (_) {
      // Fallback to legacy local state if backend fetch fails.
      _hasRubrics = (prefs.getBool(_rubricKey) ?? false) ||
          (prefs.getBool('hasRubric') ?? false);

      final ids = prefs.getStringList(_answerSheetIdsKey);
      final localLatestId =
          (ids ?? const <String>[]).where((e) => e.isNotEmpty).isNotEmpty
              ? (ids ?? const <String>[]).where((e) => e.isNotEmpty).last
              : '';

      if (clearedByUser && localLatestId.isEmpty) {
        _hasAttachment = false;
        _attachedFileName = null;
        _answerSheetDocs = const <_UploadedDoc>[];
      } else {
        _hasAttachment = localLatestId.isNotEmpty || _hasAttachment;
      }

      final filtered =
          (ids ?? const <String>[]).where((e) => e.isNotEmpty).toList();
      final latestId = filtered.isNotEmpty ? filtered.last : '';
      _answerSheetDocs = latestId.isNotEmpty
          ? <_UploadedDoc>[
              _UploadedDoc(
                id: latestId,
                name: 'Resource $latestId',
                sizeBytes: 0,
                mimeType: '',
              ),
            ]
          : const <_UploadedDoc>[];

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

    // Determine if uploaded docs changed since last successful processing.
    final currentTokens =
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId);
    final processedTokens =
        EvalDocTokens.loadProcessed(prefs, chatSessionId: widget.chatSessionId);
    final canProcess = _canProcessDocuments();
    _needsReprocess = canProcess &&
        (processedTokens == null ||
            !EvalDocTokens.equals(
              currentTokens,
              processedTokens,
            ));

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

  String _stepTitle(_DocStep step) {
    switch (step) {
      case _DocStep.answerSheets:
        return 'evaluation.docStepAnswerSheetsProcessing'.tr();
      case _DocStep.questionPaper:
        return 'evaluation.docStepQuestionPaperProcessing'.tr();
      case _DocStep.syllabus:
        return 'evaluation.docStepSyllabusProcessing'.tr();
    }
  }

  bool _canProcessDocuments() {
    // Only these docs are processed: Answer sheets + Question paper + Syllabus.
    return _hasAttachment && _hasQuestionPaper && _hasSyllabus;
  }

  bool _canStartDocumentProcessing() {
    // UX gate: require rubric + required documents before processing.
    return _hasRubrics && _canProcessDocuments();
  }

  bool _documentsProcessedUpToDate() {
    // After processing completes and there are no pending changes.
    return _canProcessDocuments() && !_needsReprocess;
  }

  Future<void> _processDocuments() async {
    if (_isProcessing) return;

    // ignore: avoid_print
    print(
        'ProcessDocuments clicked for chatSessionId: ${widget.chatSessionId}');

    setState(() {
      _showProcessing = true;
      _isProcessing = true;
      for (final step in _docSteps.keys) {
        _docSteps[step] = const _DocStepState(status: _DocStepStatus.pending);
      }
    });

    // Refresh current availability before starting.
    await _loadAllData();

    final prefs = await SharedPreferences.getInstance();
    final answerIds =
        prefs.getStringList(_answerSheetIdsKey) ?? const <String>[];
    final latestAnswerId = answerIds.where((e) => e.isNotEmpty).isNotEmpty
        ? answerIds.where((e) => e.isNotEmpty).last
        : '';

    // ignore: avoid_print
    print('ProcessDocuments latest answer_resource_id: $latestAnswerId');

    // Hard gate: we only process when question paper + syllabus + answer sheets exist.
    if (!_hasQuestionPaper || !_hasSyllabus) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Missing question paper or syllabus upload')),
        );
      }
      return;
    }
    if (latestAnswerId.isEmpty) {
      setState(() {
        _isProcessing = false;
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
        answerResourceIds: <String>[latestAnswerId],
      );

      await EvalDocTokens.saveProcessed(
        prefs,
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId),
        chatSessionId: widget.chatSessionId,
      );

      if (!mounted) return;
      setState(() {
        for (final step in _docSteps.keys) {
          _docSteps[step] = const _DocStepState(status: _DocStepStatus.done);
        }
        _isProcessing = false;
        _needsReprocess = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Process documents failed: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
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

    unawaited(
      showBlockingProgressDialog(
        context,
        message: 'Uploading ${file.name}...',
      ),
    );

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

      final latestId = uploads
              .map((u) => u.resourceId)
              .where((id) => id.isNotEmpty)
              .isNotEmpty
          ? uploads.map((u) => u.resourceId).where((id) => id.isNotEmpty).last
          : '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_attachmentKey, file.name);
      if (latestId.isNotEmpty) {
        // Keep only the latest answer sheet per evaluation session.
        await prefs.setStringList(_answerSheetIdsKey, <String>[latestId]);
        await prefs.setBool(_answerSheetClearedKey, false);
        if (mounted) {
          setState(() {
            _answerSheetDocs = <_UploadedDoc>[
              _UploadedDoc(
                id: latestId,
                name: file.name,
                sizeBytes: file.size,
                mimeType: _guessMimeTypeFromName(file.name),
              ),
            ];
          });
        }
      }

      // Docs changed: require re-process.
      if (mounted) {
        setState(() {
          _needsReprocess = _canProcessDocuments();
        });
      }

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
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _removeAttachment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attachmentKey);
    await prefs.remove(_answerSheetIdsKey);
    await prefs.setBool(_answerSheetClearedKey, true);

    setState(() {
      _attachedFileName = null;
      _hasAttachment = false;
      _answerSheetDocs = const <_UploadedDoc>[];
      _needsReprocess = _canProcessDocuments();
    });
  }

  String _guessMimeTypeFromName(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return '';
  }

  // ---------------------------------------------------------------------------
  // SEND FLOW
  // ---------------------------------------------------------------------------
  Future<void> _sendToChat() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_allDocumentsAvailable()) return;

    // Require "Process Documents" to be up-to-date before evaluation.
    final currentTokens =
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId);
    final processedTokens =
        EvalDocTokens.loadProcessed(prefs, chatSessionId: widget.chatSessionId);
    final upToDate = processedTokens != null &&
        EvalDocTokens.equals(currentTokens, processedTokens);
    if (!upToDate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('evaluation.docsChangedBody'.tr())),
        );
      }
      return;
    }

    final answerIds =
        prefs.getStringList(_answerSheetIdsKey) ?? const <String>[];
    final latestAnswerId = answerIds.where((e) => e.isNotEmpty).isNotEmpty
        ? answerIds.where((e) => e.isNotEmpty).last
        : '';

    if (latestAnswerId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing answer sheet upload')),
        );
      }
      return;
    }

    try {
      final res = await EvaluationService.startEvaluation(
        chatSessionId: widget.chatSessionId,
        answerResourceIds: <String>[latestAnswerId],
      );

      final evalSessionId =
          (res ?? const <String, dynamic>{})['id']?.toString();
      if (evalSessionId != null && evalSessionId.isNotEmpty) {
        await prefs.setString(
          'evaluation_session_id:${widget.chatSessionId}',
          evalSessionId,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Failed to start evaluation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start evaluation')),
        );
      }
      return;
    }

    final legacyData = prefs.getString(_evaluationStorageKey);
    final decoded = legacyData != null ? jsonDecode(legacyData) : null;
    final evalData = asStringKeyedMap(decoded);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationProcessPage(
          chatSessionId: widget.chatSessionId,
          assumeDocsAvailable: true,
          attachmentName: _attachedFileName,
          evaluationData: evalData,
          evaluationSessionId: evalSessionId,
        ),
      ),
    );
  }

  void _openResultsHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationResponsePage(
          chatSessionId: widget.chatSessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final docsReadyForProcessing = _canStartDocumentProcessing();
    final docsProcessed = _documentsProcessedUpToDate();
    final marksAvailable = docsProcessed;
    final sendAvailable = docsProcessed && _hasMarks && _hasRubrics;

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
        onHistoryPressed: _openResultsHistory,
        chatSessionId: widget.chatSessionId,
      ),
      drawer: const RecentChatsDrawer(),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
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
                      _Roadmap(
                        steps: [
                          _RoadmapStep(
                            icon: Icons.rule,
                            isActive: _hasRubrics,
                            label: 'Rubric',
                            tooltip: 'Select/apply a rubric',
                          ),
                          _RoadmapStep(
                            icon: Icons.menu_book_outlined,
                            isActive: _hasSyllabus,
                            label: 'Syllabus',
                            tooltip: 'Upload and select syllabus',
                          ),
                          _RoadmapStep(
                            icon: Icons.description_outlined,
                            isActive: _hasQuestionPaper,
                            label: 'Question',
                            tooltip: 'Upload question paper',
                          ),
                          _RoadmapStep(
                            icon: Icons.attachment_outlined,
                            isActive: _hasAttachment,
                            label: 'Answer',
                            tooltip: 'Upload answer sheet',
                          ),
                          _RoadmapStep(
                            icon: Icons.auto_awesome,
                            isActive: docsProcessed,
                            isAvailable: docsReadyForProcessing,
                            label: 'Process',
                            tooltip:
                                'Process documents (required before marks)',
                          ),
                          _RoadmapStep(
                            icon: Icons.edit_note,
                            isActive: docsProcessed && _hasMarks,
                            isAvailable: marksAvailable,
                            label: 'Marks',
                            tooltip: 'Configure marks / paper settings',
                          ),
                          _RoadmapStep(
                            icon: Icons.send,
                            isActive: false,
                            isAvailable: sendAvailable,
                            label: 'Send',
                            tooltip: 'Send for evaluation',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Uploaded answer sheets details
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Uploaded Answer Sheets',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 10),
                              if (_needsReprocess)
                                Card(
                                  elevation: 0,
                                  color: theme.colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.35),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'evaluation.docsChangedTitle'
                                                    .tr(),
                                                style:
                                                    theme.textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'evaluation.docsChangedBody'
                                                    .tr(),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withOpacity(0.75),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_answerSheetDocs.isEmpty)
                                Text(
                                  'No answer sheets uploaded',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                )
                              else
                                ..._answerSheetDocs.map(
                                  (d) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _UploadedDocRow(doc: d),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Tooltip(
                                              message:
                                                  'evaluation.replaceAttachment'
                                                      .tr(),
                                              waitDuration: const Duration(
                                                  milliseconds: 250),
                                              child: TextButton.icon(
                                                onPressed: _isProcessing
                                                    ? null
                                                    : _pickAndSaveAttachment,
                                                icon: const Icon(
                                                    Icons.swap_horiz),
                                                label: Text(
                                                  'evaluation.replaceAttachment'
                                                      .tr(),
                                                ),
                                              ),
                                            ),
                                            Tooltip(
                                              message:
                                                  'evaluation.removeAttachment'
                                                      .tr(),
                                              waitDuration: const Duration(
                                                  milliseconds: 250),
                                              child: TextButton.icon(
                                                onPressed: _isProcessing
                                                    ? null
                                                    : _removeAttachment,
                                                icon: const Icon(Icons.close),
                                                label: Text(
                                                  'evaluation.removeAttachment'
                                                      .tr(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : (docsReadyForProcessing
                                  ? _processDocuments
                                  : null),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text('evaluation.processDocuments'.tr()),
                        ),
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _openResultsHistory,
                          icon: const Icon(Icons.history),
                          label: Text('evaluation.viewResultsHistory'.tr()),
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
                  ),
                );
              },
            ),
          ),

          // INPUT BAR
          _InputBar(
            controller: _inputController,
            isDark: isDark,
            attachedFileName: _attachedFileName,
            onAttachPressed: _pickAndSaveAttachment,
            onMarksPressed: marksAvailable
                ? () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaperConfigReviewPage(
                          sessionId: widget.chatSessionId,
                        ),
                      ),
                    );
                    _loadAllData();
                  }
                : null,
            onSendPressed:
                (_allDocumentsAvailable() && !_needsReprocess && docsProcessed)
                    ? _sendToChat
                    : null,
          ),
        ],
      ),
    );
  }
}

class _RoadmapStep {
  final IconData icon;
  final bool isActive;
  final bool isAvailable;
  final String label;
  final String tooltip;

  const _RoadmapStep({
    required this.icon,
    required this.isActive,
    required this.label,
    required this.tooltip,
    bool? isAvailable,
  }) : isAvailable = isAvailable ?? true;
}

class _Roadmap extends StatelessWidget {
  final List<_RoadmapStep> steps;

  const _Roadmap({required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.35);
    final disabledColor = theme.colorScheme.onSurface.withOpacity(0.18);

    const bubbleSize = 36.0;

    return SizedBox(
      height: 74,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _RoadmapBubble(
                  step: steps[i],
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  disabledColor: disabledColor,
                ),
                if (i != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: steps[i + 1].isAvailable
                            ? (steps[i].isActive || steps[i + 1].isActive
                                ? activeColor.withOpacity(0.65)
                                : inactiveColor)
                            : disabledColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                SizedBox(
                  width: bubbleSize,
                  child: Text(
                    steps[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: steps[i].isAvailable
                          ? theme.colorScheme.onSurface.withOpacity(0.75)
                          : theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ),
                ),
                if (i != steps.length - 1) const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RoadmapBubble extends StatelessWidget {
  final _RoadmapStep step;
  final Color activeColor;
  final Color inactiveColor;
  final Color disabledColor;

  const _RoadmapBubble({
    required this.step,
    required this.activeColor,
    required this.inactiveColor,
    required this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bg = step.isAvailable
        ? (step.isActive ? activeColor : theme.colorScheme.surface)
        : theme.colorScheme.surface;
    final border = step.isAvailable
        ? (step.isActive ? activeColor : inactiveColor)
        : disabledColor;
    final fg = step.isAvailable
        ? (step.isActive ? theme.colorScheme.onPrimary : inactiveColor)
        : disabledColor;

    return Tooltip(
      message: step.tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: Semantics(
        label: step.label,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(
            step.isActive ? Icons.check : step.icon,
            size: 18,
            color: fg,
          ),
        ),
      ),
    );
  }
}

enum _DocStep {
  answerSheets,
  questionPaper,
  syllabus,
}

class _UploadedDoc {
  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;

  const _UploadedDoc({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
  });

  String metaText() {
    final type = _typeLabel(mimeType, name);
    final size = _formatBytes(sizeBytes);
    if (type.isEmpty && size.isEmpty) return '';
    if (type.isNotEmpty && size.isNotEmpty) return '$type • $size';
    return type.isNotEmpty ? type : size;
  }
}

class _UploadedDocRow extends StatelessWidget {
  const _UploadedDocRow({required this.doc});

  final _UploadedDoc doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = doc.metaText();

    return Row(
      children: [
        Icon(
          Icons.article_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _typeLabel(String mimeType, String filename) {
  final mt = mimeType.toLowerCase();
  if (mt.contains('pdf')) return 'PDF';
  if (mt.contains('word') || mt.contains('officedocument')) return 'DOC';

  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) return '';
  return filename.substring(dot + 1).toUpperCase();
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '';
  const unit = 1024;
  if (bytes < unit) return '$bytes B';
  if (bytes < unit * unit) {
    final kb = bytes / unit;
    return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
  }
  final mb = bytes / (unit * unit);
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
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

  String _statusLabelKey() {
    switch (state.status) {
      case _DocStepStatus.done:
        return 'evaluation.statusCompleted';
      case _DocStepStatus.inProgress:
        return 'evaluation.statusProcessing';
      case _DocStepStatus.pending:
        return 'evaluation.statusStarting';
    }
  }

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
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              _statusLabelKey().tr(),
              style: theme.textTheme.labelMedium,
            ),
          ),
          if (state.alreadyProcessed) const SizedBox(width: 8),
          if (state.alreadyProcessed)
            Chip(
              label: Text('evaluation.alreadyProcessed'.tr()),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
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
    required this.onMarksPressed,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onAttachPressed;
  final String? attachedFileName;
  final VoidCallback? onMarksPressed;
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
              child: attachedFileName == null
                  ? Tooltip(
                      message: 'evaluation.attach'.tr(),
                      waitDuration: const Duration(milliseconds: 250),
                      child: ElevatedButton.icon(
                        onPressed: onAttachPressed,
                        icon: const Icon(Icons.attach_file),
                        label: Text('evaluation.attach'.tr()),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: 'evaluation.replaceAttachment'.tr(),
                            waitDuration: const Duration(milliseconds: 250),
                            child: ElevatedButton.icon(
                              // Tapping the file triggers "Replace".
                              onPressed: onAttachPressed,
                              icon: const Icon(Icons.attachment_outlined),
                              label: Text(
                                attachedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMarksPressed,
                icon: const Icon(Icons.add),
                label: Text('evaluation.marks'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: onMarksPressed != null ? null : Colors.grey,
                ),
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

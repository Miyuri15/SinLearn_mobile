import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/teachers_main_app_bar.dart';
import 'evaluation_response.dart';
import 'evaluation_doc_tokens.dart';
import '../../services/evaluation_service.dart';

enum _StepStatus { pending, inProgress, done }

enum _DocStep {
  answerSheets,
  questionPaper,
  syllabus,
}

class _DocStepState {
  const _DocStepState({
    this.status = _StepStatus.pending,
    this.alreadyProcessed = false,
    this.progress = 0,
  });

  final _StepStatus status;
  final bool alreadyProcessed;
  final int progress; // 0..100

  _DocStepState copyWith({
    _StepStatus? status,
    bool? alreadyProcessed,
    int? progress,
  }) {
    return _DocStepState(
      status: status ?? this.status,
      alreadyProcessed: alreadyProcessed ?? this.alreadyProcessed,
      progress: progress ?? this.progress,
    );
  }
}

class _StepState {
  const _StepState({this.status = _StepStatus.pending, this.progress = 0});

  final _StepStatus status;
  final int progress; // 0..100

  _StepState copyWith({_StepStatus? status, int? progress}) {
    return _StepState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}

class EvaluationProcessPage extends StatefulWidget {
  const EvaluationProcessPage({
    super.key,
    required this.chatSessionId,
    this.attachmentName,
    this.evaluationData,
  });

  final String chatSessionId;
  final String? attachmentName;
  final Map<String, dynamic>? evaluationData;

  @override
  State<EvaluationProcessPage> createState() => _EvaluationProcessPageState();
}

class _EvaluationProcessPageState extends State<EvaluationProcessPage> {
  int _selectedSegment = 1;

  bool _isProcessingDocs = false;
  bool _docsAvailable = false;
  bool _docsReady = false; // processed + ready to evaluate
  bool _needsReprocess = false;

  int _runToken = 0;
  int _currentEvaluationRunId = 0;
  Timer? _docWatchTimer;
  Map<String, String>? _lastObservedTokens;

  Map<_DocStep, _DocStepState> _docSteps = {
    _DocStep.answerSheets: const _DocStepState(),
    _DocStep.questionPaper: const _DocStepState(),
    _DocStep.syllabus: const _DocStepState(),
  };

  bool _isEvaluating = false;
  bool _evaluationDone = false;

  final List<String> _evaluationSteps = [
    'evaluation.evalStepEvaluating'.tr(),
    'evaluation.evalStepCalculatingMarks'.tr(),
    'evaluation.evalStepGeneratingFeedback'.tr(),
    'evaluation.evalStepPreparingReport'.tr(),
  ];

  late final List<_StepState> _evalStates = List<_StepState>.generate(
    _evaluationSteps.length,
    (_) => const _StepState(),
  );

  @override
  void initState() {
    super.initState();
    _startFlow();
    _startDocWatch();
  }

  @override
  void dispose() {
    _docWatchTimer?.cancel();
    super.dispose();
  }

  void _startDocWatch() {
    _docWatchTimer?.cancel();
    _docWatchTimer =
        Timer.periodic(const Duration(milliseconds: 900), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final current = EvalDocTokens.buildCurrent(prefs,
          chatSessionId: widget.chatSessionId);

      final last = _lastObservedTokens;
      _lastObservedTokens = current;
      if (last == null) return;
      if (!EvalDocTokens.equals(current, last)) {
        _handleDocumentsChanged();
      }
    });
  }

  void _handleDocumentsChanged() {
    // Cancel any in-flight processing/evaluation and require explicit reprocess.
    _runToken++;
    if (!mounted) return;

    setState(() {
      _isProcessingDocs = false;
      _docsReady = false;
      _needsReprocess = true;
      _isEvaluating = false;
      _evaluationDone = false;
      _resetEvaluationStates();
    });

    // Refresh displayed doc step statuses based on latest prefs.
    _refreshDocStatus();
  }

  void _resetEvaluationStates() {
    for (int i = 0; i < _evalStates.length; i++) {
      _evalStates[i] = const _StepState();
    }
  }

  Future<void> _reprocessDocumentsAndEvaluate() async {
    if (_isProcessingDocs || _isEvaluating) return;
    if (!_docsAvailable) return;

    if (!mounted) return;
    setState(() {
      _docsReady = false;
      _isProcessingDocs = true;
      _needsReprocess = false;
      _evaluationDone = false;
      _isEvaluating = false;
      _resetEvaluationStates();
    });

    final runId = ++_runToken;
    final processed = await _processChangedDocuments(runId: runId);
    if (!processed) return;

    if (!mounted || runId != _runToken) return;
    setState(() {
      _currentEvaluationRunId = DateTime.now().microsecondsSinceEpoch;
      _isEvaluating = true;
    });
    await _runEvaluation(runId: runId);
  }

  String _docTitle(_DocStep step) {
    switch (step) {
      case _DocStep.answerSheets:
        return 'evaluation.docStepAnswerSheetsProcessing'.tr();
      case _DocStep.questionPaper:
        return 'evaluation.docStepQuestionPaperProcessing'.tr();
      case _DocStep.syllabus:
        return 'evaluation.docStepSyllabusProcessing'.tr();
    }
  }

  String _tokenKeyForStep(_DocStep step) {
    switch (step) {
      case _DocStep.answerSheets:
        return 'answerSheets';
      case _DocStep.questionPaper:
        return 'questionPaper';
      case _DocStep.syllabus:
        return 'syllabus';
    }
  }

  Future<void> _startFlow() async {
    // On entry: do NOT auto-reprocess. Only evaluate if docs are already processed.
    await _refreshDocStatus();
    if (!mounted) return;

    if (_docsReady && !_needsReprocess) {
      final runId = ++_runToken;
      setState(() {
        _currentEvaluationRunId = DateTime.now().microsecondsSinceEpoch;
        _isEvaluating = true;
        _evaluationDone = false;
        _resetEvaluationStates();
      });
      await _runEvaluation(runId: runId);
    } else {
      setState(() {
        _isEvaluating = false;
        _evaluationDone = false;
        _resetEvaluationStates();
      });
    }
  }

  bool _allDocumentsAvailable(SharedPreferences prefs) {
    final answerIds =
        prefs.getStringList('answer_sheet_ids:${widget.chatSessionId}') ??
            const <String>[];
    final hasAttachment = answerIds.isNotEmpty ||
        (prefs.getString(EvalDocKeys.attachment) ?? '').isNotEmpty;

    final hasQuestionPaper =
        (prefs.getString('question_paper_file:${widget.chatSessionId}') ??
                prefs.getString(EvalDocKeys.questionPaperFile) ??
                '')
            .isNotEmpty;

    final hasSyllabus =
        (prefs.getStringList('syllabus_items:${widget.chatSessionId}') ??
                prefs.getStringList(EvalDocKeys.syllabusItems) ??
                const <String>[])
            .isNotEmpty;
    final hasRubric = prefs.getBool(EvalDocKeys.hasRubric) ?? false;

    final legacyMarks = prefs.getString(EvalDocKeys.evaluationData) ?? '';
    final paperConfirmed =
        prefs.getBool(EvalDocKeys.paperConfigConfirmed) ?? false;
    final hasMarks = (legacyMarks.isNotEmpty) || paperConfirmed;

    return hasAttachment &&
        hasQuestionPaper &&
        hasSyllabus &&
        hasRubric &&
        hasMarks;
  }

  Future<void> _refreshDocStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTokens =
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId);
    final processedTokens = EvalDocTokens.loadProcessed(prefs);

    final docsAvailable = _allDocumentsAvailable(prefs);
    final ordered = <_DocStep>[
      _DocStep.answerSheets,
      _DocStep.questionPaper,
      _DocStep.syllabus,
    ];

    final nextStates = <_DocStep, _DocStepState>{};
    var needsReprocess = false;

    if (docsAvailable) {
      for (final step in ordered) {
        final key = _tokenKeyForStep(step);
        final same = processedTokens != null &&
            processedTokens[key] == currentTokens[key];
        if (same) {
          nextStates[step] = const _DocStepState(
            status: _StepStatus.done,
            alreadyProcessed: true,
            progress: 100,
          );
        } else {
          nextStates[step] =
              const _DocStepState(status: _StepStatus.pending, progress: 0);
          needsReprocess = true;
        }
      }
    } else {
      for (final step in ordered) {
        nextStates[step] =
            const _DocStepState(status: _StepStatus.pending, progress: 0);
      }
      needsReprocess = true;
    }

    if (!mounted) return;
    setState(() {
      _docsAvailable = docsAvailable;
      _docSteps = nextStates;
      _docsReady = docsAvailable && !needsReprocess;
      _needsReprocess = needsReprocess;
      _isProcessingDocs = false;
    });
  }

  Future<bool> _processChangedDocuments({required int runId}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTokens =
        EvalDocTokens.buildCurrent(prefs, chatSessionId: widget.chatSessionId);
    final processedTokens = EvalDocTokens.loadProcessed(prefs);

    final docsAvailable = _allDocumentsAvailable(prefs);
    if (!docsAvailable) {
      if (!mounted || runId != _runToken) return false;
      setState(() {
        _docsAvailable = false;
        _docsReady = false;
        _needsReprocess = true;
        _isProcessingDocs = false;
      });
      return false;
    }

    final ordered = <_DocStep>[
      _DocStep.answerSheets,
      _DocStep.questionPaper,
      _DocStep.syllabus,
    ];

    final stepsNeedingWork = <_DocStep>[];
    final nextStates = <_DocStep, _DocStepState>{};
    for (final step in ordered) {
      final key = _tokenKeyForStep(step);
      final same =
          processedTokens != null && processedTokens[key] == currentTokens[key];
      if (same) {
        nextStates[step] = const _DocStepState(
          status: _StepStatus.done,
          alreadyProcessed: true,
          progress: 100,
        );
      } else {
        nextStates[step] =
            const _DocStepState(status: _StepStatus.pending, progress: 0);
        stepsNeedingWork.add(step);
      }
    }

    if (!mounted || runId != _runToken) return false;
    setState(() {
      _docsAvailable = true;
      _docSteps = nextStates;
      _isProcessingDocs = stepsNeedingWork.isNotEmpty;
    });

    if (stepsNeedingWork.isNotEmpty) {
      try {
        final answerIds =
            prefs.getStringList('answer_sheet_ids:${widget.chatSessionId}') ??
                const <String>[];
        final latest = answerIds.where((e) => e.isNotEmpty).isNotEmpty
            ? answerIds.where((e) => e.isNotEmpty).last
            : '';
        await EvaluationService.processDocumentsStream(
          chatSessionId: widget.chatSessionId,
          answerResourceIds:
              latest.isEmpty ? const <String>[] : <String>[latest],
        );
      } catch (e) {
        // ignore: avoid_print
        print('Process documents failed: $e');
        if (!mounted || runId != _runToken) return false;
        setState(() {
          _isProcessingDocs = false;
          _docsReady = false;
          _needsReprocess = true;
        });
        return false;
      }
    }

    // Process only the changed steps.
    for (final step in ordered) {
      if (!stepsNeedingWork.contains(step)) continue;
      if (!mounted || runId != _runToken) return false;

      setState(() {
        _docSteps[step] = (_docSteps[step] ?? const _DocStepState()).copyWith(
          status: _StepStatus.inProgress,
          progress: 0,
          alreadyProcessed: false,
        );
      });

      for (int p = 20; p <= 100; p += 20) {
        await Future.delayed(const Duration(milliseconds: 280));
        if (!mounted || runId != _runToken) return false;
        setState(() {
          _docSteps[step] = (_docSteps[step] ?? const _DocStepState()).copyWith(
            progress: p,
          );
        });
      }

      if (!mounted || runId != _runToken) return false;
      setState(() {
        _docSteps[step] = (_docSteps[step] ?? const _DocStepState()).copyWith(
          status: _StepStatus.done,
          progress: 100,
        );
      });
    }

    await EvalDocTokens.saveProcessed(prefs, currentTokens);
    if (!mounted || runId != _runToken) return false;
    setState(() {
      _docsReady = true;
      _needsReprocess = false;
      _isProcessingDocs = false;
    });
    return true;
  }

  Future<void> _runEvaluation({required int runId}) async {
    // Simple simulated progress. Replace with real API calls when available.
    for (int i = 0; i < _evalStates.length; i++) {
      if (!mounted || runId != _runToken) return;

      setState(() {
        _evalStates[i] = _evalStates[i].copyWith(
          status: _StepStatus.inProgress,
          progress: 0,
        );
      });

      // Animate progress within the step.
      for (int p = 20; p <= 100; p += 20) {
        await Future.delayed(const Duration(milliseconds: 320));
        if (!mounted || runId != _runToken) return;
        setState(() {
          _evalStates[i] = _evalStates[i].copyWith(progress: p);
        });
      }

      if (!mounted || runId != _runToken) return;
      setState(() {
        _evalStates[i] = _evalStates[i].copyWith(status: _StepStatus.done);
      });
    }

    if (!mounted || runId != _runToken) return;
    setState(() {
      _isEvaluating = false;
      _evaluationDone = true;
    });
  }

  void _openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationResponsePage(
          chatSessionId: widget.chatSessionId,
          initialMessageText: 'evaluation.evaluationStarted'.tr(),
          attachmentName: widget.attachmentName,
          evaluationData: widget.evaluationData,
          evaluationRunId: _currentEvaluationRunId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missingRequiredDocs = !_docsAvailable;
    final needsReprocess = _docsAvailable && _needsReprocess;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (_) {},
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
        chatSessionId: widget.chatSessionId,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              children: [
                Text(
                  'evaluation.evaluationInProgress'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),

                if (missingRequiredDocs) ...[
                  _SectionCard(
                    title: 'evaluation.missingDocsTitle'.tr(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'evaluation.missingDocsBody'.tr(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (!missingRequiredDocs && needsReprocess) ...[
                  _SectionCard(
                    title: 'evaluation.docsChangedTitle'.tr(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.refresh_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'evaluation.docsChangedBody'.tr(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Documents: show as already complete once the user is here.
                _SectionCard(
                  title: 'evaluation.processDocuments'.tr(),
                  child: Column(
                    children: [
                      for (final step in <_DocStep>[
                        _DocStep.answerSheets,
                        _DocStep.questionPaper,
                        _DocStep.syllabus,
                      ])
                        _RowStep(
                          title: _docTitle(step),
                          status:
                              (_docSteps[step] ?? const _DocStepState()).status,
                          trailingLabel:
                              (_docSteps[step] ?? const _DocStepState())
                                      .alreadyProcessed
                                  ? 'evaluation.alreadyProcessed'.tr()
                                  : null,
                          progress: (_docSteps[step] ?? const _DocStepState())
                              .progress,
                        ),
                      const SizedBox(height: 6),
                      if (_isProcessingDocs)
                        const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_isProcessingDocs ||
                                  _isEvaluating ||
                                  !_needsReprocess)
                              ? null
                              : _reprocessDocumentsAndEvaluate,
                          icon: const Icon(Icons.refresh_outlined),
                          label: Text('evaluation.reprocessDocuments'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Evaluation progress
                _SectionCard(
                  title: 'evaluation.send'.tr(),
                  child: Column(
                    children: [
                      if (missingRequiredDocs || needsReprocess) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 18,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.65),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                missingRequiredDocs
                                    ? 'evaluation.waitingForDocuments'.tr()
                                    : 'evaluation.waitingForReprocess'.tr(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      for (int i = 0; i < _evaluationSteps.length; i++)
                        _RowStep(
                          title: _evaluationSteps[i],
                          status: _evalStates[i].status,
                          trailingLabel:
                              _evalStates[i].status == _StepStatus.done
                                  ? 'evaluation.alreadyProcessed'.tr()
                                  : null,
                          progress: _evalStates[i].progress,
                        ),
                      const SizedBox(height: 8),
                      if (_isEvaluating)
                        const LinearProgressIndicator(minHeight: 3),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _evaluationDone ? _openResults : null,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text('evaluation.viewResults'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _RowStep extends StatelessWidget {
  const _RowStep({
    required this.title,
    required this.status,
    required this.progress,
    this.trailingLabel,
  });

  final String title;
  final _StepStatus status;
  final int progress;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget leading;
    switch (status) {
      case _StepStatus.done:
        leading = Icon(Icons.check_circle,
            color: theme.colorScheme.primary, size: 20);
        break;
      case _StepStatus.inProgress:
        leading = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: theme.colorScheme.primary,
          ),
        );
        break;
      case _StepStatus.pending:
        leading = Icon(
          Icons.radio_button_unchecked,
          color: theme.colorScheme.onSurface.withOpacity(0.45),
          size: 20,
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 10),
          if (trailingLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(trailingLabel!, style: theme.textTheme.labelMedium),
            )
          else
            Text('$progress%', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

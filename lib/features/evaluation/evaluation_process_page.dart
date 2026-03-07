import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/teachers_main_app_bar.dart';
import 'evaluation_response.dart';
import 'evaluation_doc_tokens.dart';
import '../../services/chat_service.dart';
import '../../services/evaluation_service.dart';

enum _StepStatus { pending, inProgress, done }

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
    this.assumeDocsAvailable = false,
    this.attachmentName,
    this.evaluationData,
    this.evaluationSessionId,
  });

  final String chatSessionId;
  final bool assumeDocsAvailable;
  final String? attachmentName;
  final Map<String, dynamic>? evaluationData;
  final String? evaluationSessionId;

  @override
  State<EvaluationProcessPage> createState() => _EvaluationProcessPageState();
}

class _EvaluationProcessPageState extends State<EvaluationProcessPage> {
  final int _selectedSegment = 1;

  bool _docsAvailable = false;
  String? _questionPaperName;
  int _syllabusCount = 0;
  bool _hasRubric = false;

  int _runToken = 0;
  int _currentEvaluationRunId = 0;

  bool _isEvaluating = false;
  bool _evaluationDone = false;
  String? _lastStatusLine;

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _resetEvaluationStates() {
    for (int i = 0; i < _evalStates.length; i++) {
      _evalStates[i] = const _StepState();
    }
  }

  Future<void> _loadReadOnlySummary(SharedPreferences prefs) async {
    String? questionPaperName;
    var syllabusCount = 0;
    var hasRubric = false;

    // Prefer backend truth so it survives logout/relogin.
    try {
      final details =
          await ChatService.getChatSessionDetails(widget.chatSessionId);

      final qp = details.questionPaper;
      if (qp != null) {
        final name = (qp.filename).trim().isNotEmpty
            ? qp.filename
            : (qp.resourceId.isNotEmpty ? 'Resource ${qp.resourceId}' : '');
        if (name.isNotEmpty) questionPaperName = name;
      }

      syllabusCount = details.allByType('syllabus').length;
      hasRubric =
          (details.rubricId != null && details.rubricId!.trim().isNotEmpty);
    } catch (_) {
      // Ignore backend failures; fall back to local cache.
    }

    final candidates = <String?>[
      prefs.getString('question_paper_file:${widget.chatSessionId}'),
      prefs.getString('question_paper_file:no-session'),
      prefs.getString(EvalDocKeys.questionPaperFile),
    ];

    for (final raw in candidates) {
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final name = decoded['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            questionPaperName = name;
            break;
          }
        }
      } catch (_) {
        // Some older flows stored just the filename as a plain string.
        questionPaperName = raw;
        break;
      }
    }

    final syllabusList =
        prefs.getStringList('syllabus_items:${widget.chatSessionId}') ??
            prefs.getStringList(EvalDocKeys.syllabusItems) ??
            const <String>[];
    final hasRubricFromPrefs =
        (prefs.getBool('hasRubric:${widget.chatSessionId}') ?? false) ||
            (prefs.getBool(EvalDocKeys.hasRubric) ?? false);

    if (!mounted) return;
    setState(() {
      _questionPaperName = questionPaperName;
      _syllabusCount = syllabusCount > 0 ? syllabusCount : syllabusList.length;
      _hasRubric = hasRubric || hasRubricFromPrefs;
    });
  }

  int _stepIndexForLine(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('starting evaluation')) return 0;
    if (lower.contains('evaluating answer')) return 0;
    if (lower.contains('grading')) return 1;
    if (lower.contains('updating existing evaluation result')) return 1;
    if (lower.contains('mark')) return 1;
    if (lower.contains('feedback')) return 2;
    if (lower.contains('preparing report')) return 3;
    if (lower.contains('finished')) return 3;
    if (lower.contains('report')) return 3;
    return 0;
  }

  Future<void> _startFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadReadOnlySummary(prefs);

    final docsAvailable =
        widget.assumeDocsAvailable ? true : _allDocumentsAvailable(prefs);

    if (!mounted) return;
    setState(() {
      _docsAvailable = docsAvailable;
    });

    if (docsAvailable) {
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

    final hasQuestionPaper = ((_questionPaperName ?? '').trim().isNotEmpty) ||
        (prefs.getString('question_paper_file:${widget.chatSessionId}') ??
                prefs.getString(EvalDocKeys.questionPaperFile) ??
                '')
            .isNotEmpty;

    final hasSyllabus = (_syllabusCount > 0) ||
        (prefs.getStringList('syllabus_items:${widget.chatSessionId}') ??
                prefs.getStringList(EvalDocKeys.syllabusItems) ??
                const <String>[])
            .isNotEmpty;
    final hasRubric = _hasRubric ||
        (prefs.getBool('hasRubric:${widget.chatSessionId}') ?? false) ||
        (prefs.getBool(EvalDocKeys.hasRubric) ?? false);

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

  Future<void> _runEvaluation({required int runId}) async {
    final prefs = await SharedPreferences.getInstance();
    final answerIds =
        prefs.getStringList('answer_sheet_ids:${widget.chatSessionId}') ??
            const <String>[];
    final latest = answerIds.where((e) => e.isNotEmpty).isNotEmpty
        ? answerIds.where((e) => e.isNotEmpty).last
        : '';

    if (latest.isEmpty) {
      if (!mounted || runId != _runToken) return;
      setState(() {
        _isEvaluating = false;
        _evaluationDone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing answer sheet upload')),
      );
      return;
    }

    if (!mounted || runId != _runToken) return;
    setState(() {
      for (int i = 0; i < _evalStates.length; i++) {
        _evalStates[i] =
            const _StepState(status: _StepStatus.pending, progress: 0);
      }
      _evalStates[0] =
          const _StepState(status: _StepStatus.inProgress, progress: 0);
    });

    var currentStep = 0;

    try {
      await EvaluationService.startEvaluationStream(
        chatSessionId: widget.chatSessionId,
        answerResourceIds: <String>[latest],
        onLine: (line) {
          if (!mounted || runId != _runToken) return;

          Map<String, dynamic>? asJson;
          try {
            final decoded = jsonDecode(line);
            if (decoded is Map) {
              asJson = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {
            asJson = null;
          }

          final displayMessage =
              (asJson?['message'] ?? asJson?['detail'] ?? asJson?['step'])
                      ?.toString() ??
                  line;

          final stepHint = asJson?['step']?.toString() ?? '';
          final status = asJson?['status']?.toString() ?? '';
          final progressRaw = asJson?['progress'];

          final hintedStep = stepHint.isNotEmpty
              ? _stepIndexForLine(stepHint)
              : _stepIndexForLine(line);

          var p = 0;
          if (progressRaw is num) {
            p = progressRaw.round().clamp(0, 100);
          }

          setState(() {
            _lastStatusLine = displayMessage;
            if (hintedStep > currentStep) {
              _evalStates[currentStep] = _evalStates[currentStep].copyWith(
                status: _StepStatus.done,
                progress: 100,
              );
              currentStep = hintedStep.clamp(0, _evalStates.length - 1);
              _evalStates[currentStep] = _evalStates[currentStep].copyWith(
                status: _StepStatus.inProgress,
                progress: 0,
              );
            }

            final existing = _evalStates[currentStep].progress;
            final nextProgress = p > 0 ? p : (existing + 5).clamp(0, 99);
            _evalStates[currentStep] = _evalStates[currentStep].copyWith(
              status: _StepStatus.inProgress,
              progress: nextProgress,
            );

            final statusLower = status.toLowerCase();
            final lineLower = line.toLowerCase();
            if (statusLower == 'completed' || statusLower == 'done') {
              for (int i = 0; i < _evalStates.length; i++) {
                _evalStates[i] = const _StepState(
                  status: _StepStatus.done,
                  progress: 100,
                );
              }
            }

            if (lineLower.contains('evaluation completed for session') ||
                lineLower.contains('evaluation finished for answer document')) {
              for (int i = 0; i < _evalStates.length; i++) {
                _evalStates[i] = const _StepState(
                  status: _StepStatus.done,
                  progress: 100,
                );
              }
            }
          });
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('startEvaluationStream failed: $e');
      if (!mounted || runId != _runToken) return;
      setState(() {
        _isEvaluating = false;
        _evaluationDone = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to stream evaluation progress')),
      );
      return;
    }

    if (!mounted || runId != _runToken) return;
    setState(() {
      for (int i = 0; i < _evalStates.length; i++) {
        _evalStates[i] =
            const _StepState(status: _StepStatus.done, progress: 100);
      }
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
          evaluationSessionId: widget.evaluationSessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final missingRequiredDocs = !_docsAvailable;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (_) {},
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
        chatSessionId: widget.chatSessionId,
        enableSidebars: false,
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

                _SectionCard(
                  title: 'evaluation.evaluationDetails'.tr(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'evaluation.attachedAnswerSheet'.tr(
                          args: [
                            (widget.attachmentName ?? '').isNotEmpty
                                ? widget.attachmentName!
                                : '—'
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${'question_paper.header'.tr()}: ${(_questionPaperName ?? '').isNotEmpty ? _questionPaperName! : '—'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${'syllabus.header'.tr()}: ${_syllabusCount > 0 ? '$_syllabusCount file(s)' : '—'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${'question_paper.applied_rubric'.tr()}: ${_hasRubric ? '✓' : '—'}',
                        style: theme.textTheme.bodyMedium,
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
                      if (missingRequiredDocs) ...[
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
                                'evaluation.waitingForDocuments'.tr(),
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
                      if ((_lastStatusLine ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _lastStatusLine!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ],
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

  String _statusLabelKey() {
    switch (status) {
      case _StepStatus.done:
        return 'evaluation.statusCompleted';
      case _StepStatus.inProgress:
        return 'evaluation.statusProcessing';
      case _StepStatus.pending:
        return 'evaluation.statusStarting';
    }
  }

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
          if (trailingLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(trailingLabel!, style: theme.textTheme.labelMedium),
            ),
          ],
        ],
      ),
    );
  }
}

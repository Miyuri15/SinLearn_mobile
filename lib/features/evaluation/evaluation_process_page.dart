import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../widgets/teachers_main_app_bar.dart';
import 'evaluation_response.dart';

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

  bool _isEvaluating = true;
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
    _runEvaluation();
  }

  Future<void> _runEvaluation() async {
    // Simple simulated progress. Replace with real API calls when available.
    for (int i = 0; i < _evalStates.length; i++) {
      if (!mounted) return;

      setState(() {
        _evalStates[i] = _evalStates[i].copyWith(
          status: _StepStatus.inProgress,
          progress: 0,
        );
      });

      // Animate progress within the step.
      for (int p = 20; p <= 100; p += 20) {
        await Future.delayed(const Duration(milliseconds: 320));
        if (!mounted) return;
        setState(() {
          _evalStates[i] = _evalStates[i].copyWith(progress: p);
        });
      }

      if (!mounted) return;
      setState(() {
        _evalStates[i] = _evalStates[i].copyWith(status: _StepStatus.done);
      });
    }

    if (!mounted) return;
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (_) {},
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
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

                // Documents: show as already complete once the user is here.
                _SectionCard(
                  title: 'evaluation.processDocuments'.tr(),
                  child: Column(
                    children: [
                      _RowStep(
                        title: 'evaluation.docStepAnswerSheetsProcessing'.tr(),
                        status: _StepStatus.done,
                        trailingLabel: 'evaluation.alreadyProcessed'.tr(),
                        progress: 100,
                      ),
                      _RowStep(
                        title: 'evaluation.docStepQuestionPaperProcessing'.tr(),
                        status: _StepStatus.done,
                        trailingLabel: 'evaluation.alreadyProcessed'.tr(),
                        progress: 100,
                      ),
                      _RowStep(
                        title: 'evaluation.docStepSyllabusProcessing'.tr(),
                        status: _StepStatus.done,
                        trailingLabel: 'evaluation.alreadyProcessed'.tr(),
                        progress: 100,
                      ),
                      _RowStep(
                        title: 'evaluation.docStepRubricSet'.tr(),
                        status: _StepStatus.done,
                        trailingLabel: 'evaluation.alreadyProcessed'.tr(),
                        progress: 100,
                      ),
                      _RowStep(
                        title: 'evaluation.docStepPaperConfigSet'.tr(),
                        status: _StepStatus.done,
                        trailingLabel: 'evaluation.alreadyProcessed'.tr(),
                        progress: 100,
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

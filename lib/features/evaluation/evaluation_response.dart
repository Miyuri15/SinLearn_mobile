import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../../core/utils/json_cast.dart';
import '../../services/evaluation_service.dart';
import 'evaluation_text.dart';

class EvaluationResponsePage extends StatefulWidget {
  const EvaluationResponsePage({
    super.key,
    required this.chatSessionId,
    this.initialMessageText,
    this.attachmentName,
    this.evaluationData,
    this.evaluationRunId,
    this.evaluationSessionId,
  });

  final String chatSessionId;
  final String? initialMessageText;
  final String? attachmentName;
  final Map<String, dynamic>? evaluationData;
  final int? evaluationRunId;
  final String? evaluationSessionId;

  @override
  State<EvaluationResponsePage> createState() => _EvaluationResponsePageState();
}

class _EvaluationResponsePageState extends State<EvaluationResponsePage> {
  static const String _answerSheetAttachmentKey = 'evaluation_attachment';
  static String _answerSheetClearedKey(String chatSessionId) =>
      'active_answer_sheet_cleared:$chatSessionId';

  static String _historyKey(String chatSessionId) =>
      'evaluation_chat_history_v1_$chatSessionId';

  final ScrollController _scrollController = ScrollController();
  List<_EvalChatEntry> _history = <_EvalChatEntry>[];
  bool _historyLoaded = false;

  // Backend result data
  Map<String, dynamic>? _backendResult;
  bool _isLoadingResult = false;
  String? _loadError;

  List<_EvalRunSummary> _buildRunSummaries() {
    final summaries = <_EvalRunSummary>[];

    // Prefer assistant report entries; each evaluation run should yield exactly one.
    for (final e in _history) {
      if (e.kind != _EvalChatEntryKind.assistantReport) continue;
      summaries.add(
        _EvalRunSummary(
          runId: e.runId,
          attachmentName: (e.attachmentName ?? '').trim(),
          createdAtIso: e.createdAtIso,
          evaluationData: e.evaluationData,
        ),
      );
    }

    // If no assistant reports exist (older stored history), fall back to any user entry.
    if (summaries.isEmpty) {
      for (final e in _history) {
        if (e.kind != _EvalChatEntryKind.user) continue;
        final name = (e.attachmentName ?? '').trim();
        if (name.isEmpty) continue;
        summaries.add(
          _EvalRunSummary(
            runId: e.runId,
            attachmentName: name,
            createdAtIso: e.createdAtIso,
            evaluationData: null,
          ),
        );
      }
    }

    // Sort oldest -> newest.
    summaries.sort((a, b) {
      final da = DateTime.tryParse(a.createdAtIso) ?? DateTime(1970);
      final db = DateTime.tryParse(b.createdAtIso) ?? DateTime(1970);
      return da.compareTo(db);
    });

    return summaries;
  }

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = _historyKey(widget.chatSessionId);
    final raw = prefs.getString(historyKey);

    final loaded = <_EvalChatEntry>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              loaded.add(_EvalChatEntry.fromJson(asStringKeyedMap(item)));
            }
          }
        }
      } catch (_) {
        // Ignore malformed stored history.
      }
    }

    final runId = widget.evaluationRunId;
    var appended = false;
    if (runId != null && runId != 0) {
      final alreadyHasRun = loaded.any((e) => e.runId == runId);
      if (!alreadyHasRun) {
        final now = DateTime.now();

        if (widget.attachmentName != null &&
            widget.attachmentName!.trim().isNotEmpty) {
          loaded.add(
            _EvalChatEntry.user(
              runId: runId,
              text: 'evaluation.attachedAnswerSheet'
                  .tr(args: [widget.attachmentName!]),
              attachmentName: widget.attachmentName,
              createdAtIso: now.toIso8601String(),
              evaluationData: null,
            ),
          );
        }

        if (widget.initialMessageText != null &&
            widget.initialMessageText!.trim().isNotEmpty) {
          loaded.add(
            _EvalChatEntry.assistantText(
              runId: runId,
              text: widget.initialMessageText!,
              attachmentName: widget.attachmentName,
              createdAtIso: now.toIso8601String(),
              evaluationData: null,
            ),
          );
        }

        loaded.add(
          _EvalChatEntry.assistantReport(
            runId: runId,
            text: 'evaluation.evaluationResultFor'
                .tr(args: [widget.attachmentName ?? '']),
            attachmentName: widget.attachmentName,
            createdAtIso: now.toIso8601String(),
            evaluationData: widget.evaluationData,
          ),
        );

        await prefs.setString(
          historyKey,
          jsonEncode(loaded.map((e) => e.toJson()).toList()),
        );
        appended = true;
      }
    }

    if (!mounted) return;
    setState(() {
      _history = loaded;
      _historyLoaded = true;
    });

    // Scroll to bottom after first layout.
    if (appended || _history.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }

    // Fetch real results from backend
    await _fetchBackendResults();
  }

  Future<void> _fetchBackendResults() async {
    if (!mounted) return;
    setState(() {
      _isLoadingResult = true;
      _loadError = null;
    });

    try {
      // Try to get the evaluation session ID
      final prefs = await SharedPreferences.getInstance();
      final sessionId = widget.evaluationSessionId ??
          prefs.getString('evaluation_session_id:${widget.chatSessionId}');

      if (sessionId != null && sessionId.isNotEmpty) {
        // First try to get answer documents for this session
        try {
          final answers =
              await EvaluationService.getAnswerDocuments(sessionId);
          if (answers.isNotEmpty) {
            // Get the latest answer document
            final latestAnswer = answers.last;
            final answerDocId = (latestAnswer['id'] ??
                    latestAnswer['answer_document_id'] ??
                    '')
                .toString();

            if (answerDocId.isNotEmpty) {
              final result = await EvaluationService.fetchAnswerResult(
                answerDocumentId: answerDocId,
              );
              if (result != null && mounted) {
                setState(() {
                  _backendResult = result;
                  _isLoadingResult = false;
                });
                return;
              }
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('Failed to fetch via answer documents: $e');
        }

        // Fallback: try session results
        try {
          final sessionResults =
              await EvaluationService.getEvaluationSessionResults(sessionId);
          if (sessionResults.isNotEmpty && mounted) {
            setState(() {
              _backendResult = sessionResults.last;
              _isLoadingResult = false;
            });
            return;
          }
        } catch (e) {
          // ignore: avoid_print
          print('Failed to fetch session results: $e');
        }
      }

      // Fallback: try answer sheet IDs from prefs
      final answerIds =
          prefs.getStringList('answer_sheet_ids:${widget.chatSessionId}') ??
              const <String>[];
      if (answerIds.isNotEmpty) {
        final latestId = answerIds.last;
        try {
          final result = await EvaluationService.fetchAnswerResult(
            answerDocumentId: latestId,
          );
          if (result != null && mounted) {
            setState(() {
              _backendResult = result;
              _isLoadingResult = false;
            });
            return;
          }
        } catch (e) {
          // ignore: avoid_print
          print('Failed to fetch answer result by ID: $e');
        }
      }

      // Use evaluationData passed from process page as last fallback
      if (mounted) {
        setState(() {
          _backendResult = widget.evaluationData;
          _isLoadingResult = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('_fetchBackendResults failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingResult = false;
        _loadError = e.toString();
        // Fall back to passed evaluationData
        _backendResult = widget.evaluationData;
      });
    }
  }

  Future<void> _startNewAnswerEvaluation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_answerSheetAttachmentKey);
    await prefs.remove('answer_sheet_ids:${widget.chatSessionId}');
    await prefs.remove('evaluation_session_id:${widget.chatSessionId}');
    await prefs.setBool(_answerSheetClearedKey(widget.chatSessionId), true);

    // A new answer sheet requires re-processing.
    await prefs
        .remove('evaluation_processed_tokens_v1:${widget.chatSessionId}');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationTextPage(chatSessionId: widget.chatSessionId),
      ),
      (route) => false,
    );
  }

  Future<void> _backToDocumentProcess() async {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationTextPage(
          chatSessionId: widget.chatSessionId,
          initialShowProcessing: true,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runs = _buildRunSummaries();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('evaluation_mode'.tr()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_historyLoaded
                  ? const SizedBox.shrink()
                  : runs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 44,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.45),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'evaluation.noPreviousEvaluations'.tr(),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: runs.length,
                          itemBuilder: (context, index) {
                            final run = runs[index];
                            final time = _formatTime(run.createdAtIso);
                            final attachment = run.attachmentName;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.92,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'evaluation.evaluationResultFor'.tr(
                                          args: [attachment],
                                        ),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (attachment.isNotEmpty)
                                        Text(
                                          'evaluation.attachedAnswerSheet'
                                              .tr(args: [attachment]),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      if (_isLoadingResult)
                                        const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Center(
                                            child:
                                                CircularProgressIndicator(),
                                          ),
                                        )
                                      else
                                        _EvaluationReportCard(
                                          theme: theme,
                                          evaluationData:
                                              _backendResult ?? run.evaluationData,
                                        ),
                                      if (_loadError != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'evaluation.loadErrorFallback'
                                                .tr(),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Text(
                                        time,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _startNewAnswerEvaluation,
                      icon: const Icon(Icons.attach_file),
                      label: Text('evaluation.startNewAnswerEvaluation'.tr()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _backToDocumentProcess,
                      icon: const Icon(Icons.arrow_back),
                      label: Text('evaluation.backToDocumentProcess'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _EvalChatEntryKind { user, assistantText, assistantReport }

class _EvalChatEntry {
  const _EvalChatEntry({
    required this.runId,
    required this.kind,
    required this.text,
    required this.createdAtIso,
    required this.attachmentName,
    required this.evaluationData,
  });

  factory _EvalChatEntry.user({
    required int? runId,
    required String text,
    required String createdAtIso,
    required String? attachmentName,
    required Map<String, dynamic>? evaluationData,
  }) {
    return _EvalChatEntry(
      runId: runId,
      kind: _EvalChatEntryKind.user,
      text: text,
      createdAtIso: createdAtIso,
      attachmentName: attachmentName,
      evaluationData: evaluationData,
    );
  }

  factory _EvalChatEntry.assistantText({
    required int? runId,
    required String text,
    required String createdAtIso,
    required String? attachmentName,
    required Map<String, dynamic>? evaluationData,
  }) {
    return _EvalChatEntry(
      runId: runId,
      kind: _EvalChatEntryKind.assistantText,
      text: text,
      createdAtIso: createdAtIso,
      attachmentName: attachmentName,
      evaluationData: evaluationData,
    );
  }

  factory _EvalChatEntry.assistantReport({
    required int? runId,
    required String text,
    required String createdAtIso,
    required String? attachmentName,
    required Map<String, dynamic>? evaluationData,
  }) {
    return _EvalChatEntry(
      runId: runId,
      kind: _EvalChatEntryKind.assistantReport,
      text: text,
      createdAtIso: createdAtIso,
      attachmentName: attachmentName,
      evaluationData: evaluationData,
    );
  }

  factory _EvalChatEntry.fromJson(Map<String, dynamic> json) {
    final kindRaw = (json['kind'] ?? '').toString();
    final kind = switch (kindRaw) {
      'assistantReport' => _EvalChatEntryKind.assistantReport,
      'assistantText' => _EvalChatEntryKind.assistantText,
      _ => _EvalChatEntryKind.user,
    };
    return _EvalChatEntry(
      runId: (json['runId'] is int) ? json['runId'] as int : null,
      kind: kind,
      text: (json['text'] ?? '').toString(),
      createdAtIso: (json['createdAtIso'] ?? '').toString(),
      attachmentName: (json['attachmentName'] as String?),
      evaluationData: (json['evaluationData'] is Map)
          ? asStringKeyedMap(json['evaluationData'])
          : null,
    );
  }

  final int? runId;
  final _EvalChatEntryKind kind;
  final String text;
  final String createdAtIso;
  final String? attachmentName;
  final Map<String, dynamic>? evaluationData;

  Map<String, dynamic> toJson() {
    final kindString = switch (kind) {
      _EvalChatEntryKind.assistantReport => 'assistantReport',
      _EvalChatEntryKind.assistantText => 'assistantText',
      _EvalChatEntryKind.user => 'user',
    };
    return <String, dynamic>{
      'runId': runId,
      'kind': kindString,
      'text': text,
      'createdAtIso': createdAtIso,
      'attachmentName': attachmentName,
      'evaluationData': evaluationData,
    };
  }
}

class _EvalRunSummary {
  const _EvalRunSummary({
    required this.runId,
    required this.attachmentName,
    required this.createdAtIso,
    required this.evaluationData,
  });

  final int? runId;
  final String attachmentName;
  final String createdAtIso;
  final Map<String, dynamic>? evaluationData;
}

String _formatTime(String createdAtIso) {
  try {
    final dt = DateTime.parse(createdAtIso);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  } catch (_) {
    return '';
  }
}

class _EvaluationReportCard extends StatelessWidget {
  const _EvaluationReportCard({required this.theme, this.evaluationData});
  final ThemeData theme;
  final Map<String, dynamic>? evaluationData;

  String _gradeFromData() {
    final data = evaluationData;
    if (data == null) return 'B+';
    final v = (data['grade'] ??
            data['overall_grade'] ??
            data['final_grade'] ??
            data['overallGrade'] ??
            data['finalGrade'])
        ?.toString();
    return (v != null && v.trim().isNotEmpty) ? v.trim() : 'B+';
  }

  double _scoreFromData(String key) {
    final data = evaluationData;
    if (data == null) return -1;
    final raw = data[key] ??
        data[key.replaceAll('_', '')] ??
        data[key.replaceAll('_', ' ')];
    if (raw is num) {
      final v = raw.toDouble();
      // Accept 0..1 or 0..100
      if (v <= 1.0) return v.clamp(0.0, 1.0);
      return (v / 100.0).clamp(0.0, 1.0);
    }
    if (raw is String) {
      final v = double.tryParse(raw);
      if (v == null) return -1;
      if (v <= 1.0) return v.clamp(0.0, 1.0);
      return (v / 100.0).clamp(0.0, 1.0);
    }
    return -1;
  }
  double _numFromData(String key) {
    if (evaluationData == null) return -1;
    final val = evaluationData![key];
    if (val is num) return val.toDouble();
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null) return parsed;
    }
    return -1;
  }

  String? _stringFromData(String key) {
    if (evaluationData == null) return null;
    final val = evaluationData![key];
    if (val == null) return null;
    return val.toString();
  }

  List<String> _listFromData(String key) {
    if (evaluationData == null) return [];
    final val = evaluationData![key];
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _listOfMapsFromData(String key) {
    if (evaluationData == null) return [];
    final val = evaluationData![key];
    if (val is List) {
      return val
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final grade = _gradeFromData();
    final totalScore = _numFromData('total_score');
    final percentageScore = _numFromData('percentage_score');
    final overallFeedback = _stringFromData('overall_feedback');
    final improvementPoints = _listFromData('improvement_points');
    final questionFeedback = _listOfMapsFromData('question_feedback');
    final marksSummary = evaluationData?['marks_summary'];

    final coverage = _scoreFromData('coverage_score');
    final accuracy = _scoreFromData('accuracy_score');
    final clarity = _scoreFromData('clarity');

    final hasCoverage = coverage >= 0;
    final hasAccuracy = accuracy >= 0;
    final hasClarity = clarity >= 0;

    // Extract strengths and weaknesses from backend data
    final strengths = _listFromData('strengths');
    final weaknesses = _listFromData('weaknesses');
    final missingPoints = _listFromData('missing_points');

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('evaluation_report'.tr(),
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    if (totalScore >= 0 || percentageScore >= 0)
                      Text(
                        percentageScore >= 0
                            ? '${percentageScore.toStringAsFixed(1)}%'
                            : '${totalScore.toStringAsFixed(1)} marks',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text('detailed_feedback'.tr(),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                  ],
                ),
              ),
              _GradeBadge(grade: grade),
            ],
          ),
          const SizedBox(height: 16),
          if (hasCoverage)
            _ScoreBar(labelKey: 'coverage_score', value: coverage),
          if (hasCoverage) const SizedBox(height: 10),
          if (hasAccuracy)
            _ScoreBar(labelKey: 'accuracy_score', value: accuracy),
          if (hasAccuracy) const SizedBox(height: 10),
          if (hasClarity) _ScoreBar(labelKey: 'clarity', value: clarity),
          if (hasClarity) const SizedBox(height: 10),
          // Question-level marks summary
          if (marksSummary is Map && (marksSummary).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('evaluation.questionScores'.tr(),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...(marksSummary).entries.map((entry) {
              final qLabel = entry.key.toString();
              final subMarks = entry.value;
              if (subMarks is List) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(qLabel,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    ...subMarks.map((sm) {
                      if (sm is Map) {
                        final label =
                            (sm['label'] ?? '').toString();
                        final awarded =
                            (sm['awarded'] as num?)?.toDouble() ?? 0;
                        final maxVal =
                            (sm['max'] as num?)?.toDouble() ?? 0;
                        return Padding(
                          padding:
                              const EdgeInsets.only(left: 12, top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(label,
                                      style:
                                          theme.textTheme.bodySmall)),
                              Text(
                                '${awarded.toStringAsFixed(1)} / ${maxVal.toStringAsFixed(1)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: awarded >= maxVal * 0.7
                                      ? Colors.green
                                      : awarded >= maxVal * 0.4
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 6),
          ],
          if (strengths.isNotEmpty) ...[
            _BulletSection(
              icon: Icons.check_circle_outline,
              iconColor: Colors.green,
              title: 'strengths'.tr(),
              items: strengths,
            ),
            const SizedBox(height: 10),
          ],
          if (weaknesses.isNotEmpty) ...[
            _BulletSection(
              icon: Icons.error_outline,
              iconColor: Colors.red,
              title: 'weaknesses'.tr(),
              items: weaknesses,
            ),
            const SizedBox(height: 10),
          ],
          if (missingPoints.isNotEmpty) ...[
            _BulletSection(
              icon: Icons.priority_high_rounded,
              iconColor: Colors.orange,
              title: 'missing_points'.tr(),
              items: missingPoints,
            ),
            const SizedBox(height: 10),
          ],
          if (improvementPoints.isNotEmpty) ...[
            _BulletSection(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber,
              title: 'evaluation.improvementPoints'.tr(),
              items: improvementPoints,
            ),
            const SizedBox(height: 10),
          ],
          // Question-level feedback
          if (questionFeedback.isNotEmpty) ...[
            Text('evaluation.questionFeedback'.tr(),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...questionFeedback.map((qf) {
              final qNum =
                  (qf['question_number'] ?? qf['label'] ?? '').toString();
              final feedback =
                  (qf['feedback'] ?? qf['comment'] ?? '').toString();
              final score = (qf['score'] as num?)?.toDouble();
              final maxScore = (qf['max_score'] as num?)?.toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Q$qNum',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600)),
                          if (score != null) ...[
                            const Spacer(),
                            Text(
                              maxScore != null
                                  ? '${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(1)}'
                                  : score.toStringAsFixed(1),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(feedback, style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
          if (overallFeedback != null && overallFeedback.isNotEmpty) ...[
            Text('detailed_feedback'.tr(),
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                overallFeedback,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined),
                label: Text('download'.tr()),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                label: Text('share'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});
  final String grade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
      ),
      child: Text(
        grade,
        style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.labelKey, required this.value});
  final String labelKey;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelKey.tr(), style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 10,
                width: constraints.maxWidth * value,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('${(value * 100).round()}%', style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 6, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(e, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyInputBar extends StatefulWidget {
  const _ReplyInputBar({
    required this.controller,
    required this.attachedFileName,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
  });
  final TextEditingController controller;
  final String? attachedFileName;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;

  @override
  State<_ReplyInputBar> createState() => _ReplyInputBarState();
}

class _ReplyInputBarState extends State<_ReplyInputBar>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    _animController.repeat();
  }

  void _stopRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  void _cancelRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  Widget _waveform(ThemeData theme) {
    const barCount = 14;
    const maxBarHeight = 28.0;
    const minBarHeight = 6.0;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * math.pi * 2;
            final t = (_animController.value * math.pi * 2) + phase;
            final v = (math.sin(t) + 1) / 2; // used math.sin
            final h = minBarHeight + (v * (maxBarHeight - minBarHeight));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _recordingPanel(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.red.shade50
            : Colors.red.shade900.withOpacity(0.16),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Center(child: _waveform(theme))),
          Row(
            children: [
              TextButton.icon(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                label: Text('Cancel',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.mic_off, color: Colors.red),
                label: Text('Stop',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // show attached file chip if present
          if (widget.attachedFileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(widget.attachedFileName!),
                  avatar: const Icon(Icons.attach_file, size: 18),
                  onDeleted: widget.onRemoveAttachment,
                ),
              ),
            ),
          // show recording panel if active
          if (_isRecording) _recordingPanel(theme),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.12)),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'type_answer_hint'.tr(),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: widget.onAttach,
                            icon: const Icon(Icons.attach_file),
                          ),
                          IconButton(
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            icon:
                                Icon(_isRecording ? Icons.mic : Icons.mic_none),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                width: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF1E63FF),
                  ),
                  onPressed: widget.onSend,
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Replace _UserMessageBubble with alignment-aware bubble
class _MessageBubble extends StatelessWidget {
  const _MessageBubble(
      {required this.time, required this.text, required this.fromUser});
  final String time;
  final String text;
  final bool fromUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        fromUser ? const Color(0xFF1E63FF) : theme.colorScheme.surface;
    final textColor =
        fromUser ? Colors.white : theme.textTheme.bodyLarge?.color;
    final align = fromUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
        child: Column(
          crossAxisAlignment:
              fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  if (Theme.of(context).brightness == Brightness.light)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Text(
                text,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: textColor, height: 1.5),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                time,
                textAlign: fromUser ? TextAlign.right : TextAlign.left,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: (textColor)?.withOpacity(0.7) ?? theme.hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

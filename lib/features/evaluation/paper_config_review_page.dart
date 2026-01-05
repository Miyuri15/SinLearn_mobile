import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/paper_config.dart';
import '../../services/paper_config_service.dart';

class PaperConfigReviewPage extends StatefulWidget {
  final String sessionId;

  const PaperConfigReviewPage({
    super.key,
    required this.sessionId,
  });

  @override
  State<PaperConfigReviewPage> createState() =>
      _PaperConfigReviewPageState();
}

class _PaperConfigReviewPageState extends State<PaperConfigReviewPage> {
  bool _isLoading = true;
  final List<PaperConfig> _configs = [];
  final _service = PaperConfigService();

  @override
  void initState() {
    super.initState();
    _fetchLatestConfig();
  }

  // ===========================================================================
  // FETCH LATEST SAVED CONFIG (OR EMPTY)
  // ===========================================================================
  Future<void> _fetchLatestConfig() async {
    try {
      final data = await _service.fetchConfigs(widget.sessionId);
      if (data.isNotEmpty) {
        _configs.addAll(data);

        // Prefill marks from processed questions endpoint.
        // Backend provides paper-config metadata but question marks come from
        // /evaluation/sessions/{chat_session_id}/questions.
        final rawQuestions =
            await _service.fetchQuestionsRaw(widget.sessionId);
        _applyQuestionsFromBackend(rawQuestions);
      } else {
        _configs.add(_newPaperPart());
      }
    } catch (_) {
      _configs.add(_newPaperPart());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyQuestionsFromBackend(List<Map<String, dynamic>> rawQuestions) {
    if (rawQuestions.isEmpty || _configs.isEmpty) return;

    // Ensure deterministic ordering by question_number when possible.
    final sorted = [...rawQuestions];
    sorted.sort((a, b) {
      final an = int.tryParse((a['question_number'] ?? '').toString());
      final bn = int.tryParse((b['question_number'] ?? '').toString());
      if (an == null && bn == null) return 0;
      if (an == null) return 1;
      if (bn == null) return -1;
      return an.compareTo(bn);
    });

    var cursor = 0;
    for (final config in _configs) {
      final count = config.totalMainQuestions;
      if (count <= 0) continue;

      // Ensure local question list size matches backend paper-config.
      if (config.questions.length != count) {
        _updateQuestionCount(config, count);
      }

      for (var i = 0; i < count; i++) {
        if (cursor >= sorted.length) return;

        final qJson = sorted[cursor++];
        final q = config.questions[i];

        final maxMarks = (qJson['max_marks'] is num)
            ? (qJson['max_marks'] as num).toDouble()
            : double.tryParse((qJson['max_marks'] ?? 0).toString()) ?? 0;

        final subQuestions = (qJson['sub_questions'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const <Map<String, dynamic>>[];

        if (subQuestions.isNotEmpty) {
          q.hasSubQuestions = true;
          q.marks = 0;
          q.subQuestions = subQuestions
              .map(
                (sq) => SubQuestionStructure(
                  label: (sq['label'] ?? '').toString(),
                  marks: (sq['max_marks'] is num)
                      ? (sq['max_marks'] as num).toDouble()
                      : double.tryParse((sq['max_marks'] ?? 0).toString()) ??
                          0,
                ),
              )
              .toList();
        } else {
          q.hasSubQuestions = false;
          q.subQuestions = [];
          q.marks = maxMarks;
        }
      }
    }
  }

  PaperConfig _newPaperPart() {
    return PaperConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      paperPart: 'Paper Part',
      subjectName: '',
      medium: 'Sinhala',
      totalMarks: 0,
      totalMainQuestions: 0,
      selectionRules: SelectionRules(),
      isConfirmed: false,
      questions: [],
    );
  }

  void _addPaperPart() {
    setState(() => _configs.add(_newPaperPart()));
  }

  void _removePaperPart(PaperConfig config) {
    setState(() => _configs.remove(config));
  }

  void _updateQuestionCount(PaperConfig config, int count) {
    if (count < 0) return;

    setState(() {
      config.totalMainQuestions = count;

      if (config.questions.length < count) {
        for (int i = config.questions.length; i < count; i++) {
          config.questions.add(
            QuestionStructure(
              questionNo: i + 1,
              marks: 0,
              hasSubQuestions: false,
              subQuestions: [],
            ),
          );
        }
      } else if (config.questions.length > count) {
        config.questions.removeRange(
            count, config.questions.length);
      }
    });
  }

  // ===========================================================================
  // MARKS VALIDATION LOGIC (CRITICAL)
  // ===========================================================================

  double _effectiveQuestionMarks(QuestionStructure q) {
    if (!q.hasSubQuestions) return q.marks;
    return q.subQuestions.fold(
      0.0,
      (sum, sq) => sum + sq.marks,
    );
  }

  String? _validatePaperPart(PaperConfig config) {
    final totalMarks = config.totalMarks;
    final chooseAny = config.selectionRules.chooseAny;
    final questions = config.questions;

    if (questions.isEmpty) {
      return '${config.paperPart}: No questions defined';
    }

    final marks =
        questions.map(_effectiveQuestionMarks).toList();

    // All questions required
    if (chooseAny == null || chooseAny >= questions.length) {
      final sum = marks.fold(0.0, (a, b) => a + b);
      if (sum != totalMarks) {
        return '${config.paperPart}: '
            'Sum of all questions ($sum) must equal total marks ($totalMarks)';
      }
      return null;
    }

    // Choose any X questions
    if (chooseAny < questions.length) {
      final sorted = [...marks]..sort((a, b) => b.compareTo(a));
      final bestSum =
          sorted.take(chooseAny).fold(0.0, (a, b) => a + b);

      if (bestSum != totalMarks) {
        return '${config.paperPart}: '
            'Sum of any $chooseAny questions ($bestSum) must equal total marks ($totalMarks)';
      }
    }

    return null;
  }

  // ===========================================================================
  // CONFIRM & SAVE (FINAL GATE)
  // ===========================================================================
  Future<void> _onConfirm() async {
    // Validate ALL paper parts first
    for (final config in _configs) {
      final error = _validatePaperPart(config);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await _service.confirmConfigs(widget.sessionId, _configs);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('paper_config_confirmed', true);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save paper config')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // UI
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Paper Config')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._configs.map(_buildPaperPartEditor),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _addPaperPart,
            icon: const Icon(Icons.add),
            label: const Text('Add Paper Part'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Confirm Paper Config',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAPER PART EDITOR
  // ===========================================================================
  Widget _buildPaperPartEditor(PaperConfig config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: config.paperPart,
                    decoration: const InputDecoration(
                      labelText: 'Paper Part Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => config.paperPart = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePaperPart(config),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: config.totalMarks.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Total Marks',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        config.totalMarks = int.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue:
                        config.totalMainQuestions.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Main Questions',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final c = int.tryParse(v);
                      if (c != null) _updateQuestionCount(config, c);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue:
                  config.selectionRules.chooseAny?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Choose Any (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                config.selectionRules = SelectionRules(
                  mode: config.selectionRules.mode,
                  chooseAny: int.tryParse(v),
                );
              },
            ),
            const Divider(height: 32),
            ...config.questions.map(_buildQuestionEditor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionEditor(QuestionStructure q) {
    return Column(
      children: [
        Row(
          children: [
            Text('Q${q.questionNo}'),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue:
                    q.marks > 0 ? q.marks.toString() : '',
                decoration:
                    const InputDecoration(labelText: 'Marks'),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    q.marks = double.tryParse(v) ?? 0,
              ),
            ),
            Checkbox(
              value: q.hasSubQuestions,
              onChanged: (v) {
                setState(() {
                  q.hasSubQuestions = v ?? false;
                  if (q.hasSubQuestions && q.subQuestions.isEmpty) {
                    q.subQuestions.add(
                        SubQuestionStructure(label: 'a', marks: 0));
                  }
                  if (!q.hasSubQuestions) q.subQuestions.clear();
                });
              },
            ),
          ],
        ),
if (q.hasSubQuestions)
  Padding(
    padding: const EdgeInsets.only(left: 24),
    child: Column(
      children: [
        ...q.subQuestions.asMap().entries.map((entry) {
          final index = entry.key;
          final sq = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: TextFormField(
                    initialValue: sq.label,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => sq.label = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: sq.marks.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Marks',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        sq.marks = double.tryParse(v) ?? 0,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      q.subQuestions.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }),

        // ➕ ADD SUB-QUESTION BUTTON
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                String nextLabel = 'a';
                if (q.subQuestions.isNotEmpty) {
                  final last = q.subQuestions.last.label;
                  if (last.length == 1 &&
                      last.codeUnitAt(0) >= 97 &&
                      last.codeUnitAt(0) < 122) {
                    nextLabel =
                        String.fromCharCode(last.codeUnitAt(0) + 1);
                  } else {
                    nextLabel = '${q.subQuestions.length + 1}';
                  }
                }

                q.subQuestions.add(
                  SubQuestionStructure(
                    label: nextLabel,
                    marks: 0,
                  ),
                );
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add sub-question'),
          ),
        ),
      ],
    ),
  ),

      ],
    );
  }
}

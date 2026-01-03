// lib/features/evaluation/paper_config_review_page.dart

import 'package:flutter/material.dart';
import '../../models/paper_config.dart';
import '../../services/paper_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PaperConfigReviewPage extends StatefulWidget {
  final String sessionId;
  const PaperConfigReviewPage({super.key, required this.sessionId});

  @override
  State<PaperConfigReviewPage> createState() => _PaperConfigReviewPageState();
}

class _PaperConfigReviewPageState extends State<PaperConfigReviewPage> {
  late Future<List<PaperConfig>> _future;
  final _service = PaperConfigService('BASE_URL_HERE');

  @override
  void initState() {
    super.initState();
    _future = _service.fetchConfigs(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paper Marks Structure')),
      body: FutureBuilder<List<PaperConfig>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final configs = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...configs.map(_buildPaperPartCard),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () async {
                    // 1. Call backend confirm endpoint
                    await _service.confirmConfigs(widget.sessionId, configs);

                    // 2. Mark paper config as confirmed (keeps existing features intact)
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('paper_config_confirmed', true);

                    // 3. Go back to EvaluationTextPage
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Confirm & Continue'),
                ),

            ],
          );
        },
      ),
    );
  }

  Widget _buildPaperPartCard(PaperConfig part) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(part.paperPart,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Total Marks: ${part.totalMarks}'),
            Text('Questions: ${part.totalMainQuestions}'),
            if (part.selectionRules.chooseAny != null)
              Text('Choose any ${part.selectionRules.chooseAny}'),
            const Divider(),
            ..._buildQuestions(part),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestions(PaperConfig part) {
    if (part.questions.isEmpty) {
      part.questions = List.generate(
        part.totalMainQuestions,
        (i) => QuestionStructure(questionNo: i + 1),
      );
    }

    return part.questions.map((q) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q${q.questionNo}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: q.marks.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Marks'),
                  onChanged: (v) => q.marks = double.tryParse(v) ?? 0,
                ),
              ),
              Checkbox(
                value: q.hasSubQuestions,
                onChanged: (v) {
                  setState(() {
                    q.hasSubQuestions = v!;
                    if (v && q.subQuestions.isEmpty) {
                      q.subQuestions = [
                        SubQuestionStructure(label: 'a'),
                      ];
                    }
                    if (!v) q.subQuestions.clear();
                  });
                },
              ),
              const Text('Sub'),
            ],
          ),
          if (q.hasSubQuestions)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                children: [
                  ...q.subQuestions.map((sq) {
                    return Row(
                      children: [
                        Text('${sq.label})'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: sq.marks.toString(),
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Marks'),
                            onChanged: (v) =>
                                sq.marks = double.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    );
                  }),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        q.subQuestions.add(
                          SubQuestionStructure(
                              label: String.fromCharCode(
                                  97 + q.subQuestions.length)),
                        );
                      });
                    },
                    child: const Text('+ Add sub question'),
                  )
                ],
              ),
            ),
          const Divider(),
        ],
      );
    }).toList();
  }
}

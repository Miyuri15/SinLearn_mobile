import 'package:flutter/material.dart';

class EvaluationResponsePage extends StatelessWidget {
  const EvaluationResponsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Evaluation Mode', style: TextStyle(color: Colors.black)),
        actions: [
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Rubric'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.book_outlined, size: 18),
            label: const Text('Syllabus'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(1000, 80, 0, 0),
                items: const [
                  PopupMenuItem(value: 'question', child: Text('Question Paper')),
                  PopupMenuItem(value: 'rubric', child: Text('Rubric')),
                ],
              ).then((value) {
                if (value == 'question') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question Paper selected')),
                  );
                } else if (value == 'rubric') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rubric selected')),
                  );
                }
              });
            },
            tooltip: 'New',
            icon: const Icon(Icons.add, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UserMessageBubble(
                    time: '04:40',
                    text: 'doc1.',
                  ),
                  const SizedBox(height: 12),
                  _EvaluationReportCard(theme: theme),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: _ReplyInputBar(controller: TextEditingController()),
          ),
        ],
      ),
    );
  }
}

class _UserMessageBubble extends StatelessWidget {
  const _UserMessageBubble({required this.time, required this.text});
  final String time;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mic_none, size: 16),
              const SizedBox(width: 4),
              Text(time, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _EvaluationReportCard extends StatelessWidget {
  const _EvaluationReportCard({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
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
                    Text('Evaluation Report',
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.black)),
                    const SizedBox(height: 2),
                    Text('Detailed Feedback',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.black87)),
                  ],
                ),
              ),
              _GradeBadge(grade: 'B+'),
            ],
          ),
          const SizedBox(height: 20),
          const _ScoreBar(label: 'Coverage Score', value: 0.78),
          const SizedBox(height: 12),
          const _ScoreBar(label: 'Accuracy Score', value: 0.85),
          const SizedBox(height: 12),
          const _ScoreBar(label: 'Clarity', value: 0.72),
          const SizedBox(height: 20),
          _BulletSection(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Strengths',
            items: const [
              'ප්‍රධාන කරුණු සපළිව පිළිබඳ ඉතා ඉක්මනින්',
              'දත්ත හා උදාහරණ හරහා ප්‍රමාණවත් පදනම',
              'වගන්තිවල නිවැරදි භාවිත',
            ],
          ),
          const SizedBox(height: 12),
          _BulletSection(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'Weaknesses',
            items: const [
              'සමහර ස්ථලවල උපුටා දැක්වීම් නොමැත',
              'ගැළපෙන භාෂාව සමහරවිට නොපාවිච්චි විය',
              'උපායමාර්ගික අදහස් වඩාත් පැහැදිලි කළ යුතුය',
            ],
          ),
          const SizedBox(height: 12),
          _BulletSection(
            icon: Icons.priority_high_rounded,
            iconColor: Colors.orange,
            title: 'Missing Points',
            items: const [
              'අදාළ නිකුත් කරුණු සලකා බැලීම',
              'තවදුරටත් සාරාංශය අඩංගු කිරීම',
              'නිගමන තවදුරටත් ශක්තිමත් කිරීම',
            ],
          ),
          const SizedBox(height: 16),
          Text('Detailed Feedback', style: theme.textTheme.titleSmall?.copyWith(color: Colors.black)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              'මෙම පිළිතුර සිදුකළ කාර්යයයේ මාතෘකාව, කෙටි සහ සපුරාගත් පරාග්‍රාෆ් තුළ හොඳින් උදාහරණ සහිතව පැහැදිලි කරයි. '
              'කෙසේ වෙතත්, තවත් මූලාශ්ර උපුටා දැක්වීමෙන් විශ්වාසීයත්වය වැඩි කළ හැක. '
              'සමහර ඉංග්‍රීසි පද මෘදුකමෙන් සිංහල පද වලින් ප්‍රතිස්ථාපනය කිරීම අවශ්‍යය.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: const Text('Download'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green[700],
                  side: BorderSide(color: Colors.green[700]!),
                ),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share'),
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
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[700]!),
      ),
      child: Text(
        grade,
        style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.green[700], fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black)),
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
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('${(value * 100).round()}%', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black)),
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
                    ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black)),
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
                Expanded(child: Text(e, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReplyInputBar extends StatelessWidget {
  const _ReplyInputBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Ask a follow-up question...',
                        hintStyle: TextStyle(color: Colors.black45, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Attach file',
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file, color: Colors.black54, size: 20),
                  ),
                  IconButton(
                    tooltip: 'Voice input',
                    onPressed: () {},
                    icon: const Icon(Icons.mic_none, color: Colors.black54, size: 22),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Icon(Icons.send_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

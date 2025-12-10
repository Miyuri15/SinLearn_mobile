import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class EvaluationResponsePage extends StatelessWidget {
  const EvaluationResponsePage({
    super.key,
    this.initialMessageText,
    this.attachmentName,
    this.evaluationData,
  });

  // added fields to accept payload
  final String? initialMessageText;
  final String? attachmentName;
  final Map<String, dynamic>? evaluationData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 420;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // was Colors.white
      appBar: AppBar(
        title: Text('evaluation_mode'.tr()),
        actions: isCompact
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'rubric':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rubric selected')),
                        );
                        break;
                      case 'syllabus':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Syllabus selected')),
                        );
                        break;
                      case 'question':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Question Paper selected')),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rubric', child: Text('Rubric')),
                    PopupMenuItem(value: 'syllabus', child: Text('Syllabus')),
                    PopupMenuItem(value: 'question', child: Text('Question Paper')),
                  ],
                ),
              ]
            : [
                TextButton(onPressed: () {}, child: const Text('Rubric')),
                const SizedBox(width: 8),
                TextButton(onPressed: () {}, child: const Text('Syllabus')),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add),
                  onSelected: (value) {
                    if (value == 'question') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question Paper selected')),
                      );
                    } else if (value == 'rubric') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rubric selected')),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'question', child: Text('Question Paper')),
                    PopupMenuItem(value: 'rubric', child: Text('Rubric')),
                  ],
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // render initial message and attachment if provided
            if (initialMessageText != null || attachmentName != null) ...[
              _UserMessageBubble(
                time: TimeOfDay.now().format(context),
                text: initialMessageText ?? '',
              ),
              if (attachmentName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 40),
                  child: InputChip(
                    label: Text(attachmentName!),
                    avatar: const Icon(Icons.attach_file, size: 18),
                    onDeleted: null,
                  ),
                ),
              const SizedBox(height: 12),
            ],
            _EvaluationReportCard(theme: theme),
            const SizedBox(height: 16),
            _ReplyInputBar(controller: TextEditingController()),
          ],
        ),
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
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10), // was light blue
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          ),
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
        color: theme.cardColor, // was Colors.white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
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
                    Text('evaluation_report'.tr(), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('detailed_feedback'.tr(), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                  ],
                ),
              ),
              _GradeBadge(grade: 'B+'),
            ],
          ),
          const SizedBox(height: 16),
          const _ScoreBar(labelKey: 'coverage_score', value: 0.78),
          const SizedBox(height: 10),
          const _ScoreBar(labelKey: 'accuracy_score', value: 0.85),
          const SizedBox(height: 10),
          const _ScoreBar(labelKey: 'clarity', value: 0.72),
          const SizedBox(height: 16),
          _BulletSection(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'strengths'.tr(),
            items: const [
              'ප්‍රධාන කරුණු සපළිව පිළිබඳ ඉතා ඉක්මනින්',
              'දත්ත හා උදාහරණ හරහා ප්‍රමාණවත් පදනම',
              'වගන්තිවල නිවැරදි භාවිත',
            ],
          ),
          const SizedBox(height: 10),
          _BulletSection(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'weaknesses'.tr(),
            items: const [
              'සමහර ස්ථලවල උපුටා දැක්වීම් නොමැත',
              'ගැළපෙන භාෂාව සමහරවිට නොපාවිච්චි විය',
              'උපායමාර්ගික අදහස් වඩාත් පැහැදිලි කළ යුතුය',
            ],
          ),
          const SizedBox(height: 10),
          _BulletSection(
            icon: Icons.priority_high_rounded,
            iconColor: Colors.orange,
            title: 'missing_points'.tr(),
            items: const [
              'අදාළ නිකුත් කරුණු සලකා බැලීම',
              'තවදුරටත් සාරාංශය අඩංගු කිරීම',
              'නිගමන තවදුරටත් ශක්තිමත් කිරීම',
            ],
          ),
          const SizedBox(height: 16),
          Text('detailed_feedback'.tr(), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text(
              'මෙම පිළිතුර සිදුකළ කාර්යයයේ මාතෘකාව, කෙටි සහ සපුරාගත් පරාග්‍රාෆ් තුළ හොඳින් උදාහරණ සහිතව පැහැදිලි කරයි. '
              'කෙසේ වෙතත්, තවත් මූලාශ්ර උපුටා දැක්වීමෙන් විශ්වාසීයත්වය වැඩි කළ හැක. '
              'සමහර ඉංග්‍රීසි පද මෘදුකමෙන් සිංහල පද වලින් ප්‍රතිස්ථාපනය කිරීම අවශ්‍යය.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
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
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
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

class _ReplyInputBar extends StatelessWidget {
  const _ReplyInputBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface, // was Colors.white
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
              ),
              child: TextField(
                controller: controller,
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
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                          if (result == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('evaluation.selectFileCancelled'.tr())),
                            );
                            return;
                          }
                          final file = result.files.first;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('evaluation.fileUploaded'.tr())),
                          );
                        },
                        icon: const Icon(Icons.attach_file),
                      ),
                      IconButton(
                        onPressed: () {
                          // voice action placeholder
                        },
                        icon: const Icon(Icons.mic_none),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFF1E63FF)),
              onPressed: () {},
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

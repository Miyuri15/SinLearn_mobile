import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'evaluation_process_page.dart';
import 'evaluation_text.dart';

class EvaluationResponsePage extends StatefulWidget {
  const EvaluationResponsePage({
    super.key,
    required this.chatSessionId,
    this.initialMessageText,
    this.attachmentName,
    this.evaluationData,
  });

  final String chatSessionId;
  final String? initialMessageText;
  final String? attachmentName;
  final Map<String, dynamic>? evaluationData;

  @override
  State<EvaluationResponsePage> createState() => _EvaluationResponsePageState();
}

class _EvaluationResponsePageState extends State<EvaluationResponsePage> {
  static const String _answerSheetAttachmentKey = 'evaluation_attachment';
  String? _lastAttachedAnswerSheet;

  @override
  void initState() {
    super.initState();
    _lastAttachedAnswerSheet = widget.attachmentName;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _attachAnotherAnswerSheet() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('evaluation.selectFileCancelled'.tr())),
      );
      return;
    }

    final file = result.files.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_answerSheetAttachmentKey, file.name);

    if (!mounted) return;
    setState(() => _lastAttachedAnswerSheet = file.name);

    // Re-run evaluation using the already processed documents.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationProcessPage(
          chatSessionId: widget.chatSessionId,
          attachmentName: file.name,
          evaluationData: widget.evaluationData,
        ),
      ),
    );
  }

  void _endEvaluation() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationTextPage(chatSessionId: widget.chatSessionId),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('evaluation_mode'.tr()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_lastAttachedAnswerSheet != null) ...[
                      InputChip(
                        label: Text(_lastAttachedAnswerSheet!),
                        avatar: const Icon(Icons.attach_file, size: 18),
                        onDeleted: null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _EvaluationReportCard(theme: theme),
                  ],
                ),
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
                      onPressed: _attachAnotherAnswerSheet,
                      icon: const Icon(Icons.attach_file),
                      label: Text('evaluation.attachAnotherAnswerSheet'.tr()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _endEvaluation,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text('evaluation.endEvaluation'.tr()),
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

// Simple message model for this page
class _ChatMessage {
  _ChatMessage(
      {required this.text, required this.fromUser, this.attachmentName});
  final String text;
  final bool fromUser;
  final String? attachmentName;
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
                    Text('detailed_feedback'.tr(),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
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
                  color: (textColor as Color?)?.withOpacity(0.7) ??
                      theme.hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

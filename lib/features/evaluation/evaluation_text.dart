import 'dart:math';

import 'package:flutter/material.dart';
import 'learning_mode.dart';
import 'heder.dart';

class EvaluationTextPage extends StatefulWidget {
  const EvaluationTextPage({super.key});

  @override
  State<EvaluationTextPage> createState() => _EvaluationTextPageState();
}

class _EvaluationTextPageState extends State<EvaluationTextPage> {
  int _modeIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  bool _isRecording = false;
  List<Map<String, dynamic>> _chatList = [
    {'title': 'New Learning Chat', 'subtitle': '1 messages • 6 minutes ago', 'icon': Icons.menu_book_outlined, 'type': 'learning'},
    {'title': 'New Evaluation Chat', 'subtitle': '1 messages • 43 minutes ago', 'icon': Icons.assignment_turned_in_outlined, 'type': 'evaluation'},
    {'title': 'New Learning Chat', 'subtitle': '0 messages • about 1 hour ago', 'icon': Icons.menu_book_outlined, 'type': 'learning'},
  ];

  void _addNewChat(String type) {
    setState(() {
      _chatList.insert(0, {
        'title': type == 'learning' ? 'New Learning Chat' : 'New Evaluation Chat',
        'subtitle': '0 messages • just now',
        'icon': type == 'learning' ? Icons.menu_book_outlined : Icons.assignment_turned_in_outlined,
        'type': type,
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Evaluation'),
            ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isWide)
                _Sidebar(
                  theme: theme,
                  searchController: _searchController,
                  chatList: _chatList,
                  onNewLearning: () => _addNewChat('learning'),
                  onNewEvaluation: () => _addNewChat('evaluation'),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                        modeIndex: _modeIndex,
                        onModeChanged: (i) => setState(() => _modeIndex = i)),
                    const Divider(height: 1),
                    Expanded(
                      child: _EmptyChatView(theme: theme),
                    ),
                    const Divider(height: 1),
                    _InputBar(
                      controller: _inputController,
                      onVoicePressed: () => setState(() => _isRecording = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isRecording)
            RecordingOverlay(
              onCancel: () => setState(() => _isRecording = false),
              onStop: () {
                setState(() => _isRecording = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recording stopped')),
                );
              },
            ),
        ],
      ),
    );
  }
}

class RecordingOverlay extends StatefulWidget {
  const RecordingOverlay({required this.onCancel, required this.onStop});

  final VoidCallback onCancel;
  final VoidCallback onStop;

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Center(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              // left: recording label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Recording', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red.shade400)),
                ],
              ),
              const SizedBox(width: 20),
              // waveform (center)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value * 2 * pi;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(17, (i) {
                          final progress = (sin(t + i * 0.45) + 1) / 2; // 0..1
                          final height = 6.0 + progress * 34.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 6,
                                height: height,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.onCancel,
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 18, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text('Cancel', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: widget.onStop,
                    icon: const Icon(Icons.mic_off, size: 18),
                    label: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.modeIndex,
    required this.onModeChanged,
  });

  final int modeIndex;
  final ValueChanged<int> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SegmentButton(
                  selected: modeIndex == 0,
                  icon: Icons.menu_book_outlined,
                  label: 'Learning Mode',
                  onTap: () {
                    // navigate back to Learning Mode page
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LearningModePage()),
                    );
                  },
                ),
                _SegmentButton(
                  selected: modeIndex == 1,
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Evaluation Mode',
                  onTap: () => onModeChanged(1),
                ),
              ],
            ),
          ),
          const Spacer(),
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
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.green.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.green[700] : theme.iconTheme.color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected
                    ? Colors.green[700]
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.theme,
    required this.searchController,
    required this.chatList,
    required this.onNewLearning,
    required this.onNewEvaluation,
  });

  final ThemeData theme;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> chatList;
  final VoidCallback onNewLearning;
  final VoidCallback onNewEvaluation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EvaluationHeader(
            onNewLearning: onNewLearning,
            onNewEvaluation: onNewEvaluation,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: chatList.map((chat) => _ChatListItem(
                  title: chat['title'],
                  subtitle: chat['subtitle'],
                  icon: chat['icon'],
                )).toList(),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.settings, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('Settings', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                const Spacer(),
                Icon(Icons.logout, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  const _ChatListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700], size: 20),
        title: Text(title, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {},
        selected: title.contains('Evaluation'),
        selectedTileColor: Colors.blue.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Start your conversation in Sinhala',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Type a question or use voice input',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, this.onVoicePressed});
  final TextEditingController controller;
  final VoidCallback? onVoicePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
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
                          hintText: 'Type your answer or upload a file...',
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
                      onPressed: onVoicePressed ?? () {},
                      icon: const Icon(Icons.mic_none, color: Colors.black54, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
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
      ),
    );
  }
}

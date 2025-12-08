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
      appBar: isWide
          ? null
          : AppBar(
              title: const Text('Evaluation'),
            ),
      body: Row(
        children: [
          if (isWide)
            _Sidebar(theme: theme, searchController: _searchController),
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
                _InputBar(controller: _inputController),
              ],
            ),
          ),
        ],
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
          OutlinedButton(onPressed: () {}, child: const Text('Rubric')),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: () {}, child: const Text('Syllabus')),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'New',
            icon: const Icon(Icons.add_circle_outline),
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
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? theme.colorScheme.primary : theme.iconTheme.color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
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
  });

  final ThemeData theme;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EvaluationHeader(),
          Expanded(
            child: ListView(
              children: const [
                _ChatListItem(
                    title: 'New Learning Chat',
                    subtitle: '1 messages • 6 minutes ago',
                    icon: Icons.menu_book_outlined),
                _ChatListItem(
                    title: 'New Evaluation Chat',
                    subtitle: '1 messages • 43 minutes ago',
                    icon: Icons.assignment_turned_in_outlined),
                _ChatListItem(
                    title: 'New Learning Chat',
                    subtitle: '0 messages • about 1 hour ago',
                    icon: Icons.menu_book_outlined),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 18),
                const SizedBox(width: 8),
                Text('Settings', style: theme.textTheme.bodyMedium),
                const Spacer(),
                const Icon(Icons.logout, size: 18),
                const SizedBox(width: 8),
                Text('Logout', style: theme.textTheme.bodyMedium),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {},
        selected: title.contains('Evaluation'),
        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
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
  const _InputBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your answer or upload a file…',
                  prefixIcon: IconButton(
                    tooltip: 'Attach file',
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Voice input',
                        onPressed: () {},
                        icon: const Icon(Icons.mic_none),
                      ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Send',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  shape: const CircleBorder(),
                ),
                onPressed: () {},
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

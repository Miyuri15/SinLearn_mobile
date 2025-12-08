import 'package:flutter/material.dart';
import 'evaluation_text.dart';

class LearningModePage extends StatefulWidget {
  const LearningModePage({super.key});

  @override
  State<LearningModePage> createState() => _LearningModePageState();
}

class _LearningModePageState extends State<LearningModePage> {
  int _modeIndex = 0;
  String _responseLevel = 'Grades 9-11';
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isWide ? null : AppBar(title: const Text('Learning')),
      body: Row(
        children: [
          if (isWide) _Sidebar(theme: theme, searchController: _searchController),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
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
                              selected: _modeIndex == 0,
                              label: 'Learning Mode',
                              onTap: () => setState(() => _modeIndex = 0),
                            ),
                            _SegmentButton(
                              selected: _modeIndex == 1,
                              label: 'Evaluation Mode',
                              onTap: () {
                                // Navigate to the Evaluation (text) page
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const EvaluationTextPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
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
                ),
                const Divider(height: 1),
                const Expanded(child: _EmptyChatView()),
                const Divider(height: 1),
                _InputBar(
                  controller: _inputController,
                  responseLevel: _responseLevel,
                  onResponseLevelChanged: (v) => setState(() => _responseLevel = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.selected, required this.label, required this.onTap});
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.menu_book : Icons.menu_book_outlined, size: 16, color: selected ? Colors.green : theme.iconTheme.color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.green : theme.textTheme.bodyMedium?.color,
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
  const _Sidebar({required this.theme, required this.searchController});
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Recent Chats', style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search chats...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: const [
                _ChatListItem(title: 'New Learning Chat', subtitle: '0 messages • less than a minute ago', icon: Icons.menu_book_outlined),
                _ChatListItem(title: 'New Evaluation Chat', subtitle: '1 messages • 33 minutes ago', icon: Icons.assignment_turned_in_outlined),
                _ChatListItem(title: 'New Learning Chat', subtitle: '0 messages • about 1 hour ago', icon: Icons.menu_book_outlined),
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
  const _ChatListItem({required this.title, required this.subtitle, required this.icon});
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
        selected: title.contains('Learning'),
        selectedTileColor: Colors.green.withOpacity(0.08),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Start your conversation in Sinhala', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Type a question or use voice input', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.responseLevel, required this.onResponseLevelChanged});
  final TextEditingController controller;
  final String responseLevel;
  final ValueChanged<String> onResponseLevelChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Text('Response Level', style: theme.textTheme.bodySmall),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: responseLevel,
                    items: const [
                      DropdownMenuItem(value: 'Grades 6-8', child: Text('Grades 6-8')),
                      DropdownMenuItem(value: 'Grades 9-11', child: Text('Grades 9-11')),
                      DropdownMenuItem(value: 'Grades 12+', child: Text('Grades 12+')),
                    ],
                    onChanged: (v) {
                      if (v != null) onResponseLevelChanged(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  prefixIcon: IconButton(
                    tooltip: 'Attach file',
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Voice input',
                    onPressed: () {},
                    icon: const Icon(Icons.mic_none),
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
                  backgroundColor: theme.colorScheme.primary,
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

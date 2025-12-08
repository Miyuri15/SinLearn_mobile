import 'package:flutter/material.dart';
import 'evaluation_text.dart';
import 'heder.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';

class LearningModePage extends StatefulWidget {
  const LearningModePage({super.key});

  @override
  State<LearningModePage> createState() => _LearningModePageState();
}

class _LearningModePageState extends State<LearningModePage> {
  int _selectedSegment = 0; // 0 = Learning, 1 = Evaluation
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
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context),
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (index) {
          setState(() => _selectedSegment = index);

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EvaluationTextPage()),
            );
          }
        },
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
      ),
      body: Row(
        children: [
          if (isWide)
            _Sidebar(theme: theme, searchController: _searchController),

          // RIGHT SIDE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),

                // ===== Empty Chat =====
                const Expanded(child: _EmptyChatView()),

                const Divider(height: 1),

                // ===== Input Bar =====
                _InputBar(
                  controller: _inputController,
                  responseLevel: _responseLevel,
                  onResponseLevelChanged: (v) {
                    setState(() => _responseLevel = v);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------- Drawer -----------------------
  Widget _buildDrawer(BuildContext context) {
    return const RecentChatsDrawer();
  }
}

// ============================================================================
//                                 SIDEBAR
// ============================================================================
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
        color: Colors.white, // was theme.colorScheme.surface
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
                  subtitle: '0 messages • less than a minute ago',
                  icon: Icons.menu_book_outlined,
                ),
                _ChatListItem(
                  title: 'New Evaluation Chat',
                  subtitle: '1 messages • 33 minutes ago',
                  icon: Icons.assignment_turned_in_outlined,
                ),
                _ChatListItem(
                  title: 'New Learning Chat',
                  subtitle: '0 messages • about 1 hour ago',
                  icon: Icons.menu_book_outlined,
                ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selected: title.contains("Learning"),
        selectedTileColor: Colors.green.withOpacity(0.08),
        onTap: () {},
      ),
    );
  }
}

// =================================================================
// ============================================================================
class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Start your conversation in Sinhala',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Type a question or use voice input',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//                                  INPUT BAR
// ============================================================================
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.responseLevel,
    required this.onResponseLevelChanged,
  });

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;

            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Response Level dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Text('Response Level',
                                style: theme.textTheme.bodySmall),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: responseLevel,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Grades 6-8',
                                    child: Text('Grades 6-8')),
                                DropdownMenuItem(
                                    value: 'Grades 9-11',
                                    child: Text('Grades 9-11')),
                                DropdownMenuItem(
                                    value: 'Grades 12+',
                                    child: Text('Grades 12+')),
                              ],
                              onChanged: (v) {
                                if (v != null) onResponseLevelChanged(v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Input + Send
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Ask a question...',
                                prefixIcon: Icon(Icons.attach_file),
                                suffixIcon: Icon(Icons.mic_none),
                                border: OutlineInputBorder(),
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
                    ],
                  )
                : Row(
                    children: [
                      // Response Level dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Text('Response Level',
                                style: theme.textTheme.bodySmall),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: responseLevel,
                              items: const [
                                DropdownMenuItem(
                                    value: 'Grades 6-8',
                                    child: Text('Grades 6-8')),
                                DropdownMenuItem(
                                    value: 'Grades 9-11',
                                    child: Text('Grades 9-11')),
                                DropdownMenuItem(
                                    value: 'Grades 12+',
                                    child: Text('Grades 12+')),
                              ],
                              onChanged: (v) {
                                if (v != null) onResponseLevelChanged(v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text input
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Ask a question...',
                            prefixIcon: Icon(Icons.attach_file),
                            suffixIcon: Icon(Icons.mic_none),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send Button
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
                  );
          },
        ),
      ),
    );
  }
}

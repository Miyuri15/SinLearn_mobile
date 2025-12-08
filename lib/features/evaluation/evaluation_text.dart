import 'package:flutter/material.dart';
import 'learning_mode.dart';
import 'heder.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';

class EvaluationTextPage extends StatefulWidget {
  const EvaluationTextPage({super.key});

  @override
  State<EvaluationTextPage> createState() => _EvaluationTextPageState();
}

class _EvaluationTextPageState extends State<EvaluationTextPage> {
  int _selectedSegment = 1; // 0 = Learning, 1 = Evaluation

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
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context),
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (index) {
          setState(() => _selectedSegment = index);

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LearningModePage()),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),
                Expanded(child: _EmptyChatView(theme: theme)),
                const Divider(height: 1),
                _InputBar(controller: _inputController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Drawer (Recent Chats) ----------
  Widget _buildDrawer(BuildContext context) {
    return const RecentChatsDrawer();
  }
}

// -----------------------------------------------------------------------------
//                                SIDEBAR
// -----------------------------------------------------------------------------
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
                  subtitle: '1 messages • 6 minutes ago',
                  icon: Icons.menu_book_outlined,
                ),
                _ChatListItem(
                  title: 'New Evaluation Chat',
                  subtitle: '1 messages • 43 minutes ago',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {},
        selected: title.contains('Evaluation'),
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//                            EMPTY CHAT VIEW
// -----------------------------------------------------------------------------
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

// -----------------------------------------------------------------------------
//                                  INPUT BAR
// -----------------------------------------------------------------------------
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

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;
    final bool isWide = size.width >= 900;
    final sidebarWidth = isWide ? (size.width * 0.32).clamp(260.0, 360.0) : 0.0;

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
            SizedBox(width: sidebarWidth, child: _Sidebar(theme: theme, searchController: _searchController)),
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
                Text('recent_chats.settings'.tr(), style: theme.textTheme.bodyMedium),
                const Spacer(),
                const Icon(Icons.logout, size: 18),
                const SizedBox(width: 8),
                Text('recent_chats.logout'.tr(), style: theme.textTheme.bodyMedium),
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
          Text('start_conversation'.tr(), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('type_question'.tr(), style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[450])),
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
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, isSmallPhone ? 8 : 10, 12, 14),
        child: Row(
          children: [
            // Input pill (attach + mic placed as suffix icons on the right)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallPhone ? 16 : 20),
                  border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6)],
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'type_answer_hint'.tr(),
                    border: InputBorder.none,
                    isDense: true,
                    // constrain suffix icon area so it can't overflow
                    suffixIcon: SizedBox(
                      width: isSmallPhone ? 88 : 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                              if (result == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File selection canceled')));
                                return;
                              }
                              final file = result.files.first;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: ${file.name}')));
                            },
                            icon: const Icon(Icons.attach_file),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.mic_none),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button (rounded square as in image)
            SizedBox(
              height: isSmallPhone ? 44 : 52,
              width: isSmallPhone ? 44 : 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E63FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 14)),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

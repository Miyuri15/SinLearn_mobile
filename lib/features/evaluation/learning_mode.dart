import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
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
  // store the localization key (display shows .tr())
  String _responseLevel = 'grades_9_11';

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
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isPhone = size.width < 600;
    final bool isWide = size.width >= 900;
    final sidebarWidth = isWide ? (size.width * 0.32).clamp(260.0, 360.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // was Colors.white
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
            SizedBox(width: sidebarWidth, child: _Sidebar(theme: theme, searchController: _searchController)),

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
        color: theme.colorScheme.surface, // was Colors.white
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
          // Fetch localized text for start_conversation
          Text('start_conversation'.tr(), style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          // Fetch localized text for type_question
          Text('type_question'.tr(), style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[450])),
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
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 520;

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('response_level'.tr(), style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isSmallPhone ? 6 : 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface, // was Colors.white
                          borderRadius: BorderRadius.circular(isSmallPhone ? 8 : 10),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: responseLevel,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'grades_6_8', child: Text('grades_6_8'.tr())),
                              DropdownMenuItem(value: 'grades_9_11', child: Text('grades_9_11'.tr())),
                              DropdownMenuItem(value: 'grades_12_plus', child: Text('grades_12_plus'.tr())),
                            ],
                            onChanged: (v) => v != null ? onResponseLevelChanged(v) : null,
                            selectedItemBuilder: (context) => [
                              Text('grades_6_8'.tr()),
                              Text('grades_9_11'.tr()),
                              Text('grades_12_plus'.tr()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Input row with pill input + send button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface, // was Colors.white
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                minLines: 1,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: 'ask_question_hint'.tr(),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            // constrain suffix icon area so it can't overflow on tiny screens
                            SizedBox(
                              width: isSmallPhone ? 88 : 120,
                              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                IconButton(onPressed: () async {
                                  final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                                  if (result == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File selection canceled')));
                                    return;
                                  }
                                  final file = result.files.first;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: ${file.name}')));
                                }, icon: const Icon(Icons.attach_file)),
                                IconButton(onPressed: () {}, icon: const Icon(Icons.mic_none)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      width: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E63FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Wide layout
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface, // was Colors.white
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Text('response_level'.tr(), style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: responseLevel,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(value: 'grades_6_8', child: Text('grades_6_8'.tr())),
                        DropdownMenuItem(value: 'grades_9_11', child: Text('grades_9_11'.tr())),
                        DropdownMenuItem(value: 'grades_12_plus', child: Text('grades_12_plus'.tr())),
                      ],
                      onChanged: (v) {
                        if (v != null) onResponseLevelChanged(v);
                      },
                      selectedItemBuilder: (context) => [
                        Text('grades_6_8'.tr()),
                        Text('grades_9_11'.tr()),
                        Text('grades_12_plus'.tr()),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface, // was Colors.white
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
                    boxShadow: [if (theme.brightness == Brightness.light) BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'ask_question_hint'.tr(),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                        if (result == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File selection canceled')));
                          return;
                        }
                        final file = result.files.first;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: ${file.name}')));
                      }, icon: const Icon(Icons.attach_file)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.mic_none)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

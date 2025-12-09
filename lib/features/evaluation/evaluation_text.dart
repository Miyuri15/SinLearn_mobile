import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'learning_mode.dart';
import 'evaluation_inputs.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;
    final isWide = size.width >= 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
      drawer: const RecentChatsDrawer(),
      body: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(
                  height: 1,
                  color: theme.dividerColor,
                ),
                Expanded(child: _EmptyChatView(theme: theme, isDark: isDark)),
                Divider(
                  height: 1,
                  color: theme.dividerColor,
                ),
                _InputBar(
                  controller: _inputController,
                  onMarksPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EvaluationInputPage()),
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//                                EMPTY CHAT VIEW
// -----------------------------------------------------------------------------
class _EmptyChatView extends StatelessWidget {
  const _EmptyChatView({required this.theme, required this.isDark});
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'evaluation.startNewEvaluation'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'evaluation.typeQuestions'.tr(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[450],
            ),
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
  const _InputBar({
    required this.controller,
    required this.onMarksPressed,
    required this.isDark,
  });
  final TextEditingController controller;
  final VoidCallback onMarksPressed;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 380;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, isSmallPhone ? 8 : 10, 12, 6),
            child: Row(
              children: [
                // Attach File
                Expanded(
                  child: SizedBox(
                    height: isSmallPhone ? 44 : 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 14),
                        ),
                      ),
                      icon: const Icon(Icons.attach_file),
                      label: Text('evaluation.attach'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Add Marks
                Expanded(
                  child: SizedBox(
                    height: isSmallPhone ? 44 : 52,
                    child: ElevatedButton.icon(
                      onPressed: onMarksPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 14),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text('evaluation.marks'.tr()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Send
                Expanded(
                  child: SizedBox(
                    height: isSmallPhone ? 44 : 52,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 14),
                        ),
                      ),
                      icon: const Icon(Icons.send_rounded),
                      label: Text('evaluation.send'.tr()),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtitle
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'evaluation.addAttachmentAndMarks'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
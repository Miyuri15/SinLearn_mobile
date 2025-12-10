import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'learning_mode.dart';
import 'evaluation_inputs.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'package:shared_preferences/shared_preferences.dart'; // added
import '../evaluation/evaluation_response.dart'; // add import to navigate
import 'dart:convert'; // added for jsonDecode

class EvaluationTextPage extends StatefulWidget {
  const EvaluationTextPage({super.key});

  @override
  State<EvaluationTextPage> createState() => _EvaluationTextPageState();
}

class _EvaluationTextPageState extends State<EvaluationTextPage> {
  int _selectedSegment = 1; // 0 = Learning, 1 = Evaluation
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  String? _attachedFileName; // added
  static const String _attachmentKey = 'evaluation_attachment'; // added
  static const String _evaluationStorageKey = 'evaluation_data'; // added

  @override
  void dispose() {
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAttachment(); // added
  }

  Future<void> _loadAttachment() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_attachmentKey);
    if (name != null && mounted) {
      setState(() => _attachedFileName = name);
    }
  }

  Future<void> _pickAndSaveAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('evaluation.selectFileCancelled'.tr())),
      );
      return;
    }
    final file = result.files.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attachmentKey, file.name);
    if (mounted) {
      setState(() => _attachedFileName = file.name);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('evaluation.fileUploaded'.tr())),
    );
  }

  Future<void> _removeAttachment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attachmentKey);
    if (mounted) {
      setState(() => _attachedFileName = null);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('evaluation.attachmentRemoved'.tr())),
    );
  }

  Future<Map<String, dynamic>?> _getSavedEvaluationData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_evaluationStorageKey);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendToChat() async {
    final evalData = await _getSavedEvaluationData();
    if (evalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('evaluation.viewMarks'.tr())), // minimal hint to save marks first
      );
      return;
    }
    // Build a concise message text
    final total = evalData['totalMarks'] ?? '';
    final main = evalData['mainQuestions'] ?? '';
    final req = evalData['requiredQuestions'] ?? '';
    final msg = '${'evaluation.totalMarks'.tr()}: $total, '
        '${'evaluation.mainQuestions'.tr()}: $main, '
        '${'evaluation.requiredQuestions'.tr()}: $req';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationResponsePage(
          initialMessageText: msg,
          attachmentName: _attachedFileName,
          evaluationData: evalData,
        ),
      ),
    );
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
                // Show attached file chip if present
                if (_attachedFileName != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(_attachedFileName!),
                        avatar: const Icon(Icons.attach_file, size: 18),
                        onDeleted: _removeAttachment,
                      ),
                    ),
                  ),
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
                  onAttachPressed: _pickAndSaveAttachment,
                  attachedFileName: _attachedFileName,
                  onRemoveAttachment: _removeAttachment,
                  isDark: isDark,
                  onSendPressed: _sendToChat, // added
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
    required this.onAttachPressed, // added
    required this.attachedFileName, // added
    required this.onRemoveAttachment, // added
    required this.onSendPressed, // added
  });
  final TextEditingController controller;
  final VoidCallback onMarksPressed;
  final bool isDark;
  final VoidCallback onAttachPressed; // added
  final String? attachedFileName; // added
  final VoidCallback onRemoveAttachment; // added
  final VoidCallback onSendPressed; // added

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
                      onPressed: onAttachPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isSmallPhone ? 12 : 14),
                        ),
                      ),
                      icon: const Icon(Icons.attach_file),
                      label: Text('evaluation.attach'.tr()), // changed: always show "Attach"
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
                      onPressed: onSendPressed, // changed: send to chat
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
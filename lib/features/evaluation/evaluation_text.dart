import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'learning_mode.dart';
import 'evaluation_inputs.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../evaluation/evaluation_response.dart';
import 'dart:convert';

class EvaluationTextPage extends StatefulWidget {
  const EvaluationTextPage({super.key});

  @override
  State<EvaluationTextPage> createState() => _EvaluationTextPageState();
}

class _EvaluationTextPageState extends State<EvaluationTextPage> {
  int _selectedSegment = 1;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  String? _attachedFileName;
  static const String _attachmentKey = 'evaluation_attachment';
  static const String _evaluationStorageKey = 'evaluation_data';
  static const String _rubricKey = 'hasRubric';

  // State variables to track the required inputs
  bool _hasRubrics = false;
  bool _hasMarks = false;
  bool _hasAttachment = false;

  @override
  void dispose() {
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load attachment
    final attachmentName = prefs.getString(_attachmentKey);
    if (attachmentName != null && mounted) {
      setState(() {
        _attachedFileName = attachmentName;
        _hasAttachment = true;
      });
    }

    // Load rubric status
    final hasRubric = prefs.getBool(_rubricKey) ?? false;
    if (mounted) {
      setState(() {
        _hasRubrics = hasRubric;
      });
    }

    // Load marks status
    final marksData = prefs.getString(_evaluationStorageKey);
    if (mounted) {
      setState(() {
        _hasMarks = marksData != null && marksData.isNotEmpty;
      });
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
      setState(() {
        _attachedFileName = file.name;
        _hasAttachment = true;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('evaluation.fileUploaded'.tr())),
    );
  }

  Future<void> _removeAttachment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attachmentKey);
    if (mounted) {
      setState(() {
        _attachedFileName = null;
        _hasAttachment = false;
      });
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
        SnackBar(
          content: Text('evaluation.viewMarks'.tr()),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasRubric = prefs.getBool(_rubricKey) ?? false;

    if (!hasRubric) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('evaluation.addRubricRequired'.tr()),
        ),
      );
      return;
    }

    if (!_hasAttachment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('evaluation.addAttachmentRequired'.tr()),
        ),
      );
      return;
    }

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

  // Listen for changes when returning from other pages
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when returning from other pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Debug log to check state
    print('Send button enabled: ${_hasRubrics && _hasMarks && _hasAttachment}');
    print(
        'Has Rubrics: $_hasRubrics, Has Marks: $_hasMarks, Has Attachment: $_hasAttachment');

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InputChip(
                        label: Text(_attachedFileName!),
                        avatar: const Icon(Icons.attach_file, size: 18),
                        onDeleted: _removeAttachment,
                      ),
                    ),
                  ),
                // Show requirements status
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('Rubric: ${_hasRubrics ? '✓' : '✗'}'),
                        backgroundColor: _hasRubrics
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        labelStyle: TextStyle(
                            color: _hasRubrics
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      ),
                      Chip(
                        label: Text('Marks: ${_hasMarks ? '✓' : '✗'}'),
                        backgroundColor: _hasMarks
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        labelStyle: TextStyle(
                            color: _hasMarks
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      ),
                      Chip(
                        label:
                            Text('Attachment: ${_hasAttachment ? '✓' : '✗'}'),
                        backgroundColor: _hasAttachment
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        labelStyle: TextStyle(
                            color: _hasAttachment
                                ? Colors.green.shade800
                                : Colors.red.shade800),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.dividerColor,
                ),
                _InputBar(
                  controller: _inputController,
                  onMarksPressed: () async {
                    // Navigate to marks page and wait for result
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EvaluationInputPage(),
                      ),
                    );
                    // When returning, reload the marks status
                    _loadAllData();
                  },
                  onAttachPressed: _pickAndSaveAttachment,
                  attachedFileName: _attachedFileName,
                  onRemoveAttachment: _removeAttachment,
                  isDark: isDark,
                  onSendPressed: (_hasRubrics && _hasMarks && _hasAttachment)
                      ? () => _sendToChat()
                      : null,
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
    required this.onAttachPressed,
    required this.attachedFileName,
    required this.onRemoveAttachment,
    required this.onSendPressed,
  });
  final TextEditingController controller;
  final VoidCallback onMarksPressed;
  final bool isDark;
  final VoidCallback onAttachPressed;
  final String? attachedFileName;
  final VoidCallback onRemoveAttachment;
  final VoidCallback? onSendPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                // Attach File
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onAttachPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onMarksPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onSendPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: onSendPressed != null
                            ? const Color(0xFF1E63FF)
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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

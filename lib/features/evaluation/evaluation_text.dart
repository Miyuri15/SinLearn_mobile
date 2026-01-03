// lib/features/evaluation/evaluation_text.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'learning_mode.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../evaluation/evaluation_response.dart';
import 'dart:convert';

// NEW PAGE
import 'paper_config_review_page.dart';

class EvaluationTextPage extends StatefulWidget {
  final String chatSessionId;

  const EvaluationTextPage({
    super.key,
    required this.chatSessionId,
  });

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
  static const String _paperConfigConfirmedKey = 'paper_config_confirmed';

  bool _hasRubrics = false;
  bool _hasMarks = false;
  bool _hasAttachment = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD STATE
  // ---------------------------------------------------------------------------
  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    _attachedFileName = prefs.getString(_attachmentKey);
    _hasAttachment = _attachedFileName != null;

    _hasRubrics = prefs.getBool(_rubricKey) ?? false;

    final legacyMarks = prefs.getString(_evaluationStorageKey);
    final paperConfirmed =
        prefs.getBool(_paperConfigConfirmedKey) ?? false;

    _hasMarks =
        (legacyMarks != null && legacyMarks.isNotEmpty) || paperConfirmed;

    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // ATTACHMENT
  // ---------------------------------------------------------------------------
  Future<void> _pickAndSaveAttachment() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_attachmentKey, result.files.first.name);

    setState(() {
      _attachedFileName = result.files.first.name;
      _hasAttachment = true;
    });
  }

  Future<void> _removeAttachment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attachmentKey);

    setState(() {
      _attachedFileName = null;
      _hasAttachment = false;
    });
  }

  // ---------------------------------------------------------------------------
  // SEND FLOW
  // ---------------------------------------------------------------------------
  Future<void> _sendToChat() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_hasRubrics || !_hasMarks || !_hasAttachment) return;

    final legacyData = prefs.getString(_evaluationStorageKey);
    final evalData =
        legacyData != null ? jsonDecode(legacyData) : {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EvaluationResponsePage(
          initialMessageText: 'Evaluation started',
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
        onRubricApplied: _loadAllData,
      ),
      drawer: const RecentChatsDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'evaluation.startNewEvaluation'.tr(),
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                _statusChip('Rubric', _hasRubrics),
                _statusChip('Marks', _hasMarks),
                _statusChip('Attachment', _hasAttachment),
              ],
            ),
          ),

          // INPUT BAR
          _InputBar(
            controller: _inputController,
            isDark: isDark,
            attachedFileName: _attachedFileName,
            onAttachPressed: _pickAndSaveAttachment,
            onRemoveAttachment: _removeAttachment,
            onMarksPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaperConfigReviewPage(
                    sessionId: widget.chatSessionId,
                  ),
                ),
              );
              _loadAllData();
            },
            onSendPressed:
                (_hasRubrics && _hasMarks && _hasAttachment)
                    ? _sendToChat
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool ok) {
    return Chip(
      label: Text('$label: ${ok ? '✓' : '✗'}'),
      backgroundColor:
          ok ? Colors.green.shade100 : Colors.red.shade100,
    );
  }
}

// -----------------------------------------------------------------------------
// INPUT BAR WIDGET (FIXED + COMPLETE)
// -----------------------------------------------------------------------------
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.onAttachPressed,
    required this.attachedFileName,
    required this.onRemoveAttachment,
    required this.onMarksPressed,
    required this.onSendPressed,
  });

  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onAttachPressed;
  final String? attachedFileName;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onMarksPressed;
  final VoidCallback? onSendPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onAttachPressed,
                icon: const Icon(Icons.attach_file),
                label: Text('evaluation.attach'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMarksPressed,
                icon: const Icon(Icons.add),
                label: Text('evaluation.marks'.tr()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSendPressed,
                icon: const Icon(Icons.send),
                label: Text('evaluation.send'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      onSendPressed != null ? null : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'evaluation_text.dart';
import 'heder.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import '../../services/message_service.dart';
import '../../services/chat_service.dart';


class LearningModePage extends StatefulWidget {
  const LearningModePage({super.key});


  @override
  State<LearningModePage> createState() => _LearningModePageState();
}

// Add a simple message model
class Message {
  final String text;
  final bool fromUser;
  final DateTime time;
  final List<PlatformFile>? attachments; // new
  Message({
    required this.text,
    required this.fromUser,
    this.attachments,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class _LearningModePageState extends State<LearningModePage> {
  int _selectedSegment = 0; // 0 = Learning, 1 = Evaluation
  // store the localization key (display shows .tr())
  String? _activeSessionId;
  bool _isSending = false;
  List<Message> _messages = [];
  String _responseLevel = 'grades_9_11';

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();


  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // helper: detect if text contains Sinhala characters
  bool _containsSinhala(String s) {
    return RegExp(r'[\u0D80-\u0DFF]').hasMatch(s);
  }

  // helper to handle sending + language-aware reply
  void _handleSendMessage(String text, [List<PlatformFile>? attachments]) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (attachments == null || attachments.isEmpty)) return;

    setState(() {
      _messages.add(
          Message(text: trimmed, fromUser: true, attachments: attachments));
    });

    // choose reply language based on content
    final bool isSinhala = _containsSinhala(trimmed);

    final String botReply =
        isSinhala ? 'ඔබට කෙසේ උදව් කළ හැකිද?' : 'How can I help you?';

    // schedule a fixed simple reply in the detected language
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(text: botReply, fromUser: false));
      });
    });
  }

  Future<void> _handleSendFromInputBar(
      String text,
      List<PlatformFile> attachments,
      ) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;

      // 1️⃣ Optimistic UI
      _messages.add(
        Message(
          text: text,
          fromUser: true,
          attachments: attachments,
        ),
      );
    });

    try {
      final payload = {
        "content": text,
        "modality": "text",
        "grade_level": _responseLevel,
      };

      final resp = await MessageService.postMessage(
        sessionId: _activeSessionId,
        payload: payload,
      );

      // 2️⃣ Capture session id
      final newSessionId =
          resp["session_id"] ??
              resp["session"]?["id"] ??
              resp["chat_id"] ??
              resp["id"];

      if (_activeSessionId == null && newSessionId != null) {
        _activeSessionId = newSessionId;
      }

      // 3️⃣ Append assistant reply
      if (resp["assistant_message"] != null) {
        setState(() {
          _messages.add(
            Message(
              text: resp["assistant_message"]["content"].toString(),
              fromUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("❌ Send failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send message")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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
        onSegmentSelected: (index) async {
          setState(() => _selectedSegment = index);

          if (index == 1) {
            // Create a new session ID for evaluation via API
            try {
              final session = await ChatService.createChatSession(
                mode: 'evaluation',
                title: 'New Evaluation Chat',
              );
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        EvaluationTextPage(chatSessionId: session.id)),
              );
            } catch (e) {
              print('Error creating evaluation session: $e');
              // Fallback or show error
            }
          }
        },
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
        chatSessionId: _activeSessionId,
      ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
                width: sidebarWidth,
                child: _Sidebar(
                    theme: theme, searchController: _searchController)),

          // RIGHT SIDE
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),

                // ===== Chat Body =====
                Expanded(child: _ChatView(messages: _messages)),

                const Divider(height: 1),

                // ===== Input Bar =====
                _InputBar(
                  controller: _inputController,
                  responseLevel: _responseLevel,
                  onResponseLevelChanged: (v) {
                    setState(() => _responseLevel = v);
                  },
                  onSend: _handleSendFromInputBar,
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
    // Use RecentChatsDrawer content for sidebar too, or a similar widget
    // For now, let's just wrap RecentChatsDrawer but constrained
    return const RecentChatsDrawer(); 
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

// Replace previous _EmptyChatView with _ChatView that shows messages or empty prompt
class _ChatView extends StatelessWidget {
  const _ChatView({
    Key? key,
    required this.messages,
  }) : super(key: key);

  final List<Message> messages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fetch localized text for start_conversation
            Text('start_conversation'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            // Fetch localized text for type_question
            Text('type_question'.tr(),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: Colors.grey[450])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        final align = m.fromUser ? Alignment.centerRight : Alignment.centerLeft;
        final bgColor =
            m.fromUser ? const Color(0xFF1E63FF) : theme.colorScheme.surface;
        final textColor =
            m.fromUser ? Colors.white : theme.textTheme.bodyLarge?.color;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Align(
            alignment: align,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.text.isNotEmpty)
                      Text(m.text,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: textColor)),
                    // Render attachments (if any)
                    if (m.attachments != null && m.attachments!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: m.attachments!.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: m.fromUser
                                  ? Colors.white.withOpacity(0.06)
                                  : theme.colorScheme.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.insert_drive_file, size: 16),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.45),
                                  child: Text(f.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: textColor)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${MaterialLocalizations.of(context).formatShortDate(m.time)} '
                      '${TimeOfDay.fromDateTime(m.time).format(context)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: (textColor as Color?)?.withOpacity(0.7) ??
                              Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
//                                  INPUT BAR
// ============================================================================

// Replace previous StatelessWidget _InputBar with a StatefulWidget so attachments can be shown
class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.responseLevel,
    required this.onResponseLevelChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final String responseLevel;
  final ValueChanged<String> onResponseLevelChanged;
  final void Function(String text, List<PlatformFile> attachments)
      onSend; // changed

  @override
  State<_InputBar> createState() => _InputBarState();
}


class _InputBarState extends State<_InputBar>
    with SingleTickerProviderStateMixin {
  final List<PlatformFile> _attachedFiles = [];

  String get responseLevel => widget.responseLevel;
  TextEditingController get controller => widget.controller;

  // recording state + animation
  bool _isRecording = false;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndAttachFile() async {

    final result = await FilePicker.platform
        .pickFiles(allowMultiple: false, withData: true, type: FileType.any);
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File selection canceled')));
      }
      return;
    }

    final file = result.files.first;
    await _savePickedFile(context, file);
    if (!mounted) return;
    setState(() => _attachedFiles.add(file));
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    _animController.repeat();
  }

  void _stopRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
    // optional: you could add a message or attach recorded audio here
  }

  void _cancelRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty && _attachedFiles.isEmpty) return;

    widget.onSend(
      text,
      List<PlatformFile>.from(_attachedFiles),
    );

    setState(() {
      controller.clear();
      _attachedFiles.clear();
    });
  }



  // small animated waveform widget used inside recording panel
  Widget _waveform(BuildContext context) {
    final barCount = 12;
    final maxBarHeight = 28.0;
    final minBarHeight = 6.0;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * math.pi * 2;
            final t = (_animController.value * math.pi * 2) + phase;
            final v = (math.sin(t) + 1) / 2; // 0..1
            final h = minBarHeight + (v * (maxBarHeight - minBarHeight));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: 6,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // recording panel UI (rounded with red waveform & controls)
  Widget _recordingPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? Colors.red.shade50
            : Colors.red.shade900.withOpacity(0.16),
        border: Border.all(color: Colors.red.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // left red dot
          Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle)),
          Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle)),
          const SizedBox(width: 12),

          // waveform (center)
          Expanded(
            child: Center(child: _waveform(context)),
          ),

          // controls on the right
          Row(
            children: [
              TextButton.icon(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                label: Text('Cancel',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.mic_off, color: Colors.red),
                label: Text('Stop',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

          // small chip row shown when there are attached files
          Widget attachedFilesView() {
            if (_attachedFiles.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _attachedFiles.map((f) {
                  return Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insert_drive_file, size: 16),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text('${f.name} • ${_formatSize(f.size)}',
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _attachedFiles.remove(f));
                    },
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            );
          }

          // Replace the narrow-layout response_level Container with a more compact variant
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('response_level'.tr(),
                        style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        // smaller padding & radius
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallPhone ? 6 : 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: theme.dividerColor.withOpacity(0.12)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 34, // reduced height
                              child: DropdownButton<String>(
                                value: responseLevel,
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(
                                      value: 'grades_6_8',
                                      child: Text('grades_6_8'.tr(),
                                          textAlign: TextAlign.center)),
                                  DropdownMenuItem(
                                      value: 'grades_9_11',
                                      child: Text('grades_9_11'.tr(),
                                          textAlign: TextAlign.center)),
                                  DropdownMenuItem(
                                      value: 'grades_12_plus',
                                      child: Text('grades_12_plus'.tr(),
                                          textAlign: TextAlign.center)),
                                ],
                                onChanged: (v) => v != null
                                    ? widget.onResponseLevelChanged(v)
                                    : null,
                                selectedItemBuilder: (context) => [
                                  Center(
                                      child: Text('grades_6_8'.tr(),
                                          textAlign: TextAlign.center)),
                                  Center(
                                      child: Text('grades_9_11'.tr(),
                                          textAlign: TextAlign.center)),
                                  Center(
                                      child: Text('grades_12_plus'.tr(),
                                          textAlign: TextAlign.center)),
                                ],
                                dropdownColor: theme.colorScheme.surface,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // show attached files as chips
                attachedFilesView(),

                // show recording panel if active
                if (_isRecording) _recordingPanel(context),

                // Input row with pill input + send button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface, // was Colors.white
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: theme.dividerColor.withOpacity(0.12)),
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
                            SizedBox(
                              width: isSmallPhone ? 88 : 120,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                        onPressed: _pickAndAttachFile,
                                        icon: const Icon(Icons.attach_file)),
                                    IconButton(
                                      onPressed: _isRecording
                                          ? _stopRecording
                                          : _startRecording,
                                      icon: Icon(_isRecording
                                          ? Icons.mic
                                          : Icons.mic_none),
                                    ),
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
                        onPressed: _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E63FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: EdgeInsets.zero,
                        ),
                        child:
                            const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Wide layout (smaller/narrower response card)
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 6), // tighter padding
                    margin: const EdgeInsets.only(right: 10),
                    constraints: const BoxConstraints(
                        minWidth: 110, maxWidth: 160), // narrower card
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: theme.dividerColor.withOpacity(0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text('response_level'.tr(),
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 32, // reduced height
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: responseLevel,
                              underline: const SizedBox.shrink(),
                              isExpanded: true,
                              items: [

                                DropdownMenuItem(
                                    value: 'grades_6_8',
                                    child:
                                        Center(child: Text('grades_6_8'.tr()))),
                                DropdownMenuItem(
                                    value: 'grades_9_11',
                                    child: Center(
                                        child: Text('grades_9_11'.tr()))),
                                DropdownMenuItem(
                                    value: 'grades_12_plus',
                                    child: Center(
                                        child: Text('grades_12_plus'.tr()))),
                              ],
                              onChanged: (v) {
                                if (v != null) widget.onResponseLevelChanged(v);
                              },
                              selectedItemBuilder: (context) => [

                                Center(
                                    child: Text('grades_6_8'.tr(),
                                        textAlign: TextAlign.center)),
                                Center(
                                    child: Text('grades_9_11'.tr(),
                                        textAlign: TextAlign.center)),
                                Center(
                                    child: Text('grades_12_plus'.tr(),
                                        textAlign: TextAlign.center)),
                              ],
                              dropdownColor: theme.colorScheme.surface,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                      child: Container()), // keep rest balanced horizontally
                ],
              ),

              // attached files row
              attachedFilesView(),

              // show recording panel if active
              if (_isRecording) _recordingPanel(context),

              // main input row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),

                        border: Border.all(
                            color: theme.dividerColor.withOpacity(0.12)),
                        boxShadow: [
                          if (theme.brightness == Brightness.light)
                            BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 6)
                        ],
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

                          IconButton(
                              onPressed: _pickAndAttachFile,
                              icon: const Icon(Icons.attach_file)),
                          IconButton(
                            onPressed:
                                _isRecording ? _stopRecording : _startRecording,
                            icon:
                                Icon(_isRecording ? Icons.mic : Icons.mic_none),
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
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E63FF),

                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: EdgeInsets.zero,
                      ),
                      child:
                          const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

// Add helper to save picked file bytes into local storage (SharedPreferences as base64)
Future<void> _savePickedFile(BuildContext context, PlatformFile file) async {
  try {
    final bytes = file.bytes;
    if (bytes == null) {

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file bytes')));
      return;
    }

    final key =
        'uploaded_${file.name}_${DateTime.now().millisecondsSinceEpoch}';
    final base64Str = base64Encode(bytes);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, base64Str);

    // maintain a simple manifest (list of uploaded files)
    const manifestKey = 'uploaded_files_manifest';
    final manifestJson = prefs.getString(manifestKey);
    List<Map<String, dynamic>> manifest = [];
    if (manifestJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(manifestJson);
        manifest = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {
        manifest = [];
      }
    }
    manifest.insert(0, {
      'key': key,
      'name': file.name,
      'size': file.size,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await prefs.setString(manifestKey, jsonEncode(manifest));


    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Saved ${file.name} locally')));
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error saving file: $e')));
  }
}

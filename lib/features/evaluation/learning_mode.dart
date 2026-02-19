import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sinlearn_mobile/models/chat_models.dart';
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
import '../../services/resource_service.dart';
import '../../services/chat_service.dart';
import 'package:dio/dio.dart' show MultipartFile;
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


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
  String _responseLevel = 'grade_9_11';

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
      Uint8List? voiceRecording, // Accept the voice recording as a parameter
      ) async {
    if (_isSending) return;  // Prevents sending if already in progress
    setState(() {
      _isSending = true;

      // Optimistic UI: Add the user's message immediately
      _messages.add(
        Message(
          text: text,
          fromUser: true,
          attachments: attachments,
        ),
      );
    });

    List<Map<String, dynamic>> uploadedResources = [];

    // Upload attachments first so backend receives resource ids
    if (attachments.isNotEmpty) {
      try {
        final files = attachments.map((f) {
          final bytes = f.bytes ?? Uint8List(0);
          return MultipartFile.fromBytes(bytes, filename: f.name);
        }).toList();

        final resp = await ResourceService.uploadResources(files);
        uploadedResources = resp
            .map((r) => {'resource_id': r.resourceId, 'display_name': r.filename})
            .toList();
      } catch (err) {
        debugPrint('Failed to upload files: $err');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload files')),
          );
        }
        setState(() => _isSending = false);
        return;
      }
    }

    // If there's a voice message, handle it
    if (voiceRecording != null) {
      await _handleVoiceSend(voiceRecording, attachments);  // Handle the voice message
    } else {
      // Otherwise, send a text message
      try {
        final resourceAttachments = uploadedResources
            .map((item) => {
          'resource_id': item['resource_id'],
          'display_name': item['display_name'],
          'attachment_type': 'file',
        })
            .toList();

        final payload = {
          "content": text,
          "modality": "text",  // Indicate this is a text message
          "grade_level": _responseLevel,
          if (resourceAttachments.isNotEmpty) 'attachments': resourceAttachments,
        };

        final resp = await ChatService.postMessage(
          sessionId: _activeSessionId,
          payload: payload,
        );

        // 2️⃣ Capture session id
        final newSessionId = resp["session_id"] ??
            resp["session"]?["id"] ??
            resp["chat_id"] ??
            resp["id"];

        final createdMessageId =
            resp["message_id"] ?? resp["message"]?['id'] ?? resp["id"];

        if (_activeSessionId == null && newSessionId != null) {
          _activeSessionId = newSessionId;
        }

        // Append assistant reply ONLY if backend returns it
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

        // Refresh session messages from backend to get canonical state
        final sessionToRefresh = newSessionId ?? _activeSessionId;
        if (sessionToRefresh != null) {
          try {
            final serverMessages =
            await ChatService.listSessionMessages(sessionToRefresh);
            if (!mounted) return;
            setState(() {
              _messages = serverMessages
                  .map((m) => Message(
                text: m.content is String
                    ? m.content as String
                    : m.content.toString(),
                fromUser: m.role == 'user',
                time: DateTime.parse(m.createdAt),
              ))
                  .toList();
            });
          } catch (err) {
            debugPrint('Failed to refresh messages: $err');
          }
        }
      } catch (e) {
        debugPrint("❌ Send failed: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to send message")),
          );
        }
      } finally {
        setState(() => _isSending = false);
      }
    }
  }


  // Voice send helper: accepts raw audio bytes (e.g. recorded wav)
  Future<void> _handleVoiceSend(
      Uint8List audioBytes, List<PlatformFile> attachments) async {
    if (_isSending) return;  // Prevents sending if already in progress
    setState(() => _isSending = true);

    List<Map<String, dynamic>> uploadedResources = [];

    // Upload attachments first, if any
    if (attachments.isNotEmpty) {
      try {
        final files = attachments.map((f) {
          final bytes = f.bytes ?? Uint8List(0);
          return MultipartFile.fromBytes(bytes, filename: f.name);
        }).toList();

        // Upload resources to the backend
        final resp = await ResourceService.uploadResources(files);
        uploadedResources = resp
            .map((r) => {'resource_id': r.resourceId, 'display_name': r.filename})
            .toList();
      } catch (err) {
        debugPrint('Failed to upload files: $err');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload files')),
          );
        }
        setState(() => _isSending = false);
        return;
      }
    }

    try {
      // Prepare the audio file for the API
      final audioFile = MultipartFile.fromBytes(audioBytes, filename: 'voice.wav');

      // Post the voice QA request to the backend
      final data = await ChatService.postVoiceQA(
        audio: audioFile,
        sessionId: _activeSessionId ?? 'undefined',  // Ensure session ID is valid
        resourceIds: uploadedResources.map((r) => r['resource_id'] as String).toList(),
        topK: 3,
      );

      // If a new session is returned, update the session ID
      if (data.sessionId.isNotEmpty && _activeSessionId == null) {
        _activeSessionId = data.sessionId;
      }

      setState(() {
        // Add the voice question and answer to the message list
        _messages.addAll([
          Message(text: data.question, fromUser: true),  // User's question (voice input)
          Message(text: data.answer, fromUser: false),  // Assistant's answer
        ]);
      });
    } catch (err) {
      debugPrint('Voice processing failed: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice processing failed')),
        );
      }
    } finally {
      // Reset sending state after completion
      setState(() => _isSending = false);
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
        onSegmentSelected: (index) {
          setState(() => _selectedSegment = index);

          if (index == 1) {
            // Generate a new session ID for evaluation
            final newSessionId =
                DateTime.now().millisecondsSinceEpoch.toString();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EvaluationTextPage(chatSessionId: newSessionId)),
            );
          }
        },
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
      ),
      resizeToAvoidBottomInset: true,
      body: Row(
        children: [
          if (isWide)
            SizedBox(
                width: sidebarWidth,
                child: _Sidebar(
                    theme: theme,
                    searchController: _searchController,
                    onSessionSelected: _openSession)),

          // RIGHT SIDE
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 1),

              // CHAT AREA (only scrollable area)
              Expanded(
                child: _ChatView(messages: _messages),
              ),

              const Divider(height: 1),

              // INPUT BAR (fixed)
              _InputBar(
                controller: _inputController,
                responseLevel: _responseLevel,
                onResponseLevelChanged: (v) {
                  setState(() => _responseLevel = v);
                },
                onSend: _handleSendFromInputBar,
              ),
            ],
          )),
        ],
      ),
    );
  }

  // ----------------------- Drawer -----------------------
  Widget _buildDrawer(BuildContext context) {
    return const RecentChatsDrawer();
  }

  // Open a session from the sidebar: set active session and load messages
  Future<void> _openSession(ChatSession session) async {
    final sessionId = session.id;

    setState(() {
      _activeSessionId = sessionId;
    });

    try {
      final serverMessages =
          await ChatService.listSessionMessages(_activeSessionId!);

      for (final m in serverMessages) {
        print('''
          ChatMessage
          role      : ${m.role}
          content   : ${m.content}
          createdAt : ${m.createdAt}
          ''');
      }

      if (!mounted) return;

      setState(() {
        _messages = serverMessages
            .map((m) => Message(
                  text: m.content is String
                      ? m.content as String
                      : m.content.toString(),
                  fromUser: m.role == 'user',
                  time: DateTime.parse(m.createdAt),
                ))
            .toList();
      });
    } catch (err) {
      debugPrint('Failed to load session messages: $err');
    }
  }
}

// ============================================================================
//                                 SIDEBAR
// ============================================================================
class _Sidebar extends StatefulWidget {
  const _Sidebar({
    required this.theme,
    required this.searchController,
    this.onSessionSelected,
    Key? key,
  }) : super(key: key);

  final ThemeData theme;
  final TextEditingController searchController;
  final ValueChanged<ChatSession>? onSessionSelected;

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  late Future<List<ChatSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = ChatService.listChatSessions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
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
            child: FutureBuilder<List<ChatSession>>(
              future: _sessionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('Failed to load chats',
                          style: theme.textTheme.bodyMedium),
                    ),
                  );
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return ListView(
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
                  );
                }

                return ListView(
                  children: sessions.map((s) {
                    final icon = s.mode == 'learning'
                        ? Icons.menu_book_outlined
                        : Icons.assignment_turned_in_outlined;
                    final title = s.title ??
                        (s.mode == 'learning'
                            ? 'New Learning Chat'
                            : 'New Evaluation Chat');
                    // Keep the existing simple subtitle style for now
                    final subtitle = '0 messages • less than a minute ago';
                    return _ChatListItem(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                        onTap: () => widget.onSessionSelected?.call(s));
                  }).toList(),
                );
              },
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
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

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
        onTap: onTap,
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
    Key? key,
    required this.controller,
    required this.responseLevel,
    required this.onResponseLevelChanged,
    required this.onSend,  // Updated this part
  }) : super(key: key);

  final TextEditingController controller;
  final String responseLevel;
  final ValueChanged<String> onResponseLevelChanged;
  final Future<void> Function(String text, List<PlatformFile> attachments, Uint8List? voiceRecording) onSend;  // Updated signature

  @override
  State<_InputBar> createState() => _InputBarState();
}


class _InputBarState extends State<_InputBar>
    with SingleTickerProviderStateMixin {
  final List<PlatformFile> _attachedFiles = [];
  Uint8List? pendingVoice; // Holds the recorded audio
  String get responseLevel => widget.responseLevel;
  TextEditingController get controller => widget.controller;
  final AudioRecorder _recorder = AudioRecorder();
  // recording state + animation
  bool _isRecording = false;
  late final AnimationController _animController;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();


  @override
  void initState() {
    super.initState();

    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _totalDuration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _currentPosition = p);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
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

  Future<void> _stopRecording() async {
    _animController.stop();

    try {
      final String? path = await _recorder.stop();

      if (path == null) {
        debugPrint('No audio file recorded');
        return;
      }

      final file = File(path);
      final Uint8List audioBytes = await file.readAsBytes();

      setState(() {
        pendingVoice = audioBytes;
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording saved! Ready to send.'),
        ),
      );
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }


  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();

      final String filePath =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
        ),
        path: filePath,
      );

      setState(() => _isRecording = true);
      _animController.repeat();
    }
  }



  void _cancelRecording() {
    _animController.stop();
    setState(() => _isRecording = false);
  }

  Future<void> _togglePlayback() async {
    if (pendingVoice == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_currentPosition == Duration.zero) {
        // First time play
        await _audioPlayer.play(BytesSource(pendingVoice!));
      } else {
        // Resume from pause
        await _audioPlayer.resume();
      }

      setState(() => _isPlaying = true);
    }
  }



  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty && _attachedFiles.isEmpty && pendingVoice == null) return;  // Check for voice as well

    // Check if voice is recorded, if yes, send voice as well
    widget.onSend(
      text,
      List<PlatformFile>.from(_attachedFiles),
      pendingVoice,  // Send the recorded voice along with other data
    );

    setState(() {
      controller.clear();
      _attachedFiles.clear();
      pendingVoice = null;  // Clear the voice after sending
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }


  Widget _buildResponseLevel({
    required ThemeData theme,
    required bool isSmallPhone,
    required bool narrow,
  }) {
    return Row(
      children: [
        if (narrow) ...[
          Text('response_level'.tr(),
              style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallPhone ? 6 : 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.12),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: responseLevel,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                      value: 'grade_6_8',
                      child: Center(child: Text('grades_6_8'.tr()))),
                  DropdownMenuItem(
                      value: 'grade_9_11',
                      child: Center(child: Text('grades_9_11'.tr()))),
                  DropdownMenuItem(
                      value: 'grade_12_plus',
                      child: Center(child: Text('grades_12_plus'.tr()))),
                ],
                onChanged: (v) {
                  if (v != null)
                    widget.onResponseLevelChanged(v);
                },
                dropdownColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow({
    required ThemeData theme,
    required bool isSmallPhone,
    bool addShadow = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.12),
              ),
              boxShadow: addShadow &&
                  theme.brightness == Brightness.light
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 6,
                )
              ]
                  : [],
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
                  icon: const Icon(Icons.attach_file),
                ),
                IconButton(
                  onPressed: _isRecording
                      ? _stopRecording
                      : _startRecording,
                  icon: Icon(
                    _isRecording
                        ? Icons.mic
                        : Icons.mic_none,
                  ),
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
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.white),
          ),
        ),
      ],
    );
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

  Widget _buildAudioPlaybackBar(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Play button
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 8),

                // Current time
                Text(
                  _formatDuration(_currentPosition),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(width: 8),

                // Progress slider
                Expanded(
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble(),
                    max: _totalDuration.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    activeColor: Colors.purpleAccent,
                    inactiveColor: Colors.grey,
                    onChanged: (value) async {
                      final position =
                      Duration(milliseconds: value.toInt());
                      await _audioPlayer.seek(position);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Total duration
                Text(
                  _formatDuration(_totalDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(width: 8),

                // Delete button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      pendingVoice = null;
                      _currentPosition = Duration.zero;
                      _totalDuration = Duration.zero;
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Send button
        SizedBox(
          height: 52,
          width: 52,
          child: ElevatedButton(
            onPressed: _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.send_rounded,
                color: Colors.white),
          ),
        ),
      ],
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 260, // ✅ hard cap for input bar
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildResponseLevel(
                    theme: theme,
                    isSmallPhone: isSmallPhone,
                    narrow: narrow,
                  ),

                  const SizedBox(height: 10),

                  attachedFilesView(),

                  if (_isRecording) _recordingPanel(context),

                  const SizedBox(height: 6),

                  // Show only send button when voice exists
                  if (pendingVoice != null && !_isRecording)
                    _buildAudioPlaybackBar(theme)
                  else
                    _buildInputRow(
                      theme: theme,
                      isSmallPhone: isSmallPhone,
                      addShadow: !narrow,
                    ),
                ],
              );

            }),
          ),
        ),
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

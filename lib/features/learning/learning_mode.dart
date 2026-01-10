import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../evaluation/evaluation_text.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import '../../services/message_service.dart';
import '../../services/chat_service.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/error_handler.dart';
import '../../models/message.dart';
import 'widgets/chat_view.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/sidebar.dart';

/// Main page for Learning Mode chat interface.
///
/// Features:
/// - Chat message display with API integration
/// - Message input with file attachments and audio recording
/// - Responsive layout (mobile and desktop)
/// - Grade level selection for response complexity
/// - Session management
class LearningModePage extends StatefulWidget {
  const LearningModePage({super.key, this.chatSessionId});

  final String? chatSessionId;

  @override
  State<LearningModePage> createState() => _LearningModePageState();
}

class _LearningModePageState extends State<LearningModePage> {
  int _selectedSegment = 0; // 0 = Learning, 1 = Evaluation
  String? _activeSessionId;
  bool _isSending = false;
  bool _isLoadingMessages = false;
  final List<Message> _messages = [];
  String _responseLevel = 'grade_9_11';

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.chatSessionId;
    if (_activeSessionId != null) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Load messages from API for the current session
  Future<void> _loadMessages() async {
    if (_activeSessionId == null) return;

    setState(() => _isLoadingMessages = true);

    try {
      final apiMessages = await ChatService.listChatMessages(_activeSessionId!);
      if (!mounted) return;

      setState(() {
        _messages.clear();

        for (final apiMsg in apiMessages) {
          final parsed = DateTime.tryParse(apiMsg.createdAt);
          final localTime = parsed?.toLocal() ?? DateTime.now();

          _messages.add(
            Message(
              text: apiMsg.content,
              fromUser: apiMsg.role == 'user',
              time: localTime, // ✅ Option A: device local time
              gradeLevel: apiMsg.gradeLevel,
              resourceIds: apiMsg.resourceIds,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        AppToast.error(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  /// Send message with attachments to the API
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
      final newSessionId = resp["session_id"] ??
          resp["session"]?["id"] ??
          resp["chat_id"] ??
          resp["id"];

      final bool isNewSession =
          _activeSessionId == null && newSessionId != null;
      if (isNewSession) {
        _activeSessionId = newSessionId;
      }

      // 3️⃣ Reload all messages from API to ensure consistency
      await _loadMessages();
    } catch (e) {
      debugPrint("❌ Send failed: $e");
      if (mounted) {
        AppToast.error(context, ErrorHandler.getErrorMessage(e));
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
    final bool isWide = size.width >= 900;
    final sidebarWidth = isWide ? (size.width * 0.32).clamp(260.0, 360.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        onSegmentSelected: (index) async {
          setState(() => _selectedSegment = index);

          if (index == 1) {
            // Create a new session for evaluation
            try {
              final session = await ChatService.createChatSession(
                mode: 'evaluation',
                title: 'New Evaluation Chat',
              );
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => EvaluationTextPage(chatSessionId: session.id),
                ),
              );
            } catch (e) {
              debugPrint('Error creating evaluation session: $e');
              if (mounted) {
                AppToast.error(context, ErrorHandler.getErrorMessage(e));
              }
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
          // Sidebar for wide screens
          if (isWide)
            SizedBox(
              width: sidebarWidth,
              child: LearningModeSidebar(
                theme: theme,
                searchController: _searchController,
              ),
            ),

          // Main chat area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),

                // Chat messages
                Expanded(
                  child: ChatView(
                    messages: _messages,
                    isLoading: _isLoadingMessages,
                  ),
                ),

                const Divider(height: 1),

                // Input bar
                ChatInputBar(
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

  /// Build the drawer for mobile view
  Widget _buildDrawer(BuildContext context) {
    return const RecentChatsDrawer();
  }
}

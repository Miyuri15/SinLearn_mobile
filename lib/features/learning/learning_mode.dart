import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../evaluation/evaluation_text.dart';
import '../../widgets/teachers_main_app_bar.dart';
import '../recent_chat/recent_chats_page.dart';
import '../../services/message_service.dart';
import '../../services/chat_service.dart';
import '../../services/resource_service.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/error_handler.dart';
import '../../models/message.dart';
import 'widgets/chat_view.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/sidebar.dart';

class LearningModePage extends StatefulWidget {
  const LearningModePage({super.key, this.chatSessionId});

  final String? chatSessionId;

  @override
  State<LearningModePage> createState() => _LearningModePageState();
}

class _LearningModePageState extends State<LearningModePage> {
  int _selectedSegment = 0;
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

  // ================= LOAD MESSAGES =================

  Future<void> _loadMessages() async {
    if (_activeSessionId == null) return;

    setState(() => _isLoadingMessages = true);

    try {
      final apiMessages =
          await ChatService.listChatMessages(_activeSessionId!);

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
              time: localTime,
              gradeLevel: apiMsg.gradeLevel,
              resourceIds: apiMsg.resourceIds,
            ),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  // ================= SEND MESSAGE (TEXT + FILE + VOICE) =================

  Future<void> _handleSendFromInputBar(
    String text,
    List<PlatformFile> attachments,
    Uint8List? voiceBytes,
  ) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;

      _messages.add(
        Message(
          text: text,
          fromUser: true,
          attachments: attachments,
        ),
      );
    });

    try {
      List<String> uploadedResourceIds = [];

      // 1️⃣ Upload files first
      if (attachments.isNotEmpty) {
        final files = attachments.map((f) {
          final bytes = f.bytes ?? Uint8List(0);
          return MultipartFile.fromBytes(bytes, filename: f.name);
        }).toList();

        final uploadResp = await ResourceService.uploadResources(files);
        uploadedResourceIds =
            uploadResp.map((r) => r.resourceId).toList();
      }

      // 2️⃣ VOICE MODE
      if (voiceBytes != null) {
        final audioFile =
            MultipartFile.fromBytes(voiceBytes, filename: 'voice.wav');

        final data = await ChatService.postVoiceQA(
          audio: audioFile,
          sessionId: _activeSessionId,
          resourceIds: uploadedResourceIds,
          topK: 3,
        );

        if (_activeSessionId == null && data.sessionId.isNotEmpty) {
          _activeSessionId = data.sessionId;
        }

        setState(() {
          _messages.addAll([
            Message(text: data.question, fromUser: true),
            Message(text: data.answer, fromUser: false),
          ]);
        });
      }

      // 3️⃣ TEXT MODE
      else {
        final payload = {
          "content": text,
          "modality": "text",
          "grade_level": _responseLevel,
          if (uploadedResourceIds.isNotEmpty)
            "resource_ids": uploadedResourceIds,
        };

        final resp = await MessageService.postMessage(
          sessionId: _activeSessionId,
          payload: payload,
        );

        final newSessionId = resp["session_id"] ??
            resp["session"]?["id"] ??
            resp["chat_id"] ??
            resp["id"];

        if (_activeSessionId == null && newSessionId != null) {
          _activeSessionId = newSessionId;
        }

        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 900;
    final sidebarWidth =
        isWide ? (size.width * 0.32).clamp(260.0, 360.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      appBar: MainAppBar(
        selectedIndex: _selectedSegment,
        chatSessionId: _activeSessionId,
        onSegmentSelected: (index) async {
          setState(() => _selectedSegment = index);

          if (index == 1) {
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
                      EvaluationTextPage(chatSessionId: session.id),
                ),
              );
            } catch (e) {
              if (mounted) {
                AppToast.error(context, ErrorHandler.getErrorMessage(e));
              }
            }
          }
        },
        onMenuPressed: () {},
        onRightIconPressed: () {},
        onAddPressed: () {},
      ),
      body: Row(
        children: [
          if (isWide)
            SizedBox(
              width: sidebarWidth,
              child: LearningModeSidebar(
                theme: theme,
                searchController: _searchController,
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(height: 1),

                Expanded(
                  child: ChatView(
                    messages: _messages,
                    isLoading: _isLoadingMessages,
                  ),
                ),

                const Divider(height: 1),

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

  Widget _buildDrawer(BuildContext context) {
    return const RecentChatsDrawer();
  }
}

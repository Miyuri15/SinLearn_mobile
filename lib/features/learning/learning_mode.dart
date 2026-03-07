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
import '../../models/resource_models.dart';
import '../../models/xai_models.dart';
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
  String? _sendProgressText;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool get _isFirstUserMessageInSession =>
      !_messages.any((message) => message.fromUser);

  bool _isMissingRagResourcesError(dynamic error) {
    if (error is! DioException) return false;

    final raw = error.response?.data;
    final statusCode = error.response?.statusCode;

    String normalized = '';
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final msg = map['message'] ??
          map['error'] ??
          map['detail'] ??
          map['detail_message'];
      normalized = msg?.toString().toLowerCase() ?? '';
    } else {
      normalized = raw?.toString().toLowerCase() ?? '';
    }

    return statusCode == 400 &&
        normalized.contains('no resources provided for rag');
  }

  String get _attachResourcesHint =>
      'Please attach at least one resource to generate a response.';

  // Update the _fetchMessageXai method in learning_mode.dart:

  Future<XaiResponse> _fetchMessageXai(String messageId) async {
    final response = await MessageService.getMessageXAIResponse(messageId);

    // Cache the explanation in the message
    if (mounted) {
      final index = _messages.indexWhere((m) => m.messageId == messageId);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWith(
            xaiExplanation: response.xaiExplanation?.toJson(),
          );
        });
      }
    }

    return response;
  }

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
      final apiMessages = await ChatService.listChatMessages(_activeSessionId!);

      if (!mounted) return;

      setState(() {
        _messages.clear();
        for (final apiMsg in apiMessages) {
          final parsed = DateTime.tryParse(apiMsg.createdAt);
          final localTime = parsed?.toLocal() ?? DateTime.now();

          _messages.add(
            Message(
              messageId: apiMsg.id,
              // Prefer server-provided transcript when available for voice messages
              text : apiMsg.content?.toString() ?? '',
              fromUser: apiMsg.role == 'user',
              time: localTime,
              gradeLevel: apiMsg.gradeLevel,
              resourceIds: apiMsg.resourceIds,
              safetySummary: apiMsg.safetySummary,
              modality: apiMsg.modality?.toString(),
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

    final isTextOnlyWithoutAttachments =
        voiceBytes == null && attachments.isEmpty;

    if (isTextOnlyWithoutAttachments && _isFirstUserMessageInSession) {
      if (mounted) {
        AppToast.info(context, _attachResourcesHint);
      }
      return;
    }

    setState(() {
      _isSending = true;
      _sendProgressText = "Preparing your request...";
    });

    try {
      if (voiceBytes != null) {
        List<String> uploadedResourceIds = [];

        if (attachments.isNotEmpty) {
          final files = attachments.map((f) {
            final bytes = f.bytes ?? Uint8List(0);
            return MultipartFile.fromBytes(bytes, filename: f.name);
          }).toList();

          final uploadResp =
              await ResourceService.uploadResourcesUploadOnly(files);
          uploadedResourceIds = uploadResp.map((r) => r.resourceId).toList();

          // Process uploaded resources so backend can extract text/embeddings
          // (voice flow expects resources to be ready for RAG lookups).
          if (uploadedResourceIds.isNotEmpty) {
            try {
              setState(() {
                _sendProgressText = "Processing uploaded resources...";
              });

              await ResourceService.processResourcesBatch(uploadedResourceIds);
            } catch (e) {
              if (mounted) {
                AppToast.error(context, ErrorHandler.getErrorMessage(e));
              }
            } finally {
              if (mounted) {
                setState(() {
                  _sendProgressText = null;
                });
              }
            }
          }
        }

        // Declare nullable index
        int? loaderIndex;

        // Add loader
        setState(() {
          loaderIndex = _messages.length;

          _messages.add(
            Message(
              text: "🎤 Transcribing your voice...",
              fromUser: false,
              time: DateTime.now(),
            ),
          );
        });

        try {
          final audioFile =
              MultipartFile.fromBytes(voiceBytes, filename: 'voice.wav');

          final data = await ChatService.postVoiceQA(
            audio: audioFile,
            sessionId: _activeSessionId,
            resourceIds: uploadedResourceIds,
            topK: 3,
          );

          if (data.sessionId != null) {
            setState(() {
              _activeSessionId = data.sessionId;
            });
          }

          if (!mounted) return;

          setState(() {
            // Remove loader safely
            if (loaderIndex != null && loaderIndex! < _messages.length) {
              _messages.removeAt(loaderIndex!);
            }

            // Add question + answer
            _messages.addAll([
              Message(
                text: data.question,
                fromUser: true,
                modality: 'voice',
                time: DateTime.now(),
              ),
              Message(
                text: data.answer,
                fromUser: false,
                time: DateTime.now(),
              ),
            ]);
          });
        } catch (e) {
          if (mounted) {
            setState(() {
              if (loaderIndex != null && loaderIndex! < _messages.length) {
                _messages.removeAt(loaderIndex!);
              }
            });
          }
          rethrow;
        }
      }

      // 3️⃣ TEXT MODE
      else {
        List<ResourceUploadResponse> uploadedResources = [];

        if (attachments.isNotEmpty) {
          setState(() {
            _sendProgressText = "Uploading attached resources...";
          });

          final files = attachments.map((f) {
            final bytes = f.bytes ?? Uint8List(0);
            return MultipartFile.fromBytes(bytes, filename: f.name);
          }).toList();

          uploadedResources =
              await ResourceService.uploadResourcesUploadOnly(files);
        }

        setState(() {
          _messages.add(
            Message(
              text: text,
              fromUser: true,
              attachments: attachments,
              time: DateTime.now(),
            ),
          );
        });

        final resourceAttachments = <Map<String, dynamic>>[];
        for (var i = 0; i < uploadedResources.length; i++) {
          final upload = uploadedResources[i];
          final localFile = i < attachments.length ? attachments[i] : null;

          resourceAttachments.add({
            'resource_id': upload.resourceId,
            'display_name': localFile?.name ?? upload.filename,
            'attachment_type': (localFile?.extension?.toLowerCase() == 'png' ||
                    localFile?.extension?.toLowerCase() == 'jpg' ||
                    localFile?.extension?.toLowerCase() == 'jpeg' ||
                    localFile?.extension?.toLowerCase() == 'gif' ||
                    localFile?.extension?.toLowerCase() == 'webp')
                ? 'image'
                : 'file',
          });
        }

        setState(() {
          _sendProgressText = "Generating a response...";
        });

        final payload = {
          "content": text,
          "modality": "text",
          "grade_level": _responseLevel,
          if (resourceAttachments.isNotEmpty)
            "attachments": resourceAttachments,
        };

        final resp = await MessageService.postMessage(
          sessionId: _activeSessionId,
          payload: payload,
        );

        final createdMessageId =
            resp["message_id"] ?? resp["message"]?["id"] ?? resp["id"];

        final newSessionId = resp["session_id"] ??
            resp["session"]?["id"] ??
            resp["chat_id"] ??
            resp["id"];

        if (_activeSessionId == null && newSessionId != null) {
          _activeSessionId = newSessionId;
        }

        if (createdMessageId != null &&
            createdMessageId.toString().isNotEmpty) {
          setState(() {
            _sendProgressText = "Processing message attachments...";
          });

          try {
            await ResourceService.processMessageAttachments(
              createdMessageId.toString(),
            );
          } catch (e) {
            if (mounted) {
              AppToast.error(context, ErrorHandler.getErrorMessage(e));
            }
          }

          setState(() {
            _sendProgressText = "Generating a response...";
          });

          try {
            final generated = await MessageService.generateMessageResponse(
              createdMessageId.toString(),
            );

            final generatedContent = generated["content"]?.toString();
            if (generatedContent != null &&
                generatedContent.isNotEmpty &&
                mounted) {
              setState(() {
                _messages.add(
                  Message(
                    messageId: generated["message"] is Map
                        ? generated["message"]["id"]?.toString()
                        : generated["id"]?.toString(),
                    text: generatedContent,
                    fromUser: false,
                    gradeLevel: generated["grade_level"]?.toString(),
                    safetySummary: generated["safety_summary"] is Map
                        ? Map<String, dynamic>.from(
                            generated["safety_summary"] as Map)
                        : null,
                    time: DateTime.now(),
                  ),
                );
              });
            }
          } catch (e) {
            if (_isMissingRagResourcesError(e) && mounted) {
              setState(() {
                _messages.add(
                  Message(
                    text: _attachResourcesHint,
                    fromUser: false,
                    time: DateTime.now(),
                  ),
                );
              });
              AppToast.info(context, _attachResourcesHint);
            }
          }
        }

        await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        final isMissingResources = _isMissingRagResourcesError(e);
        setState(() {
          _messages.add(
            Message(
              text: isMissingResources
                  ? _attachResourcesHint
                  : "Failed to send. Please check your connection and try again.",
              fromUser: false,
              time: DateTime.now(),
            ),
          );
        });
        if (isMissingResources) {
          AppToast.info(context, _attachResourcesHint);
        } else {
          AppToast.error(context, ErrorHandler.getErrorMessage(e));
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendProgressText = null;
        });
      }
    }
  }

  // ================= BUILD =================

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
                  builder: (_) => EvaluationTextPage(chatSessionId: session.id),
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
                    sendProgressText: _sendProgressText,
                    onExplainMessage: _fetchMessageXai,
                  ),
                ),
                const Divider(height: 1),
                ChatInputBar(
                  controller: _inputController,
                  isSending: _isSending,
                  canSendTextWithoutAttachment: !_isFirstUserMessageInSession,
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

import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/chat_models.dart';
import '../models/resource_models.dart';
import '../models/voice_models.dart';
import 'package:dio/dio.dart' show MultipartFile, FormData;

class ChatService {
  /// CREATE CHAT SESSION
  static Future<ChatSession> createChatSession({
    required String mode, // learning | evaluation
    String channel = "text",
    String? title,
    String? description,
    int? grade,
    String? subject,
  }) async {
    final res = await ApiClient.dio.post(
      "/api/v1/chat/sessions",
      data: {
        "mode": mode,
        "channel": channel,
        "title": title,
        "description": description,
        "grade": grade,
        "subject": subject,
      },
    );

    return ChatSession.fromJson(res.data);
  }

  /// LIST CHAT SESSIONS
  static Future<List<ChatSession>> listChatSessions() async {
    final res = await ApiClient.dio.get("/api/v1/chat/sessions");
    return (res.data as List)
        .map((e) => ChatSession.fromJson(e))
        .toList();
  }

  /// UPDATE CHAT TITLE
  static Future<ChatSession> updateChatSession(
      String sessionId, {
        String? title,
      }) async {
    final res = await ApiClient.dio.put(
      "/api/v1/chat/sessions/$sessionId",
      data: {
        "title": title,
      },
    );

    return ChatSession.fromJson(res.data);
  }

  /// DELETE CHAT
  static Future<void> deleteChatSession(String sessionId) async {
    await ApiClient.dio.delete("/api/v1/chat/sessions/$sessionId");
  }

  /// POST MESSAGE (wrapper)
  static Future<Map<String, dynamic>> postMessage({
    required String? sessionId,
    required Map<String, dynamic> payload,
  }) async {
    final sid = (sessionId == null || sessionId.startsWith("local-"))
        ? "undefined"
        : sessionId;

    final res = await ApiClient.dio.post(
      "/api/v1/messages/sessions/$sid",
      data: payload,
    );

    return res.data as Map<String, dynamic>;
  }

  /// UPLOAD RESOURCES (batch)
  static Future<List<ResourceUploadResponse>> uploadResources(
      List<MultipartFile> files) async {
    final formData = FormData.fromMap({
      'files': files,
    });

    final res = await ApiClient.dio.post(
      '/api/v1/resources/upload/batch',
      data: formData,
    );

    return (res.data as List)
        .map((e) => ResourceUploadResponse.fromJson(e))
        .toList();
  }

  /// LIST SESSION MESSAGES (wrapper)
  static Future<List<ChatMessage>> listSessionMessages(String sessionId) async {
    final res = await ApiClient.dio.get('/api/v1/messages/sessions/$sessionId');

    final messages = (res.data as List)
        .map((e) => ChatMessage.fromJson(e))
        .toList();

    messages.sort((a, b) => DateTime.parse(a.createdAt)
        .compareTo(DateTime.parse(b.createdAt)));

    return messages;
  }

  /// POST VOICE QA
  static Future<VoiceQAResponse> postVoiceQA({
    required MultipartFile audio,
    required String sessionId,
    List<String> resourceIds = const [],
    int topK = 3,
  }) async {
    final formData = FormData.fromMap({
      'audio': audio,
      'session_id': sessionId,
      if (resourceIds.isNotEmpty) 'resource_ids': resourceIds.join(','),
    });

    final res = await ApiClient.dio.post(
      '/api/v1/voice/qa',
      queryParameters: {'top_k': topK},
      data: formData,
    );

    return VoiceQAResponse.fromJson(res.data);
  }
}

import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/chat_models.dart';

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
      "/chat/sessions",
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
    final res = await ApiClient.dio.get("/chat/sessions");
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
      "/chat/sessions/$sessionId",
      data: {
        "title": title,
      },
    );

    return ChatSession.fromJson(res.data);
  }

  /// DELETE CHAT
  static Future<void> deleteChatSession(String sessionId) async {
    await ApiClient.dio.delete("/chat/sessions/$sessionId");
  }
}

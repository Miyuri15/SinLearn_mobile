import '../../core/network/api_client.dart';
import '../models/chat_models.dart';
import '../models/chat_session_details.dart';

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
    return (res.data as List).map((e) => ChatSession.fromJson(e)).toList();
  }

  /// GET CHAT SESSION DETAILS (including attached resources)
  static Future<ChatSessionDetails> getChatSessionDetails(
      String sessionId) async {
    final res = await ApiClient.dio.get("/api/v1/chat/sessions/$sessionId");
    if (res.data is Map) {
      return ChatSessionDetails.fromJson(
          Map<String, dynamic>.from(res.data as Map));
    }
    throw StateError(
        'Unexpected session details response: ${res.data.runtimeType}');
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
}

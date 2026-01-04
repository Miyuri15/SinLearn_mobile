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
    String? rubricId,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) "title": title,
      if (rubricId != null) "rubric_id": rubricId,
    };

    // ignore: avoid_print
    print(
        'updateChatSession PUT /api/v1/chat/sessions/$sessionId payload: $payload');

    final res = await ApiClient.dio.put(
      "/api/v1/chat/sessions/$sessionId",
      data: payload,
    );

    // ignore: avoid_print
    print('updateChatSession response: ${res.data}');

    return ChatSession.fromJson(res.data);
  }

  /// ATTACH RUBRIC TO CHAT SESSION
  /// Backend accepts: { "rubric_id": "<uuid>" }
  static Future<ChatSession> attachRubricToSession({
    required String chatSessionId,
    required String rubricId,
  }) async {
    final updated = await updateChatSession(chatSessionId, rubricId: rubricId);

    // Verify backend persisted the association.
    try {
      final details = await getChatSessionDetails(chatSessionId);
      // ignore: avoid_print
      print('attachRubricToSession verify GET rubric_id: ${details.rubricId}');
    } catch (e) {
      // ignore: avoid_print
      print('attachRubricToSession verify GET failed: $e');
    }

    return updated;
  }

  /// DELETE CHAT
  static Future<void> deleteChatSession(String sessionId) async {
    await ApiClient.dio.delete("/api/v1/chat/sessions/$sessionId");
  }
}

import '../../core/network/api_client.dart';
import '../models/chat_models.dart';
import '../models/xai_models.dart';

class MessageService {
  /// POST MESSAGE
  static Future<Map<String, dynamic>> postMessage({
    required String? sessionId,
    required Map<String, dynamic> payload,
  }) async {
    final sid = (sessionId == null || sessionId.startsWith("local-"))
        ? "undefined"
        : sessionId;

    print(payload);

    final res = await ApiClient.dio.post(
      "/api/v1/messages/sessions/$sid",
      data: payload,
    );

    return res.data;
  }

  /// LIST SESSION MESSAGES
  static Future<List<ChatMessage>> listSessionMessages(String sessionId) async {
    final res = await ApiClient.dio.get("/messages/sessions/$sessionId");

    final messages =
        (res.data as List).map((e) => ChatMessage.fromJson(e)).toList();

    messages.sort((a, b) =>
        DateTime.parse(a.createdAt).compareTo(DateTime.parse(b.createdAt)));

    return messages;
  }

  /// GENERATE ASSISTANT RESPONSE
  static Future<Map<String, dynamic>> generateMessageResponse(
      String messageId) async {
    final res = await ApiClient.dio.post(
      '/api/v1/messages/$messageId/generate',
    );

    final message = Map<String, dynamic>.from(res.data as Map);

    return {
      'role': message['role'],
      'content': message['content'],
      'grade_level': message['grade_level'],
      'safety_summary': message['safety_summary'],
      'message': message,
    };
  }

  // GET MESSAGE XAI RESPONSE
  static Future<XaiResponse> getMessageXAIResponse(String messageId) async {
    final res = await ApiClient.dio.get(
      '/api/v1/messages/$messageId/xai',
    );

    final xaiData = Map<String, dynamic>.from(res.data as Map);
    return XaiResponse.fromJson(xaiData);
  }
}

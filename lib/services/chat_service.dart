import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../models/chat_models.dart';
import '../models/resource_models.dart';
import '../models/voice_models.dart';
import 'package:dio/dio.dart' show MultipartFile, FormData;
import '../models/chat_session_details.dart';
import 'resource_service.dart';

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
      final details = ChatSessionDetails.fromJson(
          Map<String, dynamic>.from(res.data as Map));

      // If backend does not include filenames in `resources`, hydrate them by
      // fetching resource metadata. This makes attachments persist across
      // logout/login and allows the UI to show file names.
      final needsHydration = details.resources
          .where((r) => r.resourceId.isNotEmpty && r.filename.isEmpty)
          .toList();
      if (needsHydration.isEmpty) return details;

      // Preferred: hydrate via the session resources endpoint (single request).
      Map<String, Map<String, dynamic>>? sessionResourceById;
      try {
        final sessionResources =
            await ResourceService.fetchChatSessionResources(sessionId);
        sessionResourceById = <String, Map<String, dynamic>>{};
        for (final item in sessionResources) {
          final id = (item['id'] ?? item['resource_id'])?.toString();
          if (id != null && id.isNotEmpty) {
            sessionResourceById[id] = item;
          }
        }
      } catch (_) {
        sessionResourceById = null;
      }

      final updated = <SessionResource>[];
      for (final r in details.resources) {
        if (r.resourceId.isEmpty || r.filename.isNotEmpty) {
          updated.add(r);
          continue;
        }

        try {
          Map<String, dynamic>? meta = sessionResourceById?[r.resourceId];

          // Fallback: older per-resource metadata attempt.
          meta ??= await ResourceService.fetchResourceMetadata(r.resourceId);
          if (meta == null) {
            updated.add(r);
            continue;
          }

          final filename = (meta['filename'] ??
                  meta['file_name'] ??
                  meta['original_filename'] ??
                  meta['name'])
              ?.toString();
          final mime = (meta['mime_type'] ??
                  meta['content_type'] ??
                  meta['mimeType'] ??
                  meta['mimetype'])
              ?.toString();
          final sizeRaw = meta['size_bytes'] ??
              meta['size'] ??
              meta['bytes'] ??
              meta['file_size'];
          int parseSize(dynamic value) {
            if (value is int) return value;
            if (value is double) return value.toInt();
            if (value is String) return int.tryParse(value) ?? 0;
            return 0;
          }

          updated.add(
            r.copyWith(
              filename: (filename != null && filename.isNotEmpty)
                  ? filename
                  : r.filename,
              mimeType: (mime != null && mime.isNotEmpty) ? mime : r.mimeType,
              sizeBytes: parseSize(sizeRaw),
            ),
          );
        } catch (_) {
          // If metadata endpoint isn't available, keep the resource as-is.
          updated.add(r);
        }
      }

      return ChatSessionDetails(
        id: details.id,
        resources: updated,
        rubricId: details.rubricId,
      );
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

  static Future<List<ChatMessage>> listChatMessages(String sessionId) async {
    final res = await ApiClient.dio.get("/api/v1/messages/sessions/$sessionId");
    debugPrint('listChatMessages response: ${res.data}');
    return (res.data as List).map((e) => ChatMessage.fromJson(e)).toList();
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
    String? sessionId,
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

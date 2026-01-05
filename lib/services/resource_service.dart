import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/resource_models.dart';

class ResourceService {
  /// Fetch resource metadata list for a chat session.
  ///
  /// Backend endpoint:
  /// GET /api/v1/chat/sessions/{chat_session_id}/resources
  /// Response is a list of resource objects including id, original_filename,
  /// mime_type, size_bytes, etc.
  static Future<List<Map<String, dynamic>>> fetchChatSessionResources(
    String chatSessionId,
  ) async {
    if (chatSessionId.isEmpty) return const <Map<String, dynamic>>[];

    final pathsToTry = <String>[
      '/api/v1/chat/sessions/$chatSessionId/resources',
      '/chat/sessions/$chatSessionId/resources',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        final res = await ApiClient.dio.get(path);
        if (res.statusCode != 200) continue;

        final data = res.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }

        // Support envelope.
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final inner = map['data'] ?? map['resources'] ?? map['result'];
          if (inner is List) {
            return inner
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        // ignore: avoid_print
        print(
            'fetchChatSessionResources error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    // ignore: avoid_print
    print(
        'fetchChatSessionResources endpoint not found: ${last404?.message}');
    return const <Map<String, dynamic>>[];
  }

  /// Fetch resource metadata (filename, size, mime) by resource id.
  ///
  /// Some session-detail responses only include `resource_id` + `label`,
  /// so the UI must hydrate the display name via this endpoint.
  static Future<Map<String, dynamic>?> fetchResourceMetadata(
    String resourceId,
  ) async {
    if (resourceId.isEmpty) return null;

    final pathsToTry = <String>[
      '/api/v1/resources/$resourceId',
      '/api/v1/resources/$resourceId/metadata',
      '/api/v1/resources/$resourceId/meta',
      '/resources/$resourceId',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        final res = await ApiClient.dio.get(path);
        if (res.statusCode != 200) continue;

        final data = res.data;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);

          // Support envelope formats.
          final dynamic inner = map['data'] ?? map['resource'] ?? map['result'];
          if (inner is Map) {
            return Map<String, dynamic>.from(inner);
          }
          return map;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        // ignore: avoid_print
        print(
            'fetchResourceMetadata error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    // ignore: avoid_print
    print('fetchResourceMetadata not found for $resourceId: ${last404?.message}');
    return null;
  }
  static Future<List<ResourceUploadResponse>> uploadResources(
      List<MultipartFile> files) async {
    final formData = FormData.fromMap({
      "files": files,
    });

    final res = await ApiClient.dio.post(
      "/resources/upload/batch",
      data: formData,
    );

    return (res.data as List)
        .map((e) => ResourceUploadResponse.fromJson(e))
        .toList();
  }

  static Future<ResourceUploadResponse> uploadQuestionPaper({
    required MultipartFile file,
    required String chatSessionId,
  }) async {
    final formData = FormData.fromMap({
      // Backend expects a list field named "files"
      "files": [file],
    });

    final res = await ApiClient.dio.post(
      "/api/v1/resources/upload",
      queryParameters: {
        "resource_type": "question_paper",
        "chat_session_id": chatSessionId,
      },
      options: Options(
        // Backend performs extraction/embedding before responding; allow longer.
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: formData,
    );

    final data = res.data;
    // Helpful during integration/debugging (especially on web)
    // ignore: avoid_print
    print('uploadQuestionPaper response: $data');

    Map<String, dynamic>? candidate;

    if (data is List && data.isNotEmpty && data.first is Map) {
      candidate = Map<String, dynamic>.from(data.first as Map);
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // Support common envelope patterns
      final dynamic list1 = map['data'] ??
          map['resources'] ??
          map['uploaded_resources'] ??
          map['uploaded'] ??
          map['uploads'];
      if (list1 is List && list1.isNotEmpty && list1.first is Map) {
        candidate = Map<String, dynamic>.from(list1.first as Map);
      } else {
        candidate = map;
      }
    }

    if (candidate == null) {
      throw StateError('Unexpected upload response shape: ${data.runtimeType}');
    }
    return ResourceUploadResponse.fromJson(candidate);
  }

  static Future<List<ResourceUploadResponse>> uploadSyllabus({
    required List<MultipartFile> files,
    required String chatSessionId,
  }) async {
    final formData = FormData.fromMap({
      // Backend expects a list field named "files"
      "files": files,
    });

    final res = await ApiClient.dio.post(
      "/api/v1/resources/upload",
      queryParameters: {
        "resource_type": "syllabus",
        "chat_session_id": chatSessionId,
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: formData,
    );

    final data = res.data;
    // ignore: avoid_print
    print('uploadSyllabus response: $data');

    List<dynamic>? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final dynamic maybe = map['uploads'] ??
          map['data'] ??
          map['resources'] ??
          map['uploaded_resources'] ??
          map['uploaded'];
      if (maybe is List) {
        list = maybe;
      }
    }

    if (list == null) {
      throw StateError('Unexpected upload response shape: ${data.runtimeType}');
    }

    return list
        .whereType<Map>()
        .map((e) =>
            ResourceUploadResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<ResourceUploadResponse>> uploadAnswerSheets({
    required List<MultipartFile> files,
    required String chatSessionId,
  }) async {
    final formData = FormData.fromMap({
      // Backend expects a list field named "files"
      'files': files,
    });

    final res = await ApiClient.dio.post(
      '/api/v1/resources/upload',
      queryParameters: {
        'resource_type': 'answer_sheet',
        'chat_session_id': chatSessionId,
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: formData,
    );

    final data = res.data;
    // ignore: avoid_print
    print('uploadAnswerSheets response: $data');

    List<dynamic>? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final dynamic maybe = map['uploads'] ??
          map['data'] ??
          map['resources'] ??
          map['uploaded_resources'] ??
          map['uploaded'];
      if (maybe is List) {
        list = maybe;
      }
    }

    if (list == null) {
      throw StateError('Unexpected upload response shape: ${data.runtimeType}');
    }

    return list
        .whereType<Map>()
        .map((e) =>
            ResourceUploadResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

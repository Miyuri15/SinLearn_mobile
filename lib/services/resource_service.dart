import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/resource_models.dart';

class ResourceService {
  static const int _maxPreviewCacheItems = 30;
  static final LinkedHashMap<String, Uint8List> _previewCache =
      LinkedHashMap<String, Uint8List>();

  /// Fetch resource metadata list for a chat session.
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
        print(
            'fetchChatSessionResources error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    print('fetchChatSessionResources endpoint not found: ${last404?.message}');
    return const <Map<String, dynamic>>[];
  }

  /// Fetch resource metadata by id.
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
          final inner = map['data'] ?? map['resource'] ?? map['result'];

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
        print(
            'fetchResourceMetadata error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    print(
        'fetchResourceMetadata not found for $resourceId: ${last404?.message}');
    return null;
  }

  /// Generic batch upload
  static Future<List<ResourceUploadResponse>> uploadResources(
      List<MultipartFile> files) async {
    final formData = FormData.fromMap({
      "files": files,
    });

    final res = await ApiClient.dio.post(
      "/api/v1/resources/upload/batch",
      data: formData,
    );

    return (res.data as List)
        .map((e) => ResourceUploadResponse.fromJson(e))
        .toList();
  }

  /// Upload-only batch endpoint
  static Future<List<ResourceUploadResponse>> uploadResourcesUploadOnly(
      List<MultipartFile> files) async {
    final formData = FormData.fromMap({
      'files': files,
    });

    final res = await ApiClient.dio.post(
      '/api/v1/resources/upload-only/batch',
      data: formData,
    );

    return (res.data as List)
        .map((e) => ResourceUploadResponse.fromJson(e))
        .toList();
  }

  /// View resource inline
  static Future<Uint8List> viewResource(String resourceId) async {
    final res = await ApiClient.dio.get<List<int>>(
      "/api/v1/resources/$resourceId/view",
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(List<int>.from(res.data ?? []));
  }

  /// View resource with in-memory cache for faster repeated previews.
  static Future<Uint8List> viewResourceCached(
    String resourceId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _previewCache.remove(resourceId);
      if (cached != null) {
        // Reinsert to keep recent entries at the end (simple LRU behavior)
        _previewCache[resourceId] = cached;
        return cached;
      }
    }

    final bytes = await viewResource(resourceId);
    _previewCache[resourceId] = bytes;

    while (_previewCache.length > _maxPreviewCacheItems) {
      _previewCache.remove(_previewCache.keys.first);
    }

    return bytes;
  }

  /// Clear cached preview bytes for one resource, or all if id is omitted.
  static void clearPreviewCache([String? resourceId]) {
    if (resourceId == null || resourceId.isEmpty) {
      _previewCache.clear();
      return;
    }
    _previewCache.remove(resourceId);
  }

  /// Download resource
  static Future<Uint8List> downloadResource(String resourceId) async {
    final res = await ApiClient.dio.get<List<int>>(
      "/api/v1/resources/$resourceId/download",
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(List<int>.from(res.data ?? []));
  }

  /// Process message attachments
  static Future<void> processMessageAttachments(String messageId) async {
    await ApiClient.dio.post('/api/v1/messages/$messageId/attachments/process');
  }

  /// Batch process resources
  static Future<List<Map<String, dynamic>>> processResourcesBatch(
      List<String> resourceIds) async {
    final res = await ApiClient.dio.post(
      '/api/v1/resources/process/batch',
      data: {'resource_ids': resourceIds},
    );

    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Upload Question Paper
  static Future<ResourceUploadResponse> uploadQuestionPaper({
    required MultipartFile file,
    required String chatSessionId,
  }) async {
    final formData = FormData.fromMap({
      "files": [file],
    });

    final res = await ApiClient.dio.post(
      "/api/v1/resources/upload",
      queryParameters: {
        "resource_type": "question_paper",
        "chat_session_id": chatSessionId,
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: formData,
    );

    final data = res.data;

    Map<String, dynamic>? candidate;

    if (data is List && data.isNotEmpty && data.first is Map) {
      candidate = Map<String, dynamic>.from(data.first);
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final list1 = map['data'] ??
          map['resources'] ??
          map['uploaded_resources'] ??
          map['uploaded'] ??
          map['uploads'];

      if (list1 is List && list1.isNotEmpty && list1.first is Map) {
        candidate = Map<String, dynamic>.from(list1.first);
      } else {
        candidate = map;
      }
    }

    if (candidate == null) {
      throw StateError('Unexpected upload response shape');
    }

    return ResourceUploadResponse.fromJson(candidate);
  }

  /// Upload Syllabus
  static Future<List<ResourceUploadResponse>> uploadSyllabus({
    required List<MultipartFile> files,
    required String chatSessionId,
  }) async {
    return _uploadTypedResources(
      files: files,
      chatSessionId: chatSessionId,
      resourceType: "syllabus",
    );
  }

  /// Upload Answer Sheets
  static Future<List<ResourceUploadResponse>> uploadAnswerSheets({
    required List<MultipartFile> files,
    required String chatSessionId,
  }) async {
    return _uploadTypedResources(
      files: files,
      chatSessionId: chatSessionId,
      resourceType: "answer_sheet",
    );
  }

  /// Internal reusable uploader (prevents duplication)
  static Future<List<ResourceUploadResponse>> _uploadTypedResources({
    required List<MultipartFile> files,
    required String chatSessionId,
    required String resourceType,
  }) async {
    final formData = FormData.fromMap({"files": files});

    final res = await ApiClient.dio.post(
      "/api/v1/resources/upload",
      queryParameters: {
        "resource_type": resourceType,
        "chat_session_id": chatSessionId,
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 3),
        sendTimeout: const Duration(minutes: 2),
      ),
      data: formData,
    );

    final data = res.data;

    List<dynamic>? list;

    if (data is List) {
      list = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      list = map['uploads'] ??
          map['data'] ??
          map['resources'] ??
          map['uploaded_resources'] ??
          map['uploaded'];
    }

    if (list == null) {
      throw StateError('Unexpected upload response shape');
    }

    return list
        .whereType<Map>()
        .map((e) =>
            ResourceUploadResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

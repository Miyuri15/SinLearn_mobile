import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/resource_models.dart';

class ResourceService {
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
        receiveTimeout: Duration(minutes: 3),
        sendTimeout: Duration(minutes: 2),
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
        receiveTimeout: Duration(minutes: 3),
        sendTimeout: Duration(minutes: 2),
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
        receiveTimeout: Duration(minutes: 3),
        sendTimeout: Duration(minutes: 2),
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

import 'dart:typed_data';

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
      "/api/v1/resources/upload/batch",
      data: formData,
    );

    return (res.data as List)
        .map((e) => ResourceUploadResponse.fromJson(e))
        .toList();
  }

  /// Fetch resource as bytes for inline display (images, audio, pdf)
  static Future<Uint8List> viewResource(String resourceId) async {
    final res = await ApiClient.dio.get<List<int>>(
      "/api/v1/resources/$resourceId/view",
      options: Options(responseType: ResponseType.bytes),
    );

    final data = res.data;
    if (data is List<int>) return Uint8List.fromList(data);
    // Fallback: try to convert
    return Uint8List.fromList(List<int>.from(res.data as List));
  }

  /// Download resource as bytes (caller can save to file if desired)
  static Future<Uint8List> downloadResource(String resourceId) async {
    final res = await ApiClient.dio.get<List<int>>(
      "/api/v1/resources/$resourceId/download",
      options: Options(responseType: ResponseType.bytes),
    );

    final data = res.data;
    if (data is List<int>) return Uint8List.fromList(data);
    return Uint8List.fromList(List<int>.from(res.data as List));
  }

  /// Trigger processing of a message's attachments on the backend
  static Future<void> processMessageAttachments(String messageId) async {
    await ApiClient.dio.post('/api/v1/messages/$messageId/attachments/process');
  }

  /// Request batch processing for resources and return the status list
  static Future<List<Map<String, dynamic>>> processResourcesBatch(
      List<String> resourceIds) async {
    final res = await ApiClient.dio.post(
      '/api/v1/resources/process/batch',
      data: {
        'resource_ids': resourceIds,
      },
    );

    final list = (res.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return list;
  }
}

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/paper_config.dart';

class PaperConfigService {
  Future<List<PaperConfig>> fetchConfigs(String sessionId) async {
    final pathsToTry = <String>[
      '/api/v1/evaluation/sessions/$sessionId/paper-config',
      '/evaluation/sessions/$sessionId/paper-config',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        final res = await ApiClient.dio.get(path);
        if (res.statusCode != 200) {
          continue;
        }

        final data = res.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => PaperConfig.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        return const <PaperConfig>[];
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        rethrow;
      }
    }

    if (last404 != null) {
      return const <PaperConfig>[];
    }
    return const <PaperConfig>[];
  }

  Future<List<Map<String, dynamic>>> fetchQuestionsRaw(String sessionId) async {
    final pathsToTry = <String>[
      '/api/v1/evaluation/sessions/$sessionId/questions',
      '/evaluation/sessions/$sessionId/questions',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        final res = await ApiClient.dio.get(path);
        if (res.statusCode != 200) {
          continue;
        }

        final data = res.data;
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        rethrow;
      }
    }

    if (last404 != null) {
      return const <Map<String, dynamic>>[];
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> confirmConfigs(
      String sessionId, List<PaperConfig> configs) async {
    final payload = <String, dynamic>{
      'paper_configs': configs.map((e) => e.toJson()).toList(),
    };

    final pathsToTry = <String>[
      '/api/v1/evaluation/sessions/$sessionId/paper-config/confirm',
      '/evaluation/sessions/$sessionId/paper-config/confirm',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        final res = await ApiClient.dio.post(path, data: payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          return;
        }
        throw StateError(
          'Confirm paper-config failed (${res.statusCode}): ${res.data}',
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        throw StateError(
          'Confirm paper-config failed (${e.response?.statusCode}): ${e.response?.data}',
        );
      }
    }

    throw StateError(
      'paper-config confirm endpoint not found. Last error: ${last404?.message}',
    );
  }
}

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class RubricService {
  /// CREATE RUBRIC
  /// Backend: POST /api/v1/rubrics/?chat_session_id={uuid}
  static Future<String> createRubric({
    required String name,
    String? chatSessionId,
    int? semantic,
    int? coverage,
    int? relevance,
    String? source,
    String? description,
    String rubricType = 'system',
  }) async {
    String? extractId(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;

      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final dynamic idRaw = map['id'] ?? map['rubric_id'] ?? map['rubricId'];
        final id = idRaw?.toString();
        if (id != null && id.isNotEmpty) return id;

        // Common envelope shapes
        final dynamic nested = map['rubric'] ?? map['data'] ?? map['result'];
        final nestedId = extractId(nested);
        if (nestedId != null && nestedId.isNotEmpty) return nestedId;
      }

      if (value is List && value.isNotEmpty) {
        return extractId(value.first);
      }

      return null;
    }

    double normalize(int value, int total) {
      if (total <= 0) return 0.0;
      return value / total;
    }

    final weights = <String, int>{
      if (semantic != null) 'semantic': semantic,
      if (coverage != null) 'coverage': coverage,
      if (relevance != null) 'relevance': relevance,
    };

    if (weights.isEmpty) {
      throw StateError('Rubric create failed: no criteria weights provided.');
    }

    final total = weights.values.fold<int>(0, (sum, v) => sum + v);
    final criteria = weights.entries
        .map(
          (e) => <String, dynamic>{
            'criterion': e.key,
            'weight_percentage': normalize(e.value, total),
          },
        )
        .toList();

    final payload = <String, dynamic>{
      'name': name,
      if (description != null) 'description': description,
      'rubric_type': rubricType,
      'criteria': criteria,
      if (source != null) 'source': source,
    };

    final pathsToTry = <String>[
      '/api/v1/rubrics/',
      '/rubrics/',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        final res = await ApiClient.dio.post(
          path,
          data: payload,
          queryParameters: {
            if (chatSessionId != null && chatSessionId.trim().isNotEmpty)
              'chat_session_id': chatSessionId.trim(),
          },
        );

        final data = res.data;
        // ignore: avoid_print
        print('createRubric payload: $payload');
        // ignore: avoid_print
        print('createRubric response: $data');

        final id = extractId(data);
        if (id != null && id.isNotEmpty) return id;

        throw StateError(
            'Unexpected rubric create response: ${data.runtimeType}');
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        // ignore: avoid_print
        print('createRubric failed payload: $payload');
        // ignore: avoid_print
        print('createRubric failed response: ${e.response?.data}');
        if (e.response?.statusCode == 422) {
          throw StateError(
              'Rubric create failed (422). Server said: ${e.response?.data}');
        }
        rethrow;
      }
    }

    throw StateError(
      'rubrics endpoint not found. Last error: ${last404?.message}',
    );
  }
}

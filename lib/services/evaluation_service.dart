import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/network/api_client.dart';

class EvaluationService {
  /// Process uploaded documents for evaluation.
  ///
  /// Backend (Postman): POST {{baseurl}}/evaluation/process-documents/stream
  /// Body:
  /// {
  ///   "chat_session_id": "<uuid>",
  ///   "answer_resource_ids": ["<resource_uuid>"]
  /// }
  static Future<void> processDocumentsStream({
    required String chatSessionId,
    required List<String> answerResourceIds,
  }) async {
    if (answerResourceIds.isEmpty) {
      throw StateError('No answer_resource_ids provided.');
    }

    final payload = <String, dynamic>{
      'chat_session_id': chatSessionId,
      'answer_resource_ids': answerResourceIds,
    };

    // Some deployments mount APIs with /api/v1 and some without.
    final pathsToTry = <String>[
      '/api/v1/evaluation/process-documents/stream',
      '/evaluation/process-documents/stream',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('processDocumentsStream POST $path payload: $payload');

        final options = Options(
          // Web doesn't support ResponseType.stream the same way as IO.
          responseType: kIsWeb ? ResponseType.plain : ResponseType.stream,
          receiveTimeout: const Duration(minutes: 6),
          sendTimeout: const Duration(minutes: 2),
        );

        final res =
            await ApiClient.dio.post(path, data: payload, options: options);

        // ignore: avoid_print
        print('processDocumentsStream response status: ${res.statusCode}');

        // On IO platforms, consume the stream so the Future completes when
        // processing completes.
        if (!kIsWeb && res.data is ResponseBody) {
          final body = res.data as ResponseBody;
          await body.stream.forEach((bytes) {
            // ignore: avoid_print
            print('processDocuments stream: ${utf8.decode(bytes)}');
          });
        } else {
          // ignore: avoid_print
          print('processDocumentsStream response body: ${res.data}');
        }

        return;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }

        // ignore: avoid_print
        print(
            'processDocumentsStream error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    throw StateError(
      'process-documents endpoint not found. Last error: ${last404?.message}',
    );
  }
}

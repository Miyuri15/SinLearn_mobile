import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/network/api_client.dart';

class EvaluationService {
  static String? _normalizeStreamLine(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Server-Sent Events style lines.
    if (trimmed.startsWith('event:')) return null;
    if (trimmed.startsWith(':')) return null; // heartbeat/comment
    if (trimmed.startsWith('data:')) {
      final v = trimmed.substring('data:'.length).trim();
      return v.isEmpty ? null : v;
    }

    return trimmed;
  }

  /// Fetch evaluation result for a specific answer document.
  ///
  /// Backend (Postman): GET {{baseurl}}/evaluation/answers/{answer_document_id}/result
  static Future<Map<String, dynamic>?> fetchAnswerResult({
    required String answerDocumentId,
  }) async {
    if (answerDocumentId.trim().isEmpty) {
      throw StateError('No answer document id provided.');
    }

    final pathsToTry = <String>[
      '/api/v1/evaluation/answers/$answerDocumentId/result',
      '/evaluation/answers/$answerDocumentId/result',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('fetchAnswerResult GET $path');

        final res = await ApiClient.dio.get(path);

        // ignore: avoid_print
        print('fetchAnswerResult response status: ${res.statusCode}');

        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return null;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }

        // ignore: avoid_print
        print(
            'fetchAnswerResult error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    throw StateError(
      'evaluation/answers/{id}/result endpoint not found. Last error: ${last404?.message}',
    );
  }

  /// Start evaluation.
  ///
  /// Backend (Postman): POST {{baseurl}}/evaluation/start
  /// Body:
  /// {
  ///   "chat_session_id": "<uuid>",
  ///   "answer_resource_ids": ["<resource_uuid>"]
  /// }
  static Future<Map<String, dynamic>?> startEvaluation({
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

    final pathsToTry = <String>[
      '/api/v1/evaluation/start',
      '/evaluation/start',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('startEvaluation POST $path payload: $payload');

        final res = await ApiClient.dio.post(path, data: payload);

        // ignore: avoid_print
        print('startEvaluation response status: ${res.statusCode}');

        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return null;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }

        // ignore: avoid_print
        print(
            'startEvaluation error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    throw StateError(
      'evaluation/start endpoint not found. Last error: ${last404?.message}',
    );
  }

  /// Stream evaluation progress.
  ///
  /// Backend (Postman): POST {{baseurl}}/evaluation/start/stream
  /// Body:
  /// {
  ///   "chat_session_id": "<uuid>",
  ///   "answer_resource_ids": ["<resource_uuid>"]
  /// }
  ///
  /// Notes:
  /// - On IO platforms, consumes a byte stream.
  /// - On web, falls back to a plain response body.
  static Future<void> startEvaluationStream({
    required String chatSessionId,
    required List<String> answerResourceIds,
    void Function(String line)? onLine,
  }) async {
    if (answerResourceIds.isEmpty) {
      throw StateError('No answer_resource_ids provided.');
    }

    final payload = <String, dynamic>{
      'chat_session_id': chatSessionId,
      'answer_resource_ids': answerResourceIds,
    };

    final pathsToTry = <String>[
      '/api/v1/evaluation/start/stream',
      '/evaluation/start/stream',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('startEvaluationStream POST $path payload: $payload');

        final options = Options(
          responseType: kIsWeb ? ResponseType.plain : ResponseType.stream,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 2),
        );

        final res =
            await ApiClient.dio.post(path, data: payload, options: options);

        // ignore: avoid_print
        print('startEvaluationStream response status: ${res.statusCode}');

        if (!kIsWeb && res.data is ResponseBody) {
          final body = res.data as ResponseBody;
          var buffer = '';
          await body.stream.forEach((bytes) {
            final chunk = utf8.decode(bytes, allowMalformed: true);
            buffer += chunk;

            // Split on newlines (supports \n or \r\n)
            final parts = buffer.split(RegExp(r'\r?\n'));
            buffer = parts.isNotEmpty ? parts.last : '';
            for (final line in parts.take(parts.length - 1)) {
              final normalized = _normalizeStreamLine(line);
              if (normalized == null) continue;
              onLine?.call(normalized);

              // ignore: avoid_print
              print('startEvaluation stream: $normalized');
            }
          });

          final normalizedTrailing = _normalizeStreamLine(buffer);
          if (normalizedTrailing != null) {
            onLine?.call(normalizedTrailing);
            // ignore: avoid_print
            print('startEvaluation stream: $normalizedTrailing');
          }
        } else {
          final text = res.data?.toString() ?? '';
          if (text.isNotEmpty) {
            final normalizedLines = <String>[];
            for (final line in text.split(RegExp(r'\r?\n'))) {
              final normalized = _normalizeStreamLine(line);
              if (normalized == null) continue;
              normalizedLines.add(normalized);
            }

            // Web can't consume an HTTP byte stream via Dio, so we replay
            // server-emitted lines with a tiny delay to visualize progress.
            for (final line in normalizedLines) {
              onLine?.call(line);
              if (normalizedLines.length > 1) {
                await Future<void>.delayed(const Duration(milliseconds: 120));
              }
            }
          }
        }

        return;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }

        // ignore: avoid_print
        print(
            'startEvaluationStream error (${e.response?.statusCode}): ${e.response?.data}');
        rethrow;
      }
    }

    throw StateError(
      'evaluation/start/stream endpoint not found. Last error: ${last404?.message}',
    );
  }

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

  /// Fetch all results for an evaluation session.
  ///
  /// Backend: GET {{baseurl}}/evaluation/sessions/{evaluation_session_id}/results
  static Future<List<Map<String, dynamic>>> getEvaluationSessionResults(
      String evaluationSessionId) async {
    final pathsToTry = <String>[
      '/api/v1/evaluation/sessions/$evaluationSessionId/results',
      '/evaluation/sessions/$evaluationSessionId/results',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('getEvaluationSessionResults GET $path');
        final res = await ApiClient.dio.get(path);
        // ignore: avoid_print
        print(
            'getEvaluationSessionResults response status: ${res.statusCode}');
        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is List) {
          return (data as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        rethrow;
      }
    }
    throw StateError(
      'evaluation/sessions/{id}/results endpoint not found. Last error: ${last404?.message}',
    );
  }

  /// Fetch answer documents for an evaluation session.
  ///
  /// Backend: GET {{baseurl}}/evaluation/sessions/{evaluation_session_id}/answers
  static Future<List<Map<String, dynamic>>> getAnswerDocuments(
      String evaluationSessionId) async {
    final pathsToTry = <String>[
      '/api/v1/evaluation/sessions/$evaluationSessionId/answers',
      '/evaluation/sessions/$evaluationSessionId/answers',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('getAnswerDocuments GET $path');
        final res = await ApiClient.dio.get(path);
        // ignore: avoid_print
        print('getAnswerDocuments response status: ${res.statusCode}');
        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is List) {
          return (data as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        rethrow;
      }
    }
    throw StateError(
      'evaluation/sessions/{id}/answers endpoint not found. Last error: ${last404?.message}',
    );
  }

  /// Fetch feedback for a specific answer document.
  ///
  /// Backend: GET {{baseurl}}/evaluation/answers/{answer_document_id}/feedback
  static Future<Map<String, dynamic>?> getEvaluationAnswerFeedback(
      String answerDocumentId) async {
    final pathsToTry = <String>[
      '/api/v1/evaluation/answers/$answerDocumentId/feedback',
      '/evaluation/answers/$answerDocumentId/feedback',
    ];

    DioException? last404;
    for (final path in pathsToTry) {
      try {
        // ignore: avoid_print
        print('getEvaluationAnswerFeedback GET $path');
        final res = await ApiClient.dio.get(path);
        // ignore: avoid_print
        print(
            'getEvaluationAnswerFeedback response status: ${res.statusCode}');
        dynamic data = res.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return null;
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          last404 = e;
          continue;
        }
        rethrow;
      }
    }
    throw StateError(
      'evaluation/answers/{id}/feedback endpoint not found. Last error: ${last404?.message}',
    );
  }
}

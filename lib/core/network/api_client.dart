import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sinlearn_mobile/core/auth/auth_refresh_lock.dart';
import 'token_storage.dart';

typedef RefreshCallback = Future<void> Function();

class ApiClient {
  static CancelToken cancelToken = CancelToken();

  static late RefreshCallback onRefresh;

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://6c55fa6a92a7.ngrok-free.app',
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach global cancel token
          options.cancelToken ??= cancelToken;

          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }

          final accessToken = await TokenStorage.getAccessToken();
          if (accessToken == null) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'User logged out',
              ),
            );
          }

          try {
            if (await TokenStorage.shouldRefresh()) {
              await AuthRefreshLock.run(() => onRefresh());
            }

            // Attach fresh token
            final token = await TokenStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            // Content-Type handling
            if (options.data is FormData) {
              options.headers.remove('Content-Type');
              options.contentType = 'multipart/form-data';
            } else {
              options.contentType = Headers.jsonContentType;
            }

            return handler.next(options);
          } on DioException catch (e, st) {
            debugPrint('ApiClient refresh failed: ${e.message}');
            debugPrint('Status: ${e.response?.statusCode}');
            debugPrint('Data: ${e.response?.data}');
            debugPrintStack(stackTrace: st);

            await TokenStorage.clear();
            return handler.reject(e);
          } catch (e, st) {
            debugPrint('ApiClient onRequest error: $e');
            debugPrintStack(stackTrace: st);

            await TokenStorage.clear();
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Session expired',
              ),
            );
          }
        },
        onError: (e, handler) async {
          if (e.requestOptions.extra['skipAuth'] == true) {
            return handler.next(e);
          }

          // Retry once on 401
          if (e.response?.statusCode == 401) {
            try {
              await AuthRefreshLock.run(() => onRefresh());

              final newToken = await TokenStorage.getAccessToken();
              if (newToken != null && newToken.isNotEmpty) {
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              }

              final response = await dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } on DioException catch (err, st) {
              debugPrint('401 retry refresh failed: ${err.message}');
              debugPrint('Status: ${err.response?.statusCode}');
              debugPrint('Data: ${err.response?.data}');
              debugPrintStack(stackTrace: st);

              await TokenStorage.clear();
            } catch (err, st) {
              debugPrint('401 retry refresh failed (unknown): $err');
              debugPrintStack(stackTrace: st);

              await TokenStorage.clear();
            }
          }

          return handler.next(e);
        },
      ),
    );

  static void reset() {
    cancelToken.cancel('User logged out');
    cancelToken = CancelToken();
  }
}

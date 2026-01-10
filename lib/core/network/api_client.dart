import 'package:dio/dio.dart';
import 'package:sinlearn_mobile/features/auth/services/auth_service.dart';
import 'token_storage.dart';

class ApiClient {
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
          if (await TokenStorage.shouldRefresh()) {
            try {
              await AuthService().refreshToken();
            } catch (_) {
              await TokenStorage.clear();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Session expired',
                ),
              );
            }
          }

          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.contentType = 'multipart/form-data';
          } else {
            options.contentType = Headers.jsonContentType;
          }

          return handler.next(options);
        },
        onError: (e, handler) async {
          // Fallback if backend still returns 401
          if (e.response?.statusCode == 401) {
            try {
              await AuthService().refreshToken();
              final newToken = await TokenStorage.getAccessToken();
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

              final response = await dio.fetch(e.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              await TokenStorage.clear();
            }
          }

          return handler.next(e);
        },
      ),
    );
}

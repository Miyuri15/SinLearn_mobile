import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://e223-2402-4000-2330-def-591e-d409-47c8-fe4a.ngrok-free.app', // Local backend (use 10.0.2.2 for Android emulator)
      connectTimeout: const Duration(minutes: 60),
      sendTimeout: const Duration(minutes: 60),
      receiveTimeout: const Duration(minutes: 60),
      // Don't force a global Content-Type.
      // Dio will set it appropriately (e.g. multipart/form-data for FormData).
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Ensure uploads work: avoid sending application/json for FormData.
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.contentType = 'multipart/form-data';
          } else {
            // Keep JSON as the default for regular API calls.
            options.contentType = Headers.jsonContentType;
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            // (Optional) refresh-token flow can be added here
          }
          return handler.next(e);
        },
      ),
    );
}

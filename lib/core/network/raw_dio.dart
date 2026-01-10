import 'package:dio/dio.dart';

class RawDio {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://6c55fa6a92a7.ngrok-free.app',
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
}

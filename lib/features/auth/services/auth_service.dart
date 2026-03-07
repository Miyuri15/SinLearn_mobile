import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sinlearn_mobile/core/network/raw_dio.dart';
import 'package:sinlearn_mobile/core/network/token_storage.dart';

class AuthService {
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await RawDio.dio.post(
      '/api/v1/auth/signup',
      data: {
        "full_name": fullName,
        "email": email,
        "password": password,
      },
    );

    final data = response.data;

    await TokenStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );

    return data;
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('BASE URL: ${RawDio.dio.options.baseUrl}');
    debugPrint('Calling: /api/v1/auth/signin');

    final response = await RawDio.dio.post(
      '/api/v1/auth/signin',
      data: {
        "email": email,
        "password": password,
      },
    );

    final data = response.data;

    await TokenStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );

    return data;
  }

Future<void> refreshToken() async {
  final refreshToken = await TokenStorage.getRefreshToken();
  if (refreshToken == null) {
    throw Exception('No refresh token available');
  }

  try {
    final response = await RawDio.dio.post(
      '/api/v1/auth/refresh',
      data: {'refresh_token': refreshToken},
    );

    final data = response.data as Map<String, dynamic>;

    if (data['access_token'] == null || data['refresh_token'] == null) {
      throw Exception('Invalid refresh response');
    }

    await TokenStorage.saveTokens(
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
    );
  } on DioException catch (e) {
    debugPrint('Refresh token failed');
    debugPrint('Status: ${e.response?.statusCode}');
    debugPrint('Data: ${e.response?.data}');
    throw Exception(e.response?.data['detail'] ?? 'Refresh token failed');
  }
}
}
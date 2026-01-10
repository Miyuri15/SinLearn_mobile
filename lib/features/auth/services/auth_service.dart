import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sinlearn_mobile/core/network/api_client.dart';
import 'package:sinlearn_mobile/core/network/token_storage.dart';

class AuthService {
  Future<Map<String, dynamic>> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
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

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Signup failed');
      }
      throw Exception('Network error');
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
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

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Login failed');
      }
      throw Exception('Network error');
    }
  }

  Future<void> refreshToken() async {
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await ApiClient.dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(
          extra: {'skipAuth': true},
        ),
      );

      final data = response.data;

      if (data['access_token'] == null || data['refresh_token'] == null) {
        throw Exception('Invalid refresh response');
      }

      await TokenStorage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
    } on DioException catch (e) {
      // 🔍 Useful debugging info
      debugPrint('Refresh token request failed');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      rethrow;
    }
  }
}

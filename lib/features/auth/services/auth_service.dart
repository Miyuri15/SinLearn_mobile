import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

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

      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Login failed');
      }
      throw Exception('Network error');
    }
  }
}

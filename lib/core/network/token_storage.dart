import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  static Future<String?> getRefreshToken() =>
      _storage.read(key: 'refresh_token');

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<bool> shouldRefresh({int bufferMinutes = 5}) async {
    final token = await getAccessToken();
    if (token == null) return true;

    final expiry = JwtDecoder.getExpirationDate(token);
    final now = DateTime.now();

    return expiry.isBefore(now.add(Duration(minutes: bufferMinutes)));
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;

    return !JwtDecoder.isExpired(token);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const keyAccessToken = 'auth.accessToken';
  static const keyRefreshToken = 'auth.refreshToken';
  static const keyAccessExpAt = 'auth.accessExpAt';

  static Future<void> saveTokens({
    required String accessToken,
    required String? refreshToken,
    required DateTime accessExpAt,
  }) async {
    await _storage.write(key: keyAccessToken, value: accessToken);
    if (refreshToken == null) {
      await _storage.delete(key: keyRefreshToken);
    } else {
      await _storage.write(key: keyRefreshToken, value: refreshToken);
    }
    await _storage.write(key: keyAccessExpAt, value: accessExpAt.toIso8601String());
  }

  static Future<String?> getAccessToken() => _storage.read(key: keyAccessToken);
  static Future<String?> getRefreshToken() => _storage.read(key: keyRefreshToken);
  static Future<DateTime?> getAccessExpAt() async {
    final v = await _storage.read(key: keyAccessExpAt);
    return v == null ? null : DateTime.tryParse(v);
  }

  static Future<void> clear() async {
    await _storage.delete(key: keyAccessToken);
    await _storage.delete(key: keyRefreshToken);
    await _storage.delete(key: keyAccessExpAt);
  }
}


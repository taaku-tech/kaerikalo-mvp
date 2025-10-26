import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_profile.dart';
import '../config/app_config.dart';
import 'auth_client.dart';

class AuthService implements AuthClient {
  AuthService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = baseUrl ?? AppConfig.apiBaseUrl;
  final http.Client _client;
  final String _base;

  Uri _u(String p) => Uri.parse('$_base$p');

  @override
  Future<({String accessToken, String? refreshToken, DateTime accessExpAt})> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _u('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw AuthError.fromResponse(res);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      accessToken: j['accessToken'] as String,
      refreshToken: j['refreshToken'] as String?,
      accessExpAt: DateTime.parse(j['accessExpAt'] as String),
    );
  }

  @override
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required double heightCm,
    required double weightKg,
  }) async {
    final res = await _client.post(
      _u('/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
        'heightCm': heightCm,
        'weightKg': weightKg,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw AuthError.fromResponse(res);
    }
  }

  @override
  Future<UserProfile> me(String accessToken) async {
    final res = await _client.get(
      _u('/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (res.statusCode != 200) {
      throw AuthError.fromResponse(res);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile.fromJson(j);
  }

  @override
  Future<UserProfile> updateMe({
    required String accessToken,
    required String nickname,
    required double heightCm,
    required double weightKg,
  }) async {
    final res = await _client.put(
      _u('/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'nickname': nickname,
        'heightCm': heightCm,
        'weightKg': weightKg,
      }),
    );
    if (res.statusCode != 200) {
      throw AuthError.fromResponse(res);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return UserProfile.fromJson(j);
  }
}

class AuthError implements Exception {
  final String message;
  final int status;
  const AuthError(this.message, this.status);

  factory AuthError.fromResponse(http.Response res) {
    String msg = 'Network error. Please retry.';
    try {
      final j = jsonDecode(res.body);
      msg = (j is Map && j['message'] is String) ? j['message'] as String : msg;
    } catch (_) {}
    return AuthError(msg, res.statusCode);
  }

  @override
  String toString() => 'AuthError($status): $message';
}

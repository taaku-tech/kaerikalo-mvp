import 'dart:async';
import 'dart:math';

import '../models/user_profile.dart';
import 'auth_client.dart';
import 'auth_service.dart' show AuthError; // reuse error class

class FakeAuthService implements AuthClient {
  static final Map<String, (_Account acc, String password)> _db = {}; // email -> (account,password)
  static final Map<String, String> _tokenToEmail = {}; // accessToken -> email

  @override
  Future<({String accessToken, String? refreshToken, DateTime accessExpAt})> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final entry = _db[email.toLowerCase()];
    if (entry == null || entry.$2 != password) {
      throw const AuthError('メールまたはパスワードが違います', 401);
    }
    final token = _genToken();
    _tokenToEmail[token] = email.toLowerCase();
    return (
      accessToken: token,
      refreshToken: null,
      accessExpAt: DateTime.now().add(const Duration(days: 1)),
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
    await Future.delayed(const Duration(milliseconds: 400));
    final key = email.toLowerCase();
    if (_db.containsKey(key)) {
      throw const AuthError('既に登録済みのメールアドレスです', 409);
    }
    final id = _genId();
    final acc = _Account(
      id: id,
      email: key,
      nickname: nickname,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    _db[key] = (acc, password);
  }

  @override
  Future<UserProfile> me(String accessToken) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final email = _tokenToEmail[accessToken];
    if (email == null) throw const AuthError('未認証です', 401);
    final entry = _db[email];
    if (entry == null) throw const AuthError('アカウントが見つかりません', 404);
    return entry.$1.toProfile();
  }

  @override
  Future<UserProfile> updateMe({
    required String accessToken,
    required String nickname,
    required double heightCm,
    required double weightKg,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final email = _tokenToEmail[accessToken];
    if (email == null) throw const AuthError('未認証です', 401);
    final entry = _db[email];
    if (entry == null) throw const AuthError('アカウントが見つかりません', 404);
    final acc = entry.$1.copyWith(nickname: nickname, heightCm: heightCm, weightKg: weightKg);
    _db[email] = (acc, entry.$2);
    return acc.toProfile();
  }

  static String _genId() => 'u_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  static String _genToken() => 'fake_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
}

class _Account {
  final String id;
  final String email;
  final String nickname;
  final double heightCm;
  final double weightKg;
  final String? avatarUrl;

  const _Account({
    required this.id,
    required this.email,
    required this.nickname,
    required this.heightCm,
    required this.weightKg,
    this.avatarUrl,
  });

  _Account copyWith({
    String? nickname,
    double? heightCm,
    double? weightKg,
  }) => _Account(
        id: id,
        email: email,
        nickname: nickname ?? this.nickname,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        avatarUrl: avatarUrl,
      );

  UserProfile toProfile() => UserProfile(
        id: id,
        email: email,
        nickname: nickname,
        heightCm: heightCm,
        weightKg: weightKg,
        avatarUrl: avatarUrl,
      );
}


import '../models/user_profile.dart';

abstract class AuthClient {
  Future<({String accessToken, String? refreshToken, DateTime accessExpAt})> login({
    required String email,
    required String password,
  });

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required double heightCm,
    required double weightKg,
  });

  Future<UserProfile> me(String accessToken);

  Future<UserProfile> updateMe({
    required String accessToken,
    required String nickname,
    required double heightCm,
    required double weightKg,
  });
}


import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/user_profile_repository.dart';
import '../services/auth_client.dart';
import '../services/secure_storage_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthClient _auth;
  bool _loading = false;
  bool _remember = false;
  String? _accessToken;
  DateTime? _accessExpAt;
  UserProfile? _profile;

  AuthProvider({required AuthClient auth}) : _auth = auth;

  bool get isLoading => _loading;
  bool get isAuthenticated => _accessToken != null;
  bool get rememberLogin => _remember;
  UserProfile? get profile => _profile;

  Future<void> loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    _remember = prefs.getBool('auth.rememberLogin') ?? false;
    _accessToken = await SecureStorageService.getAccessToken();
    _accessExpAt = await SecureStorageService.getAccessExpAt();
    if (_accessToken != null) {
      final p = UserProfileRepository.get();
      _profile = p;
    }
    notifyListeners();
  }

  Future<void> setRemember(bool v) async {
    _remember = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth.rememberLogin', v);
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    _accessExpAt = null;
    _profile = null;
    await SecureStorageService.clear();
    await UserProfileRepository.clear();
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final tokens = await _auth.login(email: email, password: password);
      _accessToken = tokens.accessToken;
      _accessExpAt = tokens.accessExpAt;
      final refresh = _remember ? tokens.refreshToken : null;
      await SecureStorageService.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: refresh,
        accessExpAt: tokens.accessExpAt,
      );
      final me = await _auth.me(tokens.accessToken);
      _profile = me;
      await UserProfileRepository.save(me);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required double heightCm,
    required double weightKg,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _auth.signup(
        email: email,
        password: password,
        nickname: nickname,
        heightCm: heightCm,
        weightKg: weightKg,
      );
      // auto login
      await login(email: email, password: password);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    final token = _accessToken;
    if (token == null) return;
    final me = await _auth.me(token);
    _profile = me;
    await UserProfileRepository.save(me);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String nickname,
    required double heightCm,
    required double weightKg,
  }) async {
    final token = _accessToken;
    if (token == null) return;
    _loading = true;
    notifyListeners();
    try {
      final updated = await _auth.updateMe(
        accessToken: token,
        nickname: nickname,
        heightCm: heightCm,
        weightKg: weightKg,
      );
      _profile = updated;
      await UserProfileRepository.save(updated);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

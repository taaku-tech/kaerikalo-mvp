import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _firebaseUser;
  UserProfile? _profile;
  bool _isLoading = false;

  User? get user => _firebaseUser;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _setLoading(true);
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      // User is logged in, load their profile from local storage (Hive).
      _profile = UserProfileRepository.get(firebaseUser.uid);
      // If profile doesn't exist locally (e.g., first login on a new device),
      // create a default one.
      if (_profile == null) {
        final nickname = firebaseUser.email?.split('@').first ?? 'User';
        _profile = UserProfile(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          nickname: nickname,
          heightCm: 170, // Default value
          weightKg: 60,  // Default value
        );
        await UserProfileRepository.save(firebaseUser.uid, _profile!);
      }
    } else {
      // User is logged out, clear profile data.
      if (_profile != null) await UserProfileRepository.delete(_profile!.id);
      _profile = null;
    }
    _setLoading(false);
  }

  Future<void> loadPersisted() async {
    // The authStateChanges stream handles the initial state,
    // but we can call this to ensure the profile is loaded on app start if needed.
    if (_auth.currentUser != null && _profile == null) {
      await _onAuthStateChanged(_auth.currentUser);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // After successful sign-up, create a default profile.
      if (credential.user != null) {
        final uid = credential.user!.uid;
        final nickname = email.split('@').first;
        _profile = UserProfile(
          id: uid,
          email: email,
          nickname: nickname,
          heightCm: 160, // Default value
          weightKg: 55,  // Default value
        );
        await UserProfileRepository.save(uid, _profile!);

        // Ensure UI updates immediately without relying solely on the stream
        await _onAuthStateChanged(credential.user);
      }
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    }
    // _onAuthStateChanged handles loading state and notifications.
  }

  Future<void> logIn(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Proactively reflect the new state on Web where the stream might lag
      await _onAuthStateChanged(_auth.currentUser);
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    }
    // _onAuthStateChanged handles loading state and notifications.
  }

  Future<void> resetPassword(String email) async {
    final addr = email.trim();
    if (addr.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email', message: 'Email is empty');
    }
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: addr);
    } on FirebaseAuthException {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  Future<void> logOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({required String nickname, required double heightCm, required double weightKg}) async {
    if (_profile == null || _firebaseUser == null) return;
    _setLoading(true);
    _profile = _profile!.copyWith(nickname: nickname, heightCm: heightCm, weightKg: weightKg);
    // Ensure we save the profile against the correct user ID.
    await UserProfileRepository.save(_firebaseUser!.uid, _profile!);
    _setLoading(false);
    notifyListeners(); // Notify UI about the profile update
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

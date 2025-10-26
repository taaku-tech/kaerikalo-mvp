class AppConfig {
  // Set via: --dart-define=API_BASE_URL=https://api.yourdomain.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator default; change as needed
  );

  static const bool useFakeAuth = bool.fromEnvironment(
    'USE_FAKE_AUTH',
    defaultValue: false,
  );
}

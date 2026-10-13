/// Build-time config via `--dart-define-from-file=.env.dev.json`.
abstract final class Env {
  static String get name =>
      const String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get apiBaseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  // socketBaseUrl là base url của socket
  static String get socketBaseUrl {
    final api = apiBaseUrl;
    return api.endsWith('/api') ? api.substring(0, api.length - 4) : api;
  }

  /// Gọi từ [bootstrap] — giữ hook nếu sau này load thêm config runtime.
  static void load() {}
}

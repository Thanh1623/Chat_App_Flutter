/// Build-time config via `--dart-define-from-file=.env.dev.json`.
abstract final class Env {
  static String get name =>
      const String.fromEnvironment('ENV', defaultValue: 'dev');

  static String get apiBaseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      );

  /// Gọi từ [bootstrap] — giữ hook nếu sau này load thêm config runtime.
  static void load() {}
}

import 'dart:convert';

import 'package:chat_app/app/theme/app_accent.dart';
import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessToken = 'access_token';
const _kUserJson = 'user_json';
const _kThemeAccent = 'theme_accent';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(const FlutterSecureStorage());
});

class SessionStorage {
  SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  String? _cachedToken;
  User? _cachedUser;

  String? get accessToken => _cachedToken;
  User? get user => _cachedUser;

  Future<void> load() async {
    _cachedToken = await _storage.read(key: _kAccessToken);
    final raw = await _storage.read(key: _kUserJson);
    if (raw == null) {
      _cachedUser = null;
      return;
    }
    _cachedUser = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save({required String accessToken, required User user}) async {
    _cachedToken = accessToken;
    _cachedUser = user;
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kUserJson, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    _cachedToken = null;
    _cachedUser = null;
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kUserJson);
  }

  Future<AppAccent> loadThemeAccent() async {
    final raw = await _storage.read(key: _kThemeAccent);
    return AppAccent.fromStorageKey(raw);
  }

  Future<void> saveThemeAccent(AppAccent accent) async {
    await _storage.write(key: _kThemeAccent, value: accent.storageKey);
  }
}

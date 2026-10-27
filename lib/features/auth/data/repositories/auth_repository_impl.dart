import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._session);

  final AuthRemoteDataSource _remote;
  final SessionStorage _session;

  @override
  User? get currentUser => _session.user;

  @override
  Future<User?> restoreSession() async {
    await _session.load();
    if (_session.accessToken == null || _session.refreshToken == null) {
      await _session.clear();
      return null;
    }
    try {
      final user = await _remote.fetchMe();
      await _session.save(
        accessToken: _session.accessToken!,
        refreshToken: _session.refreshToken!,
        user: user,
      );
      return user;
    } catch (e) {
      await _session.clear();
      return null;
    }
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email và mật khẩu không được trống');
    }
    try {
      final result = await _remote.login(email: email, password: password);
      if (result.refreshToken.isEmpty) {
        throw StateError('Login response missing refresh token');
      }
      await _session.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );
      return result.user;
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    final refresh = _session.refreshToken;
    if (refresh != null) {
      await _remote.logout(refresh);
    }
    await _session.clear();
  }

  @override
  Future<User> refreshMe() async {
    try {
      final user = await _remote.fetchMe();
      final access = _session.accessToken;
      final refresh = _session.refreshToken;
      if (access != null && refresh != null) {
        await _session.save(
          accessToken: access,
          refreshToken: refresh,
          user: user,
        );
      }
      return user;
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? email,
    String? password,
    String? currentPassword,
  }) async {
    try {
      final result = await _remote.updateProfile(
        name: name,
        email: email,
        password: password,
        currentPassword: currentPassword,
      );
      final tokens = result.tokens;
      if (tokens != null) {
        await _session.save(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          user: tokens.user,
        );
        return tokens.user;
      }
      return await _persistUser(result.user);
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<User> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final user = await _remote.uploadAvatar(bytes: bytes, filename: filename);
      return await _persistUser(user);
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<User> _persistUser(User user) async {
    final access = _session.accessToken;
    final refresh = _session.refreshToken;
    if (access == null || refresh == null) {
      return user;
    }
    await _session.save(accessToken: access, refreshToken: refresh, user: user);
    return user;
  }
}

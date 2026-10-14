import 'package:chat_app/core/error/exception_mapper.dart';
import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/models/login_response.dart';
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
    return _session.user;
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email và mật khẩu không được trống');
    }
    try {
      final result = await _remote.login(email: email, password: password);
      await _session.save(accessToken: result.accessToken, user: result.user);
      return result.user;
    } catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _remote.logout();
    await _session.clear();
  }

  @override
  Future<User> refreshMe() async {
    try {
      final user = await _remote.fetchMe();
      final token = _session.accessToken;
      if (token != null && token.isNotEmpty) {
        await _session.save(accessToken: token, user: user);
      }
      return user;
    } catch (e) {
      throw mapException(e);
    }
  }

  Future<User> _persistSessionResponse(
    Future<LoginResponse> Function() call,
  ) async {
    try {
      final result = await call();
      await _session.save(
        accessToken: result.accessToken,
        user: result.user,
      );
      return result.user;
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
  }) {
    return _persistSessionResponse(
      () => _remote.updateProfile(
        name: name,
        email: email,
        password: password,
        currentPassword: currentPassword,
      ),
    );
  }

  @override
  Future<User> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) {
    return _persistSessionResponse(
      () => _remote.uploadAvatar(bytes: bytes, filename: filename),
    );
  }
}

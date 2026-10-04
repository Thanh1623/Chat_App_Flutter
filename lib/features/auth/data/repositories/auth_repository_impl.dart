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
}

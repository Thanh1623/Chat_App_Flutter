import 'package:chat_app/core/storage/session_storage.dart';
import 'package:chat_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:chat_app/features/auth/data/models/login_response.dart';
import 'package:chat_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAuthRemote extends AuthRemoteDataSource {
  _StubAuthRemote() : super(Dio(BaseOptions(baseUrl: 'http://test')));

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    return LoginResponse(
      accessToken: 'jwt',
      user: User(id: '1', displayName: 'Test', email: email),
    );
  }
}

class _InMemorySecureStorage extends FlutterSecureStorage {
  _InMemorySecureStorage() : super();

  final _store = <String, String>{};

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

void main() {
  test('LoginResponse parses Nest-style JSON', () {
    final parsed = LoginResponse.fromJson({
      'accessToken': 'abc',
      'user': {
        'id': '1',
        'displayName': 'An',
        'email': 'a@b.c',
      },
    });
    expect(parsed.accessToken, 'abc');
    expect(parsed.user.email, 'a@b.c');
  });

  test('signIn rejects empty credentials', () async {
    final repo = AuthRepositoryImpl(
      _StubAuthRemote(),
      SessionStorage(_InMemorySecureStorage()),
    );
    expect(
      () => repo.signIn(email: '', password: 'x'),
      throwsArgumentError,
    );
  });
}

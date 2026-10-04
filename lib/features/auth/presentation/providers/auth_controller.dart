import 'package:chat_app/core/error/failure.dart';
import 'package:chat_app/features/auth/data/providers/auth_repository_provider.dart';
import 'package:chat_app/features/auth/domain/entities/user.dart';
import 'package:chat_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  final controller = AuthController(ref);
  controller.restore();
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this._ref);

  final Ref _ref;

  User? _user;
  bool _loading = false;
  bool _bootstrapping = true;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  bool get isBootstrapping => _bootstrapping;
  String? get error => _error;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> restore() async {
    _bootstrapping = true;
    notifyListeners();
    try {
      _user = await _repo.restoreSession();
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repo.signIn(email: email, password: password);
    } on Failure catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    notifyListeners();
  }
}

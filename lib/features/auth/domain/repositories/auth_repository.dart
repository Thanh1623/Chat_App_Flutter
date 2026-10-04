import 'package:chat_app/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<User> signIn({required String email, required String password});
  Future<void> signOut();
  Future<User?> restoreSession();
  User? get currentUser;
}

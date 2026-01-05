import 'dart:async';

/// Placeholder auth service; replace with firebase_auth wiring.
class AuthService {
  Future<bool> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<bool> register({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return email.isNotEmpty && password.isNotEmpty;
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

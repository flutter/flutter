import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return credential.user;
  }

  Future<User?> register({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return credential.user;
  }

  Future<void> signOut() => _auth.signOut();
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  User? _user;
  String? _role;

  User? get user => _user;
  String? get role => _role;
  bool get isAuthenticated => _user != null;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void clearRole() {
    _role = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String? _role;
  String? get role => _role;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void clearRole() {
    _role = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _role;
  String? _userName;
  String? _fullName;
  String? _userEmail; // ← ADDED
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get role => _role;
  String? get userName => _userName;
  String? get fullName => _fullName;
  String? get userEmail => _userEmail; // ← ADDED
  String? get errorMessage => _errorMessage;

  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _service.isLoggedIn();
    if (_isLoggedIn) {
      _role = await _service.getRole();
      _userName = await _service.getUserName();
      _fullName = await _service.getFullName();
      _userEmail = await _service.getUserEmail(); // ← ADDED
    }
    notifyListeners();
  }

  Future<LoginApiResponse> login(LoginRequest request) async {
    _setLoading(true);
    final response = await _service.login(request);
    if (response.success && response.data != null) {
      _isLoggedIn = true;
      _role = response.data!.role;
      _userName = response.data!.userName;
      _fullName = response.data!.fullName;
      _userEmail = response.data!.email; // ← ADDED
    } else {
      _errorMessage = response.message;
    }
    _setLoading(false);
    return response;
  }

  Future<RegisterApiResponse> register(RegisterRequest request) async {
    _setLoading(true);
    final response = await _service.register(request);
    if (!response.success) _errorMessage = response.message;
    _setLoading(false);
    return response;
  }

  Future<void> logout() async {
    _setLoading(true);
    await _service.logout();
    _isLoggedIn = false;
    _role = null;
    _userName = null;
    _fullName = null;
    _userEmail = null; // ← ADDED
    _errorMessage = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

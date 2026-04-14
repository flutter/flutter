import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';
import '../utils/constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // ── LOGIN ──────────────────────────────────────────────
  Future<LoginApiResponse> login(LoginRequest request) async {
    try {
      final res = await http.post(
        Uri.parse(AppConstants.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final response = LoginApiResponse.fromJson(jsonDecode(res.body));

      if (response.success && response.data != null) {
        await _storage.write(key: 'auth_token', value: response.data!.token);
        await _storage.write(key: 'user_role', value: response.data!.role);
        await _storage.write(key: 'user_email', value: response.data!.email);
        await _storage.write(key: 'user_name', value: response.data!.userName);
        await _storage.write(key: 'full_name', value: response.data!.fullName);
        await _storage.write(
          key: 'location_id',
          value: response.data!.locationId ?? '',
        );
        await _storage.write(key: 'tenant_id', value: request.tenantIdentifier);
      }

      return response;
    } catch (e) {
      return LoginApiResponse(
        statusCode: 500,
        message: 'Connection error. Please check your network.',
      );
    }
  }

  // ── REGISTER ───────────────────────────────────────────
  Future<RegisterApiResponse> register(RegisterRequest request) async {
    try {
      final res = await http.post(
        Uri.parse(AppConstants.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
      return RegisterApiResponse.fromJson(jsonDecode(res.body));
    } catch (e) {
      return RegisterApiResponse(
        statusCode: 500,
        message: 'Connection error. Please check your network.',
      );
    }
  }

  // ── LOGOUT ─────────────────────────────────────────────
  Future<LogoutApiResponse> logout() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final tenant = await _storage.read(key: 'tenant_id');

      if (token != null) {
        await http.post(
          Uri.parse(AppConstants.logoutUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'X-Tenant': tenant ?? '',
          },
        );
      }
    } catch (_) {
    } finally {
      await _storage.deleteAll();
    }
    return LogoutApiResponse(statusCode: 200, message: 'Logged out.');
  }

  // ── HELPERS ────────────────────────────────────────────
  Future<String?> getToken() => _storage.read(key: 'auth_token');
  Future<String?> getRole() => _storage.read(key: 'user_role');
  Future<String?> getUserName() => _storage.read(key: 'user_name');
  Future<String?> getFullName() => _storage.read(key: 'full_name');
  Future<String?> getUserEmail() => _storage.read(key: 'user_email'); // ← ADDED
  Future<String?> getTenant() => _storage.read(key: 'tenant_id');

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null && token.isNotEmpty;
  }

  // Use for every authenticated API call
  Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    final tenant = await getTenant();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Tenant': tenant ?? '',
    };
  }
}

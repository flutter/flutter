import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Super admin email configuration - update this with the actual super admin email
  static const String _superAdminEmail = 'admin@hwrpainting.com.au';
  
  // Additional super admin emails can be added here
  static const List<String> _superAdminEmails = [
    'admin@hwrpainting.com.au',
    'owner@hwrpainting.com.au',
    'ceo@hwrpainting.com.au',
  ];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if current user is super admin
  bool get isSuperAdmin => _currentUser != null && 
      (_superAdminEmails.contains(_currentUser!.email.toLowerCase()) || 
       _currentUser!.id == 'admin-001');

  // Role-based access control methods with super admin override
  bool canViewFinancials() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.ceo || 
           _currentUser?.role == UserRole.supervisor;
  }

  bool canManageProjects() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.ceo || 
           _currentUser?.role == UserRole.supervisor;
  }

  bool canApproveTimesheets() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.ceo || 
           _currentUser?.role == UserRole.supervisor;
  }

  bool canApproveExpenses() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.ceo || 
           _currentUser?.role == UserRole.supervisor;
  }

  bool canSubmitTimesheets() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.painter ||
           _currentUser?.role == UserRole.supervisor ||
           _currentUser?.role == UserRole.ceo;
  }

  bool canSubmitExpenses() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.painter ||
           _currentUser?.role == UserRole.supervisor ||
           _currentUser?.role == UserRole.ceo;
  }

  bool canManageUsers() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.ceo;
  }

  bool canManageLandingPage() {
    return isSuperAdmin ||
           _currentUser?.role == UserRole.ceo ||
           _currentUser?.role == UserRole.supervisor;
  }

  // Set current user method with super admin detection
  void setCurrentUser(UserModel user) {
    // Check if this email is designated as super admin
    if (_superAdminEmails.contains(user.email.toLowerCase())) {
      _currentUser = user.copyWith(role: UserRole.ceo);
    } else {
      _currentUser = user;
    }
    notifyListeners();
  }

  // Login with email and password (original method)
  Future<bool> login(String email, String password, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Platform-specific error handling
      if (kIsWeb && email.isEmpty) {
        _errorMessage = 'Email is required for web login';
        return false;
      }

      // Try Supabase authentication
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id, role, email);
        return true;
      } else {
        _errorMessage = kIsWeb 
            ? 'Invalid credentials. Please check your email and password.'
            : 'Invalid credentials';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _getLocalizedErrorMessage(e.message);
      if (kDebugMode) {
        print('Auth error: ${e.message}');
      }
      return false;
    } catch (e) {
      _errorMessage = kIsWeb
          ? 'Connection error. Please check your internet connection.'
          : 'Login failed. Please try again.';
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with username and password (method for admin)
  Future<bool> loginWithCredentials(String username, String password, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check admin credentials
      if (username == 'admin' && password == 'hwrp123') {
        await _createAdminUser(role);
        return true;
      }

      _errorMessage = kIsWeb
          ? 'Invalid username or password. Please try again.'
          : 'Invalid username or password';
      return false;
    } catch (e) {
      _errorMessage = kIsWeb
          ? 'Login failed. Please refresh the page and try again.'
          : 'Login failed. Please try again.';
      if (kDebugMode) {
        print('Login error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createAdminUser(UserRole role) async {
    _currentUser = UserModel(
      id: 'admin-001',
      fullName: 'System Administrator',
      email: 'admin@paintops.com',
      role: role,
      isActive: true,
      profileImageUrl: null,
    );
    notifyListeners();
  }

  Future<void> _loadUserProfile(String userId, UserRole role, String email) async {
    try {
      // Try to fetch user profile from Supabase
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      var user = UserModel.fromJson(response);
      
      // Check if this email is designated as super admin and upgrade role
      if (_superAdminEmails.contains(email.toLowerCase())) {
        user = user.copyWith(role: UserRole.ceo);
        
        // Update the database to reflect CEO role for super admin
        await _supabase.from('profiles').update({
          'role': 'ceo'
        }).eq('id', userId);
      }
      
      _currentUser = user;
    } catch (e) {
      // If profile doesn't exist, create a basic user
      var newRole = role;
      
      // Check if this email should be super admin
      if (_superAdminEmails.contains(email.toLowerCase())) {
        newRole = UserRole.ceo;
      }
      
      _currentUser = UserModel(
        id: userId,
        fullName: 'User',
        email: email,
        role: newRole,
        isActive: true,
        profileImageUrl: null,
      );
      
      // Create profile in database
      try {
        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': 'User',
          'email': email,
          'role': newRole.name,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (insertError) {
        if (kDebugMode) {
          print('Error creating profile: $insertError');
        }
      }
    }
    notifyListeners();
  }

  Future<bool> register(String email, String password, String fullName, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Platform-specific validation
      if (kIsWeb && (!_isValidEmail(email))) {
        _errorMessage = 'Please enter a valid email address';
        return false;
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if this email should be super admin
        var userRole = role;
        if (_superAdminEmails.contains(email.toLowerCase())) {
          userRole = UserRole.ceo;
        }
        
        // Create user profile
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'full_name': fullName,
          'email': email,
          'role': userRole.name,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        await _loadUserProfile(response.user!.id, userRole, email);
        return true;
      } else {
        _errorMessage = 'Registration failed';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _getLocalizedErrorMessage(e.message);
      if (kDebugMode) {
        print('Registration error: ${e.message}');
      }
      return false;
    } catch (e) {
      _errorMessage = kIsWeb
          ? 'Registration failed. Please check your connection and try again.'
          : 'Registration failed. Please try again.';
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
    } finally {
      _currentUser = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String fullName, String? profileImageUrl) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('profiles').update({
        'full_name': fullName,
        'profile_image_url': profileImageUrl,
      }).eq('id', _currentUser!.id);

      _currentUser = _currentUser!.copyWith(
        fullName: fullName,
        profileImageUrl: profileImageUrl,
      );
    } catch (e) {
      _errorMessage = kIsWeb
          ? 'Failed to update profile. Please check your connection.'
          : 'Failed to update profile';
      if (kDebugMode) {
        print('Profile update error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Auto-login on app start if session exists
  Future<void> checkAuthStatus() async {
    final session = _supabase.auth.currentSession;
    if (session?.user != null) {
      await _loadUserProfile(
        session!.user.id, 
        UserRole.painter, 
        session.user.email ?? ''
      );
    }
  }

  // Platform-specific helper methods
  String _getLocalizedErrorMessage(String error) {
    if (kIsWeb) {
      // Web-specific error messages
      if (error.contains('Invalid login credentials')) {
        return 'Invalid email or password. Please try again.';
      } else if (error.contains('Email not confirmed')) {
        return 'Please check your email and click the confirmation link.';
      } else if (error.contains('Too many requests')) {
        return 'Too many login attempts. Please wait and try again.';
      }
    }
    
    // Default mobile-friendly messages
    return error.length > 50 ? 'Login failed. Please try again.' : error;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Platform-specific session management
  Future<void> refreshSession() async {
    if (!kIsWeb) return; // Only needed for web
    
    try {
      await _supabase.auth.refreshSession();
    } catch (e) {
      if (kDebugMode) {
        print('Session refresh error: $e');
      }
    }
  }

  // Method to update super admin emails (for future configuration)
  Future<void> updateSuperAdminEmail(String newEmail) async {
    // This method can be used to dynamically update super admin emails
    // For now, it's a placeholder for future configuration
    if (kDebugMode) {
      print('Super admin email update requested: $newEmail');
    }
  }
}

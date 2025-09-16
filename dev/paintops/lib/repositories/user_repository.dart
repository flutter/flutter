import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserModel>> getUsers({bool? activeOnly}) async {
    try {
      var query = _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query;

      return (response as List).map((user) {
        return UserModel.fromJson(user);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading users: $e');
      }
      throw Exception('Failed to load users: $e');
    }
  }

  Future<UserModel?> getUser(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user: $e');
      }
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user by email: $e');
      }
      return null;
    }
  }

  Future<bool> createUser(UserModel user, String password) async {
    try {
      // Platform-specific user creation handling
      if (kIsWeb && !_isValidEmail(user.email)) {
        if (kDebugMode) {
          print('Invalid email format for web user creation');
        }
        return false;
      }

      // First create the auth user
      final authResponse = await _supabase.auth.signUp(
        email: user.email,
        password: password,
        data: {
          'full_name': user.fullName,
          'role': user.role.name,
        },
      );

      if (authResponse.user != null) {
        // Then create the profile record
        final profileData = user.toJson();
        profileData['id'] = authResponse.user!.id;
        profileData['created_at'] = DateTime.now().toIso8601String();
        
        await _supabase.from('profiles').insert(profileData);
        return true;
      }
      
      return false;
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('Auth error creating user: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user: $e');
      }
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      final data = user.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      data.remove('created_at'); // Don't update creation date

      await _supabase
          .from('profiles')
          .update(data)
          .eq('id', user.id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      return false;
    }
  }

  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      // Deactivate instead of actually deleting
      await _supabase
          .from('profiles')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user: $e');
      }
      return false;
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role, {bool? activeOnly}) async {
    try {
      var query = _supabase
          .from('profiles')
          .select()
          .eq('role', role.name)
          .order('full_name', ascending: true);

      if (activeOnly == true) {
        query = query.eq('is_active', true);
      }

      final response = await query;

      return (response as List).map((user) {
        return UserModel.fromJson(user);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading users by role: $e');
      }
      throw Exception('Failed to load users by role: $e');
    }
  }

  Future<Map<String, int>> getUserMetrics() async {
    try {
      final users = await getUsers();
      final activeUsers = users.where((u) => u.isActive).length;
      final inactiveUsers = users.where((u) => !u.isActive).length;
      final ceos = users.where((u) => u.role == UserRole.ceo).length;
      final supervisors = users.where((u) => u.role == UserRole.supervisor).length;
      final painters = users.where((u) => u.role == UserRole.painter).length;
      
      return {
        'totalUsers': users.length,
        'activeUsers': activeUsers,
        'inactiveUsers': inactiveUsers,
        'ceos': ceos,
        'supervisors': supervisors,
        'painters': painters,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user metrics: $e');
      }
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'inactiveUsers': 0,
        'ceos': 0,
        'supervisors': 0,
        'painters': 0,
      };
    }
  }

  Future<String?> uploadProfileImage(String userId, List<int> imageBytes, String fileName) async {
    try {
      final filePath = 'profiles/$userId/$fileName';
      
      // Platform-specific image processing
      final processedBytes = await _processImageForPlatform(imageBytes);
      
      await _supabase.storage
          .from('profile-images')
          .uploadBinary(
            filePath,
            processedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: kIsWeb ? _getMimeTypeFromFileName(fileName) : null,
            ),
          );

      final imageUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(filePath);

      // Update user profile with image URL
      await _supabase
          .from('profiles')
          .update({'profile_image_url': imageUrl})
          .eq('id', userId);

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      return null;
    }
  }

  // Platform-specific helper methods
  Future<List<int>> _processImageForPlatform(List<int> imageBytes) async {
    if (kIsWeb) {
      // Web-specific image processing
      if (imageBytes.length > 2 * 1024 * 1024) { // 2MB limit for profile images
        throw Exception('Profile image too large. Please select an image smaller than 2MB.');
      }
      return imageBytes;
    } else {
      // Mobile-specific image processing
      // Could add compression or format conversion
      return imageBytes;
    }
  }

  String? _getMimeTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Enhanced error handling with platform-specific messages
  String _getPlatformSpecificErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (kIsWeb) {
      if (errorStr.contains('email')) {
        return 'Please enter a valid email address.';
      } else if (errorStr.contains('password')) {
        return 'Password must be at least 6 characters long.';
      } else if (errorStr.contains('network')) {
        return 'Network error. Please check your connection.';
      }
    }
    
    return 'Operation failed. Please try again.';
  }
}

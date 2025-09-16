import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserManagementProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  
  UserManagementProvider(this._userRepository);

  List<UserModel> _users = [];
  Map<String, int> _userMetrics = {};
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  Map<String, int> get userMetrics => _userMetrics;
  
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<UserModel> get activeUsers => _users.where((u) => u.isActive).toList();
  List<UserModel> get inactiveUsers => _users.where((u) => !u.isActive).toList();
  List<UserModel> get ceos => _users.where((u) => u.role == UserRole.ceo).toList();
  List<UserModel> get supervisors => _users.where((u) => u.role == UserRole.supervisor).toList();
  List<UserModel> get painters => _users.where((u) => u.role == UserRole.painter).toList();

  Future<void> loadUsers({bool activeOnly = false, bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.getUsers(activeOnly: activeOnly);
      _userMetrics = await _userRepository.getUserMetrics();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load users. Please try again.';
      if (kDebugMode) {
        print('Error loading users: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(UserModel user, String password) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _userRepository.createUser(user, password);
      
      if (success) {
        await loadUsers(forceRefresh: true);
      } else {
        _errorMessage = 'Failed to create user. Please check the details and try again.';
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Failed to create user: ${e.toString()}';
      if (kDebugMode) {
        print('Error creating user: $e');
      }
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(UserModel user) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _userRepository.updateUser(user);
      
      if (success) {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = user;
          await _loadUserMetrics();
          notifyListeners();
        }
      } else {
        _errorMessage = 'Failed to update user.';
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update user: ${e.toString()}';
      if (kDebugMode) {
        print('Error updating user: $e');
      }
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      final success = await _userRepository.updateUserStatus(userId, isActive);
      
      if (success) {
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isActive: isActive);
          await _loadUserMetrics();
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user status: $e');
      }
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final success = await _userRepository.deleteUser(userId);
      
      if (success) {
        _users.removeWhere((u) => u.id == userId);
        await _loadUserMetrics();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user: $e');
      }
      return false;
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      return await _userRepository.getUser(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user: $e');
      }
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      return await _userRepository.getUserByEmail(email);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by email: $e');
      }
      return null;
    }
  }

  Future<List<UserModel>> getUsersByRole(UserRole role, {bool activeOnly = true}) async {
    try {
      return await _userRepository.getUsersByRole(role, activeOnly: activeOnly);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting users by role: $e');
      }
      return [];
    }
  }

  Future<String?> uploadProfileImage(String userId, List<int> imageBytes, String fileName) async {
    try {
      final imageUrl = await _userRepository.uploadProfileImage(userId, imageBytes, fileName);
      
      if (imageUrl != null) {
        final index = _users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(profileImageUrl: imageUrl);
          notifyListeners();
        }
      }
      
      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      return null;
    }
  }

  Future<void> _loadUserMetrics() async {
    try {
      _userMetrics = await _userRepository.getUserMetrics();
    } catch (e) {
      print('Error loading user metrics: $e');
    }
  }

  List<UserModel> searchUsers(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _users.where((user) =>
        user.fullName.toLowerCase().contains(lowercaseQuery) ||
        user.email.toLowerCase().contains(lowercaseQuery) ||
        user.role.displayName.toLowerCase().contains(lowercaseQuery) ||
        (user.phone?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  void sortUsersByName({bool ascending = true}) {
    _users.sort((a, b) => ascending 
        ? a.fullName.compareTo(b.fullName)
        : b.fullName.compareTo(a.fullName));
    notifyListeners();
  }

  void sortUsersByRole() {
    _users.sort((a, b) => a.role.displayName.compareTo(b.role.displayName));
    notifyListeners();
  }

  void sortUsersByHireDate({bool ascending = false}) {
    _users.sort((a, b) {
      final aDate = a.hireDate ?? DateTime(1900);
      final bDate = b.hireDate ?? DateTime(1900);
      return ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });
    notifyListeners();
  }

  void sortUsersByStatus() {
    _users.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return 0;
    });
    notifyListeners();
  }

  void filterUsersByRole(UserRole? role) {
    if (role == null) {
      // Show all users - reload from repository
      loadUsers(forceRefresh: true);
    } else {
      // Apply filter
      // Note: This filters the current list, not the repository
      // For a more robust solution, you'd want to reload from repository with filter
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshUsers() async {
    await loadUsers(forceRefresh: true);
  }

  // Analytics methods
  double get averageHourlyRate {
    final usersWithRates = _users.where((u) => u.hourlyRate != null);
    if (usersWithRates.isEmpty) return 0.0;
    
    final totalRate = usersWithRates.fold(0.0, (sum, user) => sum + user.hourlyRate!);
    return totalRate / usersWithRates.length;
  }

  Map<String, int> get userRoleDistribution {
    final distribution = <String, int>{};
    for (final role in UserRole.values) {
      distribution[role.displayName] = _users.where((u) => u.role == role).length;
    }
    return distribution;
  }

  List<UserModel> getNewHires({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _users.where((u) => 
        u.hireDate != null && u.hireDate!.isAfter(cutoffDate)
    ).toList();
  }

  int get totalActiveUsers => activeUsers.length;
  int get totalInactiveUsers => inactiveUsers.length;
  
  double get activeUserPercentage {
    if (_users.isEmpty) return 0.0;
    return (activeUsers.length / _users.length) * 100;
  }
}

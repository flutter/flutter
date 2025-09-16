class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final bool isActive;
  final String? profileImageUrl;
  final DateTime? hireDate;
  final double? hourlyRate;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    required this.isActive,
    this.profileImageUrl,
    this.hireDate,
    this.hourlyRate,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: _parseUserRole(json['role']),
      phone: json['phone'],
      isActive: json['is_active'] ?? true,
      profileImageUrl: json['profile_image_url'],
      hireDate: json['hire_date'] != null ? DateTime.tryParse(json['hire_date']) : null,
      hourlyRate: json['hourly_rate'] != null ? (json['hourly_rate'] as num).toDouble() : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role.name,
      'phone': phone,
      'is_active': isActive,
      'profile_image_url': profileImageUrl,
      'hire_date': hireDate?.toIso8601String().split('T')[0],
      'hourly_rate': hourlyRate,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    UserRole? role,
    String? phone,
    bool? isActive,
    String? profileImageUrl,
    DateTime? hireDate,
    double? hourlyRate,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hireDate: hireDate ?? this.hireDate,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static UserRole _parseUserRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'ceo':
        return UserRole.ceo;
      case 'supervisor':
        return UserRole.supervisor;
      case 'painter':
      default:
        return UserRole.painter;
    }
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}';
    } else if (names.isNotEmpty) {
      return names[0].substring(0, 1);
    }
    return 'U';
  }

  String get displayHourlyRate {
    if (hourlyRate != null) {
      return '\$${hourlyRate!.toStringAsFixed(2)}/hr';
    }
    return 'Rate not set';
  }

  String get statusText => isActive ? 'Active' : 'Inactive';
}

enum UserRole {
  ceo('CEO', 'Chief Executive Officer - Full system access'),
  supervisor('Supervisor', 'Project supervision and team management'),
  painter('Painter', 'Field work and timesheet management');

  const UserRole(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

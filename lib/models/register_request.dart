class RegisterRequest {
  final String tenantIdentifier;
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String phone;

  RegisterRequest({
    required this.tenantIdentifier,
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phone = '',
  });

  Map<String, dynamic> toJson() => {
    'tenantIdentifier': tenantIdentifier,
    'fullName': fullName,
    'email': email,
    'password': password,
    'confirmPassword': confirmPassword,
    'phone': phone,
  };
}

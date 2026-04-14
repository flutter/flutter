class LoginRequest {
  final String tenantIdentifier;
  final String email;
  final String password;
  final double latitude;
  final double longitude;

  LoginRequest({
    required this.tenantIdentifier,
    required this.email,
    required this.password,
    this.latitude = 0,
    this.longitude = 0,
  });

  Map<String, dynamic> toJson() => {
    'tenantIdentifier': tenantIdentifier,
    'email': email,
    'password': password,
    'latitude': latitude,
    'longitude': longitude,
  };
}

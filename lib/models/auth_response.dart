class LoginData {
  final String token;
  final String role;
  final String userName;
  final String email;
  final String fullName;
  final String? locationId;
  final String? tokenExpiry;

  LoginData({
    required this.token,
    required this.role,
    required this.userName,
    required this.email,
    required this.fullName,
    this.locationId,
    this.tokenExpiry,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) => LoginData(
    token: json['token'] ?? '',
    role: json['role'] ?? '',
    userName: json['userName'] ?? '',
    email: json['email'] ?? '',
    fullName: json['fullName'] ?? '',
    locationId: json['locationId']?.toString(),
    tokenExpiry: json['tokenExpiry']?.toString(),
  );
}

class LoginApiResponse {
  final int statusCode;
  final String message;
  final LoginData? data;

  bool get success => statusCode == 200;

  LoginApiResponse({
    required this.statusCode,
    required this.message,
    this.data,
  });

  factory LoginApiResponse.fromJson(Map<String, dynamic> json) =>
      LoginApiResponse(
        statusCode: json['statusCode'] ?? 500,
        message: json['message'] ?? '',
        data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
      );
}

class RegisterApiResponse {
  final int statusCode;
  final String message;

  bool get success => statusCode == 200;

  RegisterApiResponse({required this.statusCode, required this.message});

  factory RegisterApiResponse.fromJson(Map<String, dynamic> json) =>
      RegisterApiResponse(
        statusCode: json['statusCode'] ?? 500,
        message: json['message'] ?? '',
      );
}

class LogoutApiResponse {
  final int statusCode;
  final String message;

  bool get success => statusCode == 200;

  LogoutApiResponse({required this.statusCode, required this.message});

  factory LogoutApiResponse.fromJson(Map<String, dynamic> json) =>
      LogoutApiResponse(
        statusCode: json['statusCode'] ?? 500,
        message: json['message'] ?? '',
      );
}

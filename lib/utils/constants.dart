class AppConstants {
  // Your Ocelot Gateway base URL
  // Change host/port to match your gateway
  static const String _gatewayBase = 'https://localhost:44371/Franchise';

  // Auth endpoints — matches your route: /Franchise/{everything}
  // which forwards to localhost:44378/{everything}
  static const String loginUrl = '$_gatewayBase/api/AuthApi/login';
  static const String registerUrl = '$_gatewayBase/api/AuthApi/register';
  static const String logoutUrl = '$_gatewayBase/api/AuthApi/logout';
}

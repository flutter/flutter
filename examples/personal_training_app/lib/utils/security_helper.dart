import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityHelper {
  /// Hash a password using SHA-256 with salt
  /// For better security, consider using bcrypt or argon2 in production
  static String hashPassword(String password, String username) {
    // Use username as salt to make each hash unique
    final salt = username.toLowerCase();
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify if a password matches the stored hash
  static bool verifyPassword(
    String password,
    String username,
    String storedHash,
  ) {
    final hash = hashPassword(password, username);
    return hash == storedHash;
  }

  /// Generate a simple session token (for future use)
  static String generateSessionToken(String username) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(username + timestamp);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

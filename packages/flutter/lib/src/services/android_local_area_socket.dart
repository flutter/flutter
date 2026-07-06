import 'dart:io';
import 'package:flutter/services.dart';

/// A wrapper around [Socket] that handles Android 17 local area permissions.
class AndroidLocalAreaSocket {
  static const MethodChannel _channel =
      MethodChannel('plugins.flutter.io/android_local_area_config');

  /// Visible for testing to simulate Android behavior on other platforms.
  static bool debugPlatformIsAndroid = Platform.isAndroid;

  /// Connects to a socket, requesting permission on Android if needed.
  static Future<Socket> connect(
    dynamic host,
    int port, {
    Duration? timeout,
  }) async {
    if (debugPlatformIsAndroid) {
      // Request configuration/permission from the Android embedder.
      final bool hasAccess = await _requestAccess();
      if (!hasAccess) {
        throw SocketException('Local area access permission denied by user.');
      }
    }

    // Proceed with standard socket connection.
    return Socket.connect(host, port, timeout: timeout);
  }

  static Future<bool> _requestAccess() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestLocalAreaAccess');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error requesting local area access: ${e.message}');
      return false;
    }
  }
}

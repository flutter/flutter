import 'package:flutter/foundation.dart';

/// Logger
void log(String message) => debugPrint(_logTemplate(message), wrapWidth: 1024);
String _logTemplate(String message) {
  return '\x1B[34m[WebViewX]\x1B[0m $message\x1B[0m';
}

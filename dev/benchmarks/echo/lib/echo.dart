import 'dart:async';

import 'package:flutter/services.dart';

class Echo {
  static const MethodChannel _channel =
      const MethodChannel('echo');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}

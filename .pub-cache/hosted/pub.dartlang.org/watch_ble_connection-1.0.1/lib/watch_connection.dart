import 'package:flutter/services.dart';

/// Class WatchConnection for connect like sendMessage & setData with Watch
class WatchConnection {
  /// Method channel to communnicate with native code
  static const MethodChannel _channel = const MethodChannel('watchConnection');

  /// Get Platform Version
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// send message to watch
  /// the message must conform to https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
  ///
  /// android consideration: message will be converted to a json string and send on a channel name "MessageChannel"
  static void sendMessage(Map<String, dynamic> message) async {
    await _channel.invokeMethod('sendMessage', message);
  }

  /// set constant data
  /// the data must conform to https://api.flutter.dev/flutter/services/StandardMessageCodec-class.html
  /// android: sets data on data layer by the name
  static void setData(String path, Map<String, dynamic> data) async {
    if (!path.startsWith("/")) {
      path = "/" + path;
    }
    await _channel.invokeListMethod('setData', {"path": path, "data": data});
  }
}

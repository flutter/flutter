import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// A web implementation of the AudioSession plugin.
class AudioSessionWeb {
  static void registerWith(Registrar registrar) {
    AudioSessionWeb(registrar);
  }

  final MethodChannel _channel;
  dynamic _configuration;

  AudioSessionWeb(Registrar registrar)
      : _channel = MethodChannel(
          'com.ryanheise.audio_session',
          const StandardMethodCodec(),
          registrar,
        ) {
    _channel.setMethodCallHandler(handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      case 'setConfiguration':
        _configuration = args[0];
        _channel.invokeMethod('onConfigurationChanged', [_configuration]);
        break;
      case 'getConfiguration':
        return _configuration;
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'audio_session for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}

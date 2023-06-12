import 'package:audioplayers_platform_interface/api/audio_context_config.dart';
import 'package:audioplayers_platform_interface/api/log_level.dart';
import 'package:audioplayers_platform_interface/method_channel_interface.dart';
import 'package:flutter/services.dart';

abstract class GlobalPlatformInterface {
  static GlobalPlatformInterface instance = MethodChannelGlobalPlatform();

  LogLevel get logLevel;

  Future<void> changeLogLevel(LogLevel value);

  Future<void> setGlobalAudioContext(AudioContext ctx);

  void log(LogLevel level, String message) {
    if (level.getLevel() <= logLevel.getLevel()) {
      // ignore: avoid_print
      print(message);
    }
  }

  void info(String message) => log(LogLevel.info, message);

  void error(String message) => log(LogLevel.error, message);
}

class MethodChannelGlobalPlatform extends GlobalPlatformInterface {
  static const MethodChannel _channel =
      MethodChannel('xyz.luan/audioplayers.global');

  static LogLevel _logLevel = LogLevel.error;

  @override
  Future<void> changeLogLevel(LogLevel value) {
    _logLevel = value;
    return _channel.call(
      'changeLogLevel',
      <String, dynamic>{'value': value.toString()},
    );
  }

  @override
  Future<void> setGlobalAudioContext(AudioContext ctx) {
    return _channel.call(
      'setGlobalAudioContext',
      ctx.toJson(),
    );
  }

  @override
  LogLevel get logLevel => _logLevel;
}

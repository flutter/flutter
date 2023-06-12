import '../audioplayers.dart';
import 'api/log_level.dart';

class Logger {
  static LogLevel _logLevel = LogLevel.ERROR;

  static LogLevel get logLevel => _logLevel;

  static Future<int> changeLogLevel(LogLevel value) {
    _logLevel = value;
    return AudioPlayer.invokeMethod(
      'changeLogLevel',
      <String, dynamic>{'value': value.toString()},
    );
  }

  Logger._() {
    throw UnimplementedError();
  }

  static void log(LogLevel level, String message) {
    if (level.getLevel() <= logLevel.getLevel()) {
      print(message);
    }
  }

  static void info(String message) => log(LogLevel.INFO, message);

  static void error(String message) => log(LogLevel.ERROR, message);
}

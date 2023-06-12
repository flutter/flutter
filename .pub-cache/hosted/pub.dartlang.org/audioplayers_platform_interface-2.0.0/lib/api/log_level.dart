enum LogLevel { info, error, none }

extension LogLevelExtension on LogLevel {
  int getLevel() {
    switch (this) {
      case LogLevel.info:
        return 2;
      case LogLevel.error:
        return 1;
      case LogLevel.none:
        return 0;
    }
  }
}

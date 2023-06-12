enum LogLevel { INFO, ERROR, NONE }

extension LogLevelExtension on LogLevel {
  int getLevel() {
    switch (this) {
      case LogLevel.INFO:
        return 2;
      case LogLevel.ERROR:
        return 1;
      case LogLevel.NONE:
        return 0;
    }
  }
}

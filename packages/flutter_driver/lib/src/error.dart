// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show stderr;

/// Standard error thrown by Flutter Driver API.
class DriverError extends Error {
  DriverError(this.message, [this.originalError, this.originalStackTrace]);

  /// Human-readable error message.
  final String message;

  final dynamic originalError;
  final dynamic originalStackTrace;

  @override
  String toString() {
    return '''DriverError: $message
Original error: $originalError
Original stack trace:
$originalStackTrace
    ''';
  }
}

// Whether someone redirected the log messages somewhere.
bool _noLogSubscribers = true;

final StreamController<LogRecord> _logger =
    new StreamController<LogRecord>.broadcast(sync: true, onListen: () {
      _noLogSubscribers = false;
    });

void _log(LogLevel level, String loggerName, Object message) {
  LogRecord record = new LogRecord._(level, loggerName, '$message');
  // If nobody expressed interest in rerouting log messages somewhere specific,
  // print them to stderr.
  if (_noLogSubscribers)
    stderr.writeln(record);
  else
    _logger.add(record);
}

/// Emits log records from Flutter Driver.
final Stream<LogRecord> flutterDriverLog = _logger.stream;

/// Severity of a log entry.
enum LogLevel { trace, info, warning, error, critical }

/// A log entry.
class LogRecord {
  const LogRecord._(this.level, this.loggerName, this.message);

  final LogLevel level;
  final String loggerName;
  final String message;

  String get levelDescription => level.toString().split(".").last;

  @override
  String toString() => '[${levelDescription.padRight(5)}] $loggerName: $message';
}

/// Package-private; users should use other public logging libraries.
class Logger {
  Logger(this.name);

  final String name;

  void trace(Object message) {
    _log(LogLevel.trace, name, message);
  }

  void info(Object message) {
    _log(LogLevel.info, name, message);
  }

  void warning(Object message) {
    _log(LogLevel.warning, name, message);
  }

  void error(Object message) {
    _log(LogLevel.error, name, message);
  }

  void critical(Object message) {
    _log(LogLevel.critical, name, message);
  }
}

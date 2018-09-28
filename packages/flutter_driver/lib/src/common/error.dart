// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show stderr;

/// Standard error thrown by Flutter Driver API.
class DriverError extends Error {
  /// Create an error with a [message] and (optionally) the [originalError] and
  /// [originalStackTrace] that caused it.
  DriverError(this.message, [this.originalError, this.originalStackTrace]);

  /// Human-readable error message.
  final String message;

  /// The error object that was caught and wrapped by this error object.
  final dynamic originalError;

  /// The stack trace that was caught and wrapped by this error object.
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
    StreamController<LogRecord>.broadcast(sync: true, onListen: () {
      _noLogSubscribers = false;
    });

void _log(LogLevel level, String loggerName, Object message) {
  final LogRecord record = LogRecord._(level, loggerName, '$message');
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
enum LogLevel {
  /// Messages used to supplement the higher-level messages with more details.
  ///
  /// This will likely produce a lot of output.
  trace,

  /// Informational messages that do not indicate a problem.
  info,

  /// A potential problem.
  warning,

  /// A certain problem but the program will attempt to continue.
  error,

  /// A critical problem; the program will attempt to quit immediately.
  critical,
}

/// A log entry, as emitted on [flutterDriverLog].
class LogRecord {
  const LogRecord._(this.level, this.loggerName, this.message);

  /// The severity of the log record.
  final LogLevel level;

  /// The name of the logger that logged the message.
  final String loggerName;

  /// The log message.
  ///
  /// The message should be a normal and complete sentence ending with a period.
  /// It is OK to omit the subject in the message to imply [loggerName]. It is
  /// also OK to omit article, such as "the" and "a".
  ///
  /// Example: if [loggerName] is "FlutterDriver" and [message] is "Failed to
  /// connect to application." then this log record means that FlutterDriver
  /// failed to connect to the application.
  final String message;

  /// Short description of the log level.
  ///
  /// It is meant to be read by humans. There's no guarantee that this value is
  /// stable enough to be parsed by machines.
  String get levelDescription => level.toString().split('.').last;

  @override
  String toString() => '[${levelDescription.padRight(5)}] $loggerName: $message';
}

/// Logger used internally by Flutter Driver to avoid mandating any specific
/// logging library.
///
/// By default the output from this logger is printed to [stderr]. However, a
/// subscriber to the [flutterDriverLog] stream may redirect the log records
/// elsewhere, including other logging API. The logger stops sending messages to
/// [stderr] upon first subscriber.
///
/// This class is package-private. Flutter users should use other public logging
/// libraries.
class Logger {
  /// Creates a new logger.
  Logger(this.name);

  /// Identifies the part of the system that emits message into this object.
  ///
  /// It is common for [name] to be used as an implicit subject of an action
  /// described in a log message. For example, if you emit message "failed" and
  /// [name] is "FlutterDriver", the meaning of the message should be understood
  /// as "FlutterDriver failed". See also [LogRecord.message].
  final String name;

  /// Emits a [LogLevel.trace] record into `this` logger.
  void trace(Object message) {
    _log(LogLevel.trace, name, message);
  }

  /// Emits a [LogLevel.info] record into `this` logger.
  void info(Object message) {
    _log(LogLevel.info, name, message);
  }

  /// Emits a [LogLevel.warning] record into `this` logger.
  void warning(Object message) {
    _log(LogLevel.warning, name, message);
  }

  /// Emits a [LogLevel.error] record into `this` logger.
  void error(Object message) {
    _log(LogLevel.error, name, message);
  }

  /// Emits a [LogLevel.critical] record into `this` logger.
  void critical(Object message) {
    _log(LogLevel.critical, name, message);
  }
}

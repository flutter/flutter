// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:io';

/// Determines the level of logging.
///
/// Verbosity is increasing from one (none) to five (fine). The sixth level
/// (all) logs everything.
enum LoggingLevel {
  /// Logs no logs.
  none,

  /// Logs severe messages at the most (severe messages are always logged).
  ///
  /// Severe means that the process has encountered a critical level of failure
  /// in which it cannot recover and will terminate as a result.
  severe,

  /// Logs warning messages at the most.
  ///
  /// Warning implies that an error was encountered, but the process will
  /// attempt to continue, and may/may not succeed.
  warning,

  /// Logs info messages at the most.
  ///
  /// An info message is for determining information about the state of the
  /// application as it runs through execution.
  info,

  /// Logs fine logs at the most.
  ///
  /// A fine message is one that is not important for logging outside of
  /// debugging potential issues in the application.
  fine,

  /// Logs everything.
  all,
}

/// Signature of a function that logs a [LogMessage].
typedef LoggingFunction = void Function(LogMessage log);

/// The default logging function.
///
/// Runs the [print] function using the format string:
///   '[${log.levelName}]::${log.tag}--${log.time}: ${log.message}'
///
/// Exits with status code 1 if the `log` is [LoggingLevel.severe].
LoggingFunction defaultLoggingFunction = (LogMessage log) {
  print('[${log.levelName}]::${log.tag}--${log.time}: ${log.message}');
  if (log.level == LoggingLevel.severe) {
    exit(1);
  }
};

/// Represents a logging message created by the logger.
///
/// Includes a message, the time the message was created, the level of the log
/// as an enum, the name of the level as a string, and a tag. This class is used
/// to print from the global logging function defined in
/// [Logger.loggingFunction] (a function that can be user-defined).
class LogMessage {
  /// Creates a log, including the level of the log, the time it was created,
  /// and the actual log message.
  ///
  /// When this message is created, it sets its [time] to [DateTime.now].
  LogMessage(this.message, this.tag, this.level)
    : levelName = level.toString().substring(level.toString().indexOf('.') + 1),
      time = DateTime.now();

  /// The actual log message.
  final String message;

  /// The time the log message was created.
  final DateTime time;

  /// The level of this log.
  final LoggingLevel level;

  /// The human readable level of this log.
  final String levelName;

  /// The tag associated with the message. This is set to [Logger.tag] when
  /// emitted by a [Logger] object.
  final String tag;
}

/// Logs messages using the global [LoggingFunction] and logging level.
///
/// Example of setting log level to [LoggingLevel.warning] and creating a
/// logging function:
///
/// ```dart
/// Logger.globalLevel = LoggingLevel.warning;
/// ```
class Logger {
  /// Creates a logger with the given [tag].
  Logger(this.tag);

  /// The tag associated with the log message (usable in the logging function).
  /// [LogMessage] objects emitted by this class will have [LogMessage.tag] set
  /// to this value.
  final String tag;

  /// Determines what to do when the [Logger] creates and attempts to log a
  /// [LogMessage] object.
  ///
  /// This function can be reassigned to whatever functionality of your
  /// choosing, so long as it has the same signature of [LoggingFunction] (it
  /// can also be an asynchronous function, if doing file I/O, for
  /// example).
  static LoggingFunction loggingFunction = defaultLoggingFunction;

  /// Determines the logging level all [Logger] instances use.
  static LoggingLevel globalLevel = LoggingLevel.none;

  /// Logs a [LoggingLevel.severe] level `message`.
  ///
  /// Severe messages are always logged, regardless of what level is set.
  void severe(String message) {
    loggingFunction(LogMessage(message, tag, LoggingLevel.severe));
  }

  /// Logs a [LoggingLevel.warning] level `message`.
  void warning(String message) {
    if (globalLevel.index >= LoggingLevel.warning.index) {
      loggingFunction(LogMessage(message, tag, LoggingLevel.warning));
    }
  }

  /// Logs a [LoggingLevel.info] level `message`.
  void info(String message) {
    if (globalLevel.index >= LoggingLevel.info.index) {
      loggingFunction(LogMessage(message, tag, LoggingLevel.info));
    }
  }

  /// Logs a [LoggingLevel.fine] level `message`.
  void fine(String message) {
    if (globalLevel.index >= LoggingLevel.fine.index) {
      loggingFunction(LogMessage(message, tag, LoggingLevel.fine));
    }
  }
}

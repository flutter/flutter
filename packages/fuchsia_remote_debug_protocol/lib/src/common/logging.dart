// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:async';

/// Determines the level of logging.
///
/// Verbosity is increasing from zero (none) to four (fine).
enum LoggingLevel {
  /// Logs no logs.
  none,

  /// Logs severe logs at the most.
  severe,

  /// Logs warning logs at the most.
  warning,

  /// Logs info logs at the most.
  info,

  /// Logs fine logs at the most.
  fine,

  /// Logs everything.
  all,
}

/// Synchronously logs a `Log.`
typedef void LoggingFunction(Log log);
LoggingFunction _defaultFormatter(Log log) {
  print('[${log.levelName}] -- ${log.time}: ${log.message}');
}

class Log {
  /// The actual log message.
  final String message;

  /// The time the log message was created.
  final DateTime time;

  /// The level of this log.
  final LoggingLevel level;

  /// The human readable level of this log.
  final String levelName;

  /// The tag associated with the message.
  final String tag;

  /// Creates a log, including the level of the log, the time it was created,
  /// and the actual log message.
  Log(this.message, this.tag, this.time, this.level)
      : this.levelName =
            level.toString().substring(level.toString().indexOf('.') + 1);
}

/// Very barebones logging class. Prints using the global LoggingFunction and
/// logging level.
///
/// Example of setting log level to `LoggingLevel.warning` and creating a
/// logging function.
class Logger {
  /// Determines the tag included with the logging when chosen in the formatter
  /// function.
  final String tag;

  /// Determines the global formatting function through a `LoggingFunction`
  /// which takes a logger and a string and prints out a log message.
  static LoggingFunction loggingFunction = _defaultFormatter;

  /// Determines the global logging level.
  static LoggingLevel globalLevel = LoggingLevel.none;

  /// Creates a logger with the given tag.
  Logger(this.tag);

  /// Logs an severe level log.
  void severe(String message) {
    if (globalLevel.index >= LoggingLevel.severe.index) {
      loggingFunction(
          new Log(message, tag, new DateTime.now(), LoggingLevel.severe));
    }
  }

  /// Logs a warning level log.
  void warning(String message) {
    if (globalLevel.index >= LoggingLevel.warning.index) {
      loggingFunction(
          new Log(message, tag, new DateTime.now(), LoggingLevel.warning));
    }
  }

  /// Logs a info level log.
  void info(String message) {
    if (globalLevel.index >= LoggingLevel.info.index) {
      loggingFunction(
          new Log(message, tag, new DateTime.now(), LoggingLevel.info));
    }
  }

  /// Logs a fine level log.
  void fine(String message) {
    if (globalLevel.index >= LoggingLevel.fine.index) {
      loggingFunction(
          new Log(message, tag, new DateTime.now(), LoggingLevel.fine));
    }
  }
}

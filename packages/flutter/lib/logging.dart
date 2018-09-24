// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Flutter logging framework.
///
/// Logging in Flutter revolves around a familiar pattern of named logger objects
/// that correspond to specific systems or functional areas that, using a
/// traditional dot-separated namespace, can be further treated as hierarchical
/// by clients (tools such as IDEs).
///
/// From a client's perspective, named loggers correspond to "streams" of events
/// that tools can opt into by subscription via a VM service call.  Loggers with
/// no subscriptions do not produce any events. Common programming idioms can
/// make logging calls very low cost.
///
/// The structure of logger calls is designed to be familiar and compatible with
/// that of `package:logging`.  Behind the scenes, logged events are forwarded
/// to the logging facility of `dart.developer`.
///
/// A logger is created via constructor call:
///
/// ```dart
/// final Logger _xLogger = new Logger('functional.area.x');
/// ```
///
/// Messages are logged with method calls that correspond to
/// `package:logging` levels.  For example,
///
/// ```dart
/// _xLogger.info('X is starting...');
/// ```
///
/// produces a log event of [Level.INFO].
///
/// If no client is subscribed to its corresponding stream, logging calls are
/// ignored (and no event passed on to the `dart.developer` log function).  The
/// cost of logging calls can be further mitigated at call sites by invoking
/// them in a function that is only evaluated in profile or debug modes. For
/// example,
///
/// ```dart
/// profile(() {
///   _xLogger.info('X is starting...');
/// });
/// ```
///
/// In this case, logging is entirely ignored in release mode and no
/// performance penalty is paid.
///
/// Clients interact with the loggers via VM Services.  Specifically,
///
///   * 'loggers' : provides an enumeration of available loggers
///   * 'logger.subscribe' : supports logger subscriptions
///
/// See <https://github.com/dart-lang/logging> for more details on
/// `package:logging`.
///
/// See <https://api.dartlang.org/stable/2.0.0/dart-developer/log.html> for more
/// on the `log` function.
///
library logging;

import 'dart:developer' as developer;

import 'package:flutter/src/logging/logging.dart';
import 'package:logging/logging.dart';

/// A Logger object is used to log messages for specific systems or components.
class Logger {
  static int _sequenceNumber = 0;

  /// Logger name.
  final String name;

  /// Logger description.
  final String description;

  /// Singleton constructor. Calling `Logger(name)` returns the same
  /// actual instance whenever it is called with the same string name.
  factory Logger(String name, {String description}) =>
      _getOrRegisterLogger(name, description: description ?? '');

  Logger._(this.name, {this.description});

  static Logger _getOrRegisterLogger(String name, {String description}) =>
      LoggingService.instance.loggers.putIfAbsent(
          name, () => new Logger._(name, description: description));

  /// The fully qualified name of this logging stream.
  String get fullName => name;

  /// Log message at level [Level.CONFIG].
  void config(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.CONFIG, message, error, stackTrace);
  }

  /// Log message at level [Level.FINE].
  void fine(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.FINE, message, error, stackTrace);
  }

  /// Log message at level [Level.FINER].
  void finer(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.FINER, message, error, stackTrace);
  }

  /// Log message at level [Level.FINEST].
  void finest(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.FINER, message, error, stackTrace);
  }

  /// Log message at level [Level.INFO].
  void info(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.INFO, message, error, stackTrace);
  }

  /// Log [message] at the given [level] with optional [error] and [stackTrace].
  void log(Level level, dynamic message,
      [Object error, StackTrace stackTrace]) {
    assert(level != null);
    assert(message != null);
    // If there are no subscribers, don't report.
    if (!LoggingService.instance.hasSubscriptions(this)) {
      return;
    }

    if (message is Function) {
      message = message();
    }
    if (message is! String) {
      message = message.toString();
    }
    developer.log(
      message,
      level: level.value,
      error: error,
      sequenceNumber: _sequenceNumber++,
      name: fullName,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  /// Log message at level [Level.SEVERE].
  void severe(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.SEVERE, message, error, stackTrace);
  }

  /// Log message at level [Level.SHOUT].
  void shout(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.SEVERE, message, error, stackTrace);
  }

  /// Log message at level [Level.WARNING].
  void warning(dynamic message, [Object error, StackTrace stackTrace]) {
    log(Level.WARNING, message, error, stackTrace);
  }
}

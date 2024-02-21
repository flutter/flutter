// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show runZoned;
import 'dart:io' as io show
  IOSink,
  stderr,
  stdout;

import 'package:logging/logging.dart' as log;
import 'package:meta/meta.dart';

// This is where a flutter_tool style progress spinner, color output,
// ascii art, terminal control for clearing lines or the whole screen, etc.
// can go. We can just add more methods to Logger using the flutter_tool's
// Logger as a guide:
//
// https://github.com/flutter/flutter/blob/c530276f7806c77da2541c518a0e103c9bb44f10/packages/flutter_tools/lib/src/base/logger.dart#L422

/// A simplified wrapper around the [Logger] from package:logging.
///
/// The default log level is [Logger.status]. A --quiet flag might change it to
/// [Logger.warning] or [Logger.error]. A --verbose flag might change it to
/// [Logger.info].
///
/// Log messages at [Logger.warning] and higher will be written to stderr, and
/// to stdout otherwise. [Logger.test] records all log messages to a buffer,
/// which can be inspected by unit tetss.
class Logger {
  /// Constructs a logger for use in the tool.
  Logger() : _logger = log.Logger.detached('et') {
    _logger.level = statusLevel;
    _logger.onRecord.listen(_handler);
    _setupIoSink(io.stderr);
    _setupIoSink(io.stdout);
  }

  /// A logger for tests.
  @visibleForTesting
  Logger.test() : _logger = log.Logger.detached('et') {
    _logger.level = statusLevel;
    _logger.onRecord.listen((log.LogRecord r) => _testLogs.add(r));
  }

  /// The logging level for error messages. These go to stderr.
  static const log.Level errorLevel = log.Level('ERROR', 100);

  /// The logging level for warning messages. These go to stderr.
  static const log.Level warningLevel = log.Level('WARNING', 75);

  /// The logging level for normal status messages. These go to stdout.
  static const log.Level statusLevel = log.Level('STATUS', 25);

  /// The logging level for verbose informational messages. These go to stdout.
  static const log.Level infoLevel = log.Level('INFO', 10);

  static void _handler(log.LogRecord r) {
    final io.IOSink sink = r.level >= warningLevel ? io.stderr : io.stdout;
    final String prefix = r.level >= warningLevel
      ? '[${r.time}] ${r.level}: '
      : '';
    _ioSinkWrite(sink, '$prefix${r.message}');
  }

  // Status of the global io.stderr and io.stdout is shared across all
  // Logger instances.
  static bool _stdioDone = false;

  // stdout and stderr might already be closed, and when not already closed,
  // writing can still fail by throwing either a sync or async exception.
  // This function handles all three cases.
  static void _ioSinkWrite(io.IOSink sink, String message) {
    if (_stdioDone) {
      return;
    }
    runZoned<void>(() {
      try {
        sink.write(message);
      } catch (_) { // ignore: avoid_catches_without_on_clauses
        _stdioDone = true;
      }
    }, onError: (Object e, StackTrace s) {
      _stdioDone = true;
    });
  }

  static void _setupIoSink(io.IOSink sink) {
    sink.done.then(
      (void _) { _stdioDone = true; },
      onError: (Object err, StackTrace st) { _stdioDone = true; },
    );
  }

  final log.Logger _logger;
  final List<log.LogRecord> _testLogs = <log.LogRecord>[];

  /// Get the current logging level.
  log.Level get level => _logger.level;

  /// Set the current logging level.
  set level(log.Level l) {
    _logger.level = l;
  }

  /// Record a log message at level [Logger.error].
  void error(Object? message, {int indent = 0, bool newline = true}) {
    _emitLog(errorLevel, message, indent, newline);
  }

  /// Record a log message at level [Logger.warning].
  void warning(Object? message, {int indent = 0, bool newline = true}) {
    _emitLog(warningLevel, message, indent, newline);
  }

  /// Record a log message at level [Logger.warning].
  void status(Object? message, {int indent = 0, bool newline = true}) {
    _emitLog(statusLevel, message, indent, newline);
  }

  /// Record a log message at level [Logger.info].
  void info(Object? message, {int indent = 0, bool newline = true}) {
    _emitLog(infoLevel, message, indent, newline);
  }

  /// Writes a number of spaces to stdout equal to the width of the terminal
  /// and emits a carriage return.
  void clearLine() {
    if (!io.stdout.hasTerminal) {
      return;
    }
    final int width = io.stdout.terminalColumns;
    final String spaces = ' ' * width;
    _ioSinkWrite(io.stdout, '$spaces\r');
  }

  void _emitLog(log.Level level, Object? message, int indent, bool newline) {
    final String m = '${' ' * indent}$message${newline ? '\n' : ''}';
    _logger.log(level, m);
  }

  /// In a [Logger] constructed by [Logger.test], this list will contain all of
  /// the [LogRecord]s emitted by the test.
  @visibleForTesting
  List<log.LogRecord> get testLogs => _testLogs;
}

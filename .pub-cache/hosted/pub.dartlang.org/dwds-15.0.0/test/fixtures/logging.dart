// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

typedef LogWriter = void Function(Level level, String message,
    {String error, String loggerName, String stackTrace});

StreamSubscription<LogRecord> _loggerSub;

/// Redirect the logs for the current zone to emit on failure.
///
/// If [debug] is false, messages are stored and reported on test failure.
/// If [debug] is true, messages are always printed to the console.
///
/// Note that the logwriter uses [printOnFailure] that stores the messages
/// on the current zone. As a result, [setCurrentLogWriter] needs to be set
/// in both `setUpAll` and `setUp` to store messages for the same zone as the
/// failure in order to report all stored messages on that failure.
///
/// For example:
///
/// // Enable verbose logging for debugging.
/// bool debug = true;
///
/// group('shared context', () {
///     setUpAll(() async {
///       // Set the logger for the current group.
///       setCurrentLogWriter(debug: debug);
///       ...
///     });
///     setUp(() async {
///       // Reset the logger for the current test.
///       setCurrentLogWriter(debug: debug);
///       ...
///     });
///     ...
/// });
void setCurrentLogWriter({bool debug = false}) =>
    configureLogWriter(customLogWriter: createLogWriter(debug: debug));

/// Configure test log writer.
///
/// Tests and groups of tests can use this to configure individual
/// log writers on setup.
void configureLogWriter({LogWriter customLogWriter}) {
  _logWriter = customLogWriter ?? _logWriter;
  Logger.root.level = Level.ALL;
  _loggerSub?.cancel();
  _loggerSub = Logger.root.onRecord.listen((event) {
    logWriter(event.level, event.message,
        error: event.error?.toString(),
        loggerName: event.loggerName,
        stackTrace: event.stackTrace?.toString());
  });
}

void stopLogWriter() {
  _loggerSub?.cancel();
  _loggerSub = null;
}

LogWriter _logWriter = createLogWriter();

LogWriter createLogWriter({bool debug = false}) =>
    (level, message, {String error, String loggerName, String stackTrace}) {
      final printFn = debug ? print : printOnFailure;
      final errorMessage = error == null ? '' : ':\n$error';
      final stackMessage = stackTrace == null ? '' : ':\n$stackTrace';
      printFn('[$level] $loggerName: $message'
          '$errorMessage'
          '$stackMessage');
    };

LogWriter get logWriter => _logWriter;

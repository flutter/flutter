// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show stderr, FileSystemException;

/// Standard error thrown by Flutter Driver API.
class DriverError extends Error {
  /// Create an error with a [message] and (optionally) the [originalError] and
  /// [originalStackTrace] that caused it.
  DriverError(this.message, [this.originalError, this.originalStackTrace]);

  /// Human-readable error message.
  final String message;

  /// The error object that was caught and wrapped by this error object, if any.
  final Object? originalError;

  /// The stack trace that was caught and wrapped by this error object, if any.
  final Object? originalStackTrace;

  @override
  String toString() {
    if (originalError == null) {
      return 'DriverError: $message\n';
    }
    return '''
DriverError: $message
Original error: $originalError
Original stack trace:
$originalStackTrace
''';
  }
}

/// Signature for [driverLog].
///
/// The first argument is a string representing the source of the message,
/// typically the class name or library name calling the method.
///
/// The second argument is the message being logged.
typedef DriverLogCallback = void Function(String source, String message);

/// Print the given message to the console.
///
/// The first argument is a string representing the source of the message.
///
/// The second argument is the message being logged.
///
/// This can be set to a different callback to override the handling of log
/// messages from the driver subsystem.
///
/// The default implementation prints `"$source: $message"` to stderr.
DriverLogCallback driverLog = _defaultDriverLogger;

void _defaultDriverLogger(String source, String message) {
  try {
    stderr.writeln('$source: $message');
  } on FileSystemException {
    // May encounter IO error: https://github.com/flutter/flutter/issues/69314
  }
}

// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An exception that occurred during the analysis of one or more sources.
class AnalysisException implements Exception {
  /// The message that explains why the exception occurred.
  final String message;

  /// The exception that caused this exception, or `null` if this exception was
  /// not caused by another exception.
  final CaughtException? cause;

  /// Initialize a newly created exception to have the given [message] and
  /// [cause].
  AnalysisException([this.message = 'Exception', this.cause]);

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    buffer.write('$runtimeType: ');
    buffer.writeln(message);

    final cause = this.cause;
    if (cause != null) {
      buffer.write('Caused by ');
      cause._writeOn(buffer);
    }

    return buffer.toString();
  }
}

/// An exception that was caught and has an associated stack trace.
class CaughtException implements Exception {
  /// The exception that was caught.
  final Object exception;

  /// The message describing where/how/why this was caught.
  final String? message;

  /// The stack trace associated with the exception.
  StackTrace stackTrace;

  /// Initialize a newly created caught exception to have the given [exception]
  /// and [stackTrace].
  CaughtException(Object exception, StackTrace stackTrace)
      : this.withMessage(null, exception, stackTrace);

  /// Initialize a newly created caught exception to have the given [exception],
  /// [stackTrace], and [message].
  CaughtException.withMessage(this.message, this.exception, this.stackTrace);

  /// Recursively unwrap this [CaughtException] if it itself contains a
  /// [CaughtException].
  ///
  /// If it does not contain a [CaughtException], simply return this instance.
  CaughtException get rootCaughtException {
    if (exception is CaughtException) {
      return (exception as CaughtException).rootCaughtException;
    }
    return this;
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();
    _writeOn(buffer);
    return buffer.toString();
  }

  /// Write a textual representation of the caught exception and its associated
  /// stack trace.
  void _writeOn(StringBuffer buffer) {
    if (message != null) {
      buffer.writeln(message);
    }
    final exception = this.exception;
    if (exception is AnalysisException) {
      buffer.writeln(exception.message);
      buffer.writeln(stackTrace.toString());
      CaughtException? cause = exception.cause;
      if (cause != null) {
        buffer.write('Caused by ');
        cause._writeOn(buffer);
      }
    } else {
      buffer.writeln(exception.toString());
      buffer.writeln(stackTrace.toString());
    }
  }
}

/// A form of [CaughtException] that should be silent to users.
///
/// This is still considered an exceptional situation and will be sent to crash
/// reporting.
class SilentException extends CaughtException {
  SilentException(String super.message, super.exception, super.stackTrace)
      : super.withMessage();

  /// Create a [SilentException] to wrap a [CaughtException], adding a
  /// [message].
  SilentException.wrapInMessage(String message, CaughtException exception)
      : this(message, exception, StackTrace.current);
}

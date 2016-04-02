// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'print.dart';

/// Signature for [FlutterError.onException] handler.
typedef void FlutterExceptionHandler(FlutterErrorDetails details);

/// Signature for [FlutterErrorDetails.informationCollector] callback.
///
/// The text written to the information argument may contain newlines but should
/// not end with a newline.
typedef void FlutterInformationCollector(StringBuffer information);

/// Class for information provided to [FlutterExceptionHandler] callbacks.
///
/// See [FlutterError.onError].
class FlutterErrorDetails {
  /// Creates a [FlutterErrorDetails] object with the given arguments setting
  /// the object's properties.
  ///
  /// The framework calls this constructor when catching an exception that will
  /// subsequently be reported using [FlutterError.onError].
  const FlutterErrorDetails({
    this.exception,
    this.stack,
    this.library: 'Flutter framework',
    this.context,
    this.informationCollector,
    this.silent: false
  });

  /// The exception. Often this will be an [AssertionError], maybe specifically
  /// a [FlutterError]. However, this could be any value at all.
  final dynamic exception;

  /// The stack trace from where the [exception] was thrown (as opposed to where
  /// it was caught).
  ///
  /// StackTrace objects are opaque except for their [toString] function. A
  /// stack trace is not expected to be machine-readable.
  final StackTrace stack;

  /// A human-readable brief name describing the library that caught the error
  /// message. This is used by the default error handler in the header dumped to
  /// the console.
  final String library;

  /// A human-readable description of where the error was caught (as opposed to
  /// where it was thrown).
  final String context;

  /// A callback which, when invoked with a [StringBuffer] will write to that buffer
  /// information that could help with debugging the problem.
  ///
  /// Information collector callbacks can be expensive, so the generated information
  /// should be cached, rather than the callback being invoked multiple times.
  final FlutterInformationCollector informationCollector;

  /// Whether this error should be ignored by the default error reporting
  /// behavior in release mode.
  ///
  /// If this is false, the default, then the default error handler will always
  /// dump this error to the console.
  ///
  /// If this is true, then the default error handler would only dump this error
  /// to the console in checked mode. In release mode, the error is ignored.
  ///
  /// This is used by certain exception handlers that catch errors that could be
  /// triggered by environmental conditions (as opposed to logic errors). For
  /// example, the HTTP library sets this flag so as to not report every 404
  /// error to the console on end-user devices, while still allowing a custom
  /// error handler to see the errors even in release builds.
  final bool silent;
}

/// Error class used to report Flutter-specific assertion failures and
/// contract violations.
class FlutterError extends AssertionError {
  /// Creates a [FlutterError].
  ///
  /// See [message] for details on the format that the message should
  /// take.
  ///
  /// Include as much detail as possible in the full error message,
  /// including specifics about the state of the app that might be
  /// relevant to debugging the error.
  FlutterError(this.message);

  /// The message associated with this error.
  ///
  /// The message may have newlines in it. The first line should be a terse
  /// description of the error, e.g. "Incorrect GlobalKey usage" or "setState()
  /// or markNeedsBuild() called during build". Subsequent lines should contain
  /// substantial additional information, ideally sufficient to develop a
  /// correct solution to the problem.
  ///
  /// In some cases, when a FlutterError is reported to the user, only the first
  /// line is included. For example, Flutter will typically only fully report
  /// the first exception at runtime, displaying only the first line of
  /// subsequent errors.
  ///
  /// All sentences in the error should be correctly punctuated (i.e.,
  /// do end the error message with a period).
  final String message;

  @override
  String toString() => message;

  /// Called whenever the Flutter framework catches an error.
  ///
  /// The default behavior is to invoke [dumpErrorToConsole].
  ///
  /// You can set this to your own function to override this default behavior.
  /// For example, you could report all errors to your server.
  ///
  /// If the error handler throws an exception, it will not be caught by the
  /// Flutter framework.
  ///
  /// Set this to null to silently catch and ignore errors. This is not
  /// recommended.
  static FlutterExceptionHandler onError = dumpErrorToConsole;

  static int _errorCount = 0;

  /// Prints the given exception details to the console.
  ///
  /// The first time this is called, it dumps a very verbose message to the
  /// console using [debugPrint].
  ///
  /// Subsequent calls only dump the first line of the exception.
  ///
  /// This is the default behavior for the [onError] handler.
  static void dumpErrorToConsole(FlutterErrorDetails details) {
    assert(details != null);
    assert(details.exception != null);
    bool reportError = !details.silent;
    assert(() {
      // In checked mode, we ignore the "silent" flag.
      reportError = true;
      return true;
    });
    if (!reportError)
      return;
    if (_errorCount == 0) {
      final String header = '-- EXCEPTION CAUGHT BY ${details.library} '.toUpperCase();
      const String footer = '------------------------------------------------------------------------';
      debugPrint('$header${"-" * (footer.length - header.length)}');
      debugPrint('The following exception was raised${ details.context != null ? " ${details.context}" : ""}:');
      debugPrint('${details.exception}');
      if (details.informationCollector != null) {
        StringBuffer information = new StringBuffer();
        details.informationCollector(information);
        debugPrint(information.toString());
      }
      if (details.stack != null) {
        debugPrint('Stack trace:');
        debugPrint('${details.stack}$footer');
      } else {
        debugPrint(footer);
      }
    } else {
      debugPrint('Another exception was raised: ${details.exception.toString().split("\n")[0]}');
    }
    _errorCount += 1;
  }

  /// Calls [onError] with the given details, unless it is null.
  static void reportError(FlutterErrorDetails details) {
    assert(details != null);
    assert(details.exception != null);
    if (onError != null)
      onError(details);
  }
}

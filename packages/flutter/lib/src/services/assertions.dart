// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  /// The message may have newlines in it. The first line should be a
  /// terse description of the error, e.g. "Incorrect GlobalKey usage"
  /// or "setState() or markNeedsBuild() called during build".
  /// Subsequent lines can then contain more information. In some
  /// cases, when a FlutterError is reported to the user, only the
  /// first line is included. For example, Flutter will typically only
  /// fully report the first exception at runtime, displaying only the
  /// first line of subsequent errors.
  ///
  /// All sentences in the error should be correctly punctuated (i.e.,
  /// do end the error message with a period).
  final String message;

  @override
  String toString() => message;
}

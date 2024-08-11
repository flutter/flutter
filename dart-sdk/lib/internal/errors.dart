// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._internal;

/// Error thrown when a `late` variable is accessed inappropriately.
class LateError extends Error {
  final String? _message;

  LateError([this._message]);

  // The constructor names have been deliberately shortened to reduce the size
  // of unminified code as used by DDC.

  /// Variable written while evaluating its initializer expression.
  @pragma("vm:entry-point")
  LateError.fieldADI(String fieldName)
      : _message =
            "Field '$fieldName' has been assigned during initialization.";

  /// Local variable written while evaluating its initializer expression.
  LateError.localADI(String localName)
      : _message =
            "Local '$localName' has been assigned during initialization.";

  /// Variable read before it was initialized.
  @pragma("vm:entry-point")
  LateError.fieldNI(String fieldName)
      : _message = "Field '${fieldName}' has not been initialized.";

  /// Local variable read before it was initialized.
  LateError.localNI(String localName)
      : _message = "Local '${localName}' has not been initialized.";

  /// Final variable written more than once.
  LateError.fieldAI(String fieldName)
      : _message = "Field '${fieldName}' has already been initialized.";

  /// Final local variable written more than once.
  LateError.localAI(String localName)
      : _message = "Local '${localName}' has already been initialized.";

  String toString() {
    var message = _message;
    return (message != null)
        ? "LateInitializationError: $message"
        : "LateInitializationError";
  }
}

/// Error thrown when unsoundness causes flow analysis to be incorrect.
///
/// A switch on an enum type is considered exhaustive if it covers all
/// the enum values. If run in unsound null-safety mode, the value
/// can also be `null`. If so, a `ReachabilityError` is thrown rather
/// than allowing the switch to be inexhaustive.
///
/// This is not a public facing error. It should not happen in sound
/// programs.
class ReachabilityError extends Error {
  final String? _message;

  ReachabilityError([this._message]);

  String toString() {
    var message = _message;
    return (message != null)
        ? "ReachabilityError: $message"
        : "ReachabilityError";
  }
}

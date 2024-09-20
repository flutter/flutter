// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An interface implemented by all stack trace objects.
///
/// A [StackTrace] is intended to convey information to the user about the call
/// sequence that triggered an exception.
///
/// These objects are created by the runtime, it is not possible to create
/// them programmatically.
abstract interface class StackTrace {
  /// A stack trace object with no information.
  ///
  /// This stack trace is used as the default in situations where
  /// a stack trace is required, but the user has not supplied one.
  @Since("2.8")
  static const empty = const _StringStackTrace("");

  StackTrace(); // In case existing classes extend StackTrace.

  /// Create a `StackTrace` object from [stackTraceString].
  ///
  /// The created stack trace will have a `toString` method returning
  /// `stackTraceString`.
  ///
  /// The `stackTraceString` can be a string returned by some other
  /// stack trace, or it can be any string at all.
  /// If the string doesn't look like a stack trace, code that interprets
  /// stack traces is likely to fail, so fake stack traces should be used
  /// with care.
  factory StackTrace.fromString(String stackTraceString) = _StringStackTrace;

  /// Returns a representation of the current stack trace.
  ///
  /// This is similar to what can be achieved by doing:
  /// ```dart
  /// try { throw 0; } catch (_, stack) { return stack; }
  /// ```
  /// The getter achieves this without throwing if possible.
  external static StackTrace get current;

  /// Returns a [String] representation of the stack trace.
  ///
  /// The string represents the full stack trace starting from
  /// the point where a throw occurred to the top of the current call sequence.
  ///
  /// The exact format of the string representation is not final.
  String toString();
}

class _StringStackTrace implements StackTrace {
  final String _stackTrace;
  const _StringStackTrace(this._stackTrace);
  String toString() => _stackTrace;
}

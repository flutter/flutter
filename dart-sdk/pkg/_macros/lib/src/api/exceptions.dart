// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// Exception for use in macro implementations.
///
/// Throw to stop the current macro execution and report a [Diagnostic].
class DiagnosticException implements Exception {
  final Diagnostic diagnostic;
  DiagnosticException(this.diagnostic);
}

/// Base class for exceptions thrown by the host implementation during macro
/// execution.
///
/// Macro implementations can catch these exceptions to provide more
/// information to the user. In case an exception results from user error, they
/// can provide a pointer to the likely fix. If the exception results from an
/// implementation error or unknown error, the macro implementation might give
/// the user information on where and how to file an issue.
///
/// If a `MacroException` is not caught by a macro implementation then it will
/// be reported in a user-oriented way, for example for
/// `MacroImplementationException` the displayed message suggests that there
/// is a bug in the macro implementation.
abstract interface class MacroException implements Exception {
  String get message;
  String? get stackTrace;
}

/// Something unexpected happened during macro execution.
///
/// For example, a bug in the SDK.
abstract interface class UnexpectedMacroException implements MacroException {}

/// An error due to incorrect implementation was thrown during macro execution.
///
/// For example, an incorrect argument was passed to the macro API.
///
/// The type `Error` is usually used for such throwables, and it's common to
/// allow the program to crash when one is thrown.
///
/// In the case of macros, however, type `Exception` is used because the macro
/// implementation can usefully catch it in order to give the user information
/// about how to notify the macro author about the bug.
abstract interface class MacroImplementationException
    implements MacroException {}

/// A cycle was detected in macro applications introspecting targets of other
/// macro applications.
///
/// The order the macros should run in is not defined, so allowing
/// introspection in this case would make the macro output non-deterministic.
/// Instead, all the introspection calls in the cycle fail with this exception.
abstract interface class MacroIntrospectionCycleException
    implements MacroException {}

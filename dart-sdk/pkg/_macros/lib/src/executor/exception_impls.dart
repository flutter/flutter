// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import 'remote_instance.dart';
import 'serialization.dart';

/// Base class for exceptions thrown during macro execution.
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
abstract base class MacroExceptionImpl extends RemoteInstance
    implements MacroException {
  @override
  final String message;
  @override
  final String? stackTrace;

  MacroExceptionImpl._({int? id, required this.message, this.stackTrace})
      : super(id ?? RemoteInstance.uniqueId);

  factory MacroExceptionImpl(
      {required int id,
      required RemoteInstanceKind kind,
      required String message,
      String? stackTrace}) {
    switch (kind) {
      case RemoteInstanceKind.unexpectedMacroException:
        return UnexpectedMacroExceptionImpl(message,
            id: id, stackTrace: stackTrace);
      case RemoteInstanceKind.macroImplementationException:
        return MacroImplementationExceptionImpl(message,
            id: id, stackTrace: stackTrace);
      case RemoteInstanceKind.macroIntrospectionCycleException:
        return MacroIntrospectionCycleExceptionImpl(message,
            id: id, stackTrace: stackTrace);

      default:
        throw ArgumentError.value(kind, 'kind');
    }
  }

  /// Instantiates from a throwable caught during macro execution.
  ///
  /// If [throwable] is already a subclass of `MacroException`, return it.
  /// Otherwise it's an unexpected type, return an [UnexpectedMacroException].
  factory MacroExceptionImpl.from(Object throwable, StackTrace stackTrace) {
    if (throwable is MacroExceptionImpl) return throwable;
    return UnexpectedMacroExceptionImpl(throwable.toString(),
        stackTrace: stackTrace.toString());
  }

  @override
  String toString() => '$message${stackTrace == null ? '' : '\n\n$stackTrace'}';

  @override
  void serializeUncached(Serializer serializer) {
    super.serializeUncached(serializer);
    serializer.addString(message);
    serializer.addNullableString(stackTrace);
  }
}

/// Something unexpected happened during macro execution.
///
/// For example, a bug in the SDK.
final class UnexpectedMacroExceptionImpl extends MacroExceptionImpl
    implements UnexpectedMacroException {
  UnexpectedMacroExceptionImpl(String message, {super.id, super.stackTrace})
      : super._(message: message);

  @override
  RemoteInstanceKind get kind => RemoteInstanceKind.unexpectedMacroException;

  @override
  String toString() => 'UnexpectedMacroException: ${super.toString()}';
}

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
final class MacroImplementationExceptionImpl extends MacroExceptionImpl
    implements MacroImplementationException {
  MacroImplementationExceptionImpl(String message, {super.id, super.stackTrace})
      : super._(message: message);

  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.macroImplementationException;

  @override
  String toString() => 'MacroImplementationException: ${super.toString()}';
}

/// A cycle was detected in macro applications introspecting targets of other
/// macro applications.
///
/// The order the macros should run in is not defined, so allowing
/// introspection in this case would make the macro output non-deterministic.
/// Instead, all the introspection calls in the cycle fail with this exception.
base class MacroIntrospectionCycleExceptionImpl extends MacroExceptionImpl
    implements MacroIntrospectionCycleException {
  MacroIntrospectionCycleExceptionImpl(String message,
      {super.id, super.stackTrace})
      : super._(message: message);

  @override
  RemoteInstanceKind get kind =>
      RemoteInstanceKind.macroIntrospectionCycleException;

  @override
  String toString() => 'MacroIntrospectionCycleException: ${super.toString()}';
}

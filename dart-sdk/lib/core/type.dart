// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Runtime representation of a type.
///
/// Type objects represent types.
/// A type object can be created in several ways:
/// * By a *type literal*, a type name occurring as an expression,
///   like `Type type = int;`,
///   or a type variable occurring as an expression, like `Type type = T;`.
/// * By reading the run-time type of an object,
///   like `Type type = o.runtimeType;`.
/// * Through `dart:mirrors`.
///
/// A type object is intended as an entry point for using `dart:mirrors`.
/// The only operations supported are comparing to other type objects
/// for equality, and converting it to a string for debugging.
abstract interface class Type {
  /// A hash code for the type which is compatible with [operator==].
  int get hashCode;

  /// Whether [other] is a [Type] instance representing an equivalent type.
  ///
  /// The language specification dictates which types are considered
  /// to be the equivalent.
  /// If two types are equivalent, it's guaranteed that they are subtypes
  /// of each other,
  /// but there are also types which are subtypes of each other,
  /// and which are not equivalent (for example `dynamic` and `void`,
  /// or `FutureOr<Object>` and `Object`).
  bool operator ==(Object other);

  /// Returns a string which represents the underlying type.
  ///
  /// The string is only intended for providing information to a reader
  /// while debugging.
  /// There is no guaranteed format,
  /// the string value returned for a [Type] instances is entirely
  /// implementation dependent.
  ///
  /// The string should be consistent, so a `Type` object for the *same* type
  /// returns the same string throughout a program execution.
  /// The string may or may not contain parts corresponding to the
  /// source name of declaration of the type, if the type has a source name
  /// at all (some types reachable through `dart:mirrors` may not).
  String toString();
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// The reserved word `null` denotes an object that is the sole instance of
/// this class.
///
/// The `Null` class is the only class which does not implement `Object`.
/// It is a compile-time error for a class to attempt to extend or implement
/// [Null].
///
/// The language contains a number of specialized operators for working with
/// `null` value. Examples:
/// ```dart
/// e1!       // Throws if e1 is null.
/// e2 ?? e3  // Same as e2, unless e2 is null, then use value of e3
/// x ??= e4  // Same as x unless x is null, then same as `x = e4`.
/// e5?.foo() // call `foo` on e5, unless e5 is null.
/// [...? e6] // spreads e6 into the list literal, unless e6 is null.
/// ```
@pragma("vm:entry-point")
final class Null {
  factory Null._uninstantiable() {
    throw UnsupportedError('class Null cannot be instantiated');
  }

  external int get hashCode;

  /// Returns the string `"null"`.
  String toString() => "null";
}

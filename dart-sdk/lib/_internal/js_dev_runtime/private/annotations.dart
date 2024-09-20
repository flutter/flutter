// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

/// Tells the optimizing compiler to always inline the annotated method.
class ForceInline {
  const ForceInline();
}

class _NotNull {
  const _NotNull();
}

/// Marks a variable or API to be non-nullable.
/// ****CAUTION******
/// This is currently unchecked, and hence should never be used
/// on any public interface where user code could subclass, implement,
/// or otherwise cause the contract to be violated.
/// TODO(leafp): Consider adding static checking and exposing
/// this to user code.
const notNull = _NotNull();

/// Marks a generic function or static method API to be not reified.
/// ****CAUTION******
/// This is currently unchecked, and hence should be used very carefully for
/// internal SDK APIs only.
class NoReifyGeneric {
  const NoReifyGeneric();
}

/// Enables/disables reification of functions within the body of this function.
/// ****CAUTION******
/// This is currently unchecked, and hence should be used very carefully for
/// internal SDK APIs only.
class ReifyFunctionTypes {
  final bool value;
  const ReifyFunctionTypes(this.value);
}

class _NullCheck {
  const _NullCheck();
}

/// Annotation indicating the parameter should default to the JavaScript
/// undefined constant.
const undefined = _Undefined();

class _Undefined {
  const _Undefined();
}

/// Tells the development compiler to check a variable for null at its
/// declaration point, and then to assume that the variable is non-null
/// from that point forward.
/// ****CAUTION******
/// This is currently unchecked, and hence will not catch re-assignments
/// of a variable with null
const nullCheck = _NullCheck();

/// Marks a class as native and defines its JavaScript name(s).
class Native {
  final String name;
  const Native(this.name);
}

class JsPeerInterface {
  /// The JavaScript type that we should match the API of.
  /// Used for classes where Dart subclasses should be callable from JavaScript
  /// matching the JavaScript calling conventions.
  final String name;
  const JsPeerInterface({required this.name});
}

/// A Dart interface may only be implemented by a native JavaScript object
/// if it is marked with this annotation.
class SupportJsExtensionMethods {
  const SupportJsExtensionMethods();
}

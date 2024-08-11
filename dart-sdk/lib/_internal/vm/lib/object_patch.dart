// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:exact-result-type", "dart:core#_Smi")
@pragma("vm:external-name", "Object_getHash")
external int _getHash(obj);

@patch
@pragma("vm:entry-point")
class Object {
  // The VM has its own implementation of equals.
  @patch
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "Object_equals")
  external bool operator ==(Object other);

  @patch
  int get hashCode => _getHash(this);
  int get _identityHashCode => _getHash(this);

  @patch
  @pragma("vm:external-name", "Object_toString")
  external String toString();
  // A statically dispatched version of Object.toString.
  @pragma("vm:external-name", "Object_toString")
  external static String _toString(obj);

  @patch
  @pragma("vm:entry-point", "call")
  dynamic noSuchMethod(Invocation invocation) {
    // TODO(regis): Remove temp constructor identifier 'withInvocation'.
    throw new NoSuchMethodError.withInvocation(this, invocation);
  }

  @patch
  @pragma("vm:recognized", "asm-intrinsic")
  // Result type is either "dart:core#_Type" or "dart:core#_FunctionType".
  @pragma("vm:external-name", "Object_runtimeType")
  external Type get runtimeType;

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:entry-point", "call")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Object_haveSameRuntimeType")
  external static bool _haveSameRuntimeType(a, b);

  // Call this function instead of inlining instanceof, thus collecting
  // type feedback and reducing code size of unoptimized code.
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "Object_instanceOf")
  external bool _instanceOf(
      instantiatorTypeArguments, functionTypeArguments, type);

  // Group of functions for implementing fast simple instance of.
  @pragma("vm:entry-point", "call")
  @pragma("vm:external-name", "Object_simpleInstanceOf")
  external bool _simpleInstanceOf(type);
  @pragma("vm:entry-point", "call")
  bool _simpleInstanceOfTrue(type) => true;
  @pragma("vm:entry-point", "call")
  bool _simpleInstanceOfFalse(type) => false;
}

// Used by DartLibraryCalls::Equals.
@pragma("vm:entry-point", "call")
bool _objectEquals(Object? o1, Object? o2) => o1 == o2;

// Used by DartLibraryCalls::HashCode.
@pragma("vm:entry-point", "call")
int _objectHashCode(Object? obj) => obj.hashCode;

// Used by DartLibraryCalls::ToString.
@pragma("vm:entry-point", "call")
String _objectToString(Object? obj) => obj.toString();

// Used by DartEntry::InvokeNoSuchMethod.
@pragma("vm:entry-point", "call")
dynamic _objectNoSuchMethod(Object? obj, Invocation invocation) =>
    obj.noSuchMethod(invocation);

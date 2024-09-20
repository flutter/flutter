// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class Object {
  @patch
  external bool operator ==(Object other);

  // Random number generator used to generate identity hash codes.
  static final _hashCodeRnd = new Random();

  static int _objectHashCode(Object obj) {
    var result = getIdentityHashField(obj);
    if (result == 0) {
      // We want the hash to be a Smi value greater than 0.
      do {
        result = _hashCodeRnd.nextInt(0x40000000);
      } while (result == 0);

      setIdentityHashField(obj, result);
      return result;
    }
    return result;
  }

  @patch
  int get hashCode => _objectHashCode(this);

  /// Concrete subclasses of [Object] will have overrides of [_typeArguments]
  /// which return their type arguments.
  WasmArray<_Type> get _typeArguments => const WasmArray<_Type>.literal([]);

  // An instance member needs a call from Dart code to be properly included in
  // the dispatch table. Hence we use an inlined static wrapper as entry point.
  @pragma("wasm:entry-point")
  @pragma("wasm:prefer-inline")
  static WasmArray<_Type> _getTypeArguments(Object object) =>
      object._typeArguments;

  @patch
  external Type get runtimeType;

  @patch
  String toString() => _toString(this);
  // A statically dispatched version of Object.toString.
  static String _toString(Object obj) {
    return "Instance of '${_getMasqueradedRuntimeType(obj)}'";
  }

  @patch
  @pragma("wasm:entry-point")
  dynamic noSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError.withInvocation(this, invocation);
  }

  // Used for `null.toString` tear-offs.
  @pragma("wasm:entry-point")
  static String _nullToString() => "null";

  // Used for `null.noSuchMethod` tear-offs.
  @pragma("wasm:entry-point")
  static dynamic _nullNoSuchMethod(Invocation invocation) {
    throw new NoSuchMethodError.withInvocation(null, invocation);
  }
}

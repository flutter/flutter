// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=10
// VMOptions=--use-slow-path
// SharedObjects=ffi_test_functions
//
// This file tests subtyping relationships (at compile time and at runtime) of
// parameters and return types of ffi trampolines and ffi callback trampolines.

import 'dart:ffi';

import 'dylib_utils.dart';

import "expect.dart";
import "package:ffi/ffi.dart";

typedef Int64PointerParamOpDart = void Function(Pointer<Int64>);
typedef Int64PointerParamOp = Void Function(Pointer<Int64>);
typedef NaTyPointerParamOpDart = void Function(Pointer<NativeType>);
typedef NaTyPointerParamOp = Void Function(Pointer<NativeType>);
typedef Int64PointerReturnOp = Pointer<Int64> Function();
typedef NaTyPointerReturnOp = Pointer<NativeType> Function();

final paramOpName = "NativeTypePointerParam";
final returnOpName = "NativeTypePointerReturn";

final DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

// =============================================
// Tests calls from Dart to native (asFunction).
// =============================================

void paramInvariant1() {
  final fp =
      ffiTestFunctions.lookup<NativeFunction<Int64PointerParamOp>>(paramOpName);
  final f = fp.asFunction<Int64PointerParamOpDart>();
  final arg = allocate<Int64>();
  f(arg);
  free(arg);
}

void paramInvariant2() {
  final fp =
      ffiTestFunctions.lookup<NativeFunction<NaTyPointerParamOp>>(paramOpName);
  final f = fp.asFunction<NaTyPointerParamOpDart>();
  final arg = allocate<Int64>().cast<NativeType>();
  Expect.type<Pointer<NativeType>>(arg);
  f(arg);
  free(arg);
}

// Pass a statically and dynamically subtyped argument.
void paramSubtype1() {
  final fp =
      ffiTestFunctions.lookup<NativeFunction<NaTyPointerParamOp>>(paramOpName);
  final f = fp.asFunction<NaTyPointerParamOpDart>();
  final arg = allocate<Int64>();
  Expect.type<Pointer<Int64>>(arg);
  f(arg);
  free(arg);
}

// Pass a statically subtyped but dynamically invariant argument.
void paramSubtype2() {
  final fp =
      ffiTestFunctions.lookup<NativeFunction<NaTyPointerParamOp>>(paramOpName);
  final f = fp.asFunction<NaTyPointerParamOpDart>();
  final Pointer<NativeType> arg = allocate<Int64>();
  Expect.type<Pointer<Int64>>(arg);
  f(arg);
  free(arg);
}

void returnInvariant1() {
  final fp = ffiTestFunctions
      .lookup<NativeFunction<Int64PointerReturnOp>>(returnOpName);
  final f = fp.asFunction<Int64PointerReturnOp>();
  final result = f();
  Expect.type<Pointer<Int64>>(result);
}

void returnInvariant2() {
  final fp = ffiTestFunctions
      .lookup<NativeFunction<NaTyPointerReturnOp>>(returnOpName);
  final f = fp.asFunction<NaTyPointerReturnOp>();
  final result = f();
  Expect.type<Pointer<NativeType>>(result);
}

void returnSubtype() {
  final fp = ffiTestFunctions
      .lookup<NativeFunction<Int64PointerReturnOp>>(returnOpName);
  final f = fp.asFunction<Int64PointerReturnOp>();
  final NaTyPointerReturnOp f2 = f;
  Expect.type<Int64PointerReturnOp>(f2);
  final result = f2();
  Expect.type<Pointer<NativeType>>(result);
}

void functionArgumentVariance() {
  final p = Pointer<
      NativeFunction<
          Pointer<NativeFunction<Pointer<Int8> Function(Pointer<NativeType>)>> Function(
              Pointer<
                  NativeFunction<
                      Pointer<NativeType> Function(
                          Pointer<Int8>)>>)>>.fromAddress(0x1234);
  final f = p.asFunction<
      Pointer<NativeFunction<Pointer<NativeType> Function(Pointer<Int8>)>> Function(
          Pointer<
              NativeFunction<Pointer<Int8> Function(Pointer<NativeType>)>>)>();
}

void asFunctionTests() {
  for (int i = 0; i < 100; ++i) {
    paramInvariant1(); // Parameter invariant: Pointer<Int64>.
    paramInvariant2(); // Parameter invariant: Pointer<NativeType>.
    paramSubtype1(); // Parameter statically and dynamically subtyped.
    paramSubtype2(); // Parameter statically invariant, dynamically subtyped.
    returnInvariant1(); // Return value invariant: Pointer<Int64>.
    returnInvariant2(); // Return value invariant: Pointer<NativeType>.
    returnSubtype(); // Return value static subtyped, dynamically invariant.
    functionArgumentVariance(); // Check nested function signatures.
  }
}

// =======================================================
// Test with callbacks from native to Dart (fromFunction).
// =======================================================

typedef CallbackInt64PointerParamOpDart = void Function(
    Pointer<NativeFunction<Int64PointerParamOp>>);
typedef CallbackInt64PointerParamOp = Void Function(
    Pointer<NativeFunction<Int64PointerParamOp>>);

typedef CallbackNaTyPointerParamOpDart = void Function(
    Pointer<NativeFunction<NaTyPointerParamOp>>);
typedef CallbackNaTyPointerParamOp = Void Function(
    Pointer<NativeFunction<NaTyPointerParamOp>>);

typedef CallbackInt64PointerReturnOpDart = void Function(
    Pointer<NativeFunction<Int64PointerReturnOp>>);
typedef CallbackInt64PointerReturnOp = Void Function(
    Pointer<NativeFunction<Int64PointerReturnOp>>);

typedef CallbackNaTyPointerReturnOpDart = void Function(
    Pointer<NativeFunction<NaTyPointerReturnOp>>);
typedef CallbackNaTyPointerReturnOp = Void Function(
    Pointer<NativeFunction<NaTyPointerReturnOp>>);

final callbackParamOpName = "CallbackNativeTypePointerParam";
final callbackReturnOpName = "CallbackNativeTypePointerReturn";

void int64PointerParamOp(Pointer<Int64> p) {
  p.value = 42;
}

void naTyPointerParamOp(Pointer<NativeType> p) {
  final Pointer<Int8> asInt8 = p.cast();
  asInt8.value = 42;
}

// Pointer to return to C when C calls back into Dart and asks for a Pointer.
Pointer<Int64> data;

Pointer<Int64> int64PointerReturnOp() {
  return data;
}

Pointer<NativeType> naTyPointerReturnOp() {
  return data;
}

void callbackParamInvariant1() {
  final callback = ffiTestFunctions.lookupFunction<CallbackInt64PointerParamOp,
      CallbackInt64PointerParamOpDart>(callbackParamOpName);
  final fp = Pointer.fromFunction<Int64PointerParamOp>(int64PointerParamOp);
  callback(fp);
}

void callbackParamInvariant2() {
  final callback = ffiTestFunctions.lookupFunction<CallbackNaTyPointerParamOp,
      CallbackNaTyPointerParamOpDart>(callbackParamOpName);
  final fp = Pointer.fromFunction<NaTyPointerParamOp>(naTyPointerParamOp);
  callback(fp);
}

void callbackParamImplictDowncast1() {
  final callback = ffiTestFunctions.lookupFunction<CallbackNaTyPointerParamOp,
      CallbackNaTyPointerParamOpDart>(callbackParamOpName);
  final fp = Pointer.fromFunction<Int64PointerParamOp>(int64PointerParamOp);
  Expect.throws(() {
    callback(fp);
  });
}

void callbackParamSubtype1() {
  final callback = ffiTestFunctions.lookupFunction<CallbackNaTyPointerParamOp,
      CallbackNaTyPointerParamOpDart>(callbackParamOpName);
  final fp = Pointer.fromFunction<NaTyPointerParamOp>(int64PointerParamOp);
  callback(fp);
}

void callbackReturnInvariant1() {
  final callback = ffiTestFunctions.lookupFunction<CallbackInt64PointerReturnOp,
      CallbackInt64PointerReturnOpDart>(callbackReturnOpName);
  final fp = Pointer.fromFunction<Int64PointerReturnOp>(int64PointerReturnOp);
  callback(fp);
}

void callbackReturnInvariant2() {
  final callback = ffiTestFunctions.lookupFunction<CallbackNaTyPointerReturnOp,
      CallbackNaTyPointerReturnOpDart>(callbackReturnOpName);
  final fp = Pointer.fromFunction<NaTyPointerReturnOp>(naTyPointerReturnOp);
  callback(fp);
}

void fromFunctionTests() {
  data = allocate();
  for (int i = 0; i < 100; ++i) {
    callbackParamInvariant1(); // Pointer<Int64> invariant
    callbackParamInvariant2(); // Pointer<NativeType> invariant
    callbackParamImplictDowncast1(); // static and dynamically supertyped
    callbackParamSubtype1(); // static and dynamically subtyped
    callbackReturnInvariant1(); // Pointer<Int64> invariant
    callbackReturnInvariant2(); // Pointer<NativeType> invariant
  }
  free(data);
}

void main() {
  asFunctionTests();
  fromFunctionTests();
}

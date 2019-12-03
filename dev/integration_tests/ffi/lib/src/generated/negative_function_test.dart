// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error handling with dart:ffi functions.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi' as ffi;
import 'dylib_utils.dart';
import "expect.dart";

main() {
  testWrongArity();
  testWrongTypes();
  testDynamicAsFunction();
  testDynamicLookupFunction();
}

ffi.DynamicLibrary ffiTestFunctions =
    dlopenPlatformSpecific("ffi_test_functions");

typedef NativeBinaryOp = ffi.Int32 Function(ffi.Int32, ffi.Int32);
typedef BinaryOp = int Function(int, int);

typedef NativeUnaryOp = ffi.Int64 Function(ffi.Pointer<ffi.Int64>);
typedef UnaryOp = int Function(ffi.Pointer<ffi.Int64>);

void testWrongArity() {
  {
    dynamic sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");
    Expect.throwsNoSuchMethodError(() => sumPlus42(10));
    Expect.throwsNoSuchMethodError(() => sumPlus42(10, 11, 12));
    Expect.throwsNoSuchMethodError(() => sumPlus42(10, 11, 12, y: 13));
  }

  {
    Function sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");
    Expect.throwsNoSuchMethodError(() => sumPlus42(10));
    Expect.throwsNoSuchMethodError(() => sumPlus42(10, 11, 12));
    Expect.throwsNoSuchMethodError(() => sumPlus42(10, 11, 12, y: 13));
  }
}

void testWrongTypes() {
  {
    dynamic sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");
    Expect.throwsTypeError(() => sumPlus42("abc", "def"));
  }

  {
    Function sumPlus42 =
        ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");
    Expect.throwsTypeError(() => sumPlus42("abc", "def"));
  }

  {
    dynamic pointerOp = ffiTestFunctions
        .lookupFunction<NativeUnaryOp, UnaryOp>("Assign1337Index1");
    Expect.throwsTypeError(() => pointerOp(0));
  }
}

// Test that invoking 'Pointer.asFunction' with a dynamic receiver type throws
// an exception.
void testDynamicAsFunction() {
  dynamic x = ffi.nullptr.cast<ffi.NativeFunction<ffi.Void Function()>>();
  Expect.throwsNoSuchMethodError(() {
    x.asFunction<void Function()>();
  });
}

// Test that invoking 'DynamicLibrary.lookupFunction' with a dynamic receiver
// type throws an exception.
void testDynamicLookupFunction() {
  dynamic lib = ffiTestFunctions;
  Expect.throwsNoSuchMethodError(() {
    lib.lookupFunction<ffi.Void Function(), void Function()>("_");
  });
}

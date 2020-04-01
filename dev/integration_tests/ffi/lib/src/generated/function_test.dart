// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers.
//
// VMOptions=
// VMOptions=--deterministic --optimization-counter-threshold=10
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--write-protect-code --no-dual-map-code
// VMOptions=--write-protect-code --no-dual-map-code --use-slow-path
// VMOptions=--write-protect-code --no-dual-map-code --stacktrace-every=100
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

import "package:ffi/ffi.dart";
import "expect.dart";

void main() {
  for (int i = 0; i < 100; ++i) {
    testNativeFunctionFromCast();
    testNativeFunctionFromLookup();
    test64bitInterpretations();
    testExtension();
    testTruncation();
    testNativeFunctionDoubles();
    testNativeFunctionFloats();
    testNativeFunctionManyArguments1();
    testNativeFunctionManyArguments2();
    testNativeFunctionManyArguments3();
    testNativeFunctionManyArguments4();
    testNativeFunctionManyArguments5();
    testNativeFunctionPointer();
    testNullPointers();
    testFloatRounding();
    testVoidReturn();
    testNoArgs();
  }
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef NativeBinaryOp = Int32 Function(Int32, Int32);
typedef UnaryOp = int Function(int);
typedef BinaryOp = int Function(int, int);
typedef GenericBinaryOp<T> = int Function(int, T);

void testNativeFunctionFromCast() {
  Pointer<IntPtr> p1 = allocate();
  Pointer<NativeFunction<NativeBinaryOp>> p2 = p1.cast();
  p2.asFunction<BinaryOp>();
  p2.asFunction<GenericBinaryOp<int>>();
  free(p1);
}

typedef NativeQuadOpSigned = Int64 Function(Int8, Int16, Int32, Int64);
typedef QuadOp = int Function(int, int, int, int);
typedef NativeQuadOpUnsigned = Uint64 Function(Uint8, Uint16, Uint32, Uint64);

BinaryOp sumPlus42 =
    ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

QuadOp intComputation = ffiTestFunctions
    .lookupFunction<NativeQuadOpSigned, QuadOp>("IntComputation");

void testNativeFunctionFromLookup() {
  Expect.equals(49, sumPlus42(3, 4));

  Expect.equals(625, intComputation(125, 250, 500, 1000));

  Expect.equals(
      0x7FFFFFFFFFFFFFFF, intComputation(0, 0, 0, 0x7FFFFFFFFFFFFFFF));
  Expect.equals(
      -0x8000000000000000, intComputation(0, 0, 0, -0x8000000000000000));
}

typedef NativeReturnMaxUint8 = Uint8 Function();
int Function() returnMaxUint8 = ffiTestFunctions
    .lookup("ReturnMaxUint8")
    .cast<NativeFunction<NativeReturnMaxUint8>>()
    .asFunction();
int Function() returnMaxUint8v2 = ffiTestFunctions
    .lookup("ReturnMaxUint8v2")
    .cast<NativeFunction<NativeReturnMaxUint8>>()
    .asFunction();

typedef NativeReturnMaxUint16 = Uint16 Function();
int Function() returnMaxUint16 = ffiTestFunctions
    .lookup("ReturnMaxUint16")
    .cast<NativeFunction<NativeReturnMaxUint16>>()
    .asFunction();
int Function() returnMaxUint16v2 = ffiTestFunctions
    .lookup("ReturnMaxUint16v2")
    .cast<NativeFunction<NativeReturnMaxUint16>>()
    .asFunction();

typedef NativeReturnMaxUint32 = Uint32 Function();
int Function() returnMaxUint32 = ffiTestFunctions
    .lookup("ReturnMaxUint32")
    .cast<NativeFunction<NativeReturnMaxUint32>>()
    .asFunction();
int Function() returnMaxUint32v2 = ffiTestFunctions
    .lookup("ReturnMaxUint32v2")
    .cast<NativeFunction<NativeReturnMaxUint32>>()
    .asFunction();

typedef NativeReturnMinInt8 = Int8 Function();
int Function() returnMinInt8 = ffiTestFunctions
    .lookup("ReturnMinInt8")
    .cast<NativeFunction<NativeReturnMinInt8>>()
    .asFunction();
int Function() returnMinInt8v2 = ffiTestFunctions
    .lookup("ReturnMinInt8v2")
    .cast<NativeFunction<NativeReturnMinInt8>>()
    .asFunction();

typedef NativeReturnMinInt16 = Int16 Function();
int Function() returnMinInt16 = ffiTestFunctions
    .lookup("ReturnMinInt16")
    .cast<NativeFunction<NativeReturnMinInt16>>()
    .asFunction();
int Function() returnMinInt16v2 = ffiTestFunctions
    .lookup("ReturnMinInt16v2")
    .cast<NativeFunction<NativeReturnMinInt16>>()
    .asFunction();

typedef NativeReturnMinInt32 = Int32 Function();
int Function() returnMinInt32 = ffiTestFunctions
    .lookup("ReturnMinInt32")
    .cast<NativeFunction<NativeReturnMinInt32>>()
    .asFunction();
int Function() returnMinInt32v2 = ffiTestFunctions
    .lookup("ReturnMinInt32v2")
    .cast<NativeFunction<NativeReturnMinInt32>>()
    .asFunction();

typedef NativeTakeMaxUint8 = IntPtr Function(Uint8);
int Function(int) takeMaxUint8 = ffiTestFunctions
    .lookup("TakeMaxUint8")
    .cast<NativeFunction<NativeTakeMaxUint8>>()
    .asFunction();

typedef NativeTakeMaxUint16 = IntPtr Function(Uint16);
int Function(int) takeMaxUint16 = ffiTestFunctions
    .lookup("TakeMaxUint16")
    .cast<NativeFunction<NativeTakeMaxUint16>>()
    .asFunction();

typedef NativeTakeMaxUint32 = IntPtr Function(Uint32);
int Function(int) takeMaxUint32 = ffiTestFunctions
    .lookup("TakeMaxUint32")
    .cast<NativeFunction<NativeTakeMaxUint32>>()
    .asFunction();

typedef NativeTakeMinInt8 = IntPtr Function(Int8);
int Function(int) takeMinInt8 = ffiTestFunctions
    .lookup("TakeMinInt8")
    .cast<NativeFunction<NativeTakeMinInt8>>()
    .asFunction();

typedef NativeTakeMinInt16 = IntPtr Function(Int16);
int Function(int) takeMinInt16 = ffiTestFunctions
    .lookup("TakeMinInt16")
    .cast<NativeFunction<NativeTakeMinInt16>>()
    .asFunction();

typedef NativeTakeMinInt32 = IntPtr Function(Int32);
int Function(int) takeMinInt32 = ffiTestFunctions
    .lookup("TakeMinInt32")
    .cast<NativeFunction<NativeTakeMinInt32>>()
    .asFunction();

typedef NativeTakeMaxUint8x10 = IntPtr Function(
    Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8, Uint8);
int Function(int, int, int, int, int, int, int, int, int, int) takeMaxUint8x10 =
    ffiTestFunctions
        .lookup("TakeMaxUint8x10")
        .cast<NativeFunction<NativeTakeMaxUint8x10>>()
        .asFunction();

void testExtension() {
  // Sign extension on the way back to Dart.
  Expect.equals(0xff, returnMaxUint8());
  Expect.equals(0xffff, returnMaxUint16());
  Expect.equals(0xffffffff, returnMaxUint32());
  Expect.equals(-0x80, returnMinInt8());
  Expect.equals(-0x8000, returnMinInt16());
  Expect.equals(-0x80000000, returnMinInt32());
  // Truncation in C, and sign extension back to Dart.
  Expect.equals(0xff, returnMaxUint8v2());
  Expect.equals(0xffff, returnMaxUint16v2());
  Expect.equals(0xffffffff, returnMaxUint32v2());
  Expect.equals(-0x80, returnMinInt8v2());
  Expect.equals(-0x8000, returnMinInt16v2());
  Expect.equals(-0x80000000, returnMinInt32v2());

  // Upper bits propper, should work without truncation.
  Expect.equals(1, takeMaxUint8(0xff));
  Expect.equals(1, takeMaxUint16(0xffff));
  Expect.equals(1, takeMaxUint32(0xffffffff));
  Expect.equals(1, takeMinInt8(-0x80));
  Expect.equals(1, takeMinInt16(-0x8000));
  Expect.equals(1, takeMinInt32(-0x80000000));
  Expect.equals(
      1,
      takeMaxUint8x10(
          0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff));
  // Upper bits garbage, needs to truncate.
  Expect.equals(1, takeMaxUint8(0xabcff));
  Expect.equals(1, takeMaxUint16(0xabcffff));
  Expect.equals(1, takeMaxUint32(0xabcffffffff));
  Expect.equals(1, takeMinInt8(0x8abc80));
  Expect.equals(1, takeMinInt16(0x8abc8000));
  Expect.equals(1, takeMinInt32(0x8abc80000000));
  Expect.equals(
      1,
      takeMaxUint8x10(0xabcff, 0xabcff, 0xabcff, 0xabcff, 0xabcff, 0xabcff,
          0xabcff, 0xabcff, 0xabcff, 0xabcff));
}

QuadOp uintComputation = ffiTestFunctions
    .lookupFunction<NativeQuadOpUnsigned, QuadOp>("UintComputation");

void test64bitInterpretations() {
  // 2 ^ 63 - 1
  Expect.equals(
      0x7FFFFFFFFFFFFFFF, uintComputation(0, 0, 0, 0x7FFFFFFFFFFFFFFF));
  // -2 ^ 63 interpreted as 2 ^ 63
  Expect.equals(
      -0x8000000000000000, uintComputation(0, 0, 0, -0x8000000000000000));
  // -1 interpreted as 2 ^ 64 - 1
  Expect.equals(-1, uintComputation(0, 0, 0, -1));
}

typedef NativeSenaryOp = Int64 Function(
    Int8, Int16, Int32, Uint8, Uint16, Uint32);
typedef SenaryOp = int Function(int, int, int, int, int, int);

SenaryOp sumSmallNumbers = ffiTestFunctions
    .lookupFunction<NativeSenaryOp, SenaryOp>("SumSmallNumbers");

void testTruncation() {
  sumSmallNumbers(128, 0, 0, 0, 0, 0);
  sumSmallNumbers(-129, 0, 0, 0, 0, 0);
  sumSmallNumbers(0, 0, 0, 256, 0, 0);
  sumSmallNumbers(0, 0, 0, -1, 0, 0);

  sumSmallNumbers(0, 0x8000, 0, 0, 0, 0);
  sumSmallNumbers(0, 0xFFFFFFFFFFFF7FFF, 0, 0, 0, 0);
  sumSmallNumbers(0, 0, 0, 0, 0x10000, 0);
  sumSmallNumbers(0, 0, 0, 0, -1, 0);

  Expect.equals(0xFFFFFFFF80000000, sumSmallNumbers(0, 0, 0x80000000, 0, 0, 0));
  Expect.equals(
      0x000000007FFFFFFF, sumSmallNumbers(0, 0, 0xFFFFFFFF7FFFFFFF, 0, 0, 0));
  Expect.equals(0, sumSmallNumbers(0, 0, 0, 0, 0, 0x100000000));
  Expect.equals(0xFFFFFFFF, sumSmallNumbers(0, 0, 0, 0, 0, -1));
}

typedef NativeDoubleUnaryOp = Double Function(Double);
typedef DoubleUnaryOp = double Function(double);

DoubleUnaryOp times1_337Double = ffiTestFunctions
    .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");

void testNativeFunctionDoubles() {
  Expect.approxEquals(2.0 * 1.337, times1_337Double(2.0));
}

typedef NativeFloatUnaryOp = Float Function(Float);

DoubleUnaryOp times1_337Float = ffiTestFunctions
    .lookupFunction<NativeFloatUnaryOp, DoubleUnaryOp>("Times1_337Float");

void testNativeFunctionFloats() {
  Expect.approxEquals(1337.0, times1_337Float(1000.0));
}

typedef NativeDecenaryOp = IntPtr Function(IntPtr, IntPtr, IntPtr, IntPtr,
    IntPtr, IntPtr, IntPtr, IntPtr, IntPtr, IntPtr);
typedef NativeDecenaryOp2 = Int16 Function(
    Int8, Int16, Int8, Int16, Int8, Int16, Int8, Int16, Int8, Int16);
typedef DecenaryOp = int Function(
    int, int, int, int, int, int, int, int, int, int);

DecenaryOp sumManyInts = ffiTestFunctions
    .lookupFunction<NativeDecenaryOp, DecenaryOp>("SumManyInts");

void testNativeFunctionManyArguments1() {
  Expect.equals(55, sumManyInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
}

DecenaryOp sumManySmallInts = ffiTestFunctions
    .lookupFunction<NativeDecenaryOp2, DecenaryOp>("SumManySmallInts");

void testNativeFunctionManyArguments5() {
  Expect.equals(55, sumManySmallInts(1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
}

typedef NativeUndenaryOp = IntPtr Function(IntPtr, IntPtr, IntPtr, IntPtr,
    IntPtr, IntPtr, IntPtr, IntPtr, IntPtr, IntPtr, IntPtr);
typedef UndenaryOp = int Function(
    int, int, int, int, int, int, int, int, int, int, int);

UndenaryOp sumManyIntsOdd = ffiTestFunctions
    .lookupFunction<NativeUndenaryOp, UndenaryOp>("SumManyIntsOdd");

void testNativeFunctionManyArguments4() {
  Expect.equals(66, sumManyIntsOdd(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
}

typedef NativeDoubleDecenaryOp = Double Function(Double, Double, Double, Double,
    Double, Double, Double, Double, Double, Double);
typedef DoubleDecenaryOp = double Function(double, double, double, double,
    double, double, double, double, double, double);

DoubleDecenaryOp sumManyDoubles = ffiTestFunctions
    .lookupFunction<NativeDoubleDecenaryOp, DoubleDecenaryOp>("SumManyDoubles");

void testNativeFunctionManyArguments2() {
  Expect.approxEquals(
      55.0, sumManyDoubles(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0));
}

typedef NativeVigesimalOp = Double Function(
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double,
    IntPtr,
    Float,
    IntPtr,
    Double);
typedef VigesimalOp = double Function(
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double,
    int,
    double);

VigesimalOp sumManyNumbers = ffiTestFunctions
    .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");

void testNativeFunctionManyArguments3() {
  Expect.approxEquals(
      210.0,
      sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13,
          14.0, 15, 16.0, 17, 18.0, 19, 20.0));
}

typedef Int64PointerUnOp = Pointer<Int64> Function(Pointer<Int64>);

Int64PointerUnOp assign1337Index1 = ffiTestFunctions
    .lookupFunction<Int64PointerUnOp, Int64PointerUnOp>("Assign1337Index1");

void testNativeFunctionPointer() {
  Pointer<Int64> p2 = allocate(count: 2);
  p2.value = 42;
  p2[1] = 1000;
  Pointer<Int64> result = assign1337Index1(p2);
  Expect.equals(1337, result.value);
  Expect.equals(1337, p2[1]);
  Expect.equals(p2.elementAt(1).address, result.address);
  free(p2);
}

Int64PointerUnOp nullableInt64ElemAt1 = ffiTestFunctions
    .lookupFunction<Int64PointerUnOp, Int64PointerUnOp>("NullableInt64ElemAt1");

void testNullPointers() {
  Pointer<Int64> result = nullableInt64ElemAt1(nullptr);
  Expect.equals(result, nullptr);

  Pointer<Int64> p2 = allocate(count: 2);
  result = nullableInt64ElemAt1(p2);
  Expect.notEquals(result, nullptr);
  free(p2);
}

typedef NativeFloatPointerToBool = Uint8 Function(Pointer<Float>);
typedef FloatPointerToBool = int Function(Pointer<Float>);

FloatPointerToBool isRoughly1337 = ffiTestFunctions.lookupFunction<
    NativeFloatPointerToBool, FloatPointerToBool>("IsRoughly1337");

void testFloatRounding() {
  Pointer<Float> p2 = allocate();
  p2.value = 1337.0;

  int result = isRoughly1337(p2);
  Expect.equals(1, result);

  free(p2);
}

typedef NativeFloatToVoid = Void Function(Float);
typedef DoubleToVoid = void Function(double);

DoubleToVoid devNullFloat = ffiTestFunctions
    .lookupFunction<NativeFloatToVoid, DoubleToVoid>("DevNullFloat");

void testVoidReturn() {
  devNullFloat(1337.0);

  dynamic loseSignature = devNullFloat;
  dynamic result = loseSignature(1337.0);
  Expect.isNull(result);
}

typedef NativeVoidToFloat = Float Function();
typedef VoidToDouble = double Function();

VoidToDouble inventFloatValue = ffiTestFunctions
    .lookupFunction<NativeVoidToFloat, VoidToDouble>("InventFloatValue");

void testNoArgs() {
  double result = inventFloatValue();
  Expect.approxEquals(1337.0, result);
}

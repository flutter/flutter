// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi with null values.
//
// Separated into a separate file to make NNBD testing easier.
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

import "expect.dart";
import "package:ffi/ffi.dart";

import 'dylib_utils.dart';
import 'ffi_test_helpers.dart';

void main() {
  for (int i = 0; i < 100; i++) {
    testPointerStoreNull();
    testEquality();
    testNullReceivers();
    testNullIndices();
    testNullArguments();
    testNullInt();
    testNullDouble();
    testNullManyArgs();
    testException();
    testNullReturnCallback();
  }
}

void testPointerStoreNull() {
  int i = null;
  Pointer<Int8> p = allocate();
  Expect.throws(() => p.value = i);
  free(p);
  double d = null;
  Pointer<Float> p2 = allocate();
  Expect.throws(() => p2.value = d);
  free(p2);
  Pointer<Void> x = null;
  Pointer<Pointer<Void>> p3 = allocate();
  Expect.throws(() => p3.value = x);
  free(p3);
}

void testEquality() {
  Pointer<Int8> p = Pointer.fromAddress(12345678);
  Expect.notEquals(p, null);
  Expect.notEquals(null, p);
}

/// With extension methods, the receiver position can be null.
testNullReceivers() {
  Pointer<Int8> p = allocate();

  Pointer<Int8> p4 = null;
  Expect.throws(() => Expect.equals(10, p4.value));
  Expect.throws(() => p4.value = 10);

  Pointer<Pointer<Int8>> p5 = null;
  Expect.throws(() => Expect.equals(10, p5.value));
  Expect.throws(() => p5.value = p);

  Pointer<Foo> p6 = null;
  Expect.throws(() => Expect.equals(10, p6.ref));

  free(p);
}

testNullIndices() {
  Pointer<Int8> p = allocate();

  Expect.throws(() => Expect.equals(10, p[null]));
  Expect.throws(() => p[null] = 10);

  Pointer<Pointer<Int8>> p5 = p.cast();
  Expect.throws(() => Expect.equals(10, p5[null]));
  Expect.throws(() => p5[null] = p);

  Pointer<Foo> p6 = p.cast();
  Expect.throws(() => Expect.equals(10, p6[null]));

  free(p);
}

testNullArguments() {
  Pointer<Int8> p = allocate();
  Expect.throws(() => p.value = null);
  free(p);
}

class Foo extends Struct {
  @Int8()
  int a;
}

void testNullInt() {
  Expect.throws(() => sumPlus42(43, null));
}

void testNullDouble() {
  Expect.throws(() => times1_337Double(null));
}

void testNullManyArgs() {
  Expect.throws(() => sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0,
      11, 12.0, 13, 14.0, 15, 16.0, 17, 18.0, null, 20.0));
}

typedef NativeBinaryOp = Int32 Function(Int32, Int32);
typedef BinaryOp = int Function(int, int);

typedef NativeDoubleUnaryOp = Double Function(Double);
typedef DoubleUnaryOp = double Function(double);

DoubleUnaryOp times1_337Double = ffiTestFunctions
    .lookupFunction<NativeDoubleUnaryOp, DoubleUnaryOp>("Times1_337Double");

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

// Throw an exception from within the trampoline and collect a stacktrace
// include its frame.
void testException() {
  try {
    sumPlus42(null, null);
  } catch (e, s) {
    return;
  }
  throw "Didn't throw!";
}

BinaryOp sumPlus42 =
    ffiTestFunctions.lookupFunction<NativeBinaryOp, BinaryOp>("SumPlus42");

void testNullReturnCallback() {
  final test =
      Test("ReturnNull", Pointer.fromFunction<ReturnNullType>(returnNull, 42));
  test.run();
}

typedef NativeCallbackTest = Int32 Function(Pointer);
typedef NativeCallbackTestFn = int Function(Pointer);

final DynamicLibrary testLibrary = dlopenPlatformSpecific("ffi_test_functions");

class Test {
  final String name;
  final Pointer callback;
  final bool skip;

  Test(this.name, this.callback, {bool skipIf: false}) : skip = skipIf {}

  void run() {
    if (skip) return;

    final NativeCallbackTestFn tester = testLibrary
        .lookupFunction<NativeCallbackTest, NativeCallbackTestFn>("Test$name");
    final int testCode = tester(callback);
    if (testCode != 0) {
      Expect.fail("Test $name failed.");
    }
  }
}

typedef ReturnNullType = Int32 Function();
int returnNull() {
  return null;
}

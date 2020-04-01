// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi function pointers with struct
// arguments.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

import "expect.dart";
import "package:ffi/ffi.dart";

import 'coordinate.dart';
import 'very_large_struct.dart';

typedef NativeCoordinateOp = Pointer<Coordinate> Function(Pointer<Coordinate>);

void main() {
  testFunctionWithStruct();
  // testFunctionWithStructArray();
  // testFunctionWithVeryLargeStruct();
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

/// pass a struct to a c function and get a struct as return value
void testFunctionWithStruct() {
  Pointer<NativeFunction<NativeCoordinateOp>> p1 =
      ffiTestFunctions.lookup("TransposeCoordinate");
  NativeCoordinateOp f1 = p1.asFunction();

  Pointer<Coordinate> c1 = Coordinate.allocate(10.0, 20.0, nullptr).addressOf;
  Pointer<Coordinate> c2 = Coordinate.allocate(42.0, 84.0, c1).addressOf;
  c1.ref.next = c2;

  Coordinate result = f1(c1).ref;

  Expect.approxEquals(20.0, c1.ref.x);
  Expect.approxEquals(30.0, c1.ref.y);

  Expect.approxEquals(42.0, result.x);
  Expect.approxEquals(84.0, result.y);

  free(c1);
  free(c2);
}

/// pass an array of structs to a c funtion
void testFunctionWithStructArray() {
  Pointer<NativeFunction<NativeCoordinateOp>> p1 =
      ffiTestFunctions.lookup("CoordinateElemAt1");
  NativeCoordinateOp f1 = p1.asFunction();

  Coordinate c1 = allocate<Coordinate>(count: 3).ref;
  Coordinate c2 = c1.addressOf[1];
  Coordinate c3 = c1.addressOf[2];
  c1.x = 10.0;
  c1.y = 10.0;
  c1.next = c3.addressOf;
  c2.x = 20.0;
  c2.y = 20.0;
  c2.next = c1.addressOf;
  c3.x = 30.0;
  c3.y = 30.0;
  c3.next = c2.addressOf;

  Coordinate result = f1(c1.addressOf).ref;
  Expect.approxEquals(20.0, result.x);
  Expect.approxEquals(20.0, result.y);

  free(c1.addressOf);
}

typedef VeryLargeStructSum = int Function(Pointer<VeryLargeStruct>);
typedef NativeVeryLargeStructSum = Int64 Function(Pointer<VeryLargeStruct>);

void testFunctionWithVeryLargeStruct() {
  Pointer<NativeFunction<NativeVeryLargeStructSum>> p1 =
      ffiTestFunctions.lookup("SumVeryLargeStruct");
  VeryLargeStructSum f = p1.asFunction();

  VeryLargeStruct vls1 = allocate<VeryLargeStruct>(count: 2).ref;
  VeryLargeStruct vls2 = vls1.addressOf[1];
  List<VeryLargeStruct> structs = [vls1, vls2];
  for (VeryLargeStruct struct in structs) {
    struct.a = 1;
    struct.b = 2;
    struct.c = 4;
    struct.d = 8;
    struct.e = 16;
    struct.f = 32;
    struct.g = 64;
    struct.h = 128;
    struct.i = 256;
    struct.j = 512;
    struct.k = 1024;
    struct.smallLastField = 1;
  }
  vls1.parent = vls2.addressOf;
  vls1.numChildren = 2;
  vls1.children = vls1.addressOf;
  vls2.parent = vls2.addressOf;
  vls2.parent = nullptr;
  vls2.numChildren = 0;
  vls2.children = nullptr;

  int result = f(vls1.addressOf);
  Expect.equals(2051, result);

  result = f(vls2.addressOf);
  Expect.equals(2048, result);

  free(vls1.addressOf);
}

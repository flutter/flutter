// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check that the optimizer does not fuse constants with different
// representations.
//
// SharedObjects=ffi_test_functions

import "dart:ffi";

import "expect.dart";

import "dylib_utils.dart";

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

main() {
  final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

  final sumManyNumbers = ffiTestFunctions
      .lookupFunction<NativeVigesimalOp, VigesimalOp>("SumManyNumbers");

  // Should not crash.
  sumManyNumbers(1, 2.0, 3, 4.0, 5, 6.0, 7, 8.0, 9, 10.0, 11, 12.0, 13, 14.0,
      15, 16.0, 17, 18.0, 19, 20.0);
}

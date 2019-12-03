// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing dart:ffi function pointers with callbacks.
//
// VMOptions=--deterministic --optimization-counter-threshold=10
// VMOptions=--enable-testing-pragmas
// VMOptions=--enable-testing-pragmas --stacktrace-every=100
// VMOptions=--enable-testing-pragmas --write-protect-code --no-dual-map-code
// VMOptions=--enable-testing-pragmas --write-protect-code --no-dual-map-code --stacktrace-every=100
// VMOptions=--use-slow-path --enable-testing-pragmas
// VMOptions=--use-slow-path --enable-testing-pragmas --stacktrace-every=100
// VMOptions=--use-slow-path --enable-testing-pragmas --write-protect-code --no-dual-map-code
// VMOptions=--use-slow-path --enable-testing-pragmas --write-protect-code --no-dual-map-code --stacktrace-every=100
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'callback_tests_utils.dart';

final testcases = [
  CallbackTest("SumVeryManySmallInts",
      Pointer.fromFunction<NativeVeryManyIntsOp>(sumVeryManySmallInts, 0)),
  CallbackTest(
      "SumVeryManyFloatsDoubles",
      Pointer.fromFunction<NativeVeryManyFloatsDoublesOp>(
          sumVeryManyDoubles, 0.0)),
];

void main() {
  for (int i = 0; i < 100; ++i) {
    testcases.forEach((t) => t.run());
  }
}

int sumVeryManySmallInts(
    int _1,
    int _2,
    int _3,
    int _4,
    int _5,
    int _6,
    int _7,
    int _8,
    int _9,
    int _10,
    int _11,
    int _12,
    int _13,
    int _14,
    int _15,
    int _16,
    int _17,
    int _18,
    int _19,
    int _20,
    int _21,
    int _22,
    int _23,
    int _24,
    int _25,
    int _26,
    int _27,
    int _28,
    int _29,
    int _30,
    int _31,
    int _32,
    int _33,
    int _34,
    int _35,
    int _36,
    int _37,
    int _38,
    int _39,
    int _40) {
  print("sumVeryManySmallInts(" +
      "$_1, $_2, $_3, $_4, $_5, $_6, $_7, $_8, $_9, $_10, " +
      "$_11, $_12, $_13, $_14, $_15, $_16, $_17, $_18, $_19, $_20, " +
      "$_21, $_22, $_23, $_24, $_25, $_26, $_27, $_28, $_29, $_30, " +
      "$_31, $_32, $_33, $_34, $_35, $_36, $_37, $_38, $_39, $_40)");
  return _1 +
      _2 +
      _3 +
      _4 +
      _5 +
      _6 +
      _7 +
      _8 +
      _9 +
      _10 +
      _11 +
      _12 +
      _13 +
      _14 +
      _15 +
      _16 +
      _17 +
      _18 +
      _19 +
      _20 +
      _21 +
      _22 +
      _23 +
      _24 +
      _25 +
      _26 +
      _27 +
      _28 +
      _29 +
      _30 +
      _31 +
      _32 +
      _33 +
      _34 +
      _35 +
      _36 +
      _37 +
      _38 +
      _39 +
      _40;
}

double sumVeryManyDoubles(
    double _1,
    double _2,
    double _3,
    double _4,
    double _5,
    double _6,
    double _7,
    double _8,
    double _9,
    double _10,
    double _11,
    double _12,
    double _13,
    double _14,
    double _15,
    double _16,
    double _17,
    double _18,
    double _19,
    double _20,
    double _21,
    double _22,
    double _23,
    double _24,
    double _25,
    double _26,
    double _27,
    double _28,
    double _29,
    double _30,
    double _31,
    double _32,
    double _33,
    double _34,
    double _35,
    double _36,
    double _37,
    double _38,
    double _39,
    double _40) {
  print("sumVeryManyDoubles(" +
      "$_1, $_2, $_3, $_4, $_5, $_6, $_7, $_8, $_9, $_10, " +
      "$_11, $_12, $_13, $_14, $_15, $_16, $_17, $_18, $_19, $_20, " +
      "$_21, $_22, $_23, $_24, $_25, $_26, $_27, $_28, $_29, $_30, " +
      "$_31, $_32, $_33, $_34, $_35, $_36, $_37, $_38, $_39, $_40)");
  return _1 +
      _2 +
      _3 +
      _4 +
      _5 +
      _6 +
      _7 +
      _8 +
      _9 +
      _10 +
      _11 +
      _12 +
      _13 +
      _14 +
      _15 +
      _16 +
      _17 +
      _18 +
      _19 +
      _20 +
      _21 +
      _22 +
      _23 +
      _24 +
      _25 +
      _26 +
      _27 +
      _28 +
      _29 +
      _30 +
      _31 +
      _32 +
      _33 +
      _34 +
      _35 +
      _36 +
      _37 +
      _38 +
      _39 +
      _40;
}

typedef NativeVeryManyIntsOp = Int16 Function(
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16,
    Int8,
    Int16);

typedef NativeVeryManyFloatsDoublesOp = Double Function(
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double,
    Float,
    Double);

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
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

import "expect.dart";

import 'callback_tests_utils.dart';
import 'dylib_utils.dart';

void main() {
  for (int i = 0; i < 100; ++i) {
    testSumFloatsAndDoubles();
    testSumFloatsAndDoublesCallback();
  }
}

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final sumFloatsAndDoubles = ffiTestFunctions.lookupFunction<
    Double Function(Float, Double, Float),
    double Function(double, double, double)>("SumFloatsAndDoubles");

void testSumFloatsAndDoubles() {
  Expect.approxEquals(6.0, sumFloatsAndDoubles(1.0, 2.0, 3.0));
}

void testSumFloatsAndDoublesCallback() {
  CallbackTest(
          "SumFloatsAndDoubles",
          Pointer.fromFunction<Double Function(Float, Double, Float)>(
              sumFloatsAndDoublesDart, 0.0))
      .run();
}

double sumFloatsAndDoublesDart(double a, double b, double c) {
  print("sumFloatsAndDoublesDart($a, $b, $c)");
  return a + b + c;
}

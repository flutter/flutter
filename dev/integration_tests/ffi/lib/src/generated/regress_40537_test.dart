// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Truncation and sign extension of small ints, tested with something else than
// equality.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import "expect.dart";

import "dylib_utils.dart";

main() {
  variant1Negative();
  variant1Positive();
  variant2Negative();
  variant2Positive();
  variant3Negative();
}

/// `return x == 249 ? 1 : 0`.
///
/// This doesn't catch the error.
final regress40537 = ffiTestFunctions
    .lookupFunction<IntPtr Function(Uint8), int Function(int)>("Regress40537");

variant1Negative() {
  // 0xF9 =  -7 in 2s complement.
  // 0xF9 = 249 in unsinged.
  final result = regress40537(-7);
  print(result);
  Expect.equals(1, result);
}

variant1Positive() {
  // 0xF9 = 249 in unsinged.
  final result = regress40537(0xFFFFFFF9);
  print(result);
  Expect.equals(1, result);
}

/// `return x`.
///
/// This does.
final regress40537Variant2 =
    ffiTestFunctions.lookupFunction<IntPtr Function(Uint8), int Function(int)>(
        "Regress40537Variant2");

variant2Negative() {
  // The 32 bit representation of -7 is 0xFFFFFFF9.
  // Only the lowest byte, 0xF9, should be interpreted by calling convention,
  // or it should be truncated and zero extended before calling.
  final result = regress40537Variant2(-7);
  print(result);
  Expect.equals(249, result);
}

variant2Positive() {
  // Only the lowest byte, 0xF9, should be interpreted by calling convention,
  // or it should be truncated and zero extended before calling.
  final result = regress40537Variant2(0xFFFFFFF9);
  print(result);
  Expect.equals(249, result);
}

/// `return x`.
final regress40537Variant3 =
    ffiTestFunctions.lookupFunction<Uint8 Function(IntPtr), int Function(int)>(
        "Regress40537Variant3");

variant3Negative() {
  // This really passes -7 its intptr_t.
  final result = regress40537Variant3(-7);
  print(result);
  Expect.equals(249, result);
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test programing for testing that optimizations do wrongly assume loads
// from and stores to C memory are not aliased.
//
// SharedObjects=ffi_test_functions
// VMOptions=--deterministic --optimization-counter-threshold=50

import 'dart:ffi';

import "package:ffi/ffi.dart";
import "expect.dart";

import 'ffi_test_helpers.dart';

void main() {
  for (int i = 0; i < 100; ++i) {
    testNonAlias();
    testAliasCast();
    testAliasCast2();
    testAliasOffsetBy();
    testAliasOffsetBy2();
    testAliasElementAt();
    testAliasElementAt2();
    testAliasFromAddress();
    testAliasFromAddress2();
    testAliasFromAddressViaMemory();
    testAliasFromAddressViaMemory2();
    testAliasFromAddressViaNativeFunction();
    testAliasFromAddressViaNativeFunction2();
    testPartialOverlap();
  }
}

void testNonAlias() {
  final source = allocate<Int64>();
  source.value = 42;
  final int a = source.value;
  source.value = 1984;
  // alias.value should be re-executed, as we wrote to alias.
  Expect.notEquals(a, source.value);
  free(source);
}

void testAliasCast() {
  final source = allocate<Int64>();
  final alias = source.cast<Int8>().cast<Int64>();
  source.value = 42;
  final int a = source.value;
  alias.value = 1984;
  // source.value should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.value);
  free(source);
}

void testAliasCast2() {
  final source = allocate<Int64>();
  final alias = source.cast<Int16>().cast<Int64>();
  final alias2 = source.cast<Int8>().cast<Int64>();
  alias.value = 42;
  final int a = alias.value;
  alias2.value = 1984;
  // alias.value should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.value);
  free(source);
}

void testAliasOffsetBy() {
  final source = allocate<Int64>(count: 2);
  final alias = source.offsetBy(8).offsetBy(-8);
  source.value = 42;
  final int a = source.value;
  alias.value = 1984;
  // source.value should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.value);
  free(source);
}

void testAliasOffsetBy2() {
  final source = allocate<Int64>(count: 3);
  final alias = source.offsetBy(16).offsetBy(-16);
  final alias2 = source.offsetBy(8).offsetBy(-8);
  alias.value = 42;
  final int a = alias.value;
  alias2.value = 1984;
  // alias.value should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.value);
  free(source);
}

void testAliasElementAt() {
  final source = allocate<Int64>(count: 2);
  final alias = source.elementAt(1).elementAt(-1);
  source.value = 42;
  final int a = source.value;
  alias.value = 1984;
  // source.value should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.value);
  free(source);
}

void testAliasElementAt2() {
  final source = allocate<Int64>(count: 3);
  final alias = source.elementAt(2).elementAt(-2);
  final alias2 = source.elementAt(1).elementAt(-1);
  alias.value = 42;
  final int a = alias.value;
  alias2.value = 1984;
  // alias.value should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.value);
  free(source);
}

void testAliasFromAddress() {
  final source = allocate<Int64>();
  final alias = Pointer<Int64>.fromAddress(source.address);
  source.value = 42;
  final int a = source.value;
  alias.value = 1984;
  // source.value should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.value);
  free(source);
}

void testAliasFromAddress2() {
  final source = allocate<Int64>();
  final alias = Pointer<Int64>.fromAddress(source.address);
  final alias2 = Pointer<Int64>.fromAddress(source.address);
  alias.value = 42;
  final int a = alias.value;
  alias2.value = 1984;
  // alias.value should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.value);
  free(source);
}

void testAliasFromAddressViaMemory() {
  final helper = allocate<IntPtr>();
  final source = allocate<Int64>();
  helper.value = source.address;
  final alias = Pointer<Int64>.fromAddress(helper.value);
  source.value = 42;
  final int a = source.value;
  alias.value = 1984;
  // source.value should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.value);
  free(helper);
  free(source);
}

void testAliasFromAddressViaMemory2() {
  final helper = allocate<IntPtr>();
  final source = allocate<Int64>();
  helper.value = source.address;
  final alias = Pointer<Int64>.fromAddress(helper.value);
  final alias2 = Pointer<Int64>.fromAddress(helper.value);
  alias.value = 42;
  final int a = alias.value;
  alias2.value = 1984;
  // alias.value should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.value);
  free(helper);
  free(source);
}

typedef NativeQuadOpSigned = Int64 Function(Int8, Int16, Int32, Int64);
typedef QuadOp = int Function(int, int, int, int);

QuadOp intComputation = ffiTestFunctions
    .lookupFunction<NativeQuadOpSigned, QuadOp>("IntComputation");

void testAliasFromAddressViaNativeFunction() {
  final source = allocate<Int64>();
  final alias =
      Pointer<Int64>.fromAddress(intComputation(0, 0, 0, source.address));
  source.value = 42;
  final int a = source.value;
  alias.value = 1984;
  // source.value should be re-executed, we wrote alias which aliases source.
  Expect.notEquals(a, source.value);
  free(source);
}

void testAliasFromAddressViaNativeFunction2() {
  final source = allocate<Int64>();
  final alias =
      Pointer<Int64>.fromAddress(intComputation(0, 0, 0, source.address));
  final alias2 =
      Pointer<Int64>.fromAddress(intComputation(0, 0, 0, source.address));
  alias.value = 42;
  final int a = alias.value;
  alias2.value = 1984;
  // alias.value should be re-executed, we wrote alias2 which aliases alias.
  Expect.notEquals(a, alias.value);
  free(source);
}

@pragma('vm:never-inline')
Pointer<Int8> makeDerived(Pointer<Int64> source) =>
    source.offsetBy(7).cast<Int8>();

testPartialOverlap() {
  final source = allocate<Int64>(count: 2);
  final derived = makeDerived(source);
  source.value = 0x1122334455667788;
  final int value = source.value;
  derived.value = 0xaa;
  Expect.notEquals(value, source.value);
  free(source);
}

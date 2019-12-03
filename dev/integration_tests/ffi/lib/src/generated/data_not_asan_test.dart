// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi primitive data pointers.
//
// These mallocs trigger an asan alarm, so these tests are in a separate file
// which is excluded in asan mode.

import 'dart:ffi';

import "package:ffi/ffi.dart";
import "expect.dart";

void main() {
  testPointerAllocateTooLarge();
  testPointerAllocateNegative();
}

void testPointerAllocateTooLarge() {
  // Try to allocate something that doesn't fit in 64 bit address space.
  int maxInt = 9223372036854775807; // 2^63 - 1
  Expect.throws(() => allocate<Int64>(count: maxInt));

  // Try to allocate almost the full 64 bit address space.
  int maxInt1_8 = 1152921504606846975; // 2^60 -1
  Expect.throws(() => allocate<Int64>(count: maxInt1_8));
}

void testPointerAllocateNegative() {
  // Passing in -1 will be converted into an unsigned integer. So, it will try
  // to allocate SIZE_MAX - 1 + 1 bytes. This will fail as it is the max amount
  // of addressable memory on the system.
  Expect.throws(() => allocate<Int8>(count: -1));
}

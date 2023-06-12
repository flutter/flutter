// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:math' show Random;

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

const testRuns = 1000;

void main() async {
  test('calloc', () {
    // Tests that calloc successfully zeroes out memory.
    for (var i = 0; i < testRuns; i++) {
      final allocBytes = Random().nextInt(1000);
      final mem = calloc<Uint8>(allocBytes);
      expect(mem.asTypedList(allocBytes).where(((element) => element != 0)),
          isEmpty);
      calloc.free(mem);
    }
  });

  test('testPointerAllocateTooLarge', () {
    // Try to allocate something that doesn't fit in 64 bit address space.
    int maxInt = 9223372036854775807; // 2^63 - 1
    expect(() => calloc<Uint8>(maxInt), throwsA(isA<ArgumentError>()));

    // Try to allocate almost the full 64 bit address space.
    int maxInt1_8 = 1152921504606846975; // 2^60 -1
    expect(() => calloc<Uint8>(maxInt1_8), throwsA(isA<ArgumentError>()));
  });

  test('testPointerAllocateNegative', () {
    // Passing in -1 will be converted into an unsigned integer. So, it will try
    // to allocate SIZE_MAX - 1 + 1 bytes. This will fail as it is the max
    // amount of addressable memory on the system.
    expect(() => calloc<Uint8>(-1), throwsA(isA<ArgumentError>()));
  });
}

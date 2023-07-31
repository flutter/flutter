// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A bitmask that limits an integer to 32 bits.
const mask32 = 0xFFFFFFFF;

/// The number of bits in a byte.
const bitsPerByte = 8;

/// The number of bytes in a 32-bit word.
const bytesPerWord = 4;

/// Adds [x] and [y] with 32-bit overflow semantics.
int add32(int x, int y) => (x + y) & mask32;

/// Bitwise rotates [val] to the left by [shift], obeying 32-bit overflow
/// semantics.
int rotl32(int val, int shift) {
  var modShift = shift & 31;
  return ((val << modShift) & mask32) | ((val & mask32) >> (32 - modShift));
}

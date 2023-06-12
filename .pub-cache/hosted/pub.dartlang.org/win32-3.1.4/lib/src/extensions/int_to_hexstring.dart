// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A convenient extension for converting integers to fixed-length hexadecimal
// strings.

extension HexConversion on int {
  /// Converts an integer value to a nicely-formatted hexadecimal equivalent.
  ///
  /// For example `255.toHex(8)` returns 0xFF.
  ///
  /// Takes a parameter `bits` indicating the width of the number. Normally
  /// this value will be 8, 16, 32 or 64, but other integers that are divisible
  /// by 8 are permissible.
  String toHexString(int bits) {
    if ((bits % 8) != 0) return '';

    // Need to cast to a BigInt because Dart integers are signed 64-bit values
    final bigValue = BigInt.from(this);
    final value = bigValue.toUnsigned(bits);
    return '0x${value.toRadixString(16).padLeft(bits ~/ 4, '0')}';
  }
}

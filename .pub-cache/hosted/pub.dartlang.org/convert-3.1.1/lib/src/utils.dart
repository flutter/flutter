// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library convert.utils;

import 'charcodes.dart';

/// Returns the digit (0 through 15) corresponding to the hexadecimal code unit
/// at index [index] in [codeUnits].
///
/// If the given code unit isn't valid hexadecimal, throws a [FormatException].
int digitForCodeUnit(List<int> codeUnits, int index) {
  // If the code unit is a numeral, get its value. XOR works because 0 in ASCII
  // is `0b110000` and the other numerals come after it in ascending order and
  // take up at most four bits.
  //
  // We check for digits first because it ensures there's only a single branch
  // for 10 out of 16 of the expected cases. We don't count the `digit >= 0`
  // check because branch prediction will always work on it for valid data.
  var codeUnit = codeUnits[index];
  var digit = $0 ^ codeUnit;
  if (digit <= 9) {
    if (digit >= 0) return digit;
  } else {
    // If the code unit is an uppercase letter, convert it to lowercase. This
    // works because uppercase letters in ASCII are exactly `0b100000 = 0x20`
    // less than lowercase letters, so if we ensure that that bit is 1 we ensure
    // that the letter is lowercase.
    var letter = 0x20 | codeUnit;
    if ($a <= letter && letter <= $f) return letter - $a + 10;
  }

  throw FormatException(
      'Invalid hexadecimal code unit '
      "U+${codeUnit.toRadixString(16).padLeft(4, '0')}.",
      codeUnits,
      index);
}

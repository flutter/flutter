// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal';
import 'dart:_string';

@patch
class _BoxedInt {
  @patch
  String toRadixString(int radix) => _intToRadixString(value, radix);

  @patch
  String toString() => _intToString(value);
}

const _digits = "0123456789abcdefghijklmnopqrstuvwxyz";

String _intToRadixString(int value, int radix) {
  if (radix < 2 || 36 < radix) {
    throw new RangeError.range(radix, 2, 36, "radix");
  }
  if (radix & (radix - 1) == 0) {
    return _toPow2String(value, radix);
  }
  if (radix == 10) return _intToString(value);
  final bool isNegative = value < 0;
  value = isNegative ? -value : value;
  if (value < 0) {
    // With int limited to 64 bits, the value
    // MIN_INT64 = -0x8000000000000000 overflows at negation:
    // -MIN_INT64 == MIN_INT64, so it requires special handling.
    return _minInt64ToRadixString(value, radix);
  }
  var temp = <int>[];
  do {
    int digit = value % radix;
    value ~/= radix;
    temp.add(_digits.codeUnitAt(digit));
  } while (value > 0);
  if (isNegative) temp.add(0x2d); // '-'.

  final string = OneByteString.withLength(temp.length);
  for (int i = 0, j = temp.length; j > 0; i++) {
    string.setUnchecked(i, temp[--j]);
  }
  return string;
}

String _toPow2String(int value, int radix) {
  if (value == 0) return "0";
  assert(radix & (radix - 1) == 0);
  var negative = value < 0;
  var bitsPerDigit = radix.bitLength - 1;
  var length = 0;
  if (negative) {
    value = -value;
    length = 1;
    if (value < 0) {
      // With int limited to 64 bits, the value
      // MIN_INT64 = -0x8000000000000000 overflows at negation:
      // -MIN_INT64 == MIN_INT64, so it requires special handling.
      return _minInt64ToRadixString(value, radix);
    }
  }
  // Integer division, rounding up, to find number of _digits.
  length += (value.bitLength + bitsPerDigit - 1) ~/ bitsPerDigit;
  final string = OneByteString.withLength(length);

  string.setUnchecked(0, 0x2d); // '-'. Is overwritten if not negative.
  var mask = radix - 1;
  do {
    string.setUnchecked(--length, _digits.codeUnitAt(value & mask));
    value >>= bitsPerDigit;
  } while (value > 0);
  return string;
}

/// Converts negative value to radix string.
/// This method is only used to handle corner case of
/// MIN_INT64 = -0x8000000000000000.
String _minInt64ToRadixString(int value, int radix) {
  var temp = <int>[];
  assert(value < 0);
  do {
    int digit = -unsafeCast<int>(value.remainder(radix));
    value ~/= radix;
    temp.add(_digits.codeUnitAt(digit));
  } while (value != 0);
  temp.add(0x2d); // '-'.

  final string = OneByteString.withLength(temp.length);
  for (int i = 0, j = temp.length; j > 0; i++) {
    string.setUnchecked(i, temp[--j]);
  }
  return string;
}

/**
 * The digits of '00', '01', ... '99' as a single array.
 *
 * Get the digits of `n`, with `0 <= n < 100`, as
 * `_digitTable[n * 2]` and `_digitTable[n * 2 + 1]`.
 */
const _digitTable = const [
  0x30, 0x30, 0x30, 0x31, 0x30, 0x32, 0x30, 0x33, //
  0x30, 0x34, 0x30, 0x35, 0x30, 0x36, 0x30, 0x37, //
  0x30, 0x38, 0x30, 0x39, 0x31, 0x30, 0x31, 0x31, //
  0x31, 0x32, 0x31, 0x33, 0x31, 0x34, 0x31, 0x35, //
  0x31, 0x36, 0x31, 0x37, 0x31, 0x38, 0x31, 0x39, //
  0x32, 0x30, 0x32, 0x31, 0x32, 0x32, 0x32, 0x33, //
  0x32, 0x34, 0x32, 0x35, 0x32, 0x36, 0x32, 0x37, //
  0x32, 0x38, 0x32, 0x39, 0x33, 0x30, 0x33, 0x31, //
  0x33, 0x32, 0x33, 0x33, 0x33, 0x34, 0x33, 0x35, //
  0x33, 0x36, 0x33, 0x37, 0x33, 0x38, 0x33, 0x39, //
  0x34, 0x30, 0x34, 0x31, 0x34, 0x32, 0x34, 0x33, //
  0x34, 0x34, 0x34, 0x35, 0x34, 0x36, 0x34, 0x37, //
  0x34, 0x38, 0x34, 0x39, 0x35, 0x30, 0x35, 0x31, //
  0x35, 0x32, 0x35, 0x33, 0x35, 0x34, 0x35, 0x35, //
  0x35, 0x36, 0x35, 0x37, 0x35, 0x38, 0x35, 0x39, //
  0x36, 0x30, 0x36, 0x31, 0x36, 0x32, 0x36, 0x33, //
  0x36, 0x34, 0x36, 0x35, 0x36, 0x36, 0x36, 0x37, //
  0x36, 0x38, 0x36, 0x39, 0x37, 0x30, 0x37, 0x31, //
  0x37, 0x32, 0x37, 0x33, 0x37, 0x34, 0x37, 0x35, //
  0x37, 0x36, 0x37, 0x37, 0x37, 0x38, 0x37, 0x39, //
  0x38, 0x30, 0x38, 0x31, 0x38, 0x32, 0x38, 0x33, //
  0x38, 0x34, 0x38, 0x35, 0x38, 0x36, 0x38, 0x37, //
  0x38, 0x38, 0x38, 0x39, 0x39, 0x30, 0x39, 0x31, //
  0x39, 0x32, 0x39, 0x33, 0x39, 0x34, 0x39, 0x35, //
  0x39, 0x36, 0x39, 0x37, 0x39, 0x38, 0x39, 0x39, //
];

/**
 * Result of int.toString for -99, -98, ..., 98, 99.
 */
const _smallLookupTable = const [
  "-99", "-98", "-97", "-96", "-95", "-94", "-93", "-92", "-91", "-90", //
  "-89", "-88", "-87", "-86", "-85", "-84", "-83", "-82", "-81", "-80", //
  "-79", "-78", "-77", "-76", "-75", "-74", "-73", "-72", "-71", "-70", //
  "-69", "-68", "-67", "-66", "-65", "-64", "-63", "-62", "-61", "-60", //
  "-59", "-58", "-57", "-56", "-55", "-54", "-53", "-52", "-51", "-50", //
  "-49", "-48", "-47", "-46", "-45", "-44", "-43", "-42", "-41", "-40", //
  "-39", "-38", "-37", "-36", "-35", "-34", "-33", "-32", "-31", "-30", //
  "-29", "-28", "-27", "-26", "-25", "-24", "-23", "-22", "-21", "-20", //
  "-19", "-18", "-17", "-16", "-15", "-14", "-13", "-12", "-11", "-10", //
  "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "0", //
  "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", //
  "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", //
  "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", //
  "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", //
  "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", //
  "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", //
  "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", //
  "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", //
  "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", //
  "91", "92", "93", "94", "95", "96", "97", "98", "99" //
];

// Powers of 10 above 1000000 are indistinguishable by eye.
const int _POW_10_7 = 10000000;
const int _POW_10_8 = 100000000;
const int _POW_10_9 = 1000000000;

// Find the number of decimal digits in a positive smi.
// Never called with numbers < 100. These are handled before calling.
int _positiveBase10Length(int smi) {
  // A positive smi has length <= 19 if 63-bit,  <=10 if 31-bit.
  // Avoid comparing a 31-bit smi to a non-smi.
  if (smi < 1000) return 3;
  if (smi < 10000) return 4;
  if (smi < _POW_10_7) {
    if (smi < 100000) return 5;
    if (smi < 1000000) return 6;
    return 7;
  }
  if (smi < _POW_10_8) return 8;
  if (smi < _POW_10_9) return 9;
  smi = smi ~/ _POW_10_9;
  // Handle numbers < 100 before calling recursively.
  if (smi < 10) return 10;
  if (smi < 100) return 11;
  return 9 + _positiveBase10Length(smi);
}

String _intToString(int value) {
  if (value < 100 && value > -100) {
    // Issue(https://dartbug.com/39639): The analyzer incorrectly reports the
    // result type as `num`.
    return _smallLookupTable[value + 99];
  }
  if (value < 0) return _negativeToString(value);
  // Inspired by Andrei Alexandrescu: "Three Optimization Tips for C++"
  // Avoid expensive remainder operation by doing it on more than
  // one digit at a time.
  const int DIGIT_ZERO = 0x30;
  int length = _positiveBase10Length(value);
  final result = OneByteString.withLength(length);
  int index = length - 1;
  int smi = value;
  do {
    // Two digits at a time.
    final int twoDigits = smi.remainder(100);
    smi = smi ~/ 100;
    int digitIndex = twoDigits * 2;
    result.setUnchecked(index, _digitTable[digitIndex + 1]);
    result.setUnchecked(index - 1, _digitTable[digitIndex]);
    index -= 2;
  } while (smi >= 100);
  if (smi < 10) {
    // Character code for '0'.
    // Issue(https://dartbug.com/39639): The analyzer incorrectly reports the
    // result type as `num`.
    result.setUnchecked(index, DIGIT_ZERO + smi);
  } else {
    // No remainder for this case.
    // Issue(https://dartbug.com/39639): The analyzer incorrectly reports the
    // result type as `num`.
    int digitIndex = smi * 2;
    result.setUnchecked(index, _digitTable[digitIndex + 1]);
    result.setUnchecked(index - 1, _digitTable[digitIndex]);
  }
  return result;
}

// Find the number of decimal digits in a negative smi.
// Never called with numbers > -100. These are handled before calling.
int _negativeBase10Length(int negSmi) {
  // A negative smi has length <= 19 if 63-bit, <=10 if 31-bit.
  // Avoid comparing a 31-bit smi to a non-smi.
  if (negSmi > -1000) return 3;
  if (negSmi > -10000) return 4;
  if (negSmi > -_POW_10_7) {
    if (negSmi > -100000) return 5;
    if (negSmi > -1000000) return 6;
    return 7;
  }
  if (negSmi > -_POW_10_8) return 8;
  if (negSmi > -_POW_10_9) return 9;
  negSmi = negSmi ~/ _POW_10_9;
  // Handle numbers > -100 before calling recursively.
  if (negSmi > -10) return 10;
  if (negSmi > -100) return 11;
  return 9 + _negativeBase10Length(negSmi);
}

// Convert a negative smi to a string.
// Doesn't negate the smi to avoid negating the most negative smi, which
// would become a non-smi.
String _negativeToString(int negSmi) {
  // Character code for '-'
  const int MINUS_SIGN = 0x2d;
  // Character code for '0'.
  const int DIGIT_ZERO = 0x30;
  // Number of digits, not including minus.
  int digitCount = _negativeBase10Length(negSmi);
  final result = OneByteString.withLength(digitCount + 1);
  result.setUnchecked(0, MINUS_SIGN); // '-'.
  int index = digitCount;
  do {
    int twoDigits = unsafeCast<int>(negSmi.remainder(100));
    negSmi = negSmi ~/ 100;
    int digitIndex = -twoDigits * 2;
    result.setUnchecked(index, _digitTable[digitIndex + 1]);
    result.setUnchecked(index - 1, _digitTable[digitIndex]);
    index -= 2;
  } while (negSmi <= -100);
  if (negSmi > -10) {
    result.setUnchecked(index, DIGIT_ZERO - negSmi);
  } else {
    // No remainder necessary for this case.
    int digitIndex = -negSmi * 2;
    result.setUnchecked(index, _digitTable[digitIndex + 1]);
    result.setUnchecked(index - 1, _digitTable[digitIndex]);
  }
  return result;
}

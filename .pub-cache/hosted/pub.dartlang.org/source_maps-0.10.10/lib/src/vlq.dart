// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities to encode and decode VLQ values used in source maps.
///
/// Sourcemaps are encoded with variable length numbers as base64 encoded
/// strings with the least significant digit coming first. Each base64 digit
/// encodes a 5-bit value (0-31) and a continuation bit. Signed values can be
/// represented by using the least significant bit of the value as the sign bit.
///
/// For more details see the source map [version 3 documentation](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit?usp=sharing).
library source_maps.src.vlq;

import 'dart:math';

const int VLQ_BASE_SHIFT = 5;

const int VLQ_BASE_MASK = (1 << 5) - 1;

const int VLQ_CONTINUATION_BIT = 1 << 5;

const int VLQ_CONTINUATION_MASK = 1 << 5;

const String BASE64_DIGITS =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

final Map<String, int> _digits = () {
  var map = <String, int>{};
  for (var i = 0; i < 64; i++) {
    map[BASE64_DIGITS[i]] = i;
  }
  return map;
}();

final int MAX_INT32 = (pow(2, 31) as int) - 1;
final int MIN_INT32 = -(pow(2, 31) as int);

/// Creates the VLQ encoding of [value] as a sequence of characters
Iterable<String> encodeVlq(int value) {
  if (value < MIN_INT32 || value > MAX_INT32) {
    throw ArgumentError('expected 32 bit int, got: $value');
  }
  var res = <String>[];
  var signBit = 0;
  if (value < 0) {
    signBit = 1;
    value = -value;
  }
  value = (value << 1) | signBit;
  do {
    var digit = value & VLQ_BASE_MASK;
    value >>= VLQ_BASE_SHIFT;
    if (value > 0) {
      digit |= VLQ_CONTINUATION_BIT;
    }
    res.add(BASE64_DIGITS[digit]);
  } while (value > 0);
  return res;
}

/// Decodes a value written as a sequence of VLQ characters. The first input
/// character will be `chars.current` after calling `chars.moveNext` once. The
/// iterator is advanced until a stop character is found (a character without
/// the [VLQ_CONTINUATION_BIT]).
int decodeVlq(Iterator<String> chars) {
  var result = 0;
  var stop = false;
  var shift = 0;
  while (!stop) {
    if (!chars.moveNext()) throw StateError('incomplete VLQ value');
    var char = chars.current;
    var digit = _digits[char];
    if (digit == null) {
      throw FormatException('invalid character in VLQ encoding: $char');
    }
    stop = (digit & VLQ_CONTINUATION_BIT) == 0;
    digit &= VLQ_BASE_MASK;
    result += (digit << shift);
    shift += VLQ_BASE_SHIFT;
  }

  // Result uses the least significant bit as a sign bit. We convert it into a
  // two-complement value. For example,
  //   2 (10 binary) becomes 1
  //   3 (11 binary) becomes -1
  //   4 (100 binary) becomes 2
  //   5 (101 binary) becomes -2
  //   6 (110 binary) becomes 3
  //   7 (111 binary) becomes -3
  var negate = (result & 1) == 1;
  result = result >> 1;
  result = negate ? -result : result;

  // TODO(sigmund): can we detect this earlier?
  if (result < MIN_INT32 || result > MAX_INT32) {
    throw FormatException(
        'expected an encoded 32 bit int, but we got: $result');
  }
  return result;
}

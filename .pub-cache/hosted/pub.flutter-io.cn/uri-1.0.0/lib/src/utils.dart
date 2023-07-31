// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Encode code points as UTF-8 code units.
///
/// Brought in from pkg:utf
/// https://github.com/dart-archive/utf/blob/7dc59db0b44ac5a50539b1a326d2001801e40d58/lib/src/utf8.dart#L69
///
/// Local modifications since only one input value is needed.
List<int> codePointToUtf8(int value) {
  var encodedLength = 0;
  if (value < 0 || value > _unicodeValidRangeMax) {
    encodedLength += 3;
  } else if (value <= _utf8OneByteMax) {
    encodedLength++;
  } else if (value <= _utf8TwoByteMax) {
    encodedLength += 2;
  } else if (value <= _utf8ThreeByteMax) {
    encodedLength += 3;
  } else if (value <= _unicodeValidRangeMax) {
    encodedLength += 4;
  }

  final encoded = List<int>.filled(encodedLength, 0);
  var insertAt = 0;
  if (value < 0 || value > _unicodeValidRangeMax) {
    encoded.setRange(insertAt, insertAt + 3, [0xef, 0xbf, 0xbd]);
    insertAt += 3;
  } else if (value <= _utf8OneByteMax) {
    encoded[insertAt] = value;
    insertAt++;
  } else if (value <= _utf8TwoByteMax) {
    encoded[insertAt] = _utf8FirstByteOfTwoBase |
        (_utf8FirstByteOfTwoMask & _addToEncoding(insertAt, 1, value, encoded));
    insertAt += 2;
  } else if (value <= _utf8ThreeByteMax) {
    encoded[insertAt] = _utf8FirstByteOfThreeBase |
        (_utf8FirstByteOfThreeMask &
            _addToEncoding(insertAt, 2, value, encoded));
    insertAt += 3;
  } else if (value <= _unicodeValidRangeMax) {
    encoded[insertAt] = _utf8FirstByteOfFourBase |
        (_utf8FirstByteOfFourMask &
            _addToEncoding(insertAt, 3, value, encoded));
    insertAt += 4;
  }
  return encoded;
}

int _addToEncoding(int offset, int bytes, int value, List<int> buffer) {
  while (bytes > 0) {
    buffer[offset + bytes] =
        _utf8SubsequentByteBase | (value & _utf8LoSixBitMask);
    value = value >> 6;
    bytes--;
  }
  return value;
}

const _utf8OneByteMax = 0x7f;
const _utf8TwoByteMax = 0x7ff;
const _utf8ThreeByteMax = 0xffff;

const _utf8LoSixBitMask = 0x3f;

const _utf8FirstByteOfTwoBase = 0xc0;
const _utf8FirstByteOfThreeBase = 0xe0;
const _utf8FirstByteOfFourBase = 0xf0;

const _utf8FirstByteOfTwoMask = 0x1f;
const _utf8FirstByteOfThreeMask = 0xf;
const _utf8FirstByteOfFourMask = 0x7;

const _utf8SubsequentByteBase = 0x80;

const _unicodeValidRangeMax = 0x10ffff;

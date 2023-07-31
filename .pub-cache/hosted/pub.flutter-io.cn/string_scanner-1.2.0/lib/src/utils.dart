// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'string_scanner.dart';

/// Validates the arguments passed to [StringScanner.error].
void validateErrorArgs(
    String string, Match? match, int? position, int? length) {
  if (match != null && (position != null || length != null)) {
    throw ArgumentError("Can't pass both match and position/length.");
  }

  if (position != null) {
    if (position < 0) {
      throw RangeError('position must be greater than or equal to 0.');
    } else if (position > string.length) {
      throw RangeError('position must be less than or equal to the '
          'string length.');
    }
  }

  if (length != null && length < 0) {
    throw RangeError('length must be greater than or equal to 0.');
  }

  if (position != null && length != null && position + length > string.length) {
    throw RangeError('position plus length must not go beyond the end of '
        'the string.');
  }
}

// See https://en.wikipedia.org/wiki/UTF-16#Code_points_from_U+010000_to_U+10FFFF
// for documentation on how UTF-16 encoding works and definitions of various
// related terms.

/// The inclusive lower bound of Unicode's supplementary plane.
const _supplementaryPlaneLowerBound = 0x10000;

/// The inclusive upper bound of Unicode's supplementary plane.
const _supplementaryPlaneUpperBound = 0x10FFFF;

/// The inclusive lower bound of the UTF-16 high surrogate block.
const _highSurrogateLowerBound = 0xD800;

/// The inclusive lower bound of the UTF-16 low surrogate block.
const _lowSurrogateLowerBound = 0xDC00;

/// The number of low bits in each code unit of a surrogate pair that goes into
/// determining which code point it encodes.
const _surrogateBits = 10;

/// A bit mask that covers the lower [_surrogateBits] of a code point, which can
/// be used to extract the value of a surrogate or the low surrogate value of a
/// code unit.
const _surrogateValueMask = (1 << _surrogateBits) - 1;

/// Returns whether [codePoint] is in the Unicode supplementary plane, and thus
/// must be represented as a surrogate pair in UTF-16.
bool inSupplementaryPlane(int codePoint) =>
    codePoint >= _supplementaryPlaneLowerBound &&
    codePoint <= _supplementaryPlaneUpperBound;

/// Returns whether [codeUnit] is a UTF-16 high surrogate.
bool isHighSurrogate(int codeUnit) =>
    (codeUnit & ~_surrogateValueMask) == _highSurrogateLowerBound;

/// Returns whether [codeUnit] is a UTF-16 low surrogate.
bool isLowSurrogate(int codeUnit) =>
    (codeUnit >> _surrogateBits) == (_lowSurrogateLowerBound >> _surrogateBits);

/// Returns the high surrogate needed to encode the supplementary-plane
/// [codePoint].
int highSurrogate(int codePoint) {
  assert(inSupplementaryPlane(codePoint));
  return ((codePoint - _supplementaryPlaneLowerBound) >> _surrogateBits) +
      _highSurrogateLowerBound;
}

/// Returns the low surrogate needed to encode the supplementary-plane
/// [codePoint].
int lowSurrogate(int codePoint) {
  assert(inSupplementaryPlane(codePoint));
  return ((codePoint - _supplementaryPlaneLowerBound) & _surrogateValueMask) +
      _lowSurrogateLowerBound;
}

/// Converts a UTF-16 surrogate pair into the Unicode code unit it represents.
int decodeSurrogatePair(int highSurrogate, int lowSurrogate) {
  assert(isHighSurrogate(highSurrogate));
  assert(isLowSurrogate(lowSurrogate));
  return _supplementaryPlaneLowerBound +
      (((highSurrogate & _surrogateValueMask) << _surrogateBits) |
          (lowSurrogate & _surrogateValueMask));
}

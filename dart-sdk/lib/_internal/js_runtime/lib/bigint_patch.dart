// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'core_patch.dart';

@patch
class BigInt implements Comparable<BigInt> {
  @patch
  static BigInt get zero => _BigIntImpl.zero;
  @patch
  static BigInt get one => _BigIntImpl.one;
  @patch
  static BigInt get two => _BigIntImpl.two;

  @patch
  static BigInt parse(String source, {int? radix}) =>
      _BigIntImpl.parse(source, radix: radix);

  @patch
  static BigInt? tryParse(String source, {int? radix}) =>
      _BigIntImpl._tryParse(source, radix: radix);

  @patch
  factory BigInt.from(num value) = _BigIntImpl.from;
}

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;

/// Empty list used as an initializer for local variables in the `_BigIntImpl`.
final _dummyList = Uint16List(0);

/*
 * Copyright (c) 2003-2005  Tom Wu
 * Copyright (c) 2012 Adam Singer (adam@solvr.io)
 * All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
 * WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
 *
 * IN NO EVENT SHALL TOM WU BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER
 * RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER OR NOT ADVISED OF
 * THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF LIABILITY, ARISING OUT
 * OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * In addition, the following condition applies:
 *
 * All redistributions must retain an intact copy of this copyright notice
 * and disclaimer.
 */

/// An implementation for the arbitrarily large integer.
///
/// The integer number is represented by a sign, an array of 16-bit unsigned
/// integers in little endian format, and a number of used digits in that array.
class _BigIntImpl implements BigInt {
  // Bits per digit.
  static const int _digitBits = 16;
  static const int _digitBase = 1 << _digitBits;
  static const int _digitMask = (1 << _digitBits) - 1;

  static final _BigIntImpl zero = _BigIntImpl._fromInt(0);
  static final _BigIntImpl one = _BigIntImpl._fromInt(1);
  static final _BigIntImpl two = _BigIntImpl._fromInt(2);

  static final _BigIntImpl _minusOne = -one;
  static final _BigIntImpl _bigInt10000 = _BigIntImpl._fromInt(10000);

  // Result cache for last _divRem call.
  // Result cache for last _divRem call.
  static Uint16List? _lastDividendDigits;
  static int? _lastDividendUsed;
  static Uint16List? _lastDivisorDigits;
  static int? _lastDivisorUsed;
  static late Uint16List _lastQuoRemDigits;
  static late int _lastQuoRemUsed;
  static late int _lastRemUsed;
  static late int _lastRem_nsh;

  /// Whether this bigint is negative.
  final bool _isNegative;

  /// The unsigned digits of this bigint.
  ///
  /// The least significant digit is in slot 0.
  /// The list may have more digits than needed. That is, `_digits.length` may
  /// be strictly greater than `_used`.
  final Uint16List _digits;

  /// The number of used entries in [_digits].
  ///
  /// To avoid reallocating [Uint16List]s, lists that are too big are not
  /// replaced.
  final int _used;

  /// Parses [source] as a, possibly signed, integer literal and returns its
  /// value.
  ///
  /// The [source] must be a non-empty sequence of base-[radix] digits,
  /// optionally prefixed with a minus or plus sign ('-' or '+').
  ///
  /// The [radix] must be in the range 2..36. The digits used are
  /// first the decimal digits 0..9, and then the letters 'a'..'z' with
  /// values 10 through 35. Also accepts upper-case letters with the same
  /// values as the lower-case ones.
  ///
  /// If no [radix] is given then it defaults to 10. In this case, the [source]
  /// digits may also start with `0x`, in which case the number is interpreted
  /// as a hexadecimal literal, which effectively means that the `0x` is ignored
  /// and the radix is instead set to 16.
  ///
  /// For any int `n` and radix `r`, it is guaranteed that
  /// `n == int.parse(n.toRadixString(r), radix: r)`.
  ///
  /// Throws a [FormatException] if the [source] is not a valid integer literal,
  /// optionally prefixed by a sign.
  static _BigIntImpl parse(String source, {int? radix}) {
    var result = _tryParse(source, radix: radix);
    if (result == null) {
      throw FormatException("Could not parse BigInt", source);
    }
    return result;
  }

  /// Parses a decimal bigint literal.
  ///
  /// The [source] must not contain leading or trailing whitespace.
  static _BigIntImpl _parseDecimal(String source, bool isNegative) {
    const _0 = 48;

    int part = 0;
    _BigIntImpl result = zero;
    // Read in the source 4 digits at a time.
    // The first part may have a few leading virtual '0's to make the remaining
    // parts all have exactly 4 digits.
    var digitInPartCount = 4 - source.length.remainder(4);
    if (digitInPartCount == 4) digitInPartCount = 0;
    for (int i = 0; i < source.length; i++) {
      part = part * 10 + source.codeUnitAt(i) - _0;
      if (++digitInPartCount == 4) {
        result = result * _bigInt10000 + _BigIntImpl._fromInt(part);
        part = 0;
        digitInPartCount = 0;
      }
    }
    if (isNegative) return -result;
    return result;
  }

  /// Returns the value of a given source digit.
  ///
  /// Source digits between "0" and "9" (inclusive) return their decimal value.
  ///
  /// Source digits between "a" and "z", or "A" and "Z" (inclusive) return
  /// 10 + their position in the ASCII alphabet.
  ///
  /// The incoming [codeUnit] must be an ASCII code-unit.
  static int _codeUnitToRadixValue(int codeUnit) {
    // We know that the characters must be ASCII as otherwise the
    // regexp wouldn't have matched. Lowercasing by doing `| 0x20` is thus
    // guaranteed to be a safe operation, since it preserves digits
    // and lower-cases ASCII letters.
    const int _0 = 48;
    const int _9 = 57;
    const int _a = 97;
    if (_0 <= codeUnit && codeUnit <= _9) return codeUnit - _0;
    codeUnit |= 0x20;
    var result = codeUnit - _a + 10;
    return result;
  }

  /// Parses the given [source] string, starting at [startPos], as a hex
  /// literal.
  ///
  /// If [isNegative] is true, negates the result before returning it.
  ///
  /// The [source] (substring) must be a valid hex literal.
  static _BigIntImpl? _parseHex(String source, int startPos, bool isNegative) {
    int hexDigitsPerChunk = _digitBits ~/ 4;
    int sourceLength = source.length - startPos;
    int chunkCount = (sourceLength / hexDigitsPerChunk).ceil();
    var digits = Uint16List(chunkCount);

    int lastDigitLength = sourceLength - (chunkCount - 1) * hexDigitsPerChunk;
    int digitIndex = digits.length - 1;
    int i = startPos;
    int chunk = 0;
    for (int j = 0; j < lastDigitLength; j++) {
      var digitValue = _codeUnitToRadixValue(source.codeUnitAt(i++));
      if (digitValue >= 16) return null;
      chunk = chunk * 16 + digitValue;
    }
    digits[digitIndex--] = chunk;

    while (i < source.length) {
      chunk = 0;
      for (int j = 0; j < hexDigitsPerChunk; j++) {
        var digitValue = _codeUnitToRadixValue(source.codeUnitAt(i++));
        if (digitValue >= 16) return null;
        chunk = chunk * 16 + digitValue;
      }
      digits[digitIndex--] = chunk;
    }
    if (digits.length == 1 && digits[0] == 0) return zero;
    return _BigIntImpl._(isNegative, digits.length, digits);
  }

  /// Parses the given [source] as a [radix] literal.
  ///
  /// The [source] will be checked for invalid characters. If it is invalid,
  /// this function returns `null`.
  static _BigIntImpl? _parseRadix(String source, int radix, bool isNegative) {
    var result = zero;
    var base = _BigIntImpl._fromInt(radix);
    for (int i = 0; i < source.length; i++) {
      var digitValue = _codeUnitToRadixValue(source.codeUnitAt(i));
      if (digitValue >= radix) return null;
      result = result * base + _BigIntImpl._fromInt(digitValue);
    }
    if (isNegative) return -result;
    return result;
  }

  /// Tries to parse the given [source] as a [radix] literal.
  ///
  /// Returns the parsed big integer, or `null` if it failed.
  ///
  /// If the [radix] is `null` accepts decimal literals or `0x` hex literals.
  static _BigIntImpl? _tryParse(String source, {int? radix}) {
    if (source == "") return null;

    var match = _parseRE.firstMatch(source);
    int signIndex = 1;
    int hexIndex = 3;
    int decimalIndex = 4;
    int nonDecimalHexIndex = 5;
    if (match == null) return null;

    bool isNegative = match[signIndex] == "-";

    String? decimalMatch = match[decimalIndex];
    String? hexMatch = match[hexIndex];
    String? nonDecimalMatch = match[nonDecimalHexIndex];

    if (radix == null) {
      if (decimalMatch != null) {
        // Cannot fail because we know that the digits are all decimal.
        return _parseDecimal(decimalMatch, isNegative);
      }
      if (hexMatch != null) {
        // Cannot fail because we know that the digits are all hex.
        return _parseHex(hexMatch, 2, isNegative);
      }
      return null;
    }

    if (radix is! int) {
      throw ArgumentError.value(radix, 'radix', 'is not an integer');
    }
    if (radix < 2 || radix > 36) {
      throw RangeError.range(radix, 2, 36, 'radix');
    }
    if (radix == 10 && decimalMatch != null) {
      return _parseDecimal(decimalMatch, isNegative);
    }
    if (radix == 16 && (decimalMatch != null || nonDecimalMatch != null)) {
      return _parseHex(decimalMatch ?? nonDecimalMatch!, 0, isNegative);
    }

    return _parseRadix(
        decimalMatch ?? nonDecimalMatch ?? hexMatch!, radix, isNegative);
  }

  static RegExp _parseRE = RegExp(
      r'^\s*([+-]?)((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$',
      caseSensitive: false);

  /// Finds the amount significant digits in the provided [digits] array.
  static int _normalize(int used, Uint16List digits) {
    while (used > 0 && digits[used - 1] == 0) used--;
    return 0 + used; // force inferred result to be non-null.
  }

  /// Factory returning an instance initialized with the given field values.
  /// If the [digits] array contains leading 0s, the [used] value is adjusted
  /// accordingly. The [digits] array is not modified.
  _BigIntImpl._(bool isNegative, int used, Uint16List digits)
      : this._normalized(isNegative, _normalize(used, digits), digits);

  _BigIntImpl._normalized(bool isNegative, this._used, this._digits)
      : _isNegative = _used == 0 ? false : isNegative;

  /// Whether this big integer is zero.
  bool get _isZero => _used == 0;

  /// Allocates an array of the given [length] and copies the [digits] in the
  /// range [from] to [to-1], starting at index 0, followed by leading zero
  /// digits.
  static Uint16List _cloneDigits(
      Uint16List digits, int from, int to, int length) {
    var resultDigits = Uint16List(length);
    var n = to - from;
    for (var i = 0; i < n; i++) {
      resultDigits[i] = digits[from + i];
    }
    return resultDigits;
  }

  /// Allocates a big integer from the provided [value] number.
  factory _BigIntImpl.from(num value) {
    if (value == 0) return zero;
    if (value == 1) return one;
    if (value == 2) return two;

    // Given this order dart2js will use the `_fromInt` for smaller value and
    // then use the bit-manipulating `_fromDouble` for all other values.
    if (value.abs() < 0x100000000) return _BigIntImpl._fromInt(value.toInt());
    if (value is double) return _BigIntImpl._fromDouble(value);
    return _BigIntImpl._fromInt(value as int);
  }

  factory _BigIntImpl._fromInt(int value) {
    bool isNegative = value < 0;
    assert(_digitBits == 16);
    if (isNegative) {
      // Handle the min 64-bit value differently, since its negation is not
      // positive.
      const int minInt64 = -0x80000000 * 0x100000000;
      if (value == minInt64) {
        var digits = Uint16List(4);
        digits[3] = 0x8000;
        return _BigIntImpl._(true, 4, digits);
      }
      value = -value;
    }
    if (value < _digitBase) {
      var digits = Uint16List(1);
      digits[0] = value;
      return _BigIntImpl._(isNegative, 1, digits);
    }
    if (value <= 0xFFFFFFFF) {
      var digits = Uint16List(2);
      digits[0] = value & _digitMask;
      digits[1] = value >> _digitBits;
      return _BigIntImpl._(isNegative, 2, digits);
    }

    var bits = value.bitLength;
    var digits = Uint16List((bits - 1) ~/ _digitBits + 1);
    var i = 0;
    while (value != 0) {
      digits[i++] = value & _digitMask;
      value = value ~/ _digitBase;
    }
    return _BigIntImpl._(isNegative, digits.length, digits);
  }

  /// An 8-byte Uint8List we can reuse for [_fromDouble] to avoid generating
  /// garbage.
  static final Uint8List _bitsForFromDouble = Uint8List(8);

  factory _BigIntImpl._fromDouble(double value) {
    const int exponentBias = 1075;

    if (value.isNaN || value.isInfinite) {
      throw ArgumentError("Value must be finite: $value");
    }
    bool isNegative = value < 0;
    if (isNegative) value = -value;

    value = value.floorToDouble();
    if (value == 0) return zero;

    var bits = _bitsForFromDouble;
    for (int i = 0; i < 8; i++) {
      bits[i] = 0;
    }
    bits.buffer.asByteData().setFloat64(0, value, Endian.little);
    // The exponent is in bits 53..63.
    var biasedExponent = (bits[7] << 4) + (bits[6] >> 4);
    var exponent = biasedExponent - exponentBias;

    assert(_digitBits == 16);
    // The significant bits are in 0 .. 52.
    var unshiftedDigits = Uint16List(4);
    unshiftedDigits[0] = (bits[1] << 8) + bits[0];
    unshiftedDigits[1] = (bits[3] << 8) + bits[2];
    unshiftedDigits[2] = (bits[5] << 8) + bits[4];
    // Don't forget to add the hidden bit.
    unshiftedDigits[3] = 0x10 | (bits[6] & 0xF);

    var unshiftedBig = _BigIntImpl._normalized(false, 4, unshiftedDigits);
    _BigIntImpl absResult = unshiftedBig;
    if (exponent < 0) {
      absResult = unshiftedBig >> -exponent;
    } else if (exponent > 0) {
      absResult = unshiftedBig << exponent;
    }
    if (isNegative) return -absResult;
    return absResult;
  }

  /// Return the negative value of this integer.
  ///
  /// The result of negating an integer always has the opposite sign, except
  /// for zero, which is its own negation.
  _BigIntImpl operator -() {
    if (_used == 0) return this;
    return _BigIntImpl._(!_isNegative, _used, _digits);
  }

  /// Returns the absolute value of this integer.
  ///
  /// For any integer `x`, the result is the same as `x < 0 ? -x : x`.
  _BigIntImpl abs() => _isNegative ? -this : this;

  /// Returns this << n *_DIGIT_BITS.
  _BigIntImpl _dlShift(int n) {
    final used = _used;
    if (used == 0) {
      return zero;
    }
    final resultUsed = used + n;
    final digits = _digits;
    final resultDigits = Uint16List(resultUsed);
    for (int i = used - 1; i >= 0; i--) {
      resultDigits[i + n] = digits[i];
    }
    return _BigIntImpl._(_isNegative, resultUsed, resultDigits);
  }

  /// Same as [_dlShift] but works on the decomposed big integers.
  ///
  /// Returns `resultUsed`.
  ///
  /// `resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] << n*_DIGIT_BITS`.
  static int _dlShiftDigits(
      Uint16List xDigits, int xUsed, int n, Uint16List resultDigits) {
    if (xUsed == 0) {
      return 0;
    }
    if (n == 0 && identical(resultDigits, xDigits)) {
      return xUsed;
    }
    final resultUsed = xUsed + n;
    for (int i = xUsed - 1; i >= 0; i--) {
      resultDigits[i + n] = xDigits[i];
    }
    for (int i = n - 1; i >= 0; i--) {
      resultDigits[i] = 0;
    }
    return resultUsed;
  }

  /// Returns `this >> n*_DIGIT_BITS`.
  _BigIntImpl _drShift(int n) {
    final used = _used;
    if (used == 0) {
      return zero;
    }
    final resultUsed = used - n;
    if (resultUsed <= 0) {
      return _isNegative ? _minusOne : zero;
    }
    final digits = _digits;
    final resultDigits = Uint16List(resultUsed);
    for (var i = n; i < used; i++) {
      resultDigits[i - n] = digits[i];
    }
    final result = _BigIntImpl._(_isNegative, resultUsed, resultDigits);
    if (_isNegative) {
      // Round down if any bit was shifted out.
      for (var i = 0; i < n; i++) {
        if (digits[i] != 0) {
          return result - one;
        }
      }
    }
    return result;
  }

  /// Shifts the digits of [xDigits] into the right place in [resultDigits].
  ///
  /// `resultDigits[ds..xUsed+ds] = xDigits[0..xUsed-1] << (n % _DIGIT_BITS)`
  ///   where `ds = n ~/ _DIGIT_BITS`
  ///
  /// Does *not* clear digits below ds.
  static void _lsh(
      Uint16List xDigits, int xUsed, int n, Uint16List resultDigits) {
    assert(xUsed > 0);
    final digitShift = n ~/ _digitBits;
    final bitShift = n % _digitBits;
    final carryBitShift = _digitBits - bitShift;
    final bitMask = (1 << carryBitShift) - 1;
    var carry = 0;
    for (int i = xUsed - 1; i >= 0; i--) {
      final digit = xDigits[i];
      resultDigits[i + digitShift + 1] = (digit >> carryBitShift) | carry;
      carry = (digit & bitMask) << bitShift;
    }
    resultDigits[digitShift] = carry;
  }

  /// Shift the bits of this integer to the left by [shiftAmount].
  ///
  /// Shifting to the left makes the number larger, effectively multiplying
  /// the number by `pow(2, shiftIndex)`.
  ///
  /// There is no limit on the size of the result. It may be relevant to
  /// limit intermediate values by using the "and" operator with a suitable
  /// mask.
  ///
  /// It is an error if [shiftAmount] is negative.
  _BigIntImpl operator <<(int shiftAmount) {
    if (shiftAmount < 0) {
      throw ArgumentError("shift-amount must be posititve $shiftAmount");
    }
    if (_isZero) return this;
    final digitShift = shiftAmount ~/ _digitBits;
    final bitShift = shiftAmount % _digitBits;
    if (bitShift == 0) {
      return _dlShift(digitShift);
    }
    var resultUsed = _used + digitShift + 1;
    var resultDigits = Uint16List(resultUsed);
    _lsh(_digits, _used, shiftAmount, resultDigits);
    return _BigIntImpl._(_isNegative, resultUsed, resultDigits);
  }

  // resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] << n.
  // Returns resultUsed.
  static int _lShiftDigits(
      Uint16List xDigits, int xUsed, int n, Uint16List resultDigits) {
    final digitsShift = n ~/ _digitBits;
    final bitShift = n % _digitBits;
    if (bitShift == 0) {
      return _dlShiftDigits(xDigits, xUsed, digitsShift, resultDigits);
    }
    var resultUsed = xUsed + digitsShift + 1;
    _lsh(xDigits, xUsed, n, resultDigits);
    var i = digitsShift;
    while (--i >= 0) {
      resultDigits[i] = 0;
    }
    if (resultDigits[resultUsed - 1] == 0) {
      resultUsed--; // Clamp result.
    }
    return resultUsed;
  }

  // resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] >> n.
  static void _rsh(
      Uint16List xDigits, int xUsed, int n, Uint16List resultDigits) {
    assert(xUsed > 0);
    final digitsShift = n ~/ _digitBits;
    final bitShift = n % _digitBits;
    final carryBitShift = _digitBits - bitShift;
    final bitMask = (1 << bitShift) - 1;
    var carry = xDigits[digitsShift] >> bitShift;
    final last = xUsed - digitsShift - 1;
    for (var i = 0; i < last; i++) {
      final digit = xDigits[i + digitsShift + 1];
      resultDigits[i] = ((digit & bitMask) << carryBitShift) | carry;
      carry = digit >> bitShift;
    }
    resultDigits[last] = carry;
  }

  /// Shift the bits of this integer to the right by [shiftAmount].
  ///
  /// Shifting to the right makes the number smaller and drops the least
  /// significant bits, effectively doing an integer division by
  /// `pow(2, shiftIndex)`.
  ///
  /// It is an error if [shiftAmount] is negative.
  _BigIntImpl operator >>(int shiftAmount) {
    if (shiftAmount < 0) {
      throw ArgumentError("shift-amount must be posititve $shiftAmount");
    }
    if (_isZero) return this;
    final digitShift = shiftAmount ~/ _digitBits;
    final bitShift = shiftAmount % _digitBits;
    if (bitShift == 0) {
      return _drShift(digitShift);
    }
    final used = _used;
    final resultUsed = used - digitShift;
    if (resultUsed <= 0) {
      return _isNegative ? _minusOne : zero;
    }
    final digits = _digits;
    final resultDigits = Uint16List(resultUsed);
    _rsh(digits, used, shiftAmount, resultDigits);
    final result = _BigIntImpl._(_isNegative, resultUsed, resultDigits);
    if (_isNegative) {
      // Round down if any bit was shifted out.
      if ((digits[digitShift] & ((1 << bitShift) - 1)) != 0) {
        return result - one;
      }
      for (var i = 0; i < digitShift; i++) {
        if (digits[i] != 0) {
          return result - one;
        }
      }
    }
    return result;
  }

  /// Compares this to [other] taking the absolute value of both operands.
  ///
  /// Returns 0 if abs(this) == abs(other); a positive number if
  /// abs(this) > abs(other); and a negative number if abs(this) < abs(other).
  int _absCompare(_BigIntImpl other) {
    return _compareDigits(_digits, _used, other._digits, other._used);
  }

  /// Compares this to `other`.
  ///
  /// Returns a negative number if `this` is less than `other`, zero if they are
  /// equal, and a positive number if `this` is greater than `other`.
  int compareTo(covariant _BigIntImpl other) {
    if (_isNegative == other._isNegative) {
      var result = _absCompare(other);
      // Use 0 - result to avoid negative zero in JavaScript.
      return _isNegative ? 0 - result : result;
    }
    return _isNegative ? -1 : 1;
  }

  /// Compares `digits[0..used-1]` with `otherDigits[0..otherUsed-1]`.
  ///
  /// Returns 0 if equal; a positive number if larger;
  /// and a negative number if smaller.
  static int _compareDigits(
      Uint16List digits, int used, Uint16List otherDigits, int otherUsed) {
    var result = used - otherUsed;
    if (result == 0) {
      for (int i = used - 1; i >= 0; i--) {
        result = digits[i] - otherDigits[i];
        if (result != 0) return result;
      }
    }
    return result;
  }

  // resultDigits[0..used] = digits[0..used-1] + otherDigits[0..otherUsed-1].
  // used >= otherUsed > 0.
  static void _absAdd(Uint16List digits, int used, Uint16List otherDigits,
      int otherUsed, Uint16List resultDigits) {
    assert(used >= otherUsed && otherUsed > 0);
    var carry = 0;
    for (var i = 0; i < otherUsed; i++) {
      carry += digits[i] + otherDigits[i];
      resultDigits[i] = carry & _digitMask;
      carry >>= _digitBits;
    }
    for (var i = otherUsed; i < used; i++) {
      carry += digits[i];
      resultDigits[i] = carry & _digitMask;
      carry >>= _digitBits;
    }
    resultDigits[used] = carry;
  }

  // resultDigits[0..used-1] = digits[0..used-1] - otherDigits[0..otherUsed-1].
  // used >= otherUsed > 0.
  static void _absSub(Uint16List digits, int used, Uint16List otherDigits,
      int otherUsed, Uint16List resultDigits) {
    assert(used >= otherUsed && otherUsed > 0);

    var carry = 0;
    for (var i = 0; i < otherUsed; i++) {
      carry += digits[i] - otherDigits[i];
      resultDigits[i] = carry & _digitMask;
      // Dart2js only supports unsigned shifts.
      // Since the carry can only be -1 or 0 use this hack.
      carry = 0 - ((carry >> _digitBits) & 1);
    }
    for (var i = otherUsed; i < used; i++) {
      carry += digits[i];
      resultDigits[i] = carry & _digitMask;
      // Dart2js only supports unsigned shifts.
      // Since the carry can only be -1 or 0 use this hack.
      carry = 0 - ((carry >> _digitBits) & 1);
    }
  }

  /// Returns `abs(this) + abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absAddSetSign(_BigIntImpl other, bool isNegative) {
    var used = _used;
    var otherUsed = other._used;
    if (used < otherUsed) {
      return other._absAddSetSign(this, isNegative);
    }
    if (used == 0) {
      assert(!isNegative);
      return zero;
    }
    if (otherUsed == 0) {
      return _isNegative == isNegative ? this : -this;
    }
    var resultUsed = used + 1;
    var resultDigits = Uint16List(resultUsed);
    _absAdd(_digits, used, other._digits, otherUsed, resultDigits);
    return _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) - abs(other)` with sign set according to [isNegative].
  ///
  /// Requirement: `abs(this) >= abs(other)`.
  _BigIntImpl _absSubSetSign(_BigIntImpl other, bool isNegative) {
    assert(_absCompare(other) >= 0);
    var used = _used;
    if (used == 0) {
      assert(!isNegative);
      return zero;
    }
    var otherUsed = other._used;
    if (otherUsed == 0) {
      return _isNegative == isNegative ? this : -this;
    }
    var resultDigits = Uint16List(used);
    _absSub(_digits, used, other._digits, otherUsed, resultDigits);
    return _BigIntImpl._(isNegative, used, resultDigits);
  }

  /// Returns `abs(this) & abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absAndSetSign(_BigIntImpl other, bool isNegative) {
    var resultUsed = _min(_used, other._used);
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = Uint16List(resultUsed);
    for (var i = 0; i < resultUsed; i++) {
      resultDigits[i] = digits[i] & otherDigits[i];
    }
    return _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) &~ abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absAndNotSetSign(_BigIntImpl other, bool isNegative) {
    var resultUsed = _used;
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = Uint16List(resultUsed);
    var m = _min(resultUsed, other._used);
    for (var i = 0; i < m; i++) {
      resultDigits[i] = digits[i] & ~otherDigits[i];
    }
    for (var i = m; i < resultUsed; i++) {
      resultDigits[i] = digits[i];
    }
    return _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) | abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absOrSetSign(_BigIntImpl other, bool isNegative) {
    var used = _used;
    var otherUsed = other._used;
    var resultUsed = _max(used, otherUsed);
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = Uint16List(resultUsed);
    _BigIntImpl l;
    int m;
    if (used < otherUsed) {
      l = other;
      m = used;
    } else {
      l = this;
      m = otherUsed;
    }
    for (var i = 0; i < m; i++) {
      resultDigits[i] = digits[i] | otherDigits[i];
    }
    var lDigits = l._digits;
    for (var i = m; i < resultUsed; i++) {
      resultDigits[i] = lDigits[i];
    }
    return _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) ^ abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absXorSetSign(_BigIntImpl other, bool isNegative) {
    var used = _used;
    var otherUsed = other._used;
    var resultUsed = _max(used, otherUsed);
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = Uint16List(resultUsed);
    _BigIntImpl l;
    int m;
    if (used < otherUsed) {
      l = other;
      m = used;
    } else {
      l = this;
      m = otherUsed;
    }
    for (var i = 0; i < m; i++) {
      resultDigits[i] = digits[i] ^ otherDigits[i];
    }
    var lDigits = l._digits;
    for (var i = m; i < resultUsed; i++) {
      resultDigits[i] = lDigits[i];
    }
    return _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Bit-wise and operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with only the bits set that are set in
  /// both `this` and [other]
  ///
  /// Of both operands are negative, the result is negative, otherwise
  /// the result is non-negative.
  _BigIntImpl operator &(covariant _BigIntImpl other) {
    if (_isZero || other._isZero) return zero;
    if (_isNegative == other._isNegative) {
      if (_isNegative) {
        // (-this) & (-other) == ~(this-1) & ~(other-1)
        //                    == ~((this-1) | (other-1))
        //                    == -(((this-1) | (other-1)) + 1)
        _BigIntImpl this1 = _absSubSetSign(one, true);
        _BigIntImpl other1 = other._absSubSetSign(one, true);
        // Result cannot be zero if this and other are negative.
        return this1._absOrSetSign(other1, true)._absAddSetSign(one, true);
      }
      return _absAndSetSign(other, false);
    }
    // _isNegative != other._isNegative
    _BigIntImpl p, n;
    if (_isNegative) {
      p = other;
      n = this;
    } else {
      // & is symmetric.
      p = this;
      n = other;
    }
    // p & (-n) == p & ~(n-1) == p &~ (n-1)
    var n1 = n._absSubSetSign(one, false);
    return p._absAndNotSetSign(n1, false);
  }

  /// Bit-wise or operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with the bits set that are set in either
  /// of `this` and [other]
  ///
  /// If both operands are non-negative, the result is non-negative,
  /// otherwise the result us negative.
  _BigIntImpl operator |(covariant _BigIntImpl other) {
    if (_isZero) return other;
    if (other._isZero) return this;
    if (_isNegative == other._isNegative) {
      if (_isNegative) {
        // (-this) | (-other) == ~(this-1) | ~(other-1)
        //                    == ~((this-1) & (other-1))
        //                    == -(((this-1) & (other-1)) + 1)
        var this1 = _absSubSetSign(one, true);
        var other1 = other._absSubSetSign(one, true);
        // Result cannot be zero if this and a are negative.
        return this1._absAndSetSign(other1, true)._absAddSetSign(one, true);
      }
      return _absOrSetSign(other, false);
    }
    // _neg != a._neg
    _BigIntImpl p, n;
    if (_isNegative) {
      p = other;
      n = this;
    } else {
      // | is symmetric.
      p = this;
      n = other;
    }
    // p | (-n) == p | ~(n-1) == ~((n-1) &~ p) == -(~((n-1) &~ p) + 1)
    var n1 = n._absSubSetSign(one, true);
    // Result cannot be zero if only one of this or a is negative.
    return n1._absAndNotSetSign(p, true)._absAddSetSign(one, true);
  }

  /// Bit-wise exclusive-or operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with the bits set that are set in one,
  /// but not both, of `this` and [other]
  ///
  /// If the operands have the same sign, the result is non-negative,
  /// otherwise the result is negative.
  _BigIntImpl operator ^(covariant _BigIntImpl other) {
    if (_isZero) return other;
    if (other._isZero) return this;
    if (_isNegative == other._isNegative) {
      if (_isNegative) {
        // (-this) ^ (-other) == ~(this-1) ^ ~(other-1) == (this-1) ^ (other-1)
        var this1 = _absSubSetSign(one, true);
        var other1 = other._absSubSetSign(one, true);
        return this1._absXorSetSign(other1, false);
      }
      return _absXorSetSign(other, false);
    }
    // _isNegative != a._isNegative
    _BigIntImpl p, n;
    if (_isNegative) {
      p = other;
      n = this;
    } else {
      // ^ is symmetric.
      p = this;
      n = other;
    }
    // p ^ (-n) == p ^ ~(n-1) == ~(p ^ (n-1)) == -((p ^ (n-1)) + 1)
    var n1 = n._absSubSetSign(one, true);
    // Result cannot be zero if only one of this or a is negative.
    return p._absXorSetSign(n1, true)._absAddSetSign(one, true);
  }

  /// The bit-wise negate operator.
  ///
  /// Treating `this` as a sufficiently large two's component integer,
  /// the result is a number with the opposite bits set.
  ///
  /// This maps any integer `x` to `-x - 1`.
  _BigIntImpl operator ~() {
    if (_isZero) return _minusOne;
    if (_isNegative) {
      // ~(-this) == ~(~(this-1)) == this-1
      return _absSubSetSign(one, false);
    }
    // ~this == -this-1 == -(this+1)
    // Result cannot be zero if this is positive.
    return _absAddSetSign(one, true);
  }

  /// Addition operator.
  _BigIntImpl operator +(covariant _BigIntImpl other) {
    if (_isZero) return other;
    if (other._isZero) return this;
    var isNegative = _isNegative;
    if (isNegative == other._isNegative) {
      // this + other == this + other
      // (-this) + (-other) == -(this + other)
      return _absAddSetSign(other, isNegative);
    }
    // this + (-other) == this - other == -(this - other)
    // (-this) + other == other - this == -(this - other)
    if (_absCompare(other) >= 0) {
      return _absSubSetSign(other, isNegative);
    }
    return other._absSubSetSign(this, !isNegative);
  }

  /// Subtraction operator.
  _BigIntImpl operator -(covariant _BigIntImpl other) {
    if (_isZero) return -other;
    if (other._isZero) return this;
    var isNegative = _isNegative;
    if (isNegative != other._isNegative) {
      // this - (-other) == this + other
      // (-this) - other == -(this + other)
      return _absAddSetSign(other, isNegative);
    }
    // this - other == this - a == -(this - other)
    // (-this) - (-other) == other - this == -(this - other)
    if (_absCompare(other) >= 0) {
      return _absSubSetSign(other, isNegative);
    }
    return other._absSubSetSign(this, !isNegative);
  }

  /// Multiplies [x] with [multiplicandDigits] and adds the result to
  /// [accumulatorDigits].
  ///
  /// The [multiplicandDigits] in the range [i] to [i]+[n]-1 are the
  /// multiplicand digits.
  ///
  /// The [accumulatorDigits] in the range [j] to [j]+[n]-1 are the accumulator
  /// digits.
  ///
  /// Adds the result of the multiplicand-digits * [x] to the accumulator.
  ///
  /// Concretely: `accumulatorDigits[j..j+n] += x * m_digits[i..i+n-1]`.
  static void _mulAdd(int x, Uint16List multiplicandDigits, int i,
      Uint16List accumulatorDigits, int j, int n) {
    if (x == 0) {
      // No-op if x is 0.
      return;
    }
    int c = 0;
    while (--n >= 0) {
      int product = x * multiplicandDigits[i++];
      int combined = product + accumulatorDigits[j] + c;
      accumulatorDigits[j++] = combined & _digitMask;
      // Note that this works with 53 bits, as the division will not lose
      // bits.
      c = combined ~/ _digitBase;
    }
    while (c != 0) {
      int l = accumulatorDigits[j] + c;
      accumulatorDigits[j++] = l & _digitMask;
      c = l ~/ _digitBase;
    }
  }

  /// Multiplication operator.
  _BigIntImpl operator *(covariant _BigIntImpl other) {
    var used = _used;
    var otherUsed = other._used;
    if (used == 0 || otherUsed == 0) {
      return zero;
    }
    var resultUsed = used + otherUsed;
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = Uint16List(resultUsed);
    var i = 0;
    while (i < otherUsed) {
      _mulAdd(otherDigits[i], digits, 0, resultDigits, i, used);
      i++;
    }
    return _BigIntImpl._(
        _isNegative != other._isNegative, resultUsed, resultDigits);
  }

  // r_digits[0..rUsed-1] = xDigits[0..xUsed-1]*otherDigits[0..otherUsed-1].
  // Return resultUsed = xUsed + otherUsed.
  static int _mulDigits(Uint16List xDigits, int xUsed, Uint16List otherDigits,
      int otherUsed, Uint16List resultDigits) {
    var resultUsed = xUsed + otherUsed;
    var i = resultUsed;
    assert(resultDigits.length >= i);
    while (--i >= 0) {
      resultDigits[i] = 0;
    }
    i = 0;
    while (i < otherUsed) {
      _mulAdd(otherDigits[i], xDigits, 0, resultDigits, i, xUsed);
      i++;
    }
    return resultUsed;
  }

  /// Returns an estimate of `digits[i-1..i] ~/ topDigitDivisor`.
  static int _estimateQuotientDigit(
      int topDigitDivisor, Uint16List digits, int i) {
    if (digits[i] == topDigitDivisor) return _digitMask;
    var quotientDigit =
        (digits[i] << _digitBits | digits[i - 1]) ~/ topDigitDivisor;
    if (quotientDigit > _digitMask) return _digitMask;
    return quotientDigit;
  }

  /// Returns `trunc(this / other)`, with `other != 0`.
  _BigIntImpl _div(_BigIntImpl other) {
    assert(other._used > 0);
    if (_used < other._used) {
      return zero;
    }
    _divRem(other);
    // Return quotient, i.e.
    // _lastQuoRem_digits[_lastRem_used.._lastQuoRem_used-1] with proper sign.
    var lastQuo_used = _lastQuoRemUsed - _lastRemUsed;
    var quo_digits = _cloneDigits(
        _lastQuoRemDigits, _lastRemUsed, _lastQuoRemUsed, lastQuo_used);
    var quo = _BigIntImpl._(false, lastQuo_used, quo_digits);
    if ((_isNegative != other._isNegative) && (quo._used > 0)) {
      quo = -quo;
    }
    return quo;
  }

  /// Returns `this - other * trunc(this / other)`, with `other != 0`.
  _BigIntImpl _rem(_BigIntImpl other) {
    assert(other._used > 0);
    if (_used < other._used) {
      return this;
    }
    _divRem(other);
    // Return remainder, i.e.
    // denormalized _lastQuoRem_digits[0.._lastRem_used-1] with proper sign.
    var remDigits =
        _cloneDigits(_lastQuoRemDigits, 0, _lastRemUsed, _lastRemUsed);
    var rem = _BigIntImpl._(false, _lastRemUsed, remDigits);
    if (_lastRem_nsh > 0) {
      rem = rem >> _lastRem_nsh; // Denormalize remainder.
    }
    if (_isNegative && (rem._used > 0)) {
      rem = -rem;
    }
    return rem;
  }

  /// Computes this ~/ other and this.remainder(other).
  ///
  /// Stores the result in [_lastQuoRemDigits], [_lastQuoRemUsed] and
  /// [_lastRemUsed]. The [_lastQuoRemDigits] contains the digits of *both*, the
  /// quotient and the remainder.
  ///
  /// Caches the input to avoid doing the work again when users write
  /// `a ~/ b` followed by a `a % b`.
  void _divRem(_BigIntImpl other) {
    // Check if result is already cached.
    if ((this._used == _lastDividendUsed) &&
        (other._used == _lastDivisorUsed) &&
        identical(this._digits, _lastDividendDigits) &&
        identical(other._digits, _lastDivisorDigits)) {
      return;
    }
    assert(_used >= other._used);

    var nsh = _digitBits - other._digits[other._used - 1].bitLength;
    // Concatenated positive quotient and normalized positive remainder.
    // The resultDigits can have at most one more digit than the dividend.
    Uint16List resultDigits;
    int resultUsed;
    // Normalized positive divisor.
    // The normalized divisor has the most-significant bit of its most
    // significant digit set.
    // This makes estimating the quotient easier.
    Uint16List yDigits;
    int yUsed;
    if (nsh > 0) {
      yDigits = Uint16List(other._used + 5);
      yUsed = _lShiftDigits(other._digits, other._used, nsh, yDigits);
      resultDigits = Uint16List(_used + 5);
      resultUsed = _lShiftDigits(_digits, _used, nsh, resultDigits);
    } else {
      yDigits = other._digits;
      yUsed = other._used;
      resultDigits = _cloneDigits(_digits, 0, _used, _used + 2);
      resultUsed = _used;
    }
    var topDigitDivisor = yDigits[yUsed - 1];
    var i = resultUsed;
    var j = i - yUsed;
    // tmpDigits is a temporary array of i (resultUsed) digits.
    var tmpDigits = Uint16List(i);
    var tmpUsed = _dlShiftDigits(yDigits, yUsed, j, tmpDigits);
    // Explicit first division step in case normalized dividend is larger or
    // equal to shifted normalized divisor.
    if (_compareDigits(resultDigits, resultUsed, tmpDigits, tmpUsed) >= 0) {
      assert(i == resultUsed);
      resultDigits[resultUsed++] = 1; // Quotient = 1.
      // Subtract divisor from remainder.
      _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
    } else {
      // Account for possible carry in _mulAdd step.
      resultDigits[resultUsed++] = 0;
    }

    // Negate y so we can later use _mulAdd instead of non-existent _mulSub.
    var nyDigits = Uint16List(yUsed + 2);
    nyDigits[yUsed] = 1;
    _absSub(nyDigits, yUsed + 1, yDigits, yUsed, nyDigits);
    // nyDigits is read-only and has yUsed digits (possibly including several
    // leading zeros).
    // resultDigits is modified during iteration.
    // resultDigits[0..yUsed-1] is the current remainder.
    // resultDigits[yUsed..resultUsed-1] is the current quotient.
    --i;

    while (j > 0) {
      var estimatedQuotientDigit =
          _estimateQuotientDigit(topDigitDivisor, resultDigits, i);
      j--;
      _mulAdd(estimatedQuotientDigit, nyDigits, 0, resultDigits, j, yUsed);
      if (resultDigits[i] < estimatedQuotientDigit) {
        // Reusing the already existing tmpDigits array.
        var tmpUsed = _dlShiftDigits(nyDigits, yUsed, j, tmpDigits);
        _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
        while (resultDigits[i] < --estimatedQuotientDigit) {
          _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
        }
      }
      i--;
    }
    // Cache result.
    _lastDividendDigits = _digits;
    _lastDividendUsed = _used;
    _lastDivisorDigits = other._digits;
    _lastDivisorUsed = other._used;
    _lastQuoRemDigits = resultDigits;
    _lastQuoRemUsed = resultUsed;
    _lastRemUsed = yUsed;
    _lastRem_nsh = nsh;
  }

  int get hashCode {
    // This is the [Jenkins hash function][1] but using masking to keep
    // values in SMI range.
    //
    // [1]: http://en.wikipedia.org/wiki/Jenkins_hash_function

    int combine(int hash, int value) {
      hash = 0x1fffffff & (hash + value);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      return hash ^ (hash >> 6);
    }

    int finish(int hash) {
      hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
      hash = hash ^ (hash >> 11);
      return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    }

    if (_isZero) return 6707; // Just a random number.
    var hash = _isNegative ? 83585 : 429689; // Also random.
    for (int i = 0; i < _used; i++) {
      hash = combine(hash, _digits[i]);
    }
    return finish(hash);
  }

  /// Test whether this value is numerically equal to `other`.
  ///
  /// If [other] is a [_BigIntImpl] returns whether the two operands have the
  /// same value.
  ///
  /// Returns false if `other` is not a [_BigIntImpl].
  bool operator ==(Object other) =>
      other is _BigIntImpl && compareTo(other) == 0;

  /// Returns the minimum number of bits required to store this big integer.
  ///
  /// The number of bits excludes the sign bit, which gives the natural length
  /// for non-negative (unsigned) values.  Negative values are complemented to
  /// return the bit position of the first bit that differs from the sign bit.
  ///
  /// To find the number of bits needed to store the value as a signed value,
  /// add one, i.e. use `x.bitLength + 1`.
  ///
  /// ```
  /// x.bitLength == (-x-1).bitLength
  ///
  /// new BigInt.from(3).bitLength == 2;   // 00000011
  /// new BigInt.from(2).bitLength == 2;   // 00000010
  /// new BigInt.from(1).bitLength == 1;   // 00000001
  /// new BigInt.from(0).bitLength == 0;   // 00000000
  /// new BigInt.from(-1).bitLength == 0;  // 11111111
  /// new BigInt.from(-2).bitLength == 1;  // 11111110
  /// new BigInt.from(-3).bitLength == 2;  // 11111101
  /// new BigInt.from(-4).bitLength == 2;  // 11111100
  /// ```
  int get bitLength {
    if (_used == 0) return 0;
    final highBits = _digits[_used - 1];
    assert(highBits != 0);
    int length = _digitBits * (_used - 1) + highBits.bitLength;
    if (!_isNegative) return length;

    // `this` is negative, i.e. `-x` for the magnitude `x`. We want to find the
    // bit length of `~this` or equivalently `-this-1`.
    //
    //     -this-1 == -(-x)-1 == x-1
    //
    // `x-1` will have the same bit length as `x` unless `x` is power of two
    // (e.g. 0x1000-1 = 0x0FFF). The magnitude is a power of two if the high
    // digit is a power of two and all the other digits are zero.
    if (highBits & (highBits - 1) != 0) return length;
    for (int i = _used - 2; i >= 0; i--) {
      if (_digits[i] != 0) return length;
    }
    return length - 1;
  }

  /// Truncating division operator.
  ///
  /// Performs a truncating integer division, where the remainder is discarded.
  ///
  /// The remainder can be computed using the [remainder] method.
  ///
  /// Examples:
  /// ```
  /// var seven = new BigInt.from(7);
  /// var three = new BigInt.from(3);
  /// seven ~/ three;    // => 2
  /// (-seven) ~/ three; // => -2
  /// seven ~/ -three;   // => -2
  /// seven.remainder(three);    // => 1
  /// (-seven).remainder(three); // => -1
  /// seven.remainder(-three);   // => 1
  /// ```
  _BigIntImpl operator ~/(covariant _BigIntImpl other) {
    if (other._used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return _div(other);
  }

  /// Returns the remainder of the truncating division of `this` by [other].
  ///
  /// The result `r` of this operation satisfies:
  /// `this == (this ~/ other) * other + r`.
  /// As a consequence the remainder `r` has the same sign as the divider
  /// `this`.
  _BigIntImpl remainder(covariant _BigIntImpl other) {
    if (other._used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return _rem(other);
  }

  /// Division operator.
  double operator /(BigInt other) => this.toDouble() / other.toDouble();

  /// Relational less than operator.
  bool operator <(covariant _BigIntImpl other) => compareTo(other) < 0;

  /// Relational less than or equal operator.
  bool operator <=(covariant _BigIntImpl other) => compareTo(other) <= 0;

  /// Relational greater than operator.
  bool operator >(covariant _BigIntImpl other) => compareTo(other) > 0;

  /// Relational greater than or equal operator.
  bool operator >=(covariant _BigIntImpl other) => compareTo(other) >= 0;

  /// Euclidean modulo operator.
  ///
  /// Returns the remainder of the Euclidean division. The Euclidean division of
  /// two integers `a` and `b` yields two integers `q` and `r` such that
  /// `a == b * q + r` and `0 <= r < b.abs()`.
  ///
  /// The sign of the returned value `r` is always positive.
  ///
  /// See [remainder] for the remainder of the truncating division.
  _BigIntImpl operator %(covariant _BigIntImpl other) {
    if (other._used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    var result = _rem(other);
    if (result._isNegative) {
      if (other._isNegative) {
        result = result - other;
      } else {
        result = result + other;
      }
    }
    return result;
  }

  /// Returns the sign of this big integer.
  ///
  /// Returns 0 for zero, -1 for values less than zero and
  /// +1 for values greater than zero.
  int get sign {
    if (_used == 0) return 0;
    return _isNegative ? -1 : 1;
  }

  /// Whether this big integer is even.
  bool get isEven => _used == 0 || (_digits[0] & 1) == 0;

  /// Whether this big integer is odd.
  bool get isOdd => !isEven;

  /// Whether this number is negative.
  bool get isNegative => _isNegative;

  _BigIntImpl pow(int exponent) {
    if (exponent < 0) {
      throw ArgumentError("Exponent must not be negative: $exponent");
    }
    if (exponent == 0) return one;

    // Exponentiation by squaring.
    var result = one;
    var base = this;
    while (exponent != 0) {
      if ((exponent & 1) == 1) {
        result *= base;
      }
      exponent >>= 1;
      // Skip unnecessary operation.
      if (exponent != 0) {
        base *= base;
      }
    }
    return result;
  }

  /// Returns this integer to the power of [exponent] modulo [modulus].
  ///
  /// The [exponent] must be non-negative and [modulus] must be
  /// positive.
  _BigIntImpl modPow(
      covariant _BigIntImpl exponent, covariant _BigIntImpl modulus) {
    if (exponent._isNegative) {
      throw ArgumentError("exponent must be positive: $exponent");
    }
    if (modulus <= zero) {
      throw ArgumentError("modulus must be strictly positive: $modulus");
    }
    if (exponent._isZero) return one;

    final modulusUsed = modulus._used;
    final modulusUsed2p4 = 2 * modulusUsed + 4;
    final exponentBitlen = exponent.bitLength;
    if (exponentBitlen <= 0) return one;
    _BigIntReduction z = _BigIntClassic(modulus);
    var resultDigits = Uint16List(modulusUsed2p4);
    var result2Digits = Uint16List(modulusUsed2p4);
    var gDigits = Uint16List(modulusUsed);
    var gUsed = z.convert(this, gDigits);
    // Initialize result with g.
    // Copy leading zero if any.
    for (int j = gUsed - 1; j >= 0; j--) {
      resultDigits[j] = gDigits[j];
    }
    var resultUsed = gUsed;
    int result2Used;
    for (int i = exponentBitlen - 2; i >= 0; i--) {
      result2Used = z.sqr(resultDigits, resultUsed, result2Digits);
      if (!(exponent & (one << i))._isZero) {
        resultUsed =
            z.mul(result2Digits, result2Used, gDigits, gUsed, resultDigits);
      } else {
        // Swap result and result2.
        var tmpDigits = resultDigits;
        var tmpUsed = resultUsed;
        resultDigits = result2Digits;
        resultUsed = result2Used;
        result2Digits = tmpDigits;
        result2Used = tmpUsed;
      }
    }
    return z.revert(resultDigits, resultUsed);
  }

  // If inv is false, returns gcd(x, y).
  // If inv is true and gcd(x, y) = 1, returns d, so that c*x + d*y = 1.
  // If inv is true and gcd(x, y) != 1, throws Exception("Not coprime").
  static _BigIntImpl _binaryGcd(_BigIntImpl x, _BigIntImpl y, bool inv) {
    var xDigits = x._digits;
    var yDigits = y._digits;
    var xUsed = x._used;
    var yUsed = y._used;
    var maxUsed = xUsed > yUsed ? xUsed : yUsed;
    var unshiftedMaxUsed = maxUsed; // Keep
    xDigits = _cloneDigits(xDigits, 0, xUsed, maxUsed);
    yDigits = _cloneDigits(yDigits, 0, yUsed, maxUsed);
    int shiftAmount = 0;
    if (inv) {
      if ((yUsed == 1) && (yDigits[0] == 1)) return one;
      if ((yUsed == 0) || (yDigits[0].isEven && xDigits[0].isEven)) {
        throw Exception("Not coprime");
      }
    } else {
      if (x._isZero) {
        throw ArgumentError.value(0, "this", "must not be zero");
      }
      if (y._isZero) {
        throw ArgumentError.value(0, "other", "must not be zero");
      }
      if (((xUsed == 1) && (xDigits[0] == 1)) ||
          ((yUsed == 1) && (yDigits[0] == 1))) return one;
      while (((xDigits[0] & 1) == 0) && ((yDigits[0] & 1) == 0)) {
        _rsh(xDigits, xUsed, 1, xDigits);
        _rsh(yDigits, yUsed, 1, yDigits);
        shiftAmount++;
      }
      if (shiftAmount >= _digitBits) {
        var digitShiftAmount = shiftAmount ~/ _digitBits;
        xUsed -= digitShiftAmount;
        yUsed -= digitShiftAmount;
        maxUsed -= digitShiftAmount;
      }
      if ((yDigits[0] & 1) == 1) {
        // Swap x and y.
        var tmpDigits = xDigits;
        var tmpUsed = xUsed;
        xDigits = yDigits;
        xUsed = yUsed;
        yDigits = tmpDigits;
        yUsed = tmpUsed;
      }
    }
    var uDigits = _cloneDigits(xDigits, 0, xUsed, unshiftedMaxUsed);
    var vDigits =
        _cloneDigits(yDigits, 0, yUsed, unshiftedMaxUsed + 2); // +2 for lsh.
    final bool ac = (xDigits[0] & 1) == 0;

    // Variables a, b, c, and d require one more digit.
    final abcdUsed = maxUsed + 1;
    final abcdLen = abcdUsed + 2; // +2 to satisfy _absAdd.
    var aDigits = _dummyList;
    var aIsNegative = false;
    var cDigits = _dummyList;
    var cIsNegative = false;
    if (ac) {
      aDigits = Uint16List(abcdLen);
      aDigits[0] = 1;
      cDigits = Uint16List(abcdLen);
    }
    var bDigits = Uint16List(abcdLen);
    var bIsNegative = false;
    var dDigits = Uint16List(abcdLen);
    var dIsNegative = false;
    dDigits[0] = 1;

    while (true) {
      while ((uDigits[0] & 1) == 0) {
        _rsh(uDigits, maxUsed, 1, uDigits);
        if (ac) {
          if (((aDigits[0] & 1) == 1) || ((bDigits[0] & 1) == 1)) {
            // a += y
            if (aIsNegative) {
              if ((aDigits[maxUsed] != 0) ||
                  (_compareDigits(aDigits, maxUsed, yDigits, maxUsed)) > 0) {
                _absSub(aDigits, abcdUsed, yDigits, maxUsed, aDigits);
              } else {
                _absSub(yDigits, maxUsed, aDigits, maxUsed, aDigits);
                aIsNegative = false;
              }
            } else {
              _absAdd(aDigits, abcdUsed, yDigits, maxUsed, aDigits);
            }
            // b -= x
            if (bIsNegative) {
              _absAdd(bDigits, abcdUsed, xDigits, maxUsed, bDigits);
            } else if ((bDigits[maxUsed] != 0) ||
                (_compareDigits(bDigits, maxUsed, xDigits, maxUsed) > 0)) {
              _absSub(bDigits, abcdUsed, xDigits, maxUsed, bDigits);
            } else {
              _absSub(xDigits, maxUsed, bDigits, maxUsed, bDigits);
              bIsNegative = true;
            }
          }
          _rsh(aDigits, abcdUsed, 1, aDigits);
        } else if ((bDigits[0] & 1) == 1) {
          // b -= x
          if (bIsNegative) {
            _absAdd(bDigits, abcdUsed, xDigits, maxUsed, bDigits);
          } else if ((bDigits[maxUsed] != 0) ||
              (_compareDigits(bDigits, maxUsed, xDigits, maxUsed) > 0)) {
            _absSub(bDigits, abcdUsed, xDigits, maxUsed, bDigits);
          } else {
            _absSub(xDigits, maxUsed, bDigits, maxUsed, bDigits);
            bIsNegative = true;
          }
        }
        _rsh(bDigits, abcdUsed, 1, bDigits);
      }
      while ((vDigits[0] & 1) == 0) {
        _rsh(vDigits, maxUsed, 1, vDigits);
        if (ac) {
          if (((cDigits[0] & 1) == 1) || ((dDigits[0] & 1) == 1)) {
            // c += y
            if (cIsNegative) {
              if ((cDigits[maxUsed] != 0) ||
                  (_compareDigits(cDigits, maxUsed, yDigits, maxUsed) > 0)) {
                _absSub(cDigits, abcdUsed, yDigits, maxUsed, cDigits);
              } else {
                _absSub(yDigits, maxUsed, cDigits, maxUsed, cDigits);
                cIsNegative = false;
              }
            } else {
              _absAdd(cDigits, abcdUsed, yDigits, maxUsed, cDigits);
            }
            // d -= x
            if (dIsNegative) {
              _absAdd(dDigits, abcdUsed, xDigits, maxUsed, dDigits);
            } else if ((dDigits[maxUsed] != 0) ||
                (_compareDigits(dDigits, maxUsed, xDigits, maxUsed) > 0)) {
              _absSub(dDigits, abcdUsed, xDigits, maxUsed, dDigits);
            } else {
              _absSub(xDigits, maxUsed, dDigits, maxUsed, dDigits);
              dIsNegative = true;
            }
          }
          _rsh(cDigits, abcdUsed, 1, cDigits);
        } else if ((dDigits[0] & 1) == 1) {
          // d -= x
          if (dIsNegative) {
            _absAdd(dDigits, abcdUsed, xDigits, maxUsed, dDigits);
          } else if ((dDigits[maxUsed] != 0) ||
              (_compareDigits(dDigits, maxUsed, xDigits, maxUsed) > 0)) {
            _absSub(dDigits, abcdUsed, xDigits, maxUsed, dDigits);
          } else {
            _absSub(xDigits, maxUsed, dDigits, maxUsed, dDigits);
            dIsNegative = true;
          }
        }
        _rsh(dDigits, abcdUsed, 1, dDigits);
      }
      if (_compareDigits(uDigits, maxUsed, vDigits, maxUsed) >= 0) {
        // u -= v
        _absSub(uDigits, maxUsed, vDigits, maxUsed, uDigits);
        if (ac) {
          // a -= c
          if (aIsNegative == cIsNegative) {
            var a_cmp_c = _compareDigits(aDigits, abcdUsed, cDigits, abcdUsed);
            if (a_cmp_c > 0) {
              _absSub(aDigits, abcdUsed, cDigits, abcdUsed, aDigits);
            } else {
              _absSub(cDigits, abcdUsed, aDigits, abcdUsed, aDigits);
              aIsNegative = !aIsNegative && (a_cmp_c != 0);
            }
          } else {
            _absAdd(aDigits, abcdUsed, cDigits, abcdUsed, aDigits);
          }
        }
        // b -= d
        if (bIsNegative == dIsNegative) {
          var b_cmp_d = _compareDigits(bDigits, abcdUsed, dDigits, abcdUsed);
          if (b_cmp_d > 0) {
            _absSub(bDigits, abcdUsed, dDigits, abcdUsed, bDigits);
          } else {
            _absSub(dDigits, abcdUsed, bDigits, abcdUsed, bDigits);
            bIsNegative = !bIsNegative && (b_cmp_d != 0);
          }
        } else {
          _absAdd(bDigits, abcdUsed, dDigits, abcdUsed, bDigits);
        }
      } else {
        // v -= u
        _absSub(vDigits, maxUsed, uDigits, maxUsed, vDigits);
        if (ac) {
          // c -= a
          if (cIsNegative == aIsNegative) {
            var c_cmp_a = _compareDigits(cDigits, abcdUsed, aDigits, abcdUsed);
            if (c_cmp_a > 0) {
              _absSub(cDigits, abcdUsed, aDigits, abcdUsed, cDigits);
            } else {
              _absSub(aDigits, abcdUsed, cDigits, abcdUsed, cDigits);
              cIsNegative = !cIsNegative && (c_cmp_a != 0);
            }
          } else {
            _absAdd(cDigits, abcdUsed, aDigits, abcdUsed, cDigits);
          }
        }
        // d -= b
        if (dIsNegative == bIsNegative) {
          var d_cmp_b = _compareDigits(dDigits, abcdUsed, bDigits, abcdUsed);
          if (d_cmp_b > 0) {
            _absSub(dDigits, abcdUsed, bDigits, abcdUsed, dDigits);
          } else {
            _absSub(bDigits, abcdUsed, dDigits, abcdUsed, dDigits);
            dIsNegative = !dIsNegative && (d_cmp_b != 0);
          }
        } else {
          _absAdd(dDigits, abcdUsed, bDigits, abcdUsed, dDigits);
        }
      }
      // Exit loop if u == 0.
      var i = maxUsed;
      while ((i > 0) && (uDigits[i - 1] == 0)) --i;
      if (i == 0) break;
    }
    if (!inv) {
      if (shiftAmount > 0) {
        maxUsed = _lShiftDigits(vDigits, maxUsed, shiftAmount, vDigits);
      }
      return _BigIntImpl._(false, maxUsed, vDigits);
    }
    // No inverse if v != 1.
    var i = maxUsed - 1;
    while ((i > 0) && (vDigits[i] == 0)) --i;
    if ((i != 0) || (vDigits[0] != 1)) {
      throw Exception("Not coprime");
    }

    if (dIsNegative) {
      while ((dDigits[maxUsed] != 0) ||
          (_compareDigits(dDigits, maxUsed, xDigits, maxUsed) > 0)) {
        // d += x, d still negative
        _absSub(dDigits, abcdUsed, xDigits, maxUsed, dDigits);
      }
      // d += x
      _absSub(xDigits, maxUsed, dDigits, maxUsed, dDigits);
      dIsNegative = false;
    } else {
      while ((dDigits[maxUsed] != 0) ||
          (_compareDigits(dDigits, maxUsed, xDigits, maxUsed) >= 0)) {
        // d -= x
        _absSub(dDigits, abcdUsed, xDigits, maxUsed, dDigits);
      }
    }
    return _BigIntImpl._(false, maxUsed, dDigits);
  }

  /// Returns the modular multiplicative inverse of this big integer
  /// modulo [modulus].
  ///
  /// The [modulus] must be positive.
  ///
  /// It is an error if no modular inverse exists.
  // Returns 1/this % modulus, with modulus > 0.
  _BigIntImpl modInverse(covariant _BigIntImpl modulus) {
    if (modulus <= zero) {
      throw ArgumentError("Modulus must be strictly positive: $modulus");
    }
    if (modulus == one) return zero;
    var tmp = this;
    if (tmp._isNegative || (tmp._absCompare(modulus) >= 0)) {
      tmp %= modulus;
    }
    return _binaryGcd(modulus, tmp, true);
  }

  /// Returns the greatest common divisor of this big integer and [other].
  ///
  /// If either number is non-zero, the result is the numerically greatest
  /// integer dividing both `this` and `other`.
  ///
  /// The greatest common divisor is independent of the order,
  /// so `x.gcd(y)` is  always the same as `y.gcd(x)`.
  ///
  /// For any integer `x`, `x.gcd(x)` is `x.abs()`.
  ///
  /// If both `this` and `other` is zero, the result is also zero.
  _BigIntImpl gcd(covariant _BigIntImpl other) {
    if (_isZero) return other.abs();
    if (other._isZero) return this.abs();
    return _binaryGcd(this, other, false);
  }

  /// Returns the least significant [width] bits of this big integer as a
  /// non-negative number (i.e. unsigned representation). The returned value
  /// has zeros in all bit positions higher than [width].
  ///
  /// ```
  /// new BigInt.from(-1).toUnsigned(5) == 31   // 11111111  ->  00011111
  /// ```
  ///
  /// This operation can be used to simulate arithmetic from low level
  /// languages.  For example, to increment an 8 bit quantity:
  ///
  /// ```
  /// q = (q + 1).toUnsigned(8);
  /// ```
  ///
  /// `q` will count from `0` up to `255` and then wrap around to `0`.
  ///
  /// If the input fits in [width] bits without truncation, the result is the
  /// same as the input. The minimum width needed to avoid truncation of `x` is
  /// given by `x.bitLength`, i.e.
  ///
  /// ```
  /// x == x.toUnsigned(x.bitLength);
  /// ```
  _BigIntImpl toUnsigned(int width) {
    return this & ((one << width) - one);
  }

  /// Returns the least significant [width] bits of this integer, extending the
  /// highest retained bit to the sign. This is the same as truncating the value
  /// to fit in [width] bits using an signed 2-s complement representation. The
  /// returned value has the same bit value in all positions higher than
  /// [width].
  ///
  /// ```
  /// var big15 = new BigInt.from(15);
  /// var big16 = new BigInt.from(16);
  /// var big239 = new BigInt.from(239);
  ///                                      V--sign bit-V
  /// big16.toSigned(5) == -big16   //  00010000 -> 11110000
  /// big239.toSigned(5) == big15   //  11101111 -> 00001111
  ///                                      ^           ^
  /// ```
  ///
  /// This operation can be used to simulate arithmetic from low level
  /// languages. For example, to increment an 8 bit signed quantity:
  ///
  /// ```
  /// q = (q + 1).toSigned(8);
  /// ```
  ///
  /// `q` will count from `0` up to `127`, wrap to `-128` and count back up to
  /// `127`.
  ///
  /// If the input value fits in [width] bits without truncation, the result is
  /// the same as the input.  The minimum width needed to avoid truncation of
  /// `x` is `x.bitLength + 1`, i.e.
  ///
  /// ```
  /// x == x.toSigned(x.bitLength + 1);
  /// ```
  _BigIntImpl toSigned(int width) {
    // The value of binary number weights each bit by a power of two.  The
    // twos-complement value weights the sign bit negatively. We compute the
    // value of the negative weighting by isolating the sign bit with the
    // correct power of two weighting and subtracting it from the value of the
    // lower bits.
    var signMask = one << (width - 1);
    return (this & (signMask - one)) - (this & signMask);
  }

  // Maximum number of digits that always fit in mantissa.
  static const _simpleValidIntDigits = 53 ~/ _digitBits;

  bool get isValidInt {
    if (_used <= _simpleValidIntDigits) return true;
    var asInt = toInt();
    if (!asInt.toDouble().isFinite) return false;
    return this == _BigIntImpl._fromInt(asInt);
  }

  int toInt() {
    var result = 0;
    for (int i = _used - 1; i >= 0; i--) {
      result = result * _digitBase + _digits[i];
    }
    return _isNegative ? -result : result;
  }

  /// Returns this [_BigIntImpl] as a [double].
  ///
  /// If the number is not representable as a [double], an
  /// approximation is returned. For numerically large integers, the
  /// approximation may be infinite.
  double toDouble() {
    const int exponentBias = 1075;
    // There are 11 bits for the exponent.
    // 2047 (all bits set to 1) is reserved for infinity and NaN.
    // When storing the exponent in the 11 bits, it is biased by exponentBias
    // to support negative exponents.
    const int maxDoubleExponent = 2046 - exponentBias;
    if (_isZero) return 0.0;

    // We fill the 53 bits little-endian.
    var resultBits = Uint8List(8);

    var length = _digitBits * (_used - 1) + _digits[_used - 1].bitLength;
    if (length > maxDoubleExponent + 53) {
      return _isNegative ? double.negativeInfinity : double.infinity;
    }

    // The most significant bit is for the sign.
    if (_isNegative) resultBits[7] = 0x80;

    // Write the exponent into bits 1..12:
    var biasedExponent = length - 53 + exponentBias;
    resultBits[6] = (biasedExponent & 0xF) << 4;
    resultBits[7] |= biasedExponent >> 4;

    int cachedBits = 0;
    int cachedBitsLength = 0;
    int digitIndex = _used - 1;
    int readBits(int n) {
      // Ensure that we have enough bits in [cachedBits].
      while (cachedBitsLength < n) {
        int nextDigit;
        int nextDigitLength = _digitBits; // May get updated.
        if (digitIndex < 0) {
          nextDigit = 0;
          digitIndex--;
        } else {
          nextDigit = _digits[digitIndex];
          if (digitIndex == _used - 1) nextDigitLength = nextDigit.bitLength;
          digitIndex--;
        }
        cachedBits = (cachedBits << nextDigitLength) + nextDigit;
        cachedBitsLength += nextDigitLength;
      }
      // Read the top [n] bits.
      var result = cachedBits >> (cachedBitsLength - n);
      // Remove the bits from the cache.
      cachedBits -= result << (cachedBitsLength - n);
      cachedBitsLength -= n;
      return result;
    }

    // The first leading 1 bit is implicit in the double-representation and can
    // be discarded.
    var leadingBits = readBits(5) & 0xF;
    resultBits[6] |= leadingBits;

    for (int i = 5; i >= 0; i--) {
      // Get the remaining 48 bits.
      resultBits[i] = readBits(8);
    }

    void roundUp() {
      // Simply consists of adding 1 to the whole 64 bit "number".
      // It will update the exponent, if necessary.
      // It might even round up to infinity (which is what we want).
      var carry = 1;
      for (int i = 0; i < 8; i++) {
        if (carry == 0) break;
        var sum = resultBits[i] + carry;
        resultBits[i] = sum & 0xFF;
        carry = sum >> 8;
      }
    }

    if (readBits(1) == 1) {
      if (resultBits[0].isOdd) {
        // Rounds to even all the time.
        roundUp();
      } else {
        // Round up, if there is at least one other digit that is not 0.
        if (cachedBits != 0) {
          // There is already one in the cachedBits.
          roundUp();
        } else {
          for (int i = digitIndex; i >= 0; i--) {
            if (_digits[i] != 0) {
              roundUp();
              break;
            }
          }
        }
      }
    }
    return resultBits.buffer.asByteData().getFloat64(0, Endian.little);
  }

  /// Returns a String-representation of this integer.
  ///
  /// The returned string is parsable by [parse].
  /// For any `_BigIntImpl` `i`, it is guaranteed that
  /// `i == _BigIntImpl.parse(i.toString())`.
  String toString() {
    if (_used == 0) return "0";
    if (_used == 1) {
      if (_isNegative) return (-_digits[0]).toString();
      return _digits[0].toString();
    }

    // Generate in chunks of 4 digits.
    // The chunks are in reversed order.
    var decimalDigitChunks = <String>[];
    var rest = isNegative ? -this : this;
    while (rest._used > 1) {
      var digits4 = rest.remainder(_bigInt10000).toString();
      decimalDigitChunks.add(digits4);
      if (digits4.length == 1) decimalDigitChunks.add("000");
      if (digits4.length == 2) decimalDigitChunks.add("00");
      if (digits4.length == 3) decimalDigitChunks.add("0");
      rest = rest ~/ _bigInt10000;
    }
    decimalDigitChunks.add(rest._digits[0].toString());
    if (_isNegative) decimalDigitChunks.add("-");
    return decimalDigitChunks.reversed.join();
  }

  int _toRadixCodeUnit(int digit) {
    const int _0 = 48;
    const int _a = 97;
    if (digit < 10) return _0 + digit;
    return _a + digit - 10;
  }

  /// Converts this [BigInt] to a string representation in the given [radix].
  ///
  /// In the string representation, lower-case letters are used for digits above
  /// '9', with 'a' being 10 an 'z' being 35.
  ///
  /// The [radix] argument must be an integer in the range 2 to 36.
  String toRadixString(int radix) {
    if (radix < 2 || radix > 36) throw RangeError.range(radix, 2, 36);

    if (_used == 0) return "0";

    if (_used == 1) {
      var digitString = _digits[0].toRadixString(radix);
      if (_isNegative) return "-" + digitString;
      return digitString;
    }

    if (radix == 16) return _toHexString();

    var base = _BigIntImpl._fromInt(radix);
    var reversedDigitCodeUnits = <int>[];
    var rest = this.abs();
    while (!rest._isZero) {
      var digit = rest.remainder(base).toInt();
      rest = rest ~/ base;
      reversedDigitCodeUnits.add(_toRadixCodeUnit(digit));
    }
    var digitString = String.fromCharCodes(reversedDigitCodeUnits.reversed);
    if (_isNegative) return "-" + digitString;
    return digitString;
  }

  String _toHexString() {
    var chars = <int>[];
    for (int i = 0; i < _used - 1; i++) {
      int chunk = _digits[i];
      for (int j = 0; j < (_digitBits ~/ 4); j++) {
        chars.add(_toRadixCodeUnit(chunk & 0xF));
        chunk >>= 4;
      }
    }
    var msbChunk = _digits[_used - 1];
    while (msbChunk != 0) {
      chars.add(_toRadixCodeUnit(msbChunk & 0xF));
      msbChunk >>= 4;
    }
    if (_isNegative) {
      const _dash = 45;
      chars.add(_dash);
    }
    return String.fromCharCodes(chars.reversed);
  }
}

// Interface for modular reduction.
abstract class _BigIntReduction {
  // Return the number of digits used by r_digits.
  int convert(_BigIntImpl x, Uint16List r_digits);
  int mul(Uint16List xDigits, int xUsed, Uint16List yDigits, int yUsed,
      Uint16List resultDigits);
  int sqr(Uint16List xDigits, int xUsed, Uint16List resultDigits);

  // Return x reverted to _BigIntImpl.
  _BigIntImpl revert(Uint16List xDigits, int xUsed);
}

// Modular reduction using "classic" algorithm.
class _BigIntClassic implements _BigIntReduction {
  final _BigIntImpl _modulus; // Modulus.
  final _BigIntImpl _normalizedModulus; // Normalized _modulus.

  _BigIntClassic(this._modulus)
      : _normalizedModulus = _modulus <<
            (_BigIntImpl._digitBits -
                _modulus._digits[_modulus._used - 1].bitLength);

  int convert(_BigIntImpl x, Uint16List resultDigits) {
    Uint16List digits;
    int used;
    if (x._isNegative || x._absCompare(_modulus) >= 0) {
      var remainder = x._rem(_modulus);
      if (x._isNegative && remainder._used > 0) {
        assert(remainder._isNegative);
        remainder += _modulus;
      }
      assert(!remainder._isNegative);
      used = remainder._used;
      digits = remainder._digits;
    } else {
      used = x._used;
      digits = x._digits;
    }
    var i = used; // Copy leading zero if any.
    while (--i >= 0) {
      resultDigits[i] = digits[i];
    }
    return used;
  }

  _BigIntImpl revert(Uint16List xDigits, int xUsed) {
    return _BigIntImpl._(false, xUsed, xDigits);
  }

  int _reduce(Uint16List xDigits, int xUsed) {
    if (xUsed < _modulus._used) {
      return xUsed;
    }
    var reverted = revert(xDigits, xUsed);
    var rem = reverted._rem(_normalizedModulus);
    return convert(rem, xDigits);
  }

  int sqr(Uint16List xDigits, int xUsed, Uint16List resultDigits) {
    var b = _BigIntImpl._(false, xUsed, xDigits);
    var b2 = b * b;
    for (int i = 0; i < b2._used; i++) {
      resultDigits[i] = b2._digits[i];
    }
    for (int i = b2._used; i < 2 * xUsed; i++) {
      resultDigits[i] = 0;
    }
    return _reduce(resultDigits, 2 * xUsed);
  }

  int mul(Uint16List xDigits, int xUsed, Uint16List yDigits, int yUsed,
      Uint16List resultDigits) {
    var resultUsed =
        _BigIntImpl._mulDigits(xDigits, xUsed, yDigits, yUsed, resultDigits);
    return _reduce(resultDigits, resultUsed);
  }
}

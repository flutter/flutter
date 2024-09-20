// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch, unsafeCast;

import "dart:typed_data" show Endian, Uint8List, Uint32List;

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
  factory BigInt.from(num value) => new _BigIntImpl.from(value);
}

int _max(int a, int b) => a > b ? a : b;
int _min(int a, int b) => a < b ? a : b;

/// Allocate a new digits list of even length.
Uint32List _newDigits(int length) => new Uint32List(length + (length & 1));

/**
 * An implementation for the arbitrarily large integer.
 *
 * The integer number is represented by a sign, an array of 32-bit unsigned
 * integers in little endian format, and a number of used digits in that array.
 */
class _BigIntImpl implements BigInt {
  // Bits per digit.
  static const int _digitBits = 32;
  static const int _digitBase = 1 << _digitBits;
  static const int _digitMask = (1 << _digitBits) - 1;

  // Bits per half digit.
  static const int _halfDigitBits = _digitBits >> 1;
  static const int _halfDigitMask = (1 << _halfDigitBits) - 1;

  static final _BigIntImpl zero = new _BigIntImpl._fromInt(0);
  static final _BigIntImpl one = new _BigIntImpl._fromInt(1);
  static final _BigIntImpl two = new _BigIntImpl._fromInt(2);

  static final _BigIntImpl _minusOne = -one;
  static final _BigIntImpl _oneDigitMask = new _BigIntImpl._fromInt(_digitMask);
  static final _BigIntImpl _twoDigitMask = (one << (2 * _digitBits)) - one;
  static final _BigIntImpl _oneBillion = new _BigIntImpl._fromInt(1000000000);
  static const int _minInt = -0x8000000000000000;
  static const int _maxInt = 0x7fffffffffffffff;

  /// Certain methods of _BigIntImpl class are intrinsified by the VM
  /// depending on the runtime flags. They return number of processed
  /// digits (2) which is different from non-intrinsic implementation (1).
  /// This flag is used to confuse constant propagation at compile time and
  /// avoid propagating return value to the callers. It should not be
  /// evaluated to a constant.
  /// Note that [_isIntrinsified] is still false if intrinsification occurs,
  /// so it should be used only inside methods which are replaced by
  /// intrinsification.
  static final bool _isIntrinsified =
      new bool.fromEnvironment('dart.vm.not.a.compile.time.constant');

  // Result cache for last _divRem call.
  static Uint32List? _lastDividendDigits;
  static int? _lastDividendUsed;
  static Uint32List? _lastDivisorDigits;
  static int? _lastDivisorUsed;
  static late Uint32List _lastQuoRemDigits;
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
  /// Also, `_digits.length` must always be even, because intrinsics on 64-bit
  /// platforms may process a digit pair as a 64-bit value.
  final Uint32List _digits;

  /// The number of used entries in [_digits].
  ///
  /// To avoid reallocating [Uint32List]s, lists that are too big are not
  /// replaced, but `_used` reflects the smaller number of digits actually used.
  ///
  /// Note that functions shortening an existing list of digits to a smaller
  /// `_used` number of digits must ensure that the highermost pair of digits
  /// is correct when read as a 64-bit value by intrinsics. Therefore, if the
  /// smaller '_used' number is odd, the high digit of that pair must be
  /// explicitly cleared, i.e. _digits[_used] = 0, which cannot result in an
  /// out of bounds access, since the length of the list is guaranteed to be
  /// even.
  final int _used;

  /**
   * Parses [source] as a, possibly signed, integer literal and returns its
   * value.
   *
   * The [source] must be a non-empty sequence of base-[radix] digits,
   * optionally prefixed with a minus or plus sign ('-' or '+').
   *
   * The [radix] must be in the range 2..36. The digits used are
   * first the decimal digits 0..9, and then the letters 'a'..'z' with
   * values 10 through 35. Also accepts upper-case letters with the same
   * values as the lower-case ones.
   *
   * If no [radix] is given then it defaults to 10. In this case, the [source]
   * digits may also start with `0x`, in which case the number is interpreted
   * as a hexadecimal literal, which effectively means that the `0x` is ignored
   * and the radix is instead set to 16.
   *
   * For any int `n` and radix `r`, it is guaranteed that
   * `n == int.parse(n.toRadixString(r), radix: r)`.
   *
   * Throws a [FormatException] if the [source] is not a valid integer literal,
   * optionally prefixed by a sign.
   */
  static _BigIntImpl parse(String source, {int? radix}) {
    var result = _tryParse(source, radix: radix);
    if (result == null) {
      throw new FormatException("Could not parse BigInt", source);
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
    // Read in the source 9 digits at a time.
    // The first part may have a few leading virtual '0's to make the remaining
    // parts all have exactly 9 digits.
    int digitInPartCount = 9 - unsafeCast<int>(source.length.remainder(9));
    if (digitInPartCount == 9) digitInPartCount = 0;
    for (int i = 0; i < source.length; i++) {
      part = part * 10 + source.codeUnitAt(i) - _0;
      if (++digitInPartCount == 9) {
        result = result * _oneBillion + new _BigIntImpl._fromInt(part);
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
    int hexCharsPerDigit = _digitBits ~/ 4;
    int sourceLength = source.length - startPos;
    int used = (sourceLength + hexCharsPerDigit - 1) ~/ hexCharsPerDigit;
    var digits = _newDigits(used);

    int lastDigitLength = sourceLength - (used - 1) * hexCharsPerDigit;
    int digitIndex = used - 1;
    int i = startPos;
    int digit = 0;
    for (int j = 0; j < lastDigitLength; j++) {
      var value = _codeUnitToRadixValue(source.codeUnitAt(i++));
      if (value >= 16) return null;
      digit = digit * 16 + value;
    }
    digits[digitIndex--] = digit;

    while (i < source.length) {
      digit = 0;
      for (int j = 0; j < hexCharsPerDigit; j++) {
        var value = _codeUnitToRadixValue(source.codeUnitAt(i++));
        if (value >= 16) return null;
        digit = digit * 16 + value;
      }
      digits[digitIndex--] = digit;
    }
    if (used == 1 && digits[0] == 0) return zero;
    return new _BigIntImpl._(isNegative, used, digits);
  }

  /// Parses the given [source] as a [radix] literal.
  ///
  /// The [source] will be checked for invalid characters. If it is invalid,
  /// this function returns `null`.
  static _BigIntImpl? _parseRadix(String source, int radix, bool isNegative) {
    var result = zero;
    var base = new _BigIntImpl._fromInt(radix);
    for (int i = 0; i < source.length; i++) {
      var value = _codeUnitToRadixValue(source.codeUnitAt(i));
      if (value >= radix) return null;
      result = result * base + new _BigIntImpl._fromInt(value);
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

    final match = _parseRE.firstMatch(source);
    int signIndex = 1;
    int hexIndex = 3;
    int decimalIndex = 4;
    int nonDecimalHexIndex = 5;
    if (match == null) return null;

    final bool isNegative = match[signIndex] == "-";

    final String? decimalMatch = match[decimalIndex];
    final String? hexMatch = match[hexIndex];
    final String? nonDecimalMatch = match[nonDecimalHexIndex];

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

    if (radix < 2 || radix > 36) {
      throw new RangeError.range(radix, 2, 36, 'radix');
    }
    if (radix == 10 && decimalMatch != null) {
      return _parseDecimal(decimalMatch, isNegative);
    }
    if (radix == 16) {
      final match = decimalMatch ?? nonDecimalMatch;
      if (match != null) {
        return _parseHex(match, 0, isNegative);
      }
    }

    // The RegExp guarantees that one of the 3 matches is non-null.
    final nonNullMatch = (decimalMatch ?? nonDecimalMatch ?? hexMatch)!;
    return _parseRadix(nonNullMatch, radix, isNegative);
  }

  static RegExp _parseRE = RegExp(
      r'^\s*([+-]?)((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$',
      caseSensitive: false);

  /// Finds the amount significant digits in the provided [digits] array.
  static int _normalize(int used, Uint32List digits) {
    while (used > 0 && digits[used - 1] == 0) used--;
    return used;
  }

  /// Factory returning an instance initialized with the given field values.
  /// If the [digits] array contains leading 0s, the [used] value is adjusted
  /// accordingly. The [digits] array is not modified.
  _BigIntImpl._(bool isNegative, int used, Uint32List digits)
      : this._normalized(isNegative, _normalize(used, digits), digits);

  _BigIntImpl._normalized(bool isNegative, this._used, this._digits)
      : _isNegative = _used == 0 ? false : isNegative {
    assert(_digits.length.isEven);
    assert(_used.isEven || _digits[_used] == 0); // Leading zero for 64-bit.
  }

  /// Whether this big integer is zero.
  bool get _isZero => _used == 0;

  /// Allocates an array of the given [length] and copies the [digits] in the
  /// range [from] to [to-1], starting at index 0, followed by leading zero
  /// digits.
  static Uint32List _cloneDigits(
      Uint32List digits, int from, int to, int length) {
    var resultDigits = _newDigits(length);
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

    if (value.abs() < 0x100000000) {
      return new _BigIntImpl._fromInt(value.toInt());
    }
    if (value is double) {
      return new _BigIntImpl._fromDouble(value);
    }
    return new _BigIntImpl._fromInt(value as int);
  }

  factory _BigIntImpl._fromInt(int value) {
    bool isNegative = value < 0;
    assert(_digitBits == 32);
    var digits = _newDigits(2);
    if (isNegative) {
      // Handle the min 64-bit value differently, since its negation is not
      // positive.
      if (value == _minInt) {
        digits[1] = 0x80000000;
        return new _BigIntImpl._(true, 2, digits);
      }
      value = -value;
    }
    if (value < _digitBase) {
      digits[0] = value;
      return new _BigIntImpl._(isNegative, 1, digits);
    }
    digits[0] = value & _digitMask;
    digits[1] = value >> _digitBits;
    return new _BigIntImpl._(isNegative, 2, digits);
  }

  /// An 8-byte Uint8List we can reuse for [_fromDouble] to avoid generating
  /// garbage.
  static final Uint8List _bitsForFromDouble = new Uint8List(8);

  factory _BigIntImpl._fromDouble(double value) {
    const int exponentBias = 1075;

    if (value.isNaN || value.isInfinite) {
      throw new ArgumentError("Value must be finite: $value");
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

    assert(_digitBits == 32);
    // The significant bits are in 0 .. 52.
    var unshiftedDigits = _newDigits(2);
    unshiftedDigits[0] =
        (bits[3] << 24) + (bits[2] << 16) + (bits[1] << 8) + bits[0];
    // Don't forget to add the hidden bit.
    unshiftedDigits[1] =
        ((0x10 | (bits[6] & 0xF)) << 16) + (bits[5] << 8) + bits[4];

    var unshiftedBig = new _BigIntImpl._normalized(false, 2, unshiftedDigits);
    _BigIntImpl absResult = unshiftedBig;
    if (exponent < 0) {
      absResult = unshiftedBig >> -exponent;
    } else if (exponent > 0) {
      absResult = unshiftedBig << exponent;
    }
    if (isNegative) return -absResult;
    return absResult;
  }

  /**
   * Return the negative value of this integer.
   *
   * The result of negating an integer always has the opposite sign, except
   * for zero, which is its own negation.
   */
  _BigIntImpl operator -() {
    if (_used == 0) return this;
    return new _BigIntImpl._(!_isNegative, _used, _digits);
  }

  /**
   * Returns the absolute value of this integer.
   *
   * For any integer `x`, the result is the same as `x < 0 ? -x : x`.
   */
  _BigIntImpl abs() => _isNegative ? -this : this;

  /// Returns this << n*_digitBits.
  _BigIntImpl _dlShift(int n) {
    final used = _used;
    if (used == 0) {
      return zero;
    }
    final resultUsed = used + n;
    final digits = _digits;
    final resultDigits = _newDigits(resultUsed);
    for (int i = used - 1; i >= 0; i--) {
      resultDigits[i + n] = digits[i];
    }
    return new _BigIntImpl._(_isNegative, resultUsed, resultDigits);
  }

  /// Same as [_dlShift] but works on the decomposed big integers.
  ///
  /// Returns `resultUsed`.
  ///
  /// `resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] << n*_digitBits`.
  static int _dlShiftDigits(
      Uint32List xDigits, int xUsed, int n, Uint32List resultDigits) {
    if (xUsed == 0) {
      return 0;
    }
    if (n == 0 && identical(resultDigits, xDigits)) {
      return xUsed;
    }
    final resultUsed = xUsed + n;
    assert(resultDigits.length >= resultUsed + (resultUsed & 1));
    for (int i = xUsed - 1; i >= 0; i--) {
      resultDigits[i + n] = xDigits[i];
    }
    for (int i = n - 1; i >= 0; i--) {
      resultDigits[i] = 0;
    }
    if (resultUsed.isOdd) {
      resultDigits[resultUsed] = 0;
    }
    return resultUsed;
  }

  /// Returns `this >> n*_digitBits`.
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
    final resultDigits = _newDigits(resultUsed);
    for (var i = n; i < used; i++) {
      resultDigits[i - n] = digits[i];
    }
    final result = new _BigIntImpl._(_isNegative, resultUsed, resultDigits);
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

  /// Same as [_drShift] but works on the decomposed big integers.
  ///
  /// Returns `resultUsed`.
  ///
  /// `resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] >> n*_digitBits`.
  static int _drShiftDigits(
      Uint32List xDigits, int xUsed, int n, Uint32List resultDigits) {
    final resultUsed = xUsed - n;
    if (resultUsed <= 0) {
      return 0;
    }
    assert(resultDigits.length >= resultUsed + (resultUsed & 1));
    for (var i = n; i < xUsed; i++) {
      resultDigits[i - n] = xDigits[i];
    }
    if (resultUsed.isOdd) {
      resultDigits[resultUsed] = 0;
    }
    return resultUsed;
  }

  /// Shifts the digits of [xDigits] into the right place in [resultDigits].
  ///
  /// `resultDigits[ds..xUsed+ds] = xDigits[0..xUsed-1] << (n % _digitBits)`
  ///   where `ds = n ~/ _digitBits`
  ///
  /// Does *not* clear digits below ds.
  ///
  /// Note: This function may be intrinsified.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:never-inline")
  static void _lsh(
      Uint32List xDigits, int xUsed, int n, Uint32List resultDigits) {
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

  /**
   * Shift the bits of this integer to the left by [shiftAmount].
   *
   * Shifting to the left makes the number larger, effectively multiplying
   * the number by `pow(2, shiftIndex)`.
   *
   * There is no limit on the size of the result. It may be relevant to
   * limit intermediate values by using the "and" operator with a suitable
   * mask.
   *
   * It is an error if [shiftAmount] is negative.
   */
  _BigIntImpl operator <<(int shiftAmount) {
    if (shiftAmount < 0) {
      throw new ArgumentError("shift-amount must be positive $shiftAmount");
    }
    if (_isZero) return this;
    final digitShift = shiftAmount ~/ _digitBits;
    final bitShift = shiftAmount % _digitBits;
    if (bitShift == 0) {
      return _dlShift(digitShift);
    }
    // Need one extra digit to hold bits shifted by bitShift.
    var resultUsed = _used + digitShift + 1;
    // The 64-bit intrinsic requires one extra pair to work with.
    var resultDigits = _newDigits(resultUsed + 1);
    _lsh(_digits, _used, shiftAmount, resultDigits);
    return new _BigIntImpl._(_isNegative, resultUsed, resultDigits);
  }

  /// resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] << n.
  /// Returns resultUsed.
  static int _lShiftDigits(
      Uint32List xDigits, int xUsed, int n, Uint32List resultDigits) {
    final digitsShift = n ~/ _digitBits;
    final bitShift = n % _digitBits;
    if (bitShift == 0) {
      return _dlShiftDigits(xDigits, xUsed, digitsShift, resultDigits);
    }
    // Need one extra digit to hold bits shifted by bitShift.
    var resultUsed = xUsed + digitsShift + 1;
    // The 64-bit intrinsic requires one extra pair to work with.
    assert(resultDigits.length >= resultUsed + 2 - (resultUsed & 1));
    _lsh(xDigits, xUsed, n, resultDigits);
    var i = digitsShift;
    while (--i >= 0) {
      resultDigits[i] = 0;
    }
    if (resultDigits[resultUsed - 1] == 0) {
      resultUsed--; // Clamp result.
    } else if (resultUsed.isOdd) {
      resultDigits[resultUsed] = 0;
    }
    return resultUsed;
  }

  /// resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] >> n.
  ///
  /// Note: This function may be intrinsified.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:never-inline")
  static void _rsh(
      Uint32List xDigits, int xUsed, int n, Uint32List resultDigits) {
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

  /**
   * Shift the bits of this integer to the right by [shiftAmount].
   *
   * Shifting to the right makes the number smaller and drops the least
   * significant bits, effectively doing an integer division by
   *`pow(2, shiftIndex)`.
   *
   * It is an error if [shiftAmount] is negative.
   */
  _BigIntImpl operator >>(int shiftAmount) {
    if (shiftAmount < 0) {
      throw new ArgumentError("shift-amount must be positive $shiftAmount");
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
    // The 64-bit intrinsic requires one extra pair to work with.
    final resultDigits = _newDigits(resultUsed + 1);
    _rsh(digits, used, shiftAmount, resultDigits);
    final result = new _BigIntImpl._(_isNegative, resultUsed, resultDigits);
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

  /// resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1] >> n.
  /// Returns resultUsed.
  static int _rShiftDigits(
      Uint32List xDigits, int xUsed, int n, Uint32List resultDigits) {
    final digitShift = n ~/ _digitBits;
    final bitShift = n % _digitBits;
    if (bitShift == 0) {
      return _drShiftDigits(xDigits, xUsed, digitShift, resultDigits);
    }
    var resultUsed = xUsed - digitShift;
    if (resultUsed <= 0) {
      return 0;
    }
    // The 64-bit intrinsic requires one extra pair to work with.
    assert(resultDigits.length >= resultUsed + 1 + (resultUsed + 1 & 1));
    _rsh(xDigits, xUsed, n, resultDigits);
    if (resultDigits[resultUsed - 1] == 0) {
      resultUsed--; // Clamp result.
    } else if (resultUsed.isOdd) {
      resultDigits[resultUsed] = 0;
    }
    return resultUsed;
  }

  /// Compares this to [other] taking the absolute value of both operands.
  ///
  /// Returns 0 if abs(this) == abs(other); a positive number if
  /// abs(this) > abs(other); and a negative number if abs(this) < abs(other).
  int _absCompare(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
    return _compareDigits(_digits, _used, other._digits, other._used);
  }

  /**
   * Compares this to `other`.
   *
   * Returns a negative number if `this` is less than `other`, zero if they are
   * equal, and a positive number if `this` is greater than `other`.
   */
  int compareTo(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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
      Uint32List digits, int used, Uint32List otherDigits, int otherUsed) {
    var result = used - otherUsed;
    if (result == 0) {
      for (int i = used - 1; i >= 0; i--) {
        result = digits[i] - otherDigits[i];
        if (result != 0) return result;
      }
    }
    return result;
  }

  /// resultDigits[0..used] = digits[0..used-1] + otherDigits[0..otherUsed-1].
  /// used >= otherUsed > 0.
  ///
  /// Note: This function may be intrinsified.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:never-inline")
  static void _absAdd(Uint32List digits, int used, Uint32List otherDigits,
      int otherUsed, Uint32List resultDigits) {
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

  /// resultDigits[0..used-1] = digits[0..used-1] - otherDigits[0..otherUsed-1].
  /// used >= otherUsed > 0.
  ///
  /// Note: This function may be intrinsified.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:never-inline")
  static void _absSub(Uint32List digits, int used, Uint32List otherDigits,
      int otherUsed, Uint32List resultDigits) {
    assert(used >= otherUsed && otherUsed > 0);
    var carry = 0;
    for (var i = 0; i < otherUsed; i++) {
      carry += digits[i] - otherDigits[i];
      resultDigits[i] = carry & _digitMask;
      carry >>= _digitBits;
    }
    for (var i = otherUsed; i < used; i++) {
      carry += digits[i];
      resultDigits[i] = carry & _digitMask;
      carry >>= _digitBits;
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
    var resultDigits = _newDigits(resultUsed);
    _absAdd(_digits, used, other._digits, otherUsed, resultDigits);
    return new _BigIntImpl._(isNegative, resultUsed, resultDigits);
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
    var resultDigits = _newDigits(used);
    _absSub(_digits, used, other._digits, otherUsed, resultDigits);
    return new _BigIntImpl._(isNegative, used, resultDigits);
  }

  /// Returns `abs(this) & abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absAndSetSign(_BigIntImpl other, bool isNegative) {
    var resultUsed = _min(_used, other._used);
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = _newDigits(resultUsed);
    for (var i = 0; i < resultUsed; i++) {
      resultDigits[i] = digits[i] & otherDigits[i];
    }
    return new _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) &~ abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absAndNotSetSign(_BigIntImpl other, bool isNegative) {
    var resultUsed = _used;
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = _newDigits(resultUsed);
    var m = _min(resultUsed, other._used);
    for (var i = 0; i < m; i++) {
      resultDigits[i] = digits[i] & ~otherDigits[i];
    }
    for (var i = m; i < resultUsed; i++) {
      resultDigits[i] = digits[i];
    }
    return new _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) | abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absOrSetSign(_BigIntImpl other, bool isNegative) {
    var used = _used;
    var otherUsed = other._used;
    var resultUsed = _max(used, otherUsed);
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = _newDigits(resultUsed);
    var l, m;
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
    return new _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /// Returns `abs(this) ^ abs(other)` with sign set according to [isNegative].
  _BigIntImpl _absXorSetSign(_BigIntImpl other, bool isNegative) {
    var used = _used;
    var otherUsed = other._used;
    var resultUsed = _max(used, otherUsed);
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = _newDigits(resultUsed);
    var l, m;
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
    return new _BigIntImpl._(isNegative, resultUsed, resultDigits);
  }

  /**
   * Bit-wise and operator.
   *
   * Treating both `this` and [other] as sufficiently large two's component
   * integers, the result is a number with only the bits set that are set in
   * both `this` and [other]
   *
   * Of both operands are negative, the result is negative, otherwise
   * the result is non-negative.
   */
  _BigIntImpl operator &(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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
    var p, n;
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

  /**
   * Bit-wise or operator.
   *
   * Treating both `this` and [other] as sufficiently large two's component
   * integers, the result is a number with the bits set that are set in either
   * of `this` and [other]
   *
   * If both operands are non-negative, the result is non-negative,
   * otherwise the result us negative.
   */
  _BigIntImpl operator |(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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
    var p, n;
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

  /**
   * Bit-wise exclusive-or operator.
   *
   * Treating both `this` and [other] as sufficiently large two's component
   * integers, the result is a number with the bits set that are set in one,
   * but not both, of `this` and [other]
   *
   * If the operands have the same sign, the result is non-negative,
   * otherwise the result is negative.
   */
  _BigIntImpl operator ^(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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
    var p, n;
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

  /**
   * The bit-wise negate operator.
   *
   * Treating `this` as a sufficiently large two's component integer,
   * the result is a number with the opposite bits set.
   *
   * This maps any integer `x` to `-x - 1`.
   */
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
  _BigIntImpl operator +(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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
  _BigIntImpl operator -(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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

  /// Multiplies `xDigits[xIndex]` with `multiplicandDigits` and adds the result
  /// to `accumulatorDigits`.
  ///
  /// The `multiplicandDigits` in the range `i` to `i`+`n`-1 are the
  /// multiplicand digits.
  ///
  /// The `accumulatorDigits` in the range `j` to `j`+`n`-1 are the accumulator
  /// digits.
  ///
  /// Concretely:
  /// `accumulatorDigits[j..j+n] += xDigits[xIndex] * m_digits[i..i+n-1]`.
  /// Returns 1.
  ///
  /// Note: This function may be intrinsified. Intrinsics on 64-bit platforms
  /// process digit pairs at even indices and returns 2.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:never-inline")
  static int _mulAdd(
      Uint32List xDigits,
      int xIndex,
      Uint32List multiplicandDigits,
      int i,
      Uint32List accumulatorDigits,
      int j,
      int n) {
    int x = xDigits[xIndex];
    if (x == 0) {
      // No-op if x is 0.
      return _isIntrinsified ? 2 : 1;
    }
    int carry = 0;
    int xl = x & _halfDigitMask;
    int xh = x >> _halfDigitBits;
    while (--n >= 0) {
      int ml = multiplicandDigits[i] & _halfDigitMask;
      int mh = multiplicandDigits[i++] >> _halfDigitBits;
      int ph = xh * ml + mh * xl;
      int pl = xl * ml +
          ((ph & _halfDigitMask) << _halfDigitBits) +
          accumulatorDigits[j] +
          carry;
      carry = (pl >> _digitBits) + (ph >> _halfDigitBits) + xh * mh;
      accumulatorDigits[j++] = pl & _digitMask;
    }
    while (carry != 0) {
      int l = accumulatorDigits[j] + carry;
      carry = l >> _digitBits;
      accumulatorDigits[j++] = l & _digitMask;
    }
    return _isIntrinsified ? 2 : 1;
  }

  /// Multiplies `xDigits[i]` with `xDigits` and adds the result to
  /// `accumulatorDigits`.
  ///
  /// The `xDigits` in the range `i` to `used`-1 are the multiplicand digits.
  ///
  /// The `accumulatorDigits` in the range 2*`i` to `i`+`used`-1 are the
  /// accumulator digits.
  ///
  /// Concretely:
  /// `accumulatorDigits[2*i..i+used-1] += xDigits[i]*xDigits[i] +
  /// 2*xDigits[i]*xDigits[i+1..used-1]`.
  /// Returns 1.
  ///
  /// Note: This function may be intrinsified. Intrinsics on 64-bit platforms
  /// process digit pairs at even indices and returns 2.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:never-inline")
  static int _sqrAdd(
      Uint32List xDigits, int i, Uint32List accumulatorDigits, int used) {
    int x = xDigits[i];
    if (x == 0) return _isIntrinsified ? 2 : 1;
    int j = 2 * i;
    int carry = 0;
    int xl = x & _halfDigitMask;
    int xh = x >> _halfDigitBits;
    int ph = 2 * xh * xl;
    int pl = xl * xl +
        ((ph & _halfDigitMask) << _halfDigitBits) +
        accumulatorDigits[j];
    carry = (pl >> _digitBits) + (ph >> _halfDigitBits) + xh * xh;
    accumulatorDigits[j] = pl & _digitMask;
    x <<= 1;
    xl = x & _halfDigitMask;
    xh = x >> _halfDigitBits;
    int n = used - i - 1;
    int k = i + 1;
    j++;
    while (--n >= 0) {
      int l = xDigits[k] & _halfDigitMask;
      int h = xDigits[k++] >> _halfDigitBits;
      int ph = xh * l + h * xl;
      int pl = xl * l +
          ((ph & _halfDigitMask) << _halfDigitBits) +
          accumulatorDigits[j] +
          carry;
      carry = (pl >> _digitBits) + (ph >> _halfDigitBits) + xh * h;
      accumulatorDigits[j++] = pl & _digitMask;
    }
    carry += accumulatorDigits[i + used];
    if (carry >= _digitBase) {
      accumulatorDigits[i + used] = carry - _digitBase;
      accumulatorDigits[i + used + 1] = 1;
    } else {
      accumulatorDigits[i + used] = carry;
    }
    return _isIntrinsified ? 2 : 1;
  }

  /// Multiplication operator.
  _BigIntImpl operator *(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
    var used = _used;
    var otherUsed = other._used;
    if (used == 0 || otherUsed == 0) {
      return zero;
    }
    var resultUsed = used + otherUsed;
    var digits = _digits;
    var otherDigits = other._digits;
    var resultDigits = _newDigits(resultUsed);
    var i = 0;
    while (i < otherUsed) {
      i += _mulAdd(otherDigits, i, digits, 0, resultDigits, i, used);
    }
    return new _BigIntImpl._(
        _isNegative != other._isNegative, resultUsed, resultDigits);
  }

  // resultDigits[0..resultUsed-1] =
  //     xDigits[0..xUsed-1]*otherDigits[0..otherUsed-1].
  // Returns resultUsed = xUsed + otherUsed.
  static int _mulDigits(Uint32List xDigits, int xUsed, Uint32List otherDigits,
      int otherUsed, Uint32List resultDigits) {
    var resultUsed = xUsed + otherUsed;
    var i = resultUsed + (resultUsed & 1);
    assert(resultDigits.length >= i);
    while (--i >= 0) {
      resultDigits[i] = 0;
    }
    i = 0;
    while (i < otherUsed) {
      i += _mulAdd(otherDigits, i, xDigits, 0, resultDigits, i, xUsed);
    }
    return resultUsed;
  }

  // resultDigits[0..resultUsed-1] = xDigits[0..xUsed-1]^2.
  // Returns resultUsed = 2*xUsed.
  static int _sqrDigits(
      Uint32List xDigits, int xUsed, Uint32List resultDigits) {
    var resultUsed = 2 * xUsed;
    assert(resultDigits.length >= resultUsed);
    // Since resultUsed is even, no need for a leading zero for
    // 64-bit processing.
    var i = resultUsed;
    while (--i >= 0) {
      resultDigits[i] = 0;
    }
    i = 0;
    while (i < xUsed - 1) {
      i += _sqrAdd(xDigits, i, resultDigits, xUsed);
    }
    // The last step is already done if digit pairs were processed above.
    if (i < xUsed) {
      _mulAdd(xDigits, i, xDigits, i, resultDigits, 2 * i, 1);
    }
    return resultUsed;
  }

  // Indices of the arguments of _estimateQuotientDigit.
  // For 64-bit processing by intrinsics on 64-bit platforms, the top digit pair
  // of the divisor is provided in the args array, and a 64-bit estimated
  // quotient is returned. However, on 32-bit platforms, the low 32-bit digit is
  // ignored and only one 32-bit digit is returned as the estimated quotient.
  static const int _divisorLowTopDigit = 0; // Low digit of top pair of divisor.
  static const int _divisorTopDigit = 1; // Top digit of divisor.
  static const int _quotientDigit = 2; // Estimated quotient.
  static const int _quotientHighDigit = 3; // High digit of estimated quotient.

  /// Estimate `args[_quotientDigit] = digits[i-1..i] ~/ args[_divisorTopDigit]`
  /// Returns 1.
  ///
  /// Note: This function may be intrinsified. Intrinsics on 64-bit platforms
  /// process a digit pair (i always odd):
  /// Estimate `args[_quotientDigit.._quotientHighDigit] = digits[i-3..i] ~/
  /// args[_divisorLowTopDigit.._divisorTopDigit]`.
  /// Returns 2.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:never-inline")
  static int _estimateQuotientDigit(Uint32List args, Uint32List digits, int i) {
    // Verify that digit pairs are accessible for 64-bit processing.
    assert(digits.length >= 4);
    if (digits[i] == args[_divisorTopDigit]) {
      args[_quotientDigit] = _digitMask;
    } else {
      // Chop off one bit, since a Mint cannot hold 2 digits.
      var quotientDigit =
          ((digits[i] << (_digitBits - 1)) | (digits[i - 1] >> 1)) ~/
              (args[_divisorTopDigit] >> 1);
      if (quotientDigit > _digitMask) {
        args[_quotientDigit] = _digitMask;
      } else {
        args[_quotientDigit] = quotientDigit;
      }
    }
    return _isIntrinsified ? 2 : 1;
  }

  /// Returns `trunc(this / other)`, with `other != 0`.
  _BigIntImpl _div(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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
    var quo = new _BigIntImpl._(false, lastQuo_used, quo_digits);
    if ((_isNegative != other._isNegative) && (quo._used > 0)) {
      quo = -quo;
    }
    return quo;
  }

  /// Returns `this - other * trunc(this / other)`, with `other != 0`.
  _BigIntImpl _rem(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
    assert(other._used > 0);
    if (_used < other._used) {
      return this;
    }
    _divRem(other);
    // Return remainder, i.e.
    // denormalized _lastQuoRem_digits[0.._lastRem_used-1] with proper sign.
    var remDigits =
        _cloneDigits(_lastQuoRemDigits, 0, _lastRemUsed, _lastRemUsed);
    var rem = new _BigIntImpl._(false, _lastRemUsed, remDigits);
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
    // For 64-bit processing, make sure other has an even number of digits.
    if (other._used.isOdd) {
      nsh += _digitBits;
    }
    // Concatenated positive quotient and normalized positive remainder.
    // The resultDigits can have at most one more digit than the dividend.
    Uint32List resultDigits;
    int resultUsed;
    // Normalized positive divisor (referred to as 'y').
    // The normalized divisor has the most-significant bit of its most
    // significant digit set.
    // This makes estimating the quotient easier.
    Uint32List yDigits;
    int yUsed;
    if (nsh > 0) {
      // Extra digits for normalization, also used for possible _mulAdd carry.
      var numExtraDigits = (nsh + _digitBits - 1) ~/ _digitBits + 1;
      yDigits = _newDigits(other._used + numExtraDigits);
      yUsed = _lShiftDigits(other._digits, other._used, nsh, yDigits);
      resultDigits = _newDigits(_used + numExtraDigits);
      resultUsed = _lShiftDigits(_digits, _used, nsh, resultDigits);
    } else {
      yDigits = other._digits;
      yUsed = other._used;
      // Extra digit to hold possible _mulAdd carry.
      resultDigits = _cloneDigits(_digits, 0, _used, _used + 1);
      resultUsed = _used;
    }
    Uint32List args = _newDigits(4);
    args[_divisorLowTopDigit] = yDigits[yUsed - 2];
    args[_divisorTopDigit] = yDigits[yUsed - 1];
    // For 64-bit processing, make sure yUsed, i, and j are even.
    assert(yUsed.isEven);
    var i = resultUsed + (resultUsed & 1);
    var j = i - yUsed;
    // tmpDigits is a temporary array of i (even resultUsed) digits.
    var tmpDigits = _newDigits(i);
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
    if (resultUsed.isOdd) {
      resultDigits[resultUsed] = 0; // Leading zero for 64-bit processing.
    }
    // Negate y so we can later use _mulAdd instead of nonexistent _mulSub.
    var nyDigits = _newDigits(yUsed + 2);
    nyDigits[yUsed] = 1;
    _absSub(nyDigits, yUsed + 1, yDigits, yUsed, nyDigits);
    // nyDigits is read-only and has yUsed digits (possibly including several
    // leading zeros) plus a leading zero for 64-bit processing.
    // resultDigits is modified during iteration.
    // resultDigits[0..yUsed-1] is the current remainder.
    // resultDigits[yUsed..resultUsed-1] is the current quotient.
    --i;
    while (j > 0) {
      var d0 = _estimateQuotientDigit(args, resultDigits, i);
      j -= d0;
      var d1 =
          _mulAdd(args, _quotientDigit, nyDigits, 0, resultDigits, j, yUsed);
      // _estimateQuotientDigit and _mulAdd must agree on the number of digits
      // to process.
      assert(d0 == d1);
      if (d0 == 1) {
        if (resultDigits[i] < args[_quotientDigit]) {
          // Reusing the already existing tmpDigits array.
          var tmpUsed = _dlShiftDigits(nyDigits, yUsed, j, tmpDigits);
          _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
          while (resultDigits[i] < --args[_quotientDigit]) {
            _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
          }
        }
      } else {
        assert(d0 == 2);
        assert(resultDigits[i] <= args[_quotientHighDigit]);
        if (resultDigits[i] < args[_quotientHighDigit] ||
            resultDigits[i - 1] < args[_quotientDigit]) {
          // Reusing the already existing tmpDigits array.
          var tmpUsed = _dlShiftDigits(nyDigits, yUsed, j, tmpDigits);
          _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
          if (args[_quotientDigit] == 0) {
            --args[_quotientHighDigit];
          }
          --args[_quotientDigit];
          assert(resultDigits[i] <= args[_quotientHighDigit]);
          while (resultDigits[i] < args[_quotientHighDigit] ||
              resultDigits[i - 1] < args[_quotientDigit]) {
            _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
            if (args[_quotientDigit] == 0) {
              --args[_quotientHighDigit];
            }
            --args[_quotientDigit];
            assert(resultDigits[i] <= args[_quotientHighDigit]);
          }
        }
      }
      i -= d0;
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

  // Customized version of _rem() minimizing allocations for use in reduction.
  // Input:
  //   xDigits[0..xUsed-1]: positive dividend.
  //   yDigits[0..yUsed-1]: normalized positive divisor.
  //   nyDigits[0..yUsed-1]: negated yDigits.
  //   nsh: normalization shift amount.
  //   args: top y digit(s) and place holder for estimated quotient digit(s).
  //   tmpDigits: temp array of 2*yUsed digits.
  //   resultDigits: result digits array large enough to temporarily hold
  //                 concatenated quotient and normalized remainder.
  // Output:
  //   resultDigits[0..resultUsed-1]: positive remainder.
  // Returns resultUsed.
  static int _remDigits(
      Uint32List xDigits,
      int xUsed,
      Uint32List yDigits,
      int yUsed,
      Uint32List nyDigits,
      int nsh,
      Uint32List args,
      Uint32List tmpDigits,
      Uint32List resultDigits) {
    // Initialize resultDigits to normalized positive dividend.
    var resultUsed = _lShiftDigits(xDigits, xUsed, nsh, resultDigits);
    // For 64-bit processing, make sure yUsed, i, and j are even.
    assert(yUsed.isEven);
    var i = resultUsed + (resultUsed & 1);
    var j = i - yUsed;
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
    if (resultUsed.isOdd) {
      resultDigits[resultUsed] = 0; // Leading zero for 64-bit processing.
    }
    // Negated yDigits passed in nyDigits allow the use of _mulAdd instead of
    // unimplemented _mulSub.
    // nyDigits is read-only and has yUsed digits (possibly including several
    // leading zeros) plus a leading zero for 64-bit processing.
    // resultDigits is modified during iteration.
    // resultDigits[0..yUsed-1] is the current remainder.
    // resultDigits[yUsed..resultUsed-1] is the current quotient.
    --i;
    while (j > 0) {
      var d0 = _estimateQuotientDigit(args, resultDigits, i);
      j -= d0;
      var d1 =
          _mulAdd(args, _quotientDigit, nyDigits, 0, resultDigits, j, yUsed);
      // _estimateQuotientDigit and _mulAdd must agree on the number of digits
      // to process.
      assert(d0 == d1);
      if (d0 == 1) {
        if (resultDigits[i] < args[_quotientDigit]) {
          var tmpUsed = _dlShiftDigits(nyDigits, yUsed, j, tmpDigits);
          _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
          while (resultDigits[i] < --args[_quotientDigit]) {
            _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
          }
        }
      } else {
        assert(d0 == 2);
        assert(resultDigits[i] <= args[_quotientHighDigit]);
        if ((resultDigits[i] < args[_quotientHighDigit]) ||
            (resultDigits[i - 1] < args[_quotientDigit])) {
          var tmpUsed = _dlShiftDigits(nyDigits, yUsed, j, tmpDigits);
          _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
          if (args[_quotientDigit] == 0) {
            --args[_quotientHighDigit];
          }
          --args[_quotientDigit];
          assert(resultDigits[i] <= args[_quotientHighDigit]);
          while ((resultDigits[i] < args[_quotientHighDigit]) ||
              (resultDigits[i - 1] < args[_quotientDigit])) {
            _absSub(resultDigits, resultUsed, tmpDigits, tmpUsed, resultDigits);
            if (args[_quotientDigit] == 0) {
              --args[_quotientHighDigit];
            }
            --args[_quotientDigit];
            assert(resultDigits[i] <= args[_quotientHighDigit]);
          }
        }
      }
      i -= d0;
    }
    // Return remainder, i.e. denormalized resultDigits[0..yUsed-1].
    resultUsed = yUsed;
    if (nsh > 0) {
      // Denormalize remainder.
      resultUsed = _rShiftDigits(resultDigits, resultUsed, nsh, resultDigits);
    }
    return resultUsed;
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

  /**
   * Test whether this value is numerically equal to `other`.
   *
   * If [other] is a [_BigIntImpl] returns whether the two operands have the
   * same value.
   *
   * Returns false if `other` is not a [_BigIntImpl].
   */
  bool operator ==(Object other) =>
      other is _BigIntImpl && compareTo(other) == 0;

  /**
   * Returns the minimum number of bits required to store this big integer.
   *
   * The number of bits excludes the sign bit, which gives the natural length
   * for non-negative (unsigned) values.  Negative values are complemented to
   * return the bit position of the first bit that differs from the sign bit.
   *
   * To find the number of bits needed to store the value as a signed value,
   * add one, i.e. use `x.bitLength + 1`.
   *
   * ```
   * x.bitLength == (-x-1).bitLength
   *
   * new BigInt.from(3).bitLength == 2;   // 00000011
   * new BigInt.from(2).bitLength == 2;   // 00000010
   * new BigInt.from(1).bitLength == 1;   // 00000001
   * new BigInt.from(0).bitLength == 0;   // 00000000
   * new BigInt.from(-1).bitLength == 0;  // 11111111
   * new BigInt.from(-2).bitLength == 1;  // 11111110
   * new BigInt.from(-3).bitLength == 2;  // 11111101
   * new BigInt.from(-4).bitLength == 2;  // 11111100
   * ```
   */
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

  /**
   * Truncating division operator.
   *
   * Performs a truncating integer division, where the remainder is discarded.
   *
   * The remainder can be computed using the [remainder] method.
   *
   * Examples:
   * ```
   * var seven = new BigInt.from(7);
   * var three = new BigInt.from(3);
   * seven ~/ three;    // => 2
   * (-seven) ~/ three; // => -2
   * seven ~/ -three;   // => -2
   * seven.remainder(three);    // => 1
   * (-seven).remainder(three); // => -1
   * seven.remainder(-three);   // => 1
   * ```
   */
  _BigIntImpl operator ~/(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
    if (other._used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return _div(other);
  }

  /**
   * Returns the remainder of the truncating division of `this` by [other].
   *
   * The result `r` of this operation satisfies:
   * `this == (this ~/ other) * other + r`.
   * As a consequence the remainder `r` has the same sign as the divider `this`.
   */
  _BigIntImpl remainder(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
    if (other._used == 0) {
      throw const IntegerDivisionByZeroException();
    }
    return _rem(other);
  }

  /// Division operator.
  double operator /(BigInt other) => this.toDouble() / other.toDouble();

  /** Relational less than operator. */
  bool operator <(BigInt other) => compareTo(other) < 0;

  /** Relational less than or equal operator. */
  bool operator <=(BigInt other) => compareTo(other) <= 0;

  /** Relational greater than operator. */
  bool operator >(BigInt other) => compareTo(other) > 0;

  /** Relational greater than or equal operator. */
  bool operator >=(BigInt other) => compareTo(other) >= 0;

  /**
   * Euclidean modulo operator.
   *
   * Returns the remainder of the Euclidean division. The Euclidean division of
   * two integers `a` and `b` yields two integers `q` and `r` such that
   * `a == b * q + r` and `0 <= r < b.abs()`.
   *
   * The sign of the returned value `r` is always positive.
   *
   * See [remainder] for the remainder of the truncating division.
   */
  _BigIntImpl operator %(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
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

  /**
   * Returns the sign of this big integer.
   *
   * Returns 0 for zero, -1 for values less than zero and
   * +1 for values greater than zero.
   */
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
      throw new ArgumentError("Exponent must not be negative: $exponent");
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

  /**
   * Returns this integer to the power of [exponent] modulo [modulus].
   *
   * The [exponent] must be non-negative and [modulus] must be
   * positive.
   */
  _BigIntImpl modPow(BigInt bigExponent, BigInt bigModulus) {
    final exponent = _ensureSystemBigInt(bigExponent, 'bigExponent');
    final modulus = _ensureSystemBigInt(bigModulus, 'bigModulus');
    if (exponent._isNegative) {
      throw new ArgumentError("exponent must be positive: $exponent");
    }
    if (modulus <= zero) {
      throw new ArgumentError("modulus must be strictly positive: $modulus");
    }
    if (exponent._isZero) return one;

    final exponentBitlen = exponent.bitLength;
    if (exponentBitlen <= 0) return one;
    final bool cannotUseMontgomery = modulus.isEven || abs() >= modulus;
    if (cannotUseMontgomery || exponentBitlen < 64) {
      _BigIntReduction z = (cannotUseMontgomery || exponentBitlen < 8)
          ? new _BigIntClassicReduction(modulus)
          : new _BigIntMontgomeryReduction(modulus);
      var resultDigits = _newDigits(2 * z._normModulusUsed + 2);
      var result2Digits = _newDigits(2 * z._normModulusUsed + 2);
      var gDigits = _newDigits(z._normModulusUsed);
      var gUsed = z._convert(this, gDigits);
      // Initialize result with g.
      // Copy leading zero if any.
      for (int j = gUsed + (gUsed & 1) - 1; j >= 0; j--) {
        resultDigits[j] = gDigits[j];
      }
      var resultUsed = gUsed;
      var result2Used;
      for (int i = exponentBitlen - 2; i >= 0; i--) {
        result2Used = z._sqr(resultDigits, resultUsed, result2Digits);
        if (exponent._digits[i ~/ _digitBits] & (1 << (i % _digitBits)) != 0) {
          resultUsed =
              z._mul(result2Digits, result2Used, gDigits, gUsed, resultDigits);
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
      return z._revert(resultDigits, resultUsed);
    }
    late int k;
    if (exponentBitlen < 18)
      k = 1;
    else if (exponentBitlen < 48)
      k = 3;
    else if (exponentBitlen < 144)
      k = 4;
    else if (exponentBitlen < 768)
      k = 5;
    else
      k = 6;
    _BigIntReduction z = new _BigIntMontgomeryReduction(modulus);
    var n = 3;
    final int k1 = k - 1;
    final km = (1 << k) - 1;
    List gDigits = new List.filled(km + 1, null);
    List gUsed = new List.filled(km + 1, null);
    gDigits[1] = _newDigits(z._normModulusUsed);
    gUsed[1] = z._convert(this, gDigits[1]);
    if (k > 1) {
      var g2Digits = _newDigits(2 * z._normModulusUsed + 2);
      var g2Used = z._sqr(gDigits[1], gUsed[1], g2Digits);
      while (n <= km) {
        gDigits[n] = _newDigits(2 * z._normModulusUsed + 2);
        gUsed[n] =
            z._mul(g2Digits, g2Used, gDigits[n - 2], gUsed[n - 2], gDigits[n]);
        n += 2;
      }
    }
    var w;
    var isOne = true;
    var resultDigits = one._digits;
    var resultUsed = one._used;
    var result2Digits = _newDigits(2 * z._normModulusUsed + 2);
    var result2Used;
    var exponentDigits = exponent._digits;
    var j = exponent._used - 1;
    int i = exponentDigits[j].bitLength - 1;
    while (j >= 0) {
      if (i >= k1) {
        w = (exponentDigits[j] >> (i - k1)) & km;
      } else {
        w = (exponentDigits[j] & ((1 << (i + 1)) - 1)) << (k1 - i);
        if (j > 0) {
          w |= exponentDigits[j - 1] >> (_digitBits + i - k1);
        }
      }
      n = k;
      while ((w & 1) == 0) {
        w >>= 1;
        --n;
      }
      if ((i -= n) < 0) {
        i += _digitBits;
        --j;
      }
      if (isOne) {
        // r == 1, don't bother squaring or multiplying it.
        resultDigits = _newDigits(2 * z._normModulusUsed + 2);
        resultUsed = gUsed[w];
        var gwDigits = gDigits[w];
        var ri = resultUsed + (resultUsed & 1); // Copy leading zero if any.
        while (--ri >= 0) {
          resultDigits[ri] = gwDigits[ri];
        }
        isOne = false;
      } else {
        while (n > 1) {
          result2Used = z._sqr(resultDigits, resultUsed, result2Digits);
          resultUsed = z._sqr(result2Digits, result2Used, resultDigits);
          n -= 2;
        }
        if (n > 0) {
          result2Used = z._sqr(resultDigits, resultUsed, result2Digits);
        } else {
          var swapDigits = resultDigits;
          var swapUsed = resultUsed;
          resultDigits = result2Digits;
          resultUsed = result2Used;
          result2Digits = swapDigits;
          result2Used = swapUsed;
        }
        resultUsed = z._mul(
            result2Digits, result2Used, gDigits[w], gUsed[w], resultDigits);
      }
      while (j >= 0 && (exponentDigits[j] & (1 << i)) == 0) {
        result2Used = z._sqr(resultDigits, resultUsed, result2Digits);
        var swapDigits = resultDigits;
        var swapUsed = resultUsed;
        resultDigits = result2Digits;
        resultUsed = result2Used;
        result2Digits = swapDigits;
        result2Used = swapUsed;
        if (--i < 0) {
          i = _digitBits - 1;
          --j;
        }
      }
    }
    assert(!isOne);
    return z._revert(resultDigits, resultUsed);
  }

  // If inv is false, returns gcd(x, y).
  // If inv is true and gcd(x, y) = 1, returns d, so that c*x + d*y = 1.
  // If inv is true and gcd(x, y) != 1, throws Exception("Not coprime").
  static _BigIntImpl _binaryGcd(_BigIntImpl x, _BigIntImpl y, bool inv) {
    var xDigits = x._digits;
    var yDigits = y._digits;
    var xUsed = x._used;
    var yUsed = y._used;
    var maxUsed = _max(xUsed, yUsed);
    final maxLen = maxUsed + (maxUsed & 1);
    xDigits = _cloneDigits(xDigits, 0, xUsed, maxLen);
    yDigits = _cloneDigits(yDigits, 0, yUsed, maxLen);
    int shiftAmount = 0;
    if (inv) {
      if ((yUsed == 1) && (yDigits[0] == 1)) return one;
      if ((yUsed == 0) || (yDigits[0].isEven && xDigits[0].isEven)) {
        throw new Exception("Not coprime");
      }
    } else {
      if (x._isZero) {
        throw new ArgumentError.value(0, "this", "must not be zero");
      }
      if (y._isZero) {
        throw new ArgumentError.value(0, "other", "must not be zero");
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
    var uDigits = _cloneDigits(xDigits, 0, xUsed, maxLen);
    var vDigits = _cloneDigits(yDigits, 0, yUsed, maxLen + 2); // +2 for lsh.
    final bool ac = (xDigits[0] & 1) == 0;

    // Variables a, b, c, and d require one more digit.
    final abcdUsed = maxUsed + 1;
    final abcdLen = abcdUsed + (abcdUsed & 1) + 2; // +2 to satisfy _absAdd.

    bool aIsNegative = false;
    bool cIsNegative = false;
    late final Uint32List aDigits, cDigits;
    if (ac) {
      aDigits = _newDigits(abcdLen);
      aDigits[0] = 1;
      cDigits = _newDigits(abcdLen);
    }
    final Uint32List bDigits = _newDigits(abcdLen);
    final Uint32List dDigits = _newDigits(abcdLen);
    bool bIsNegative = false;
    bool dIsNegative = false;
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
      return new _BigIntImpl._(false, maxUsed, vDigits);
    }
    // No inverse if v != 1.
    var i = maxUsed - 1;
    while ((i > 0) && (vDigits[i] == 0)) --i;
    if ((i != 0) || (vDigits[0] != 1)) {
      throw new Exception("Not coprime");
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
    return new _BigIntImpl._(false, maxUsed, dDigits);
  }

  /**
   * Returns the modular multiplicative inverse of this big integer
   * modulo [modulus].
   *
   * The [modulus] must be positive.
   *
   * It is an error if no modular inverse exists.
   */
  // Returns 1/this % modulus, with modulus > 0.
  _BigIntImpl modInverse(BigInt bigInt) {
    final modulus = _ensureSystemBigInt(bigInt, 'bigInt');
    if (modulus <= zero) {
      throw new ArgumentError("Modulus must be strictly positive: $modulus");
    }
    if (modulus == one) return zero;
    var tmp = this;
    if (tmp._isNegative || (tmp._absCompare(modulus) >= 0)) {
      tmp %= modulus;
    }
    return _binaryGcd(modulus, tmp, true);
  }

  /**
   * Returns the greatest common divisor of this big integer and [other].
   *
   * If either number is non-zero, the result is the numerically greatest
   * integer dividing both `this` and `other`.
   *
   * The greatest common divisor is independent of the order,
   * so `x.gcd(y)` is  always the same as `y.gcd(x)`.
   *
   * For any integer `x`, `x.gcd(x)` is `x.abs()`.
   *
   * If both `this` and `other` is zero, the result is also zero.
   */
  _BigIntImpl gcd(BigInt bigInt) {
    final other = _ensureSystemBigInt(bigInt, 'bigInt');
    if (_isZero) return other.abs();
    if (other._isZero) return this.abs();
    return _binaryGcd(this, other, false);
  }

  /**
   * Returns the least significant [width] bits of this big integer as a
   * non-negative number (i.e. unsigned representation).  The returned value has
   * zeros in all bit positions higher than [width].
   *
   * ```
   * new BigInt.from(-1).toUnsigned(5) == 31   // 11111111  ->  00011111
   * ```
   *
   * This operation can be used to simulate arithmetic from low level languages.
   * For example, to increment an 8 bit quantity:
   *
   * ```
   * q = (q + 1).toUnsigned(8);
   * ```
   *
   * `q` will count from `0` up to `255` and then wrap around to `0`.
   *
   * If the input fits in [width] bits without truncation, the result is the
   * same as the input.  The minimum width needed to avoid truncation of `x` is
   * given by `x.bitLength`, i.e.
   *
   * ```
   * x == x.toUnsigned(x.bitLength);
   * ```
   */
  _BigIntImpl toUnsigned(int width) {
    return this & ((one << width) - one);
  }

  /**
   * Returns the least significant [width] bits of this integer, extending the
   * highest retained bit to the sign.  This is the same as truncating the value
   * to fit in [width] bits using an signed 2-s complement representation.  The
   * returned value has the same bit value in all positions higher than [width].
   *
   * ```
   * var big15 = new BigInt.from(15);
   * var big16 = new BigInt.from(16);
   * var big239 = new BigInt.from(239);
   *                                      V--sign bit-V
   * big16.toSigned(5) == -big16   //  00010000 -> 11110000
   * big239.toSigned(5) == big15   //  11101111 -> 00001111
   *                                      ^           ^
   * ```
   *
   * This operation can be used to simulate arithmetic from low level languages.
   * For example, to increment an 8 bit signed quantity:
   *
   * ```
   * q = (q + 1).toSigned(8);
   * ```
   *
   * `q` will count from `0` up to `127`, wrap to `-128` and count back up to
   * `127`.
   *
   * If the input value fits in [width] bits without truncation, the result is
   * the same as the input.  The minimum width needed to avoid truncation of `x`
   * is `x.bitLength + 1`, i.e.
   *
   * ```
   * x == x.toSigned(x.bitLength + 1);
   * ```
   */
  _BigIntImpl toSigned(int width) {
    // The value of binary number weights each bit by a power of two.  The
    // twos-complement value weights the sign bit negatively.  We compute the
    // value of the negative weighting by isolating the sign bit with the
    // correct power of two weighting and subtracting it from the value of the
    // lower bits.
    var signMask = one << (width - 1);
    return (this & (signMask - one)) - (this & signMask);
  }

  bool get isValidInt {
    assert(_digitBits == 32);
    return _used < 2 ||
        (_used == 2 &&
            (_digits[1] < 0x80000000 ||
                (_isNegative && _digits[1] == 0x80000000 && _digits[0] == 0)));
  }

  int toInt() {
    assert(_digitBits == 32);
    if (_used == 0) return 0;
    if (_used == 1) return _isNegative ? -_digits[0] : _digits[0];
    if (_used == 2 && _digits[1] < 0x80000000) {
      var result = (_digits[1] << _digitBits) | _digits[0];
      return _isNegative ? -result : result;
    }
    return _isNegative ? _minInt : _maxInt;
  }

  /**
   * Returns this [_BigIntImpl] as a [double].
   *
   * If the number is not representable as a [double], an
   * approximation is returned. For numerically large integers, the
   * approximation may be infinite.
   */
  double toDouble() {
    const int exponentBias = 1075;
    // There are 11 bits for the exponent.
    // 2047 (all bits set to 1) is reserved for infinity and NaN.
    // When storing the exponent in the 11 bits, it is biased by exponentBias
    // to support negative exponents.
    const int maxDoubleExponent = 2046 - exponentBias;
    if (_isZero) return 0.0;

    // We fill the 53 bits little-endian.
    var resultBits = new Uint8List(8);

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

  /**
   * Returns a String-representation of this integer.
   *
   * The returned string is parsable by [parse].
   * For any `_BigIntImpl` `i`, it is guaranteed that
   * `i == _BigIntImpl.parse(i.toString())`.
   */
  String toString() {
    if (_used == 0) return "0";
    if (_used == 1) {
      if (_isNegative) return (-_digits[0]).toString();
      return _digits[0].toString();
    }

    // Generate in chunks of 9 digits.
    // The chunks are in reversed order.
    var decimalDigitChunks = <String>[];
    var rest = isNegative ? -this : this;
    while (rest._used > 1) {
      var digits9 = rest.remainder(_oneBillion).toString();
      decimalDigitChunks.add(digits9);
      var zeros = 9 - digits9.length;
      if (zeros == 8) {
        decimalDigitChunks.add("00000000");
      } else {
        if (zeros >= 4) {
          zeros -= 4;
          decimalDigitChunks.add("0000");
        }
        if (zeros >= 2) {
          zeros -= 2;
          decimalDigitChunks.add("00");
        }
        if (zeros >= 1) {
          decimalDigitChunks.add("0");
        }
      }
      rest = rest ~/ _oneBillion;
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

  /**
   * Converts this [BigInt] to a string representation in the given [radix].
   *
   * In the string representation, lower-case letters are used for digits above
   * '9', with 'a' being 10 an 'z' being 35.
   *
   * The [radix] argument must be an integer in the range 2 to 36.
   */
  String toRadixString(int radix) {
    if (radix < 2 || radix > 36) throw new RangeError.range(radix, 2, 36);

    if (_used == 0) return "0";

    if (_used == 1) {
      var digitString = _digits[0].toRadixString(radix);
      if (_isNegative) return "-" + digitString;
      return digitString;
    }

    if (radix == 16) return _toHexString();

    var base = new _BigIntImpl._fromInt(radix);
    var reversedDigitCodeUnits = <int>[];
    var rest = this.abs();
    while (!rest._isZero) {
      var digit = rest.remainder(base).toInt();
      rest = rest ~/ base;
      reversedDigitCodeUnits.add(_toRadixCodeUnit(digit));
    }
    var digitString = new String.fromCharCodes(reversedDigitCodeUnits.reversed);
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
    return new String.fromCharCodes(chars.reversed);
  }

  static _BigIntImpl _ensureSystemBigInt(BigInt bigInt, String parameterName) {
    if (bigInt is _BigIntImpl) return bigInt;
    throw ArgumentError.value(
        bigInt, parameterName, "Must be a platform BigInt");
  }
}

// Interface for modular reduction.
abstract class _BigIntReduction {
  int get _normModulusUsed;
  // Return the number of digits used by resultDigits.
  int _convert(_BigIntImpl x, Uint32List resultDigits);
  int _mul(Uint32List xDigits, int xUsed, Uint32List yDigits, int yUsed,
      Uint32List resultDigits);
  int _sqr(Uint32List xDigits, int xUsed, Uint32List resultDigits);

  // Return x reverted to _BigIntImpl.
  _BigIntImpl _revert(Uint32List xDigits, int xUsed);
}

// Montgomery reduction on _BigIntImpl.
class _BigIntMontgomeryReduction implements _BigIntReduction {
  final _BigIntImpl _modulus;
  final int _normModulusUsed; // Even if processing 64-bit (digit pairs).
  final Uint32List _modulusDigits;
  final Uint32List _args;
  final int _digitsPerStep; // Number of digits processed in one step. 1 or 2.
  static const int _xDigit = 0; // Index of digit of x.
  static const int _xHighDigit = 1; // Index of high digit of x (64-bit only).
  static const int _rhoDigit = 2; // Index of digit of rho.
  static const int _rhoHighDigit = 3; // Index of high digit of rho (64-bit).
  static const int _muDigit = 4; // Index of mu.
  static const int _muHighDigit = 5; // Index of high 32-bits of mu (64-bit).

  factory _BigIntMontgomeryReduction(_BigIntImpl modulus) {
    final Uint32List modulusDigits = modulus._digits;
    final Uint32List args = _newDigits(6);

    // Determine if we can process digit pairs by calling an intrinsic.
    final int digitsPerStep = _mulMod(args, args, 0);
    args[_xDigit] = modulusDigits[0];

    int normModulusUsed = modulus._used;
    if (digitsPerStep == 1) {
      _invDigit(args);
    } else {
      assert(digitsPerStep == 2);
      normModulusUsed += modulus._used & 1;
      args[_xHighDigit] = modulusDigits[1];
      _invDigitPair(args);
    }
    return _BigIntMontgomeryReduction._(
        modulus, normModulusUsed, modulusDigits, args, digitsPerStep);
  }

  _BigIntMontgomeryReduction._(this._modulus, this._normModulusUsed,
      this._modulusDigits, this._args, this._digitsPerStep);

  // Calculates -1/x % _digitBase, x is 32-bit digit.
  //         xy == 1 (mod m)
  //         xy =  1+km
  //   xy(2-xy) = (1+km)(1-km)
  // x(y(2-xy)) = 1-k^2 m^2
  // x(y(2-xy)) == 1 (mod m^2)
  // if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
  // Should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
  //
  // Operation:
  //   args[_rhoDigit] = 1/args[_xDigit] mod _digitBase.
  static void _invDigit(Uint32List args) {
    var x = args[_xDigit];
    var y = x & 3; // y == 1/x mod 2^2
    y = (y * (2 - (x & 0xf) * y)) & 0xf; // y == 1/x mod 2^4
    y = (y * (2 - (x & 0xff) * y)) & 0xff; // y == 1/x mod 2^8
    y = (y * (2 - (((x & 0xffff) * y) & 0xffff))) & 0xffff; // y == 1/x mod 2^16
    y = (y * (2 - x * y % _BigIntImpl._digitBase)) % _BigIntImpl._digitBase;
    // y == 1/x mod _digitBase
    y = -y; // We really want the negative inverse.
    args[_rhoDigit] = y & _BigIntImpl._digitMask;
    assert(((x * y) & _BigIntImpl._digitMask) == _BigIntImpl._digitMask);
  }

  // Calculates -1/x % _digitBase^2, x is a pair of 32-bit digits.
  // Operation:
  //   args[_rhoDigit.._rhoHighDigit] =
  //     1/args[_xDigit.._xHighDigit] mod _digitBase^2.
  static void _invDigitPair(Uint32List args) {
    var xl = args[_xDigit]; // Lower 32-bit digit of x.
    var y = xl & 3; // y == 1/x mod 2^2
    y = (y * (2 - (xl & 0xf) * y)) & 0xf; // y == 1/x mod 2^4
    y = (y * (2 - (xl & 0xff) * y)) & 0xff; // y == 1/x mod 2^8
    y = (y * (2 - (((xl & 0xffff) * y) & 0xffff))) & 0xffff;
    // y == 1/x mod 2^16
    y = (y * (2 - ((xl * y) & 0xffffffff))) & 0xffffffff; // y == 1/x mod 2^32
    var x = (args[_xHighDigit] << _BigIntImpl._digitBits) | xl;
    y *= 2 - x * y; // Masking with 2^64-1 is implied by 64-bit arithmetic.
    // y == 1/x mod _digitBase^2
    y = -y; // We really want the negative inverse.
    args[_rhoDigit] = y & _BigIntImpl._digitMask;
    args[_rhoHighDigit] =
        (y >> _BigIntImpl._digitBits) & _BigIntImpl._digitMask;
    assert(x * y == -1);
  }

  // Operation:
  //   args[_muDigit] = args[_rhoDigit]*digits[i] mod _digitBase.
  //   Returns 1.
  // Note: Intrinsics on 64-bit platforms process digit pairs at even indices:
  //   args[_muDigit.._muHighDigit] =
  //     args[_rhoDigit.._rhoHighDigit] * digits[i..i+1] mod _digitBase^2.
  //   Returns 2.
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:never-inline")
  static int _mulMod(Uint32List args, Uint32List digits, int i) {
    var rhol = args[_rhoDigit] & _BigIntImpl._halfDigitMask;
    var rhoh = args[_rhoDigit] >> _BigIntImpl._halfDigitBits;
    var dh = digits[i] >> _BigIntImpl._halfDigitBits;
    var dl = digits[i] & _BigIntImpl._halfDigitMask;
    args[_muDigit] = (dl * rhol +
            (((dl * rhoh + dh * rhol) & _BigIntImpl._halfDigitMask) <<
                _BigIntImpl._halfDigitBits)) &
        _BigIntImpl._digitMask;
    return _BigIntImpl._isIntrinsified ? 2 : 1;
  }

  // result = x*R mod _modulus.
  // Returns resultUsed.
  int _convert(_BigIntImpl x, Uint32List resultDigits) {
    // Montgomery reduction only works if abs(x) < _modulus.
    assert(x.abs() < _modulus);
    assert(_digitsPerStep == 1 || _normModulusUsed.isEven);
    var result = x.abs()._dlShift(_normModulusUsed)._rem(_modulus);
    if (x._isNegative && !result._isNegative && result._used > 0) {
      result = _modulus - result;
    }
    var used = result._used;
    var digits = result._digits;
    var i = used + (used & 1);
    while (--i >= 0) {
      resultDigits[i] = digits[i];
    }
    return used;
  }

  _BigIntImpl _revert(Uint32List xDigits, int xUsed) {
    // Reserve enough digits for modulus squaring and accumulator carry.
    var resultDigits = _newDigits(2 * _normModulusUsed + 2);
    var i = xUsed + (xUsed & 1);
    while (--i >= 0) {
      resultDigits[i] = xDigits[i];
    }
    var resultUsed = _reduce(resultDigits, xUsed);
    return new _BigIntImpl._(false, resultUsed, resultDigits);
  }

  // x = x/R mod _modulus.
  // Returns xUsed.
  int _reduce(Uint32List xDigits, int xUsed) {
    while (xUsed < 2 * _normModulusUsed + 2) {
      // Pad x so _mulAdd has enough room later for a possible carry.
      xDigits[xUsed++] = 0;
    }
    var i = 0;
    while (i < _normModulusUsed) {
      var d = _mulMod(_args, xDigits, i);
      assert(d == _digitsPerStep);
      d = _BigIntImpl._mulAdd(
          _args, _muDigit, _modulusDigits, 0, xDigits, i, _normModulusUsed);
      assert(d == _digitsPerStep);
      i += d;
    }
    // Clamp x.
    while (xUsed > 0 && xDigits[xUsed - 1] == 0) {
      --xUsed;
    }
    xUsed = _BigIntImpl._drShiftDigits(xDigits, xUsed, i, xDigits);
    if (_BigIntImpl._compareDigits(
            xDigits, xUsed, _modulusDigits, _normModulusUsed) >=
        0) {
      _BigIntImpl._absSub(
          xDigits, xUsed, _modulusDigits, _normModulusUsed, xDigits);
    }
    // Clamp x.
    while (xUsed > 0 && xDigits[xUsed - 1] == 0) {
      --xUsed;
    }
    return xUsed;
  }

  int _sqr(Uint32List xDigits, int xUsed, Uint32List resultDigits) {
    var resultUsed = _BigIntImpl._sqrDigits(xDigits, xUsed, resultDigits);
    return _reduce(resultDigits, resultUsed);
  }

  int _mul(Uint32List xDigits, int xUsed, Uint32List yDigits, int yUsed,
      Uint32List resultDigits) {
    var resultUsed =
        _BigIntImpl._mulDigits(xDigits, xUsed, yDigits, yUsed, resultDigits);
    return _reduce(resultDigits, resultUsed);
  }
}

// Modular reduction using "classic" algorithm.
class _BigIntClassicReduction implements _BigIntReduction {
  final _BigIntImpl _modulus; // Modulus.
  int _normModulusUsed;
  _BigIntImpl _normModulus; // Normalized _modulus.
  Uint32List _normModulusDigits;
  Uint32List _negNormModulusDigits; // Negated _normModulus digits.
  int _modulusNsh; // Normalization shift amount.
  Uint32List _args; // Top _normModulus digit(s) and place holder for estimated
  // quotient digit(s).
  Uint32List _tmpDigits; // Temporary digits used during reduction.

  factory _BigIntClassicReduction(_BigIntImpl modulus) {
    // Preprocess arguments to _remDigits.
    int nsh =
        _BigIntImpl._digitBits - modulus._digits[modulus._used - 1].bitLength;
    // For 64-bit processing, make sure _negNormModulusDigits has an even number
    // of digits.
    if (modulus._used.isOdd) {
      nsh += _BigIntImpl._digitBits;
    }
    final _BigIntImpl normModulus = modulus << nsh;
    final int normModulusUsed = normModulus._used;
    final Uint32List normModulusDigits = normModulus._digits;
    assert(normModulusUsed.isEven);

    final Uint32List args = _newDigits(4);
    args[_BigIntImpl._divisorLowTopDigit] =
        normModulusDigits[normModulusUsed - 2];
    args[_BigIntImpl._divisorTopDigit] = normModulusDigits[normModulusUsed - 1];
    // Negate normModulus so we can use _mulAdd instead of
    // unimplemented  _mulSub.
    final _BigIntImpl negNormModulus =
        _BigIntImpl.one._dlShift(normModulusUsed) - normModulus;
    late Uint32List negNormModulusDigits;
    if (negNormModulus._used < normModulusUsed) {
      negNormModulusDigits = _BigIntImpl._cloneDigits(
          negNormModulus._digits, 0, normModulusUsed, normModulusUsed);
    } else {
      negNormModulusDigits = negNormModulus._digits;
    }
    // negNormModulusDigits is read-only and has normModulusUsed digits (possibly
    // including several leading zeros) plus a leading zero for 64-bit
    // processing.
    final Uint32List tmpDigits = _newDigits(2 * normModulusUsed);

    return _BigIntClassicReduction._(modulus, normModulusUsed, normModulus,
        normModulusDigits, negNormModulusDigits, nsh, args, tmpDigits);
  }

  _BigIntClassicReduction._(
      this._modulus,
      this._normModulusUsed,
      this._normModulus,
      this._normModulusDigits,
      this._negNormModulusDigits,
      this._modulusNsh,
      this._args,
      this._tmpDigits);

  int _convert(_BigIntImpl x, Uint32List resultDigits) {
    var digits;
    var used;
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
    var i = used + (used & 1); // Copy leading zero if any.
    while (--i >= 0) {
      resultDigits[i] = digits[i];
    }
    return used;
  }

  _BigIntImpl _revert(Uint32List xDigits, int xUsed) {
    return new _BigIntImpl._(false, xUsed, xDigits);
  }

  int _reduce(Uint32List xDigits, int xUsed) {
    if (xUsed < _modulus._used) {
      return xUsed;
    }
    // The function _BigIntImpl._remDigits(...) is optimized for reduction and
    // equivalent to calling
    // 'convert(revert(xDigits, xUsed)._rem(_normModulus), xDigits);'
    return _BigIntImpl._remDigits(
        xDigits,
        xUsed,
        _normModulusDigits,
        _normModulusUsed,
        _negNormModulusDigits,
        _modulusNsh,
        _args,
        _tmpDigits,
        xDigits);
  }

  int _sqr(Uint32List xDigits, int xUsed, Uint32List resultDigits) {
    var resultUsed = _BigIntImpl._sqrDigits(xDigits, xUsed, resultDigits);
    return _reduce(resultDigits, resultUsed);
  }

  int _mul(Uint32List xDigits, int xUsed, Uint32List yDigits, int yUsed,
      Uint32List resultDigits) {
    var resultUsed =
        _BigIntImpl._mulDigits(xDigits, xUsed, yDigits, yUsed, resultDigits);
    return _reduce(resultDigits, resultUsed);
  }
}

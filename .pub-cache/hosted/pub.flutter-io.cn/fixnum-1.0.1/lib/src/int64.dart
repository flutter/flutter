// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

// Many locals are declared as `int` or `double`. We keep local variable types
// because the types are critical to the efficiency of many operations.
//
// ignore_for_file: omit_local_variable_types

part of fixnum;

/// An immutable 64-bit signed integer, in the range [-2^63, 2^63 - 1].
/// Arithmetic operations may overflow in order to maintain this range.
class Int64 implements IntX {
  // A 64-bit integer is represented internally as three non-negative
  // integers, storing the 22 low, 22 middle, and 20 high bits of the
  // 64-bit value.  _l (low) and _m (middle) are in the range
  // [0, 2^22 - 1] and _h (high) is in the range [0, 2^20 - 1].
  //
  // The values being assigned to _l, _m and _h in initialization are masked to
  // force them into the above ranges.  Sometimes we know that the value is a
  // small non-negative integer but the dart2js compiler can't infer that, so a
  // few of the masking operations are not needed for correctness but are
  // helpful for dart2js code quality.

  final int _l, _m, _h;

  // Note: several functions require _BITS == 22 -- do not change this value.
  static const int _BITS = 22;
  static const int _BITS01 = 44; // 2 * _BITS
  static const int _BITS2 = 20; // 64 - _BITS01
  static const int _MASK = 4194303; // (1 << _BITS) - 1
  static const int _MASK2 = 1048575; // (1 << _BITS2) - 1
  static const int _SIGN_BIT = 19; // _BITS2 - 1
  static const int _SIGN_BIT_MASK = 1 << _SIGN_BIT;

  /// The maximum positive value attainable by an [Int64], namely
  /// 9,223,372,036,854,775,807.
  static const Int64 MAX_VALUE = Int64._bits(_MASK, _MASK, _MASK2 >> 1);

  /// The minimum positive value attainable by an [Int64], namely
  /// -9,223,372,036,854,775,808.
  static const Int64 MIN_VALUE = Int64._bits(0, 0, _SIGN_BIT_MASK);

  /// An [Int64] constant equal to 0.
  static const Int64 ZERO = Int64._bits(0, 0, 0);

  /// An [Int64] constant equal to 1.
  static const Int64 ONE = Int64._bits(1, 0, 0);

  /// An [Int64] constant equal to 2.
  static const Int64 TWO = Int64._bits(2, 0, 0);

  /// Constructs an [Int64] with a given bitwise representation.  No validation
  /// is performed.
  const Int64._bits(this._l, this._m, this._h);

  /// Parses a [String] in a given [radix] between 2 and 36 and returns an
  /// [Int64].
  static Int64 parseRadix(String s, int radix) =>
      _parseRadix(s, Int32._validateRadix(radix));

  static Int64 _parseRadix(String s, int radix) {
    int i = 0;
    bool negative = false;
    if (i < s.length && s[0] == '-') {
      negative = true;
      i++;
    }

    // TODO(https://github.com/dart-lang/sdk/issues/38728). Replace with "if (i
    // >= s.length)".
    if (!(i < s.length)) {
      throw FormatException("No digits in '$s'");
    }

    int d0 = 0, d1 = 0, d2 = 0; //  low, middle, high components.
    for (; i < s.length; i++) {
      int c = s.codeUnitAt(i);
      int digit = Int32._decodeDigit(c);
      if (digit < 0 || digit >= radix) {
        throw FormatException('Non-radix char code: $c');
      }

      // [radix] and [digit] are at most 6 bits, component is 22, so we can
      // multiply and add within 30 bit temporary values.
      d0 = d0 * radix + digit;
      int carry = d0 >> _BITS;
      d0 = _MASK & d0;

      d1 = d1 * radix + carry;
      carry = d1 >> _BITS;
      d1 = _MASK & d1;

      d2 = d2 * radix + carry;
      d2 = _MASK2 & d2;
    }

    if (negative) return _negate(d0, d1, d2);

    return Int64._masked(d0, d1, d2);
  }

  /// Parses a decimal [String] and returns an [Int64].
  static Int64 parseInt(String s) => _parseRadix(s, 10);

  /// Parses a hexadecimal [String] and returns an [Int64].
  static Int64 parseHex(String s) => _parseRadix(s, 16);

  //
  // Public constructors
  //

  /// Constructs an [Int64] with a given [int] value; zero by default.
  factory Int64([int value = 0]) {
    int v0 = 0, v1 = 0, v2 = 0;
    bool negative = false;
    if (value < 0) {
      negative = true;
      value = -value;
    }
    // Avoid using bitwise operations that in JavaScript coerce their input to
    // 32 bits.
    v2 = value ~/ 17592186044416; // 2^44
    value -= v2 * 17592186044416;
    v1 = value ~/ 4194304; // 2^22
    value -= v1 * 4194304;
    v0 = value;

    return negative
        ? Int64._negate(_MASK & v0, _MASK & v1, _MASK2 & v2)
        : Int64._masked(v0, v1, v2);
  }

  factory Int64.fromBytes(List<int> bytes) {
    int top = bytes[7] & 0xff;
    top <<= 8;
    top |= bytes[6] & 0xff;
    top <<= 8;
    top |= bytes[5] & 0xff;
    top <<= 8;
    top |= bytes[4] & 0xff;

    int bottom = bytes[3] & 0xff;
    bottom <<= 8;
    bottom |= bytes[2] & 0xff;
    bottom <<= 8;
    bottom |= bytes[1] & 0xff;
    bottom <<= 8;
    bottom |= bytes[0] & 0xff;

    return Int64.fromInts(top, bottom);
  }

  factory Int64.fromBytesBigEndian(List<int> bytes) {
    int top = bytes[0] & 0xff;
    top <<= 8;
    top |= bytes[1] & 0xff;
    top <<= 8;
    top |= bytes[2] & 0xff;
    top <<= 8;
    top |= bytes[3] & 0xff;

    int bottom = bytes[4] & 0xff;
    bottom <<= 8;
    bottom |= bytes[5] & 0xff;
    bottom <<= 8;
    bottom |= bytes[6] & 0xff;
    bottom <<= 8;
    bottom |= bytes[7] & 0xff;

    return Int64.fromInts(top, bottom);
  }

  /// Constructs an [Int64] from a pair of 32-bit integers having the value
  /// [:((top & 0xffffffff) << 32) | (bottom & 0xffffffff):].
  factory Int64.fromInts(int top, int bottom) {
    top &= 0xffffffff;
    bottom &= 0xffffffff;
    int d0 = _MASK & bottom;
    int d1 = ((0xfff & top) << 10) | (0x3ff & (bottom >> _BITS));
    int d2 = _MASK2 & (top >> 12);
    return Int64._masked(d0, d1, d2);
  }

  // Returns the [Int64] representation of the specified value. Throws
  // [ArgumentError] for non-integer arguments.
  static Int64 _promote(value) {
    if (value is Int64) {
      return value;
    } else if (value is int) {
      return Int64(value);
    } else if (value is Int32) {
      return value.toInt64();
    }
    throw ArgumentError.value(value);
  }

  @override
  Int64 operator +(Object other) {
    Int64 o = _promote(other);
    int sum0 = _l + o._l;
    int sum1 = _m + o._m + (sum0 >> _BITS);
    int sum2 = _h + o._h + (sum1 >> _BITS);
    return Int64._masked(sum0, sum1, sum2);
  }

  @override
  Int64 operator -(Object other) {
    Int64 o = _promote(other);
    return _sub(_l, _m, _h, o._l, o._m, o._h);
  }

  @override
  Int64 operator -() => _negate(_l, _m, _h);

  @override
  Int64 operator *(Object other) {
    Int64 o = _promote(other);

    // Grab 13-bit chunks.
    int a0 = _l & 0x1fff;
    int a1 = (_l >> 13) | ((_m & 0xf) << 9);
    int a2 = (_m >> 4) & 0x1fff;
    int a3 = (_m >> 17) | ((_h & 0xff) << 5);
    int a4 = (_h & 0xfff00) >> 8;

    int b0 = o._l & 0x1fff;
    int b1 = (o._l >> 13) | ((o._m & 0xf) << 9);
    int b2 = (o._m >> 4) & 0x1fff;
    int b3 = (o._m >> 17) | ((o._h & 0xff) << 5);
    int b4 = (o._h & 0xfff00) >> 8;

    // Compute partial products.
    // Optimization: if b is small, avoid multiplying by parts that are 0.
    int p0 = a0 * b0; // << 0
    int p1 = a1 * b0; // << 13
    int p2 = a2 * b0; // << 26
    int p3 = a3 * b0; // << 39
    int p4 = a4 * b0; // << 52

    if (b1 != 0) {
      p1 += a0 * b1;
      p2 += a1 * b1;
      p3 += a2 * b1;
      p4 += a3 * b1;
    }
    if (b2 != 0) {
      p2 += a0 * b2;
      p3 += a1 * b2;
      p4 += a2 * b2;
    }
    if (b3 != 0) {
      p3 += a0 * b3;
      p4 += a1 * b3;
    }
    if (b4 != 0) {
      p4 += a0 * b4;
    }

    // Accumulate into 22-bit chunks:
    // .........................................c10|...................c00|
    // |....................|..................xxxx|xxxxxxxxxxxxxxxxxxxxxx| p0
    // |....................|......................|......................|
    // |....................|...................c11|......c01.............|
    // |....................|....xxxxxxxxxxxxxxxxxx|xxxxxxxxx.............| p1
    // |....................|......................|......................|
    // |.................c22|...............c12....|......................|
    // |..........xxxxxxxxxx|xxxxxxxxxxxxxxxxxx....|......................| p2
    // |....................|......................|......................|
    // |.................c23|..c13.................|......................|
    // |xxxxxxxxxxxxxxxxxxxx|xxxxx.................|......................| p3
    // |....................|......................|......................|
    // |.........c24........|......................|......................|
    // |xxxxxxxxxxxx........|......................|......................| p4

    int c00 = p0 & 0x3fffff;
    int c01 = (p1 & 0x1ff) << 13;
    int c0 = c00 + c01;

    int c10 = p0 >> 22;
    int c11 = p1 >> 9;
    int c12 = (p2 & 0x3ffff) << 4;
    int c13 = (p3 & 0x1f) << 17;
    int c1 = c10 + c11 + c12 + c13;

    int c22 = p2 >> 18;
    int c23 = p3 >> 5;
    int c24 = (p4 & 0xfff) << 8;
    int c2 = c22 + c23 + c24;

    // Propagate high bits from c0 -> c1, c1 -> c2.
    c1 += c0 >> _BITS;
    c2 += c1 >> _BITS;

    return Int64._masked(c0, c1, c2);
  }

  @override
  Int64 operator %(Object other) => _divide(this, other, _RETURN_MOD);

  @override
  Int64 operator ~/(Object other) => _divide(this, other, _RETURN_DIV);

  @override
  Int64 remainder(Object other) => _divide(this, other, _RETURN_REM);

  @override
  Int64 operator &(Object other) {
    Int64 o = _promote(other);
    int a0 = _l & o._l;
    int a1 = _m & o._m;
    int a2 = _h & o._h;
    return Int64._masked(a0, a1, a2);
  }

  @override
  Int64 operator |(Object other) {
    Int64 o = _promote(other);
    int a0 = _l | o._l;
    int a1 = _m | o._m;
    int a2 = _h | o._h;
    return Int64._masked(a0, a1, a2);
  }

  @override
  Int64 operator ^(Object other) {
    Int64 o = _promote(other);
    int a0 = _l ^ o._l;
    int a1 = _m ^ o._m;
    int a2 = _h ^ o._h;
    return Int64._masked(a0, a1, a2);
  }

  @override
  Int64 operator ~() => Int64._masked(~_l, ~_m, ~_h);

  @override
  Int64 operator <<(int n) {
    if (n < 0) {
      throw ArgumentError.value(n);
    }
    if (n >= 64) {
      return ZERO;
    }

    int res0, res1, res2;
    if (n < _BITS) {
      res0 = _l << n;
      res1 = (_m << n) | (_l >> (_BITS - n));
      res2 = (_h << n) | (_m >> (_BITS - n));
    } else if (n < _BITS01) {
      res0 = 0;
      res1 = _l << (n - _BITS);
      res2 = (_m << (n - _BITS)) | (_l >> (_BITS01 - n));
    } else {
      res0 = 0;
      res1 = 0;
      res2 = _l << (n - _BITS01);
    }

    return Int64._masked(res0, res1, res2);
  }

  @override
  Int64 operator >>(int n) {
    if (n < 0) {
      throw ArgumentError.value(n);
    }
    if (n >= 64) {
      return isNegative ? const Int64._bits(_MASK, _MASK, _MASK2) : ZERO;
    }

    int res0, res1, res2;

    // Sign extend h(a).
    int a2 = _h;
    bool negative = (a2 & _SIGN_BIT_MASK) != 0;
    if (negative && _MASK > _MASK2) {
      // Add extra one bits on the left so the sign gets shifted into the wider
      // lower words.
      a2 += _MASK - _MASK2;
    }

    if (n < _BITS) {
      res2 = _shiftRight(a2, n);
      if (negative) {
        res2 |= _MASK2 & ~(_MASK2 >> n);
      }
      res1 = _shiftRight(_m, n) | (a2 << (_BITS - n));
      res0 = _shiftRight(_l, n) | (_m << (_BITS - n));
    } else if (n < _BITS01) {
      res2 = negative ? _MASK2 : 0;
      res1 = _shiftRight(a2, n - _BITS);
      if (negative) {
        res1 |= _MASK & ~(_MASK >> (n - _BITS));
      }
      res0 = _shiftRight(_m, n - _BITS) | (a2 << (_BITS01 - n));
    } else {
      res2 = negative ? _MASK2 : 0;
      res1 = negative ? _MASK : 0;
      res0 = _shiftRight(a2, n - _BITS01);
      if (negative) {
        res0 |= _MASK & ~(_MASK >> (n - _BITS01));
      }
    }

    return Int64._masked(res0, res1, res2);
  }

  @override
  Int64 shiftRightUnsigned(int n) {
    if (n < 0) {
      throw ArgumentError.value(n);
    }
    if (n >= 64) {
      return ZERO;
    }

    int res0, res1, res2;
    int a2 = _MASK2 & _h; // Ensure a2 is positive.
    if (n < _BITS) {
      res2 = a2 >> n;
      res1 = (_m >> n) | (a2 << (_BITS - n));
      res0 = (_l >> n) | (_m << (_BITS - n));
    } else if (n < _BITS01) {
      res2 = 0;
      res1 = a2 >> (n - _BITS);
      res0 = (_m >> (n - _BITS)) | (_h << (_BITS01 - n));
    } else {
      res2 = 0;
      res1 = 0;
      res0 = a2 >> (n - _BITS01);
    }

    return Int64._masked(res0, res1, res2);
  }

  /// Returns [:true:] if this [Int64] has the same numeric value as the
  /// given object.  The argument may be an [int] or an [IntX].
  @override
  bool operator ==(Object other) {
    Int64? o;
    if (other is Int64) {
      o = other;
    } else if (other is int) {
      if (_h == 0 && _m == 0) return _l == other;
      // Since we know one of [_h] or [_m] is non-zero, if [other] fits in the
      // low word then it can't be numerically equal.
      if ((_MASK & other) == other) return false;
      o = Int64(other);
    } else if (other is Int32) {
      o = other.toInt64();
    }
    if (o != null) {
      return _l == o._l && _m == o._m && _h == o._h;
    }
    return false;
  }

  @override
  int compareTo(Object other) => _compareTo(other);

  int _compareTo(Object other) {
    Int64 o = _promote(other);
    int signa = _h >> (_BITS2 - 1);
    int signb = o._h >> (_BITS2 - 1);
    if (signa != signb) {
      return signa == 0 ? 1 : -1;
    }
    if (_h > o._h) {
      return 1;
    } else if (_h < o._h) {
      return -1;
    }
    if (_m > o._m) {
      return 1;
    } else if (_m < o._m) {
      return -1;
    }
    if (_l > o._l) {
      return 1;
    } else if (_l < o._l) {
      return -1;
    }
    return 0;
  }

  @override
  bool operator <(Object other) => _compareTo(other) < 0;

  @override
  bool operator <=(Object other) => _compareTo(other) <= 0;

  @override
  bool operator >(Object other) => _compareTo(other) > 0;

  @override
  bool operator >=(Object other) => _compareTo(other) >= 0;

  @override
  bool get isEven => (_l & 0x1) == 0;

  @override
  bool get isMaxValue => (_h == _MASK2 >> 1) && _m == _MASK && _l == _MASK;

  @override
  bool get isMinValue => _h == _SIGN_BIT_MASK && _m == 0 && _l == 0;

  @override
  bool get isNegative => (_h & _SIGN_BIT_MASK) != 0;

  @override
  bool get isOdd => (_l & 0x1) == 1;

  @override
  bool get isZero => _h == 0 && _m == 0 && _l == 0;

  @override
  int get bitLength {
    if (isZero) return 0;
    int a0 = _l, a1 = _m, a2 = _h;
    if (isNegative) {
      a0 = _MASK & ~a0;
      a1 = _MASK & ~a1;
      a2 = _MASK2 & ~a2;
    }
    if (a2 != 0) return _BITS01 + a2.bitLength;
    if (a1 != 0) return _BITS + a1.bitLength;
    return a0.bitLength;
  }

  /// Returns a hash code based on all the bits of this [Int64].
  @override
  int get hashCode {
    // TODO(sra): Should we ensure that hashCode values match corresponding int?
    // i.e. should `new Int64(x).hashCode == x.hashCode`?
    int bottom = ((_m & 0x3ff) << _BITS) | _l;
    int top = (_h << 12) | ((_m >> 10) & 0xfff);
    return bottom ^ top;
  }

  @override
  Int64 abs() => isNegative ? -this : this;

  @override
  Int64 clamp(Object lowerLimit, Object upperLimit) {
    Int64 lower = _promote(lowerLimit);
    Int64 upper = _promote(upperLimit);
    if (this < lower) return lower;
    if (this > upper) return upper;
    return this;
  }

  /// Returns the number of leading zeros in this [Int64] as an [int]
  /// between 0 and 64.
  @override
  int numberOfLeadingZeros() {
    int b2 = Int32._numberOfLeadingZeros(_h);
    if (b2 == 32) {
      int b1 = Int32._numberOfLeadingZeros(_m);
      if (b1 == 32) {
        return Int32._numberOfLeadingZeros(_l) + 32;
      } else {
        return b1 + _BITS2 - (32 - _BITS);
      }
    } else {
      return b2 - (32 - _BITS2);
    }
  }

  /// Returns the number of trailing zeros in this [Int64] as an [int]
  /// between 0 and 64.
  @override
  int numberOfTrailingZeros() {
    int zeros = Int32._numberOfTrailingZeros(_l);
    if (zeros < 32) {
      return zeros;
    }

    zeros = Int32._numberOfTrailingZeros(_m);
    if (zeros < 32) {
      return _BITS + zeros;
    }

    zeros = Int32._numberOfTrailingZeros(_h);
    if (zeros < 32) {
      return _BITS01 + zeros;
    }
    // All zeros
    return 64;
  }

  @override
  Int64 toSigned(int width) {
    if (width < 1 || width > 64) throw RangeError.range(width, 1, 64);
    if (width > _BITS01) {
      return Int64._masked(_l, _m, _h.toSigned(width - _BITS01));
    } else if (width > _BITS) {
      int m = _m.toSigned(width - _BITS);
      return m.isNegative
          ? Int64._masked(_l, m, _MASK2)
          : Int64._masked(_l, m, 0); // Masking for type inferrer.
    } else {
      int l = _l.toSigned(width);
      return l.isNegative
          ? Int64._masked(l, _MASK, _MASK2)
          : Int64._masked(l, 0, 0); // Masking for type inferrer.
    }
  }

  @override
  Int64 toUnsigned(int width) {
    if (width < 0 || width > 64) throw RangeError.range(width, 0, 64);
    if (width > _BITS01) {
      int h = _h.toUnsigned(width - _BITS01);
      return Int64._masked(_l, _m, h);
    } else if (width > _BITS) {
      int m = _m.toUnsigned(width - _BITS);
      return Int64._masked(_l, m, 0);
    } else {
      int l = _l.toUnsigned(width);
      return Int64._masked(l, 0, 0);
    }
  }

  @override
  List<int> toBytes() {
    var result = List<int>.filled(8, 0);
    result[0] = _l & 0xff;
    result[1] = (_l >> 8) & 0xff;
    result[2] = ((_m << 6) & 0xfc) | ((_l >> 16) & 0x3f);
    result[3] = (_m >> 2) & 0xff;
    result[4] = (_m >> 10) & 0xff;
    result[5] = ((_h << 4) & 0xf0) | ((_m >> 18) & 0xf);
    result[6] = (_h >> 4) & 0xff;
    result[7] = (_h >> 12) & 0xff;
    return result;
  }

  @override
  double toDouble() => toInt().toDouble();

  @override
  int toInt() {
    int l = _l;
    int m = _m;
    int h = _h;
    // In the sum we add least significant to most significant so that in
    // JavaScript double arithmetic rounding occurs on only the last addition.
    if ((_h & _SIGN_BIT_MASK) != 0) {
      l = _MASK & ~_l;
      m = _MASK & ~_m;
      h = _MASK2 & ~_h;
      return -((1 + l) + (4194304 * m) + (17592186044416 * h));
    } else {
      return l + (4194304 * m) + (17592186044416 * h);
    }
  }

  /// Returns an [Int32] containing the low 32 bits of this [Int64].
  @override
  Int32 toInt32() => Int32(((_m & 0x3ff) << _BITS) | _l);

  /// Returns `this`.
  @override
  Int64 toInt64() => this;

  /// Returns the value of this [Int64] as a decimal [String].
  @override
  String toString() => _toRadixString(10);

  // TODO(rice) - Make this faster by avoiding arithmetic.
  @override
  String toHexString() {
    if (isZero) return '0';
    Int64 x = this;
    String hexStr = '';
    while (!x.isZero) {
      int digit = x._l & 0xf;
      hexStr = '${_hexDigit(digit)}$hexStr';
      x = x.shiftRightUnsigned(4);
    }
    return hexStr;
  }

  /// Returns the digits of `this` when interpreted as an unsigned 64-bit value.
  @pragma('dart2js:noInline')
  String toStringUnsigned() => _toRadixStringUnsigned(10, _l, _m, _h, '');

  @pragma('dart2js:noInline')
  String toRadixStringUnsigned(int radix) =>
      _toRadixStringUnsigned(Int32._validateRadix(radix), _l, _m, _h, '');

  @override
  String toRadixString(int radix) =>
      _toRadixString(Int32._validateRadix(radix));

  String _toRadixString(int radix) {
    int d0 = _l;
    int d1 = _m;
    int d2 = _h;

    String sign = '';
    if ((d2 & _SIGN_BIT_MASK) != 0) {
      sign = '-';

      // Negate in-place.
      d0 = 0 - d0;
      int borrow = (d0 >> _BITS) & 1;
      d0 &= _MASK;
      d1 = 0 - d1 - borrow;
      borrow = (d1 >> _BITS) & 1;
      d1 &= _MASK;
      d2 = 0 - d2 - borrow;
      d2 &= _MASK2;
      // d2, d1, d0 now are an unsigned 64 bit integer for MIN_VALUE and an
      // unsigned 63 bit integer for other values.
    }
    return _toRadixStringUnsigned(radix, d0, d1, d2, sign);
  }

  static String _toRadixStringUnsigned(
      int radix, int d0, int d1, int d2, String sign) {
    if (d0 == 0 && d1 == 0 && d2 == 0) return '0';

    // Rearrange components into five components where all but the most
    // significant are 10 bits wide.
    //
    //     d4, d3, d4, d1, d0:  24 + 10 + 10 + 10 + 10 bits
    //
    // The choice of 10 bits allows a remainder of 20 bits to be scaled by 10
    // bits and added during division while keeping all intermediate values
    // within 30 bits (unsigned small integer range for 32 bit implementations
    // of Dart VM and V8).
    //
    //     6  6         5         4         3         2         1
    //     3210987654321098765432109876543210987654321098765432109876543210
    //     [--------d2--------][---------d1---------][---------d0---------]
    //  -->
    //     [----------d4----------][---d3---][---d2---][---d1---][---d0---]

    int d4 = (d2 << 4) | (d1 >> 18);
    int d3 = (d1 >> 8) & 0x3ff;
    d2 = ((d1 << 2) | (d0 >> 20)) & 0x3ff;
    d1 = (d0 >> 10) & 0x3ff;
    d0 = d0 & 0x3ff;

    int fatRadix = _fatRadixTable[radix];

    // Generate chunks of digits.  In radix 10, generate 6 digits per chunk.
    //
    // This loop generates at most 3 chunks, so we store the chunks in locals
    // rather than a list.  We are trying to generate digits 20 bits at a time
    // until we have only 30 bits left.  20 + 20 + 30 > 64 would imply that we
    // need only two chunks, but radix values 17-19 and 33-36 generate only 15
    // or 16 bits per iteration, so sometimes the third chunk is needed.

    String chunk1 = '', chunk2 = '', chunk3 = '';

    while (!(d4 == 0 && d3 == 0)) {
      int q = d4 ~/ fatRadix;
      int r = d4 - q * fatRadix;
      d4 = q;
      d3 += r << 10;

      q = d3 ~/ fatRadix;
      r = d3 - q * fatRadix;
      d3 = q;
      d2 += r << 10;

      q = d2 ~/ fatRadix;
      r = d2 - q * fatRadix;
      d2 = q;
      d1 += r << 10;

      q = d1 ~/ fatRadix;
      r = d1 - q * fatRadix;
      d1 = q;
      d0 += r << 10;

      q = d0 ~/ fatRadix;
      r = d0 - q * fatRadix;
      d0 = q;

      assert(chunk3 == '');
      chunk3 = chunk2;
      chunk2 = chunk1;
      // Adding [fatRadix] Forces an extra digit which we discard to get a fixed
      // width.  E.g.  (1000000 + 123) -> "1000123" -> "000123".  An alternative
      // would be to pad to the left with zeroes.
      chunk1 = (fatRadix + r).toRadixString(radix).substring(1);
    }
    int residue = (d2 << 20) + (d1 << 10) + d0;
    String leadingDigits = residue == 0 ? '' : residue.toRadixString(radix);
    return '$sign$leadingDigits$chunk1$chunk2$chunk3';
  }

  // Table of 'fat' radix values.  Each entry for index `i` is the largest power
  // of `i` whose remainder fits in 20 bits.
  static const _fatRadixTable = <int>[
    0,
    0,
    2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2 *
        2,
    3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3 * 3,
    4 * 4 * 4 * 4 * 4 * 4 * 4 * 4 * 4 * 4,
    5 * 5 * 5 * 5 * 5 * 5 * 5 * 5,
    6 * 6 * 6 * 6 * 6 * 6 * 6,
    7 * 7 * 7 * 7 * 7 * 7 * 7,
    8 * 8 * 8 * 8 * 8 * 8,
    9 * 9 * 9 * 9 * 9 * 9,
    10 * 10 * 10 * 10 * 10 * 10,
    11 * 11 * 11 * 11 * 11,
    12 * 12 * 12 * 12 * 12,
    13 * 13 * 13 * 13 * 13,
    14 * 14 * 14 * 14 * 14,
    15 * 15 * 15 * 15 * 15,
    16 * 16 * 16 * 16 * 16,
    17 * 17 * 17 * 17,
    18 * 18 * 18 * 18,
    19 * 19 * 19 * 19,
    20 * 20 * 20 * 20,
    21 * 21 * 21 * 21,
    22 * 22 * 22 * 22,
    23 * 23 * 23 * 23,
    24 * 24 * 24 * 24,
    25 * 25 * 25 * 25,
    26 * 26 * 26 * 26,
    27 * 27 * 27 * 27,
    28 * 28 * 28 * 28,
    29 * 29 * 29 * 29,
    30 * 30 * 30 * 30,
    31 * 31 * 31 * 31,
    32 * 32 * 32 * 32,
    33 * 33 * 33,
    34 * 34 * 34,
    35 * 35 * 35,
    36 * 36 * 36
  ];

  String toDebugString() => 'Int64[_l=$_l, _m=$_m, _h=$_h]';

  static Int64 _masked(int a0, int a1, int a2) =>
      Int64._bits(_MASK & a0, _MASK & a1, _MASK2 & a2);

  static Int64 _sub(int a0, int a1, int a2, int b0, int b1, int b2) {
    int diff0 = a0 - b0;
    int diff1 = a1 - b1 - ((diff0 >> _BITS) & 1);
    int diff2 = a2 - b2 - ((diff1 >> _BITS) & 1);
    return _masked(diff0, diff1, diff2);
  }

  static Int64 _negate(int b0, int b1, int b2) => _sub(0, 0, 0, b0, b1, b2);

  String _hexDigit(int digit) => '0123456789ABCDEF'[digit];

  // Work around dart2js bugs with negative arguments to '>>' operator.
  static int _shiftRight(int x, int n) {
    if (x >= 0) {
      return x >> n;
    } else {
      int shifted = x >> n;
      if (shifted >= 0x80000000) {
        shifted -= 4294967296;
      }
      return shifted;
    }
  }

  // Implementation of '~/', '%' and 'remainder'.

  static Int64 _divide(Int64 a, other, int what) {
    Int64 b = _promote(other);
    if (b.isZero) {
      // ignore: deprecated_member_use
      throw const IntegerDivisionByZeroException();
    }
    if (a.isZero) return ZERO;

    bool aNeg = a.isNegative;
    bool bNeg = b.isNegative;
    a = a.abs();
    b = b.abs();

    int a0 = a._l;
    int a1 = a._m;
    int a2 = a._h;

    int b0 = b._l;
    int b1 = b._m;
    int b2 = b._h;
    return _divideHelper(a0, a1, a2, aNeg, b0, b1, b2, bNeg, what);
  }

  static const _RETURN_DIV = 1;
  static const _RETURN_REM = 2;
  static const _RETURN_MOD = 3;

  static Int64 _divideHelper(
      // up to 64 bits unsigned in a2/a1/a0 and b2/b1/b0
      int a0,
      int a1,
      int a2,
      bool aNeg, // input A.
      int b0,
      int b1,
      int b2,
      bool bNeg, // input B.
      int what) {
    int q0 = 0, q1 = 0, q2 = 0; // result Q.
    int r0 = 0, r1 = 0, r2 = 0; // result R.

    if (b2 == 0 && b1 == 0 && b0 < (1 << (30 - _BITS))) {
      // Small divisor can be handled by single-digit division within Smi range.
      //
      // Handling small divisors here helps the estimate version below by
      // handling cases where the estimate is off by more than a small amount.

      q2 = a2 ~/ b0;
      int carry = a2 - q2 * b0;
      int d1 = a1 + (carry << _BITS);
      q1 = d1 ~/ b0;
      carry = d1 - q1 * b0;
      int d0 = a0 + (carry << _BITS);
      q0 = d0 ~/ b0;
      r0 = d0 - q0 * b0;
    } else {
      // Approximate Q = A ~/ B and R = A - Q * B using doubles.

      // The floating point approximation is very close to the correct value
      // when floor(A/B) fits in fewer that 53 bits.

      // We use double arithmetic for intermediate values.  Double arithmetic on
      // non-negative values is exact under the following conditions:
      //
      //   - The values are integer values that fit in 53 bits.
      //   - Dividing by powers of two (adjusts exponent only).
      //   - Floor (zeroes bits with fractional weight).

      const double K2 = 17592186044416.0; // 2^44
      const double K1 = 4194304.0; // 2^22

      // Approximate double values for [a] and [b].
      double ad = a0 + K1 * a1 + K2 * a2;
      double bd = b0 + K1 * b1 + K2 * b2;
      // Approximate quotient.
      double qd = (ad / bd).floorToDouble();

      // Extract components of [qd] using double arithmetic.
      double q2d = (qd / K2).floorToDouble();
      qd = qd - K2 * q2d;
      double q1d = (qd / K1).floorToDouble();
      double q0d = qd - K1 * q1d;
      q2 = q2d.toInt();
      q1 = q1d.toInt();
      q0 = q0d.toInt();

      assert(q0 + K1 * q1 + K2 * q2 == (ad / bd).floorToDouble());
      assert(q2 == 0 || b2 == 0); // Q and B can't both be big since Q*B <= A.

      // P = Q * B, using doubles to hold intermediates.
      // We don't need all partial sums since Q*B <= A.
      double p0d = q0d * b0;
      double p0carry = (p0d / K1).floorToDouble();
      p0d = p0d - p0carry * K1;
      double p1d = q1d * b0 + q0d * b1 + p0carry;
      double p1carry = (p1d / K1).floorToDouble();
      p1d = p1d - p1carry * K1;
      double p2d = q2d * b0 + q1d * b1 + q0d * b2 + p1carry;
      assert(p2d <= _MASK2); // No partial sum overflow.

      // R = A - P
      int diff0 = a0 - p0d.toInt();
      int diff1 = a1 - p1d.toInt() - ((diff0 >> _BITS) & 1);
      int diff2 = a2 - p2d.toInt() - ((diff1 >> _BITS) & 1);
      r0 = _MASK & diff0;
      r1 = _MASK & diff1;
      r2 = _MASK2 & diff2;

      // while (R < 0 || R >= B)
      //  adjust R towards [0, B)
      while (r2 >= _SIGN_BIT_MASK ||
          r2 > b2 ||
          (r2 == b2 && (r1 > b1 || (r1 == b1 && r0 >= b0)))) {
        // Direction multiplier for adjustment.
        int m = (r2 & _SIGN_BIT_MASK) == 0 ? 1 : -1;
        // R = R - B  or  R = R + B
        int d0 = r0 - m * b0;
        int d1 = r1 - m * (b1 + ((d0 >> _BITS) & 1));
        int d2 = r2 - m * (b2 + ((d1 >> _BITS) & 1));
        r0 = _MASK & d0;
        r1 = _MASK & d1;
        r2 = _MASK2 & d2;

        // Q = Q + 1  or  Q = Q - 1
        d0 = q0 + m;
        d1 = q1 + m * ((d0 >> _BITS) & 1);
        d2 = q2 + m * ((d1 >> _BITS) & 1);
        q0 = _MASK & d0;
        q1 = _MASK & d1;
        q2 = _MASK2 & d2;
      }
    }

    // 0 <= R < B
    assert(Int64.ZERO <= Int64._bits(r0, r1, r2));
    assert(r2 < b2 || // Handles case where B = -(MIN_VALUE)
        Int64._bits(r0, r1, r2) < Int64._bits(b0, b1, b2));

    assert(what == _RETURN_DIV || what == _RETURN_MOD || what == _RETURN_REM);
    if (what == _RETURN_DIV) {
      if (aNeg != bNeg) return _negate(q0, q1, q2);
      return Int64._masked(q0, q1, q2); // Masking for type inferrer.
    }

    if (!aNeg) {
      return Int64._masked(r0, r1, r2); // Masking for type inferrer.
    }

    if (what == _RETURN_MOD) {
      if (r0 == 0 && r1 == 0 && r2 == 0) {
        return ZERO;
      } else {
        return _sub(b0, b1, b2, r0, r1, r2);
      }
    } else {
      return _negate(r0, r1, r2);
    }
  }
}

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

part of fixnum;

/// An immutable 32-bit signed integer, in the range [-2^31, 2^31 - 1].
/// Arithmetic operations may overflow in order to maintain this range.
class Int32 implements IntX {
  /// The maximum positive value attainable by an [Int32], namely
  /// 2147483647.
  static const Int32 MAX_VALUE = Int32._internal(0x7FFFFFFF);

  /// The minimum positive value attainable by an [Int32], namely
  /// -2147483648.
  static const Int32 MIN_VALUE = Int32._internal(-0x80000000);

  /// An [Int32] constant equal to 0.
  static const Int32 ZERO = Int32._internal(0);

  /// An [Int32] constant equal to 1.
  static const Int32 ONE = Int32._internal(1);

  /// An [Int32] constant equal to 2.
  static const Int32 TWO = Int32._internal(2);

  // Hex digit char codes
  static const int _CC_0 = 48; // '0'.codeUnitAt(0)
  static const int _CC_9 = 57; // '9'.codeUnitAt(0)
  static const int _CC_a = 97; // 'a'.codeUnitAt(0)
  static const int _CC_z = 122; // 'z'.codeUnitAt(0)
  static const int _CC_A = 65; // 'A'.codeUnitAt(0)
  static const int _CC_Z = 90; // 'Z'.codeUnitAt(0)

  static int _decodeDigit(int c) {
    if (c >= _CC_0 && c <= _CC_9) {
      return c - _CC_0;
    } else if (c >= _CC_a && c <= _CC_z) {
      return c - _CC_a + 10;
    } else if (c >= _CC_A && c <= _CC_Z) {
      return c - _CC_A + 10;
    } else {
      return -1; // bad char code
    }
  }

  static int _validateRadix(int radix) {
    if (2 <= radix && radix <= 36) return radix;
    throw RangeError.range(radix, 2, 36, 'radix');
  }

  /// Parses a [String] in a given [radix] between 2 and 16 and returns an
  /// [Int32].
  // TODO(rice) - Make this faster by converting several digits at once.
  static Int32 parseRadix(String s, int radix) {
    _validateRadix(radix);
    var x = ZERO;
    for (var i = 0; i < s.length; i++) {
      var c = s.codeUnitAt(i);
      var digit = _decodeDigit(c);
      if (digit < 0 || digit >= radix) {
        throw FormatException('Non-radix code unit: $c');
      }
      x = (x * radix) + digit as Int32;
    }
    return x;
  }

  /// Parses a decimal [String] and returns an [Int32].
  static Int32 parseInt(String s) => Int32(int.parse(s));

  /// Parses a hexadecimal [String] and returns an [Int32].
  static Int32 parseHex(String s) => parseRadix(s, 16);

  // Assumes i is <= 32-bit.
  static int _bitCount(int i) {
    // See "Hacker's Delight", section 5-1, "Counting 1-Bits".

    // The basic strategy is to use "divide and conquer" to
    // add pairs (then quads, etc.) of bits together to obtain
    // sub-counts.
    //
    // A straightforward approach would look like:
    //
    // i = (i & 0x55555555) + ((i >>  1) & 0x55555555);
    // i = (i & 0x33333333) + ((i >>  2) & 0x33333333);
    // i = (i & 0x0F0F0F0F) + ((i >>  4) & 0x0F0F0F0F);
    // i = (i & 0x00FF00FF) + ((i >>  8) & 0x00FF00FF);
    // i = (i & 0x0000FFFF) + ((i >> 16) & 0x0000FFFF);
    //
    // The code below removes unnecessary &'s and uses a
    // trick to remove one instruction in the first line.

    i -= (i >> 1) & 0x55555555;
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    i = (i + (i >> 4)) & 0x0F0F0F0F;
    i += i >> 8;
    i += i >> 16;
    return i & 0x0000003F;
  }

  // Assumes i is <= 32-bit
  static int _numberOfLeadingZeros(int i) {
    i |= i >> 1;
    i |= i >> 2;
    i |= i >> 4;
    i |= i >> 8;
    i |= i >> 16;
    return _bitCount(~i);
  }

  static int _numberOfTrailingZeros(int i) => _bitCount((i & -i) - 1);

  // The internal value, kept in the range [MIN_VALUE, MAX_VALUE].
  final int _i;

  const Int32._internal(int i) : _i = i;

  /// Constructs an [Int32] from an [int].  Only the low 32 bits of the input
  /// are used.
  Int32([int i = 0]) : _i = (i & 0x7fffffff) - (i & 0x80000000);

  // Returns the [int] representation of the specified value. Throws
  // [ArgumentError] for non-integer arguments.
  int _toInt(Object val) {
    if (val is Int32) {
      return val._i;
    } else if (val is int) {
      return val;
    }
    throw ArgumentError(val);
  }

  // The +, -, * , &, |, and ^ operaters deal with types as follows:
  //
  // Int32 + int => Int32
  // Int32 + Int32 => Int32
  // Int32 + Int64 => Int64
  //
  // The %, ~/ and remainder operators return an Int32 even with an Int64
  // argument, since the result cannot be greater than the value on the
  // left-hand side:
  //
  // Int32 % int => Int32
  // Int32 % Int32 => Int32
  // Int32 % Int64 => Int32

  @override
  IntX operator +(Object other) {
    if (other is Int64) {
      return toInt64() + other;
    }
    return Int32(_i + _toInt(other));
  }

  @override
  IntX operator -(Object other) {
    if (other is Int64) {
      return toInt64() - other;
    }
    return Int32(_i - _toInt(other));
  }

  @override
  Int32 operator -() => Int32(-_i);

  @override
  IntX operator *(Object other) {
    if (other is Int64) {
      return toInt64() * other;
    }
    // TODO(rice) - optimize
    return (toInt64() * other).toInt32();
  }

  @override
  Int32 operator %(Object other) {
    if (other is Int64) {
      // Result will be Int32
      return (toInt64() % other).toInt32();
    }
    return Int32(_i % _toInt(other));
  }

  @override
  Int32 operator ~/(Object other) {
    if (other is Int64) {
      return (toInt64() ~/ other).toInt32();
    }
    return Int32(_i ~/ _toInt(other));
  }

  @override
  Int32 remainder(Object other) {
    if (other is Int64) {
      var t = toInt64();
      return (t - (t ~/ other) * other).toInt32();
    }
    return this - (this ~/ other) * other as Int32;
  }

  @override
  Int32 operator &(Object other) {
    if (other is Int64) {
      return (toInt64() & other).toInt32();
    }
    return Int32(_i & _toInt(other));
  }

  @override
  Int32 operator |(Object other) {
    if (other is Int64) {
      return (toInt64() | other).toInt32();
    }
    return Int32(_i | _toInt(other));
  }

  @override
  Int32 operator ^(Object other) {
    if (other is Int64) {
      return (toInt64() ^ other).toInt32();
    }
    return Int32(_i ^ _toInt(other));
  }

  @override
  Int32 operator ~() => Int32(~_i);

  @override
  Int32 operator <<(int n) {
    if (n < 0) {
      throw ArgumentError(n);
    }
    if (n >= 32) {
      return ZERO;
    }
    return Int32(_i << n);
  }

  @override
  Int32 operator >>(int n) {
    if (n < 0) {
      throw ArgumentError(n);
    }
    if (n >= 32) {
      return isNegative ? const Int32._internal(-1) : ZERO;
    }
    int value;
    if (_i >= 0) {
      value = _i >> n;
    } else {
      value = (_i >> n) | (0xffffffff << (32 - n));
    }
    return Int32(value);
  }

  @override
  Int32 shiftRightUnsigned(int n) {
    if (n < 0) {
      throw ArgumentError(n);
    }
    if (n >= 32) {
      return ZERO;
    }
    int value;
    if (_i >= 0) {
      value = _i >> n;
    } else {
      value = (_i >> n) & ((1 << (32 - n)) - 1);
    }
    return Int32(value);
  }

  /// Returns [:true:] if this [Int32] has the same numeric value as the
  /// given object.  The argument may be an [int] or an [IntX].
  @override
  bool operator ==(Object other) {
    if (other is Int32) {
      return _i == other._i;
    } else if (other is Int64) {
      return toInt64() == other;
    } else if (other is int) {
      return _i == other;
    }
    return false;
  }

  @override
  int compareTo(Object other) {
    if (other is Int64) {
      return toInt64().compareTo(other);
    }
    return _i.compareTo(_toInt(other));
  }

  @override
  bool operator <(Object other) {
    if (other is Int64) {
      return toInt64() < other;
    }
    return _i < _toInt(other);
  }

  @override
  bool operator <=(Object other) {
    if (other is Int64) {
      return toInt64() <= other;
    }
    return _i <= _toInt(other);
  }

  @override
  bool operator >(Object other) {
    if (other is Int64) {
      return toInt64() > other;
    }
    return _i > _toInt(other);
  }

  @override
  bool operator >=(Object other) {
    if (other is Int64) {
      return toInt64() >= other;
    }
    return _i >= _toInt(other);
  }

  @override
  bool get isEven => (_i & 0x1) == 0;

  @override
  bool get isMaxValue => _i == 2147483647;

  @override
  bool get isMinValue => _i == -2147483648;

  @override
  bool get isNegative => _i < 0;

  @override
  bool get isOdd => (_i & 0x1) == 1;

  @override
  bool get isZero => _i == 0;

  @override
  int get bitLength => _i.bitLength;

  @override
  int get hashCode => _i;

  @override
  Int32 abs() => _i < 0 ? Int32(-_i) : this;

  @override
  Int32 clamp(Object lowerLimit, Object upperLimit) {
    if (this < lowerLimit) {
      if (lowerLimit is IntX) return lowerLimit.toInt32();
      if (lowerLimit is int) return Int32(lowerLimit);
      throw ArgumentError(lowerLimit);
    } else if (this > upperLimit) {
      if (upperLimit is IntX) return upperLimit.toInt32();
      if (upperLimit is int) return Int32(upperLimit);
      throw ArgumentError(upperLimit);
    }
    return this;
  }

  @override
  int numberOfLeadingZeros() => _numberOfLeadingZeros(_i);

  @override
  int numberOfTrailingZeros() => _numberOfTrailingZeros(_i);

  @override
  Int32 toSigned(int width) {
    if (width < 1 || width > 32) throw RangeError.range(width, 1, 32);
    return Int32(_i.toSigned(width));
  }

  @override
  Int32 toUnsigned(int width) {
    if (width < 0 || width > 32) throw RangeError.range(width, 0, 32);
    return Int32(_i.toUnsigned(width));
  }

  @override
  List<int> toBytes() {
    var result = List<int>.filled(4, 0);
    result[0] = _i & 0xff;
    result[1] = (_i >> 8) & 0xff;
    result[2] = (_i >> 16) & 0xff;
    result[3] = (_i >> 24) & 0xff;
    return result;
  }

  @override
  double toDouble() => _i.toDouble();

  @override
  int toInt() => _i;

  @override
  Int32 toInt32() => this;

  @override
  Int64 toInt64() => Int64(_i);

  @override
  String toString() => _i.toString();

  @override
  String toHexString() => _i.toRadixString(16);

  @override
  String toRadixString(int radix) => _i.toRadixString(radix);
}

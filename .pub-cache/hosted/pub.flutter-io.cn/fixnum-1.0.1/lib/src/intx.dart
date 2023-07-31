// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of fixnum;

/// A fixed-precision integer.
abstract class IntX implements Comparable<Object> {
  /// Addition operator.
  IntX operator +(Object other);

  /// Subtraction operator.
  IntX operator -(Object other);

  /// Negate operator.
  ///
  /// Note that `-MIN_VALUE` is equal to `MIN_VALUE` due to overflow.
  IntX operator -();

  /// Multiplication operator.
  IntX operator *(Object other);

  /// Euclidean modulo operator.
  ///
  /// Returns the remainder of the euclidean division. The euclidean division
  /// of two integers `a` and `b` yields two integers `q` and `r` such that
  /// `a == b * q + r` and `0 <= r < a.abs()`.
  IntX operator %(Object other);

  /// Truncating division operator.
  IntX operator ~/(Object other);

  /// Returns the remainder of the truncating division of this integer by
  /// [other].
  IntX remainder(Object other);

  /// Bitwise and operator.
  IntX operator &(Object other);

  /// Bitwise or operator.
  IntX operator |(Object other);

  /// Bitwise xor operator.
  IntX operator ^(Object other);

  /// Bitwise negate operator.
  IntX operator ~();

  /// Left bit-shift operator.
  ///
  /// Returns the result of shifting the bits of this integer by [shiftAmount]
  /// bits to the left. Low-order bits are filled with zeros.
  IntX operator <<(int shiftAmount);

  /// Right bit-shift operator.
  ///
  /// Returns the result of shifting the bits of this integer by [shiftAmount]
  /// bits to the right. High-order bits are filled with zero in the case where
  /// this integer is positive, or one in the case where it is negative.
  IntX operator >>(int shiftAmount);

  /// Unsigned right-shift operator.
  ///
  /// Returns the result of shifting the bits of this integer by [shiftAmount]
  /// bits to the right. High-order bits are filled with zeros.
  IntX shiftRightUnsigned(int shiftAmount);

  @override
  int compareTo(Object other);

  /// Returns `true` if and only if [other] is an int or IntX equal in
  /// value to this integer.
  @override
  bool operator ==(Object other);

  /// Relational less than operator.
  bool operator <(Object other);

  /// Relational less than or equal to operator.
  bool operator <=(Object other);

  /// Relational greater than operator.
  bool operator >(Object other);

  /// Relational greater than or equal to operator.
  bool operator >=(Object other);

  /// Returns `true` if and only if this integer is even.
  bool get isEven;

  /// Returns `true` if and only if this integer is the maximum signed value
  /// that can be represented within its bit size.
  bool get isMaxValue;

  /// Returns `true` if and only if this integer is the minimum signed value
  /// that can be represented within its bit size.
  bool get isMinValue;

  /// Returns `true` if and only if this integer is less than zero.
  bool get isNegative;

  /// Returns `true` if and only if this integer is odd.
  bool get isOdd;

  /// Returns `true` if and only if this integer is zero.
  bool get isZero;

  @override
  int get hashCode;

  /// Returns the absolute value of this integer.
  IntX abs();

  /// Clamps this integer to be in the range [lowerLimit] - [upperLimit].
  IntX clamp(Object lowerLimit, Object upperLimit);

  /// Returns the minimum number of bits required to store this integer.
  ///
  /// The number of bits excludes the sign bit, which gives the natural length
  /// for non-negative (unsigned) values.  Negative values are complemented to
  /// return the bit position of the first bit that differs from the sign bit.
  ///
  /// To find the the number of bits needed to store the value as a signed
  /// value, add one, i.e. use `x.bitLength + 1`.
  int get bitLength;

  /// Returns the number of high-order zeros in this integer's bit
  /// representation.
  int numberOfLeadingZeros();

  /// Returns the number of low-order zeros in this integer's bit
  /// representation.
  int numberOfTrailingZeros();

  /// Returns the least significant [width] bits of this integer, extending the
  /// highest retained bit to the sign.  This is the same as truncating the
  /// value to fit in [width] bits using an signed 2-s complement
  /// representation. The returned value has the same bit value in all positions
  /// higher than [width].
  ///
  /// If the input value fits in [width] bits without truncation, the result is
  /// the same as the input.  The minimum width needed to avoid truncation of
  /// `x` is `x.bitLength + 1`, i.e.
  ///
  ///     x == x.toSigned(x.bitLength + 1);
  IntX toSigned(int width);

  /// Returns the least significant [width] bits of this integer as a
  /// non-negative number (i.e. unsigned representation). The returned value has
  /// zeros in all bit positions higher than [width].
  ///
  /// If the input fits in [width] bits without truncation, the result is the
  /// same as the input.  The minimum width needed to avoid truncation of `x` is
  /// given by `x.bitLength`, i.e.
  ///
  ///     x == x.toUnsigned(x.bitLength);
  IntX toUnsigned(int width);

  /// Returns a byte-sequence representation of this integer.
  ///
  /// Returns a list of int, starting with the least significant byte.
  List<int> toBytes();

  /// Returns the double representation of this integer.
  ///
  /// On some platforms, inputs with large absolute values (i.e., > 2^52) may
  /// lose some of their low-order bits.
  double toDouble();

  /// Returns the int representation of this integer.
  ///
  /// On some platforms, inputs with large absolute values (i.e., > 2^52) may
  /// lose some of their low-order bits.
  int toInt();

  /// Returns an Int32 representation of this integer.
  ///
  /// Narrower values are sign-extended and wider values have their high bits
  /// truncated.
  Int32 toInt32();

  /// Returns an Int64 representation of this integer.
  Int64 toInt64();

  /// Returns a string representing the value of this integer in decimal
  /// notation; example: `'13'`.
  @override
  String toString();

  /// Returns a string representing the value of this integer in hexadecimal
  /// notation; example: `'0xd'`.
  String toHexString();

  /// Returns a string representing the value of this integer in the given
  /// radix.
  ///
  /// [radix] must be an integer in the range 2 .. 16, inclusive.
  String toRadixString(int radix);
}

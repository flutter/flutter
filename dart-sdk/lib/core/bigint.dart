// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An arbitrarily large integer value.
///
/// Big integers are signed and can have an arbitrary number of
/// significant digits, only limited by memory.
///
/// To create a big integer from the provided number, use [BigInt.from].
/// ```dart
/// var bigInteger = BigInt.from(-1); // -1
/// bigInteger = BigInt.from(0.9999); // 0
/// bigInteger = BigInt.from(-10.99); // -10
/// bigInteger = BigInt.from(0x7FFFFFFFFFFFFFFF); // 9223372036854775807
/// bigInteger = BigInt.from(1e+30); // 1000000000000000019884624838656
/// ```
/// To parse a large integer value from a string, use [parse] or [tryParse].
/// ```dart
/// var value = BigInt.parse('0x1ffffffffffffffff'); // 36893488147419103231
/// value = BigInt.parse('12345678901234567890'); // 12345678901234567890
/// ```
/// To check whether a big integer can be represented as an [int] without losing
/// precision, use [isValidInt].
/// ```dart continued
/// print(bigNumber.isValidInt); // false
/// ```
/// To convert a big integer into an [int], use [toInt].
/// To convert a big integer into an [double], use [toDouble].
/// ```dart
/// var bigValue = BigInt.from(10).pow(3);
/// print(bigValue.isValidInt); // true
/// print(bigValue.toInt()); // 1000
/// print(bigValue.toDouble()); // 1000.0
/// ```
/// **See also:**
/// * [int]: An integer number.
/// * [double]: A double-precision floating point number.
/// * [num]: The super class for [int] and [double].
/// * [Numbers](https://dart.dev/guides/language/numbers) in
/// [A tour of the Dart language](https://dart.dev/guides/language/language-tour).
abstract final class BigInt implements Comparable<BigInt> {
  /// A big integer with the numerical value 0.
  external static BigInt get zero;

  /// A big integer with the numerical value 1.
  external static BigInt get one;

  /// A big integer with the numerical value 2.
  external static BigInt get two;

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
  /// Examples:
  /// ```dart
  /// print(BigInt.parse('-12345678901234567890')); // -12345678901234567890
  /// print(BigInt.parse('0xFF')); // 255
  /// print(BigInt.parse('0xffffffffffffffff')); // 18446744073709551615
  ///
  /// // From binary (base 2) value.
  /// print(BigInt.parse('1100', radix: 2)); // 12
  /// print(BigInt.parse('00011111', radix: 2)); // 31
  /// print(BigInt.parse('011111100101', radix: 2)); // 2021
  /// // From octal (base 8) value.
  /// print(BigInt.parse('14', radix: 8)); // 12
  /// print(BigInt.parse('37', radix: 8)); // 31
  /// print(BigInt.parse('3745', radix: 8)); // 2021
  /// // From hexadecimal (base 16) value.
  /// print(BigInt.parse('c', radix: 16)); // 12
  /// print(BigInt.parse('1f', radix: 16)); // 31
  /// print(BigInt.parse('7e5', radix: 16)); // 2021
  /// // From base 35 value.
  /// print(BigInt.parse('y1', radix: 35)); // 1191 == 34 * 35 + 1
  /// print(BigInt.parse('z1', radix: 35)); // Throws.
  /// // From base 36 value.
  /// print(BigInt.parse('y1', radix: 36)); // 1225 == 34 * 36 + 1
  /// print(BigInt.parse('z1', radix: 36)); // 1261 == 35 * 36 + 1
  /// ```
  external static BigInt parse(String source, {int? radix});

  /// Parses [source] as a, possibly signed, integer literal and returns its
  /// value.
  ///
  /// As [parse] except that this method returns `null` if the input is not
  /// valid
  ///
  /// Examples:
  /// ```dart
  /// print(BigInt.tryParse('-12345678901234567890')); // -12345678901234567890
  /// print(BigInt.tryParse('0xFF')); // 255
  /// print(BigInt.tryParse('0xffffffffffffffff')); // 18446744073709551615
  ///
  /// // From binary (base 2) value.
  /// print(BigInt.tryParse('1100', radix: 2)); // 12
  /// print(BigInt.tryParse('00011111', radix: 2)); // 31
  /// print(BigInt.tryParse('011111100101', radix: 2)); // 2021
  /// // From octal (base 8) value.
  /// print(BigInt.tryParse('14', radix: 8)); // 12
  /// print(BigInt.tryParse('37', radix: 8)); // 31
  /// print(BigInt.tryParse('3745', radix: 8)); // 2021
  /// // From hexadecimal (base 16) value.
  /// print(BigInt.tryParse('c', radix: 16)); // 12
  /// print(BigInt.tryParse('1f', radix: 16)); // 31
  /// print(BigInt.tryParse('7e5', radix: 16)); // 2021
  /// // From base 35 value.
  /// print(BigInt.tryParse('y1', radix: 35)); // 1191 == 34 * 35 + 1
  /// print(BigInt.tryParse('z1', radix: 35)); // null
  /// // From base 36 value.
  /// print(BigInt.tryParse('y1', radix: 36)); // 1225 == 34 * 36 + 1
  /// print(BigInt.tryParse('z1', radix: 36)); // 1261 == 35 * 36 + 1
  /// ```
  external static BigInt? tryParse(String source, {int? radix});

  /// Creates a big integer from the provided [value] number.
  ///
  /// Examples:
  /// ```dart
  /// var bigInteger = BigInt.from(1); // 1
  /// bigInteger = BigInt.from(0.9999); // 0
  /// bigInteger = BigInt.from(-10.99); // -10
  /// ```
  external factory BigInt.from(num value);

  /// Returns the absolute value of this integer.
  ///
  /// For any integer `x`, the result is the same as `x < 0 ? -x : x`.
  BigInt abs();

  /// Return the negative value of this integer.
  ///
  /// The result of negating an integer always has the opposite sign, except
  /// for zero, which is its own negation.
  BigInt operator -();

  /// Adds [other] to this big integer.
  ///
  /// The result is again a big integer.
  BigInt operator +(BigInt other);

  /// Subtracts [other] from this big integer.
  ///
  /// The result is again a big integer.
  BigInt operator -(BigInt other);

  /// Multiplies [other] by this big integer.
  ///
  /// The result is again a big integer.
  BigInt operator *(BigInt other);

  /// Double division operator.
  ///
  /// Matching the similar operator on [int],
  /// this operation first performs [toDouble] on both this big integer
  /// and [other], then does [double.operator/] on those values and
  /// returns the result.
  ///
  /// **Note:** The initial [toDouble] conversion may lose precision.
  ///
  /// Example:
  /// ```dart
  /// print(BigInt.from(1) / BigInt.from(2)); // 0.5
  /// print(BigInt.from(1.99999) / BigInt.from(2)); // 0.5
  /// ```
  double operator /(BigInt other);

  /// Truncating integer division operator.
  ///
  /// Performs a truncating integer division, where the remainder is discarded.
  ///
  /// The remainder can be computed using the [remainder] method.
  ///
  /// Examples:
  /// ```dart
  /// var seven = BigInt.from(7);
  /// var three = BigInt.from(3);
  /// seven ~/ three;    // => 2
  /// (-seven) ~/ three; // => -2
  /// seven ~/ -three;   // => -2
  /// seven.remainder(three);    // => 1
  /// (-seven).remainder(three); // => -1
  /// seven.remainder(-three);   // => 1
  /// ```
  BigInt operator ~/(BigInt other);

  /// Euclidean modulo operator.
  ///
  /// Returns the remainder of the Euclidean division. The Euclidean division of
  /// two integers `a` and `b` yields two integers `q` and `r` such that
  /// `a == b * q + r` and `0 <= r < b.abs()`.
  ///
  /// The sign of the returned value `r` is always positive.
  ///
  /// See [remainder] for the remainder of the truncating division.
  ///
  /// Example:
  /// ```dart
  /// print(BigInt.from(5) % BigInt.from(3)); // 2
  /// print(BigInt.from(-5) % BigInt.from(3)); // 1
  /// print(BigInt.from(5) % BigInt.from(-3)); // 2
  /// print(BigInt.from(-5) % BigInt.from(-3)); // 1
  /// ```
  BigInt operator %(BigInt other);

  /// Returns the remainder of the truncating division of `this` by [other].
  ///
  /// The result `r` of this operation satisfies:
  /// `this == (this ~/ other) * other + r`.
  /// As a consequence the remainder `r` has the same sign as the divider `this`.
  ///
  /// Example:
  /// ```dart
  /// print(BigInt.from(5).remainder(BigInt.from(3))); // 2
  /// print(BigInt.from(-5).remainder(BigInt.from(3))); // -2
  /// print(BigInt.from(5).remainder(BigInt.from(-3))); // 2
  /// print(BigInt.from(-5).remainder(BigInt.from(-3))); // -2
  /// ```
  BigInt remainder(BigInt other);

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
  BigInt operator <<(int shiftAmount);

  /// Shift the bits of this integer to the right by [shiftAmount].
  ///
  /// Shifting to the right makes the number smaller and drops the least
  /// significant bits, effectively doing an integer division by
  ///`pow(2, shiftIndex)`.
  ///
  /// It is an error if [shiftAmount] is negative.
  BigInt operator >>(int shiftAmount);

  /// Bit-wise and operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with only the bits set that are set in
  /// both `this` and [other]
  ///
  /// Of both operands are negative, the result is negative, otherwise
  /// the result is non-negative.
  BigInt operator &(BigInt other);

  /// Bit-wise or operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with the bits set that are set in either
  /// of `this` and [other]
  ///
  /// If both operands are non-negative, the result is non-negative,
  /// otherwise the result is negative.
  BigInt operator |(BigInt other);

  /// Bit-wise exclusive-or operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with the bits set that are set in one,
  /// but not both, of `this` and [other]
  ///
  /// If the operands have the same sign, the result is non-negative,
  /// otherwise the result is negative.
  BigInt operator ^(BigInt other);

  /// The bit-wise negate operator.
  ///
  /// Treating `this` as a sufficiently large two's component integer,
  /// the result is a number with the opposite bits set.
  ///
  /// This maps any integer `x` to `-x - 1`.
  BigInt operator ~();

  /// Whether this big integer is numerically smaller than [other].
  bool operator <(BigInt other);

  /// Whether [other] is numerically greater than this big integer.
  bool operator <=(BigInt other);

  /// Whether this big integer is numerically greater than [other].
  bool operator >(BigInt other);

  /// Whether [other] is numerically smaller than this big integer.
  bool operator >=(BigInt other);

  /// Compares this to `other`.
  ///
  /// Returns a negative number if `this` is less than `other`, zero if they are
  /// equal, and a positive number if `this` is greater than `other`.
  ///
  /// Example:
  /// ```dart
  /// print(BigInt.from(1).compareTo(BigInt.from(2))); // => -1
  /// print(BigInt.from(2).compareTo(BigInt.from(1))); // => 1
  /// print(BigInt.from(1).compareTo(BigInt.from(1))); // => 0
  /// ```
  int compareTo(BigInt other);

  /// Returns the minimum number of bits required to store this big integer.
  ///
  /// The number of bits excludes the sign bit, which gives the natural length
  /// for non-negative (unsigned) values. Negative values are complemented to
  /// return the bit position of the first bit that differs from the sign bit.
  ///
  /// To find the number of bits needed to store the value as a signed value,
  /// add one, i.e. use `x.bitLength + 1`.
  ///
  /// ```dart
  /// x.bitLength == (-x-1).bitLength;
  ///
  /// BigInt.from(3).bitLength == 2;   // 00000011
  /// BigInt.from(2).bitLength == 2;   // 00000010
  /// BigInt.from(1).bitLength == 1;   // 00000001
  /// BigInt.from(0).bitLength == 0;   // 00000000
  /// BigInt.from(-1).bitLength == 0;  // 11111111
  /// BigInt.from(-2).bitLength == 1;  // 11111110
  /// BigInt.from(-3).bitLength == 2;  // 11111101
  /// BigInt.from(-4).bitLength == 2;  // 11111100
  /// ```
  int get bitLength;

  /// Returns the sign of this big integer.
  ///
  /// Returns 0 for zero, -1 for values less than zero and
  /// +1 for values greater than zero.
  int get sign;

  /// Whether this big integer is even.
  bool get isEven;

  /// Whether this big integer is odd.
  bool get isOdd;

  /// Whether this number is negative.
  bool get isNegative;

  /// Returns `this` to the power of [exponent].
  ///
  /// Returns [one] if the [exponent] equals 0.
  ///
  /// The [exponent] must otherwise be positive.
  ///
  /// The result is always equal to the mathematical result of this to the power
  /// [exponent], only limited by the available memory.
  ///
  /// Example:
  /// ```dart
  /// var value = BigInt.from(1000);
  /// print(value.pow(0)); // 1
  /// print(value.pow(1)); // 1000
  /// print(value.pow(2)); // 1000000
  /// print(value.pow(3)); // 1000000000
  /// print(value.pow(4)); // 1000000000000
  /// print(value.pow(5)); // 1000000000000000
  /// print(value.pow(6)); // 1000000000000000000
  /// print(value.pow(7)); // 1000000000000000000000
  /// print(value.pow(8)); // 1000000000000000000000000
  /// ```
  BigInt pow(int exponent);

  /// Returns this integer to the power of [exponent] modulo [modulus].
  ///
  /// The [exponent] must be non-negative and [modulus] must be
  /// positive.
  BigInt modPow(BigInt exponent, BigInt modulus);

  /// Returns the modular multiplicative inverse of this big integer
  /// modulo [modulus].
  ///
  /// The [modulus] must be positive.
  ///
  /// It is an error if no modular inverse exists.
  // Returns 1/this % modulus, with modulus > 0.
  BigInt modInverse(BigInt modulus);

  /// Returns the greatest common divisor of this big integer and [other].
  ///
  /// If either number is non-zero, the result is the numerically greatest
  /// integer dividing both `this` and `other`.
  ///
  /// The greatest common divisor is independent of the order,
  /// so `x.gcd(y)` is always the same as `y.gcd(x)`.
  ///
  /// For any integer `x`, `x.gcd(x)` is `x.abs()`.
  ///
  /// If both `this` and `other` is zero, the result is also zero.
  ///
  /// Example:
  /// ```dart
  /// print(BigInt.from(4).gcd(BigInt.from(2))); // 2
  /// print(BigInt.from(8).gcd(BigInt.from(4))); // 4
  /// print(BigInt.from(10).gcd(BigInt.from(12))); // 2
  /// print(BigInt.from(10).gcd(BigInt.from(10))); // 10
  /// print(BigInt.from(-2).gcd(BigInt.from(-3))); // 1
  /// ```
  BigInt gcd(BigInt other);

  /// Returns the least significant [width] bits of this big integer as a
  /// non-negative number (i.e. unsigned representation). The returned value has
  /// zeros in all bit positions higher than [width].
  ///
  /// ```dart
  /// BigInt.from(-1).toUnsigned(5) == 31   // 11111111  ->  00011111
  /// ```
  ///
  /// This operation can be used to simulate arithmetic from low level languages.
  /// For example, to increment an 8 bit quantity:
  ///
  /// ```dart
  /// q = (q + 1).toUnsigned(8);
  /// ```
  ///
  /// `q` will count from `0` up to `255` and then wrap around to `0`.
  ///
  /// If the input fits in [width] bits without truncation, the result is the
  /// same as the input. The minimum width needed to avoid truncation of `x` is
  /// given by `x.bitLength`, i.e.
  ///
  /// ```dart
  /// x == x.toUnsigned(x.bitLength);
  /// ```
  BigInt toUnsigned(int width);

  /// Returns the least significant [width] bits of this integer, extending the
  /// highest retained bit to the sign. This is the same as truncating the value
  /// to fit in [width] bits using an signed 2-s complement representation. The
  /// returned value has the same bit value in all positions higher than [width].
  ///
  /// ```dart
  /// var big15 = BigInt.from(15);
  /// var big16 = BigInt.from(16);
  /// var big239 = BigInt.from(239);
  ///                                //     V--sign bit-V
  /// big16.toSigned(5) == -big16;   //  00010000 -> 11110000
  /// big239.toSigned(5) == big15;   //  11101111 -> 00001111
  ///                                //     ^           ^
  /// ```
  ///
  /// This operation can be used to simulate arithmetic from low level languages.
  /// For example, to increment an 8 bit signed quantity:
  ///
  /// ```dart
  /// q = (q + 1).toSigned(8);
  /// ```
  ///
  /// `q` will count from `0` up to `127`, wrap to `-128` and count back up to
  /// `127`.
  ///
  /// If the input value fits in [width] bits without truncation, the result is
  /// the same as the input. The minimum width needed to avoid truncation of `x`
  /// is `x.bitLength + 1`, i.e.
  ///
  /// ```dart
  /// x == x.toSigned(x.bitLength + 1);
  /// ```
  BigInt toSigned(int width);

  /// Whether this big integer can be represented as an `int` without losing
  /// precision.
  ///
  /// **Warning:** this function may give a different result on
  /// dart2js, dev compiler, and the VM, due to the differences in
  /// integer precision.
  ///
  /// Example:
  /// ```dart
  /// var bigNumber = BigInt.parse('100000000000000000000000');
  /// print(bigNumber.isValidInt); // false
  ///
  /// var value = BigInt.parse('0xFF'); // 255
  /// print(value.isValidInt); // true
  /// ```
  bool get isValidInt;

  /// Returns this [BigInt] as an [int].
  ///
  /// If the number does not fit, clamps to the max (or min)
  /// integer.
  ///
  /// **Warning:** the clamping behaves differently between the web and
  /// native platforms due to the differences in integer precision.
  ///
  /// Example:
  /// ```dart
  /// var bigNumber = BigInt.parse('100000000000000000000000');
  /// print(bigNumber.isValidInt); // false
  /// print(bigNumber.toInt()); // 9223372036854775807
  /// ```
  int toInt();

  /// Returns this [BigInt] as a [double].
  ///
  /// If the number is not representable as a [double], an
  /// approximation is returned. For numerically large integers, the
  /// approximation may be infinite.
  ///
  /// Example:
  /// ```dart
  /// var bigNumber = BigInt.parse('100000000000000000000000');
  /// print(bigNumber.toDouble()); // 1e+23
  /// ```
  double toDouble();

  /// Returns a String-representation of this integer.
  ///
  /// The returned string is parsable by [parse].
  /// For any `BigInt` `i`, it is guaranteed that
  /// `i == BigInt.parse(i.toString())`.
  ///
  /// Example:
  /// ```dart
  /// var bigNumber = BigInt.parse('100000000000000000000000');
  /// print(bigNumber.toString()); // "100000000000000000000000"
  /// ```
  String toString();

  /// Converts this [BigInt] to a string representation in the given [radix].
  ///
  /// In the string representation, lower-case letters are used for digits above
  /// '9', with 'a' being 10 an 'z' being 35.
  ///
  /// The [radix] argument must be an integer in the range 2 to 36.
  ///
  /// Example:
  /// ```dart
  /// // Binary (base 2).
  /// print(BigInt.from(12).toRadixString(2)); // 1100
  /// print(BigInt.from(31).toRadixString(2)); // 11111
  /// print(BigInt.from(2021).toRadixString(2)); // 11111100101
  /// print(BigInt.from(-12).toRadixString(2)); // -1100
  /// // Octal (base 8).
  /// print(BigInt.from(12).toRadixString(8)); // 14
  /// print(BigInt.from(31).toRadixString(8)); // 37
  /// print(BigInt.from(2021).toRadixString(8)); // 3745
  /// // Hexadecimal (base 16).
  /// print(BigInt.from(12).toRadixString(16)); // c
  /// print(BigInt.from(31).toRadixString(16)); // 1f
  /// print(BigInt.from(2021).toRadixString(16)); // 7e5
  /// // Base 36.
  /// print(BigInt.from(35 * 36 + 1).toRadixString(36)); // z1
  /// ```
  String toRadixString(int radix);
}

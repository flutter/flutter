// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// An integer number.
///
/// The default implementation of `int` is 64-bit two's complement integers
/// with operations that wrap to that range on overflow.
///
/// **Note:** When compiling to JavaScript, integers are restricted to values
/// that can be represented exactly by double-precision floating point values.
/// The available integer values include all integers between -2^53 and 2^53,
/// and some integers with larger magnitude. That includes some integers larger
/// than 2^63.
/// The behavior of the operators and methods in the [int]
/// class therefore sometimes differs between the Dart VM and Dart code
/// compiled to JavaScript. For example, the bitwise operators truncate their
/// operands to 32-bit integers when compiled to JavaScript.
///
/// Classes cannot extend, implement, or mix in `int`.
///
/// **See also:**
/// * [num] the super class for [int].
/// * [Numbers](https://dart.dev/guides/language/numbers) in
/// [A tour of the Dart language](https://dart.dev/guides/language/language-tour).
abstract final class int extends num {
  /// Integer value for [name] in the compilation configuration environment.
  ///
  /// The compilation configuration environment is provided by the
  /// surrounding tools which are compiling or running the Dart program.
  /// The environment is a mapping from a set of string keys to their associated
  /// string value.
  /// The string value, or lack of a value, associated with a [name]
  /// must be consistent across all calls to [String.fromEnvironment],
  /// `int.fromEnvironment`, [bool.fromEnvironment] and [bool.hasEnvironment]
  /// in a single program.
  /// The string values can be directly accessed using
  /// [String.fromEnvironment].
  ///
  /// This constructor looks up the string value for [name],
  /// then attempts to parse it as an integer, using the same syntax rules as
  /// [int.parse]/[int.tryParse]. That is, it accepts decimal numerals
  /// and hexadecimal numerals with a `0x` prefix, and it accepts a leading
  /// minus sign.
  /// If there is no value associated with [name] in the compilation
  /// configuration environment, or if the associated string value cannot
  /// be parsed as an integer, the value of the constructor invocation
  /// is the [defaultValue] integer, which defaults to the integer zero.
  ///
  /// The result is effectively the same as that of:
  /// ```dart template:expression
  /// int.tryParse(const String.fromEnvironment(name, defaultValue: ""))
  ///     ?? defaultValue
  /// ```
  /// except that the constructor invocation can be a constant value.
  ///
  /// Example:
  /// ```dart
  /// const defaultPort = int.fromEnvironment("defaultPort", defaultValue: 80);
  /// ```
  /// In order to check whether a value is there at all, use
  /// [bool.hasEnvironment]. Example:
  /// ```dart
  /// const int? maybeDeclared = bool.hasEnvironment("defaultPort")
  ///     ? int.fromEnvironment("defaultPort")
  ///     : null;
  /// ```
  ///
  /// The string value, or lack of a value, associated with a [name]
  /// must be consistent across all calls to [String.fromEnvironment],
  /// `int.fromEnvironment`, [bool.fromEnvironment] and [bool.hasEnvironment]
  /// in a single program.
  ///
  /// This constructor is only guaranteed to work when invoked as `const`.
  /// It may work as a non-constant invocation on some platforms which
  /// have access to compiler options at run-time, but most ahead-of-time
  /// compiled platforms will not have this information.
  external const factory int.fromEnvironment(String name,
      {int defaultValue = 0});

  /// Bit-wise and operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with only the bits set that are set in
  /// both `this` and [other]
  ///
  /// If both operands are negative, the result is negative, otherwise
  /// the result is non-negative.
  /// ```dart
  /// print((2 & 1).toRadixString(2)); // 0010 & 0001 -> 0000
  /// print((3 & 1).toRadixString(2)); // 0011 & 0001 -> 0001
  /// print((10 & 2).toRadixString(2)); // 1010 & 0010 -> 0010
  /// ```
  int operator &(int other);

  /// Bit-wise or operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with the bits set that are set in either
  /// of `this` and [other]
  ///
  /// If both operands are non-negative, the result is non-negative,
  /// otherwise the result is negative.
  ///
  /// Example:
  /// ```dart
  /// print((2 | 1).toRadixString(2)); // 0010 | 0001 -> 0011
  /// print((3 | 1).toRadixString(2)); // 0011 | 0001 -> 0011
  /// print((10 | 2).toRadixString(2)); // 1010 | 0010 -> 1010
  /// ```
  int operator |(int other);

  /// Bit-wise exclusive-or operator.
  ///
  /// Treating both `this` and [other] as sufficiently large two's component
  /// integers, the result is a number with the bits set that are set in one,
  /// but not both, of `this` and [other]
  ///
  /// If the operands have the same sign, the result is non-negative,
  /// otherwise the result is negative.
  ///
  /// Example:
  /// ```dart
  /// print((2 ^ 1).toRadixString(2)); //  0010 ^ 0001 -> 0011
  /// print((3 ^ 1).toRadixString(2)); //  0011 ^ 0001 -> 0010
  /// print((10 ^ 2).toRadixString(2)); //  1010 ^ 0010 -> 1000
  /// ```
  int operator ^(int other);

  /// The bit-wise negate operator.
  ///
  /// Treating `this` as a sufficiently large two's component integer,
  /// the result is a number with the opposite bits set.
  ///
  /// This maps any integer `x` to `-x - 1`.
  int operator ~();

  /// Shift the bits of this integer to the left by [shiftAmount].
  ///
  /// Shifting to the left makes the number larger, effectively multiplying
  /// the number by `pow(2, shiftAmount)`.
  ///
  /// There is no limit on the size of the result. It may be relevant to
  /// limit intermediate values by using the "and" operator with a suitable
  /// mask.
  ///
  /// It is an error if [shiftAmount] is negative.
  ///
  /// Example:
  /// ```dart
  /// print((3 << 1).toRadixString(2)); // 0011 -> 0110
  /// print((9 << 2).toRadixString(2)); // 1001 -> 100100
  /// print((10 << 3).toRadixString(2)); // 1010 -> 1010000
  /// ```
  int operator <<(int shiftAmount);

  /// Shift the bits of this integer to the right by [shiftAmount].
  ///
  /// Shifting to the right makes the number smaller and drops the least
  /// significant bits, effectively doing an integer division by
  /// `pow(2, shiftAmount)`.
  ///
  /// It is an error if [shiftAmount] is negative.
  ///
  /// Example:
  /// ```dart
  /// print((3 >> 1).toRadixString(2)); // 0011 -> 0001
  /// print((9 >> 2).toRadixString(2)); // 1001 -> 0010
  /// print((10 >> 3).toRadixString(2)); // 1010 -> 0001
  /// print((-6 >> 2).toRadixString); // 111...1010 -> 111...1110 == -2
  /// print((-85 >> 3).toRadixString); // 111...10101011 -> 111...11110101 == -11
  /// ```
  int operator >>(int shiftAmount);

  /// Bitwise unsigned right shift by [shiftAmount] bits.
  ///
  /// The least significant [shiftAmount] bits are dropped,
  /// the remaining bits (if any) are shifted down,
  /// and zero-bits are shifted in as the new most significant bits.
  ///
  /// The [shiftAmount] must be non-negative.
  ///
  /// Example:
  /// ```dart
  /// print((3 >>> 1).toRadixString(2)); // 0011 -> 0001
  /// print((9 >>> 2).toRadixString(2)); // 1001 -> 0010
  /// print(((-9) >>> 2).toRadixString(2)); // 111...1011 -> 001...1110 (> 0)
  /// ```
  int operator >>>(int shiftAmount);

  /// Returns this integer to the power of [exponent] modulo [modulus].
  ///
  /// The [exponent] must be non-negative and [modulus] must be
  /// positive.
  int modPow(int exponent, int modulus);

  /// Returns the modular multiplicative inverse of this integer
  /// modulo [modulus].
  ///
  /// The [modulus] must be positive.
  ///
  /// It is an error if no modular inverse exists.
  int modInverse(int modulus);

  /// Returns the greatest common divisor of this integer and [other].
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
  ///
  /// Example:
  /// ```dart
  /// print(4.gcd(2)); // 2
  /// print(8.gcd(4)); // 4
  /// print(10.gcd(12)); // 2
  /// print(10.gcd(0)); // 10
  /// print((-2).gcd(-3)); // 1
  /// ```
  int gcd(int other);

  /// Returns true if and only if this integer is even.
  bool get isEven;

  /// Returns true if and only if this integer is odd.
  bool get isOdd;

  /// Returns the minimum number of bits required to store this integer.
  ///
  /// The number of bits excludes the sign bit, which gives the natural length
  /// for non-negative (unsigned) values.  Negative values are complemented to
  /// return the bit position of the first bit that differs from the sign bit.
  ///
  /// To find the number of bits needed to store the value as a signed value,
  /// add one, i.e. use `x.bitLength + 1`.
  /// ```dart
  /// x.bitLength == (-x-1).bitLength;
  ///
  /// 3.bitLength == 2;     // 00000011
  /// 2.bitLength == 2;     // 00000010
  /// 1.bitLength == 1;     // 00000001
  /// 0.bitLength == 0;     // 00000000
  /// (-1).bitLength == 0;  // 11111111
  /// (-2).bitLength == 1;  // 11111110
  /// (-3).bitLength == 2;  // 11111101
  /// (-4).bitLength == 2;  // 11111100
  /// ```
  int get bitLength;

  /// Returns the least significant [width] bits of this integer as a
  /// non-negative number (i.e. unsigned representation).  The returned value has
  /// zeros in all bit positions higher than [width].
  /// ```dart
  /// (-1).toUnsigned(5) == 31   // 11111111  ->  00011111
  /// ```
  /// This operation can be used to simulate arithmetic from low level languages.
  /// For example, to increment an 8 bit quantity:
  /// ```dart
  /// q = (q + 1).toUnsigned(8);
  /// ```
  /// `q` will count from `0` up to `255` and then wrap around to `0`.
  ///
  /// If the input fits in [width] bits without truncation, the result is the
  /// same as the input.  The minimum width needed to avoid truncation of `x` is
  /// given by `x.bitLength`, i.e.
  /// ```dart
  /// x == x.toUnsigned(x.bitLength);
  /// ```
  int toUnsigned(int width);

  /// Returns the least significant [width] bits of this integer, extending the
  /// highest retained bit to the sign. This is the same as truncating the value
  /// to fit in [width] bits using an signed 2-s complement representation. The
  /// returned value has the same bit value in all positions higher than [width].
  ///
  /// ```dart
  ///                          //     V--sign bit-V
  /// 16.toSigned(5) == -16;   //  00010000 -> 11110000
  /// 239.toSigned(5) == 15;   //  11101111 -> 00001111
  ///                          //     ^           ^
  /// ```
  /// This operation can be used to simulate arithmetic from low level languages.
  /// For example, to increment an 8 bit signed quantity:
  /// ```dart
  /// q = (q + 1).toSigned(8);
  /// ```
  /// `q` will count from `0` up to `127`, wrap to `-128` and count back up to
  /// `127`.
  ///
  /// If the input value fits in [width] bits without truncation, the result is
  /// the same as the input.  The minimum width needed to avoid truncation of `x`
  /// is `x.bitLength + 1`, i.e.
  /// ```dart
  /// x == x.toSigned(x.bitLength + 1);
  /// ```
  int toSigned(int width);

  /// Return the negative value of this integer.
  ///
  /// The result of negating an integer always has the opposite sign, except
  /// for zero, which is its own negation.
  int operator -();

  /// Returns the absolute value of this integer.
  ///
  /// For any integer `value`,
  /// the result is the same as `value < 0 ? -value : value`.
  ///
  /// Integer overflow may cause the result of `-value` to stay negative.
  int abs();

  /// Returns the sign of this integer.
  ///
  /// Returns 0 for zero, -1 for values less than zero and
  /// +1 for values greater than zero.
  int get sign;

  /// Returns `this`.
  int round();

  /// Returns `this`.
  int floor();

  /// Returns `this`.
  int ceil();

  /// Returns `this`.
  int truncate();

  /// Returns `this.toDouble()`.
  double roundToDouble();

  /// Returns `this.toDouble()`.
  double floorToDouble();

  /// Returns `this.toDouble()`.
  double ceilToDouble();

  /// Returns `this.toDouble()`.
  double truncateToDouble();

  /// Returns a string representation of this integer.
  ///
  /// The returned string is parsable by [parse].
  /// For any `int` `i`, it is guaranteed that
  /// `i == int.parse(i.toString())`.
  String toString();

  /// Converts this [int] to a string representation in the given [radix].
  ///
  /// In the string representation, lower-case letters are used for digits above
  /// '9', with 'a' being 10 and 'z' being 35.
  ///
  /// The [radix] argument must be an integer in the range 2 to 36.
  ///
  /// Example:
  /// ```dart
  /// // Binary (base 2).
  /// print(12.toRadixString(2)); // 1100
  /// print(31.toRadixString(2)); // 11111
  /// print(2021.toRadixString(2)); // 11111100101
  /// print((-12).toRadixString(2)); // -1100
  /// // Octal (base 8).
  /// print(12.toRadixString(8)); // 14
  /// print(31.toRadixString(8)); // 37
  /// print(2021.toRadixString(8)); // 3745
  /// // Hexadecimal (base 16).
  /// print(12.toRadixString(16)); // c
  /// print(31.toRadixString(16)); // 1f
  /// print(2021.toRadixString(16)); // 7e5
  /// // Base 36.
  /// print((35 * 36 + 1).toRadixString(36)); // z1
  /// ```
  String toRadixString(int radix);

  /// Parse [source] as a, possibly signed, integer literal and return its value.
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
  /// as a hexadecimal integer literal,
  /// When `int` is implemented by 64-bit signed integers,
  /// hexadecimal integer literals may represent values larger than
  /// 2<sup>63</sup>, in which case the value is parsed as if it is an
  /// *unsigned* number, and the resulting value is the corresponding
  /// signed integer value.
  ///
  /// For any int `n` and valid radix `r`, it is guaranteed that
  /// `n == int.parse(n.toRadixString(r), radix: r)`.
  ///
  /// If the [source] string does not contain a valid integer literal,
  /// optionally prefixed by a sign, a [FormatException] is thrown.
  ///
  /// Rather than throwing and immediately catching the [FormatException],
  /// instead use [tryParse] to handle a potential parsing error.
  ///
  /// Example:
  /// ```dart
  /// var value = int.tryParse(text);
  /// if (value == null) {
  ///   // handle the problem
  ///   // ...
  /// }
  /// ```
  external static int parse(String source, {int? radix});

  /// Parse [source] as a, possibly signed, integer literal.
  ///
  /// Like [parse] except that this function returns `null` where a
  /// similar call to [parse] would throw a [FormatException].
  ///
  /// Example:
  /// ```dart
  /// print(int.tryParse('2021')); // 2021
  /// print(int.tryParse('1f')); // null
  /// // From binary (base 2) value.
  /// print(int.tryParse('1100', radix: 2)); // 12
  /// print(int.tryParse('00011111', radix: 2)); // 31
  /// print(int.tryParse('011111100101', radix: 2)); // 2021
  /// // From octal (base 8) value.
  /// print(int.tryParse('14', radix: 8)); // 12
  /// print(int.tryParse('37', radix: 8)); // 31
  /// print(int.tryParse('3745', radix: 8)); // 2021
  /// // From hexadecimal (base 16) value.
  /// print(int.tryParse('c', radix: 16)); // 12
  /// print(int.tryParse('1f', radix: 16)); // 31
  /// print(int.tryParse('7e5', radix: 16)); // 2021
  /// // From base 35 value.
  /// print(int.tryParse('y1', radix: 35)); // 1191 == 34 * 35 + 1
  /// print(int.tryParse('z1', radix: 35)); // null
  /// // From base 36 value.
  /// print(int.tryParse('y1', radix: 36)); // 1225 == 34 * 36 + 1
  /// print(int.tryParse('z1', radix: 36)); // 1261 == 35 * 36 + 1
  /// ```
  external static int? tryParse(String source, {int? radix});
}

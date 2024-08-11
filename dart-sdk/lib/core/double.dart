// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// A double-precision floating point number.
///
/// Representation of Dart doubles containing double specific constants
/// and operations and specializations of operations inherited from
/// [num]. Dart doubles are 64-bit floating-point numbers as specified in the
/// IEEE 754 standard.
///
/// The [double] type is contagious. Operations on [double]s return
/// [double] results.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// double.
///
/// **See also:**
/// * [num] the super class for [double].
/// * [Numbers](https://dart.dev/guides/language/numbers) in
/// [A tour of the Dart language](https://dart.dev/guides/language/language-tour).
abstract final class double extends num {
  static const double nan = 0.0 / 0.0;
  static const double infinity = 1.0 / 0.0;
  static const double negativeInfinity = -infinity;
  static const double minPositive = 5e-324;
  static const double maxFinite = 1.7976931348623157e+308;

  double remainder(num other);

  double operator +(num other);

  double operator -(num other);

  double operator *(num other);

  double operator %(num other);

  double operator /(num other);

  int operator ~/(num other);

  double operator -();

  double abs();

  /// The sign of the double's numerical value.
  ///
  /// Returns -1.0 if the value is less than zero,
  /// +1.0 if the value is greater than zero,
  /// and the value itself if it is -0.0, 0.0 or NaN.
  double get sign;

  /// Returns the integer closest to this number.
  ///
  /// Rounds away from zero when there is no closest integer:
  ///  `(3.5).round() == 4` and `(-3.5).round() == -4`.
  ///
  /// Throws an [UnsupportedError] if this number is not finite
  /// (NaN or an infinity).
  /// ```dart
  /// print(3.0.round()); // 3
  /// print(3.25.round()); // 3
  /// print(3.5.round()); // 4
  /// print(3.75.round()); // 4
  /// print((-3.5).round()); // -4
  /// ```
  int round();

  /// Returns the greatest integer no greater than this number.
  ///
  /// Rounds the number towards negative infinity.
  ///
  /// Throws an [UnsupportedError] if this number is not finite
  /// (NaN or infinity).
  /// ```dart
  /// print(1.99999.floor()); // 1
  /// print(2.0.floor()); // 2
  /// print(2.99999.floor()); // 2
  /// print((-1.99999).floor()); // -2
  /// print((-2.0).floor()); // -2
  /// print((-2.00001).floor()); // -3
  /// ```
  int floor();

  /// Returns the least integer that is not smaller than this number.
  ///
  /// Rounds the number towards infinity.
  ///
  /// Throws an [UnsupportedError] if this number is not finite
  /// (NaN or an infinity).
  /// ```dart
  /// print(1.99999.ceil()); // 2
  /// print(2.0.ceil()); // 2
  /// print(2.00001.ceil()); // 3
  /// print((-1.99999).ceil()); // -1
  /// print((-2.0).ceil()); // -2
  /// print((-2.00001).ceil()); // -2
  /// ```
  int ceil();

  /// Returns the integer obtained by discarding any fractional
  /// part of this number.
  ///
  /// Rounds the number towards zero.
  ///
  /// Throws an [UnsupportedError] if this number is not finite
  /// (NaN or an infinity).
  /// ```dart
  /// print(2.00001.truncate()); // 2
  /// print(1.99999.truncate()); // 1
  /// print(0.5.truncate()); // 0
  /// print((-0.5).truncate()); // 0
  /// print((-1.5).truncate()); // -1
  /// print((-2.5).truncate()); // -2
  /// ```
  int truncate();

  /// Returns the integer double value closest to `this`.
  ///
  /// Rounds away from zero when there is no closest integer:
  ///  `(3.5).roundToDouble() == 4` and `(-3.5).roundToDouble() == -4`.
  ///
  /// If this is already an integer valued double, including `-0.0`, or it is not
  /// a finite value, the value is returned unmodified.
  ///
  /// For the purpose of rounding, `-0.0` is considered to be below `0.0`,
  /// and `-0.0` is therefore considered closer to negative numbers than `0.0`.
  /// This means that for a value `d` in the range `-0.5 < d < 0.0`,
  /// the result is `-0.0`.
  /// ```dart
  /// print(3.0.roundToDouble()); // 3.0
  /// print(3.25.roundToDouble()); // 3.0
  /// print(3.5.roundToDouble()); // 4.0
  /// print(3.75.roundToDouble()); // 4.0
  /// print((-3.5).roundToDouble()); // -4.0
  /// ```
  double roundToDouble();

  /// Returns the greatest integer double value no greater than `this`.
  ///
  /// If this is already an integer valued double, including `-0.0`, or it is not
  /// a finite value, the value is returned unmodified.
  ///
  /// For the purpose of rounding, `-0.0` is considered to be below `0.0`.
  /// A number `d` in the range `0.0 < d < 1.0` will return `0.0`.
  /// ```dart
  /// print(1.99999.floorToDouble()); // 1.0
  /// print(2.0.floorToDouble()); // 2.0
  /// print(2.99999.floorToDouble()); // 2.0
  /// print((-1.99999).floorToDouble()); // -2.0
  /// print((-2.0).floorToDouble()); // -2.0
  /// print((-2.00001).floorToDouble()); // -3.0
  /// ```
  double floorToDouble();

  /// Returns the least integer double value no smaller than `this`.
  ///
  /// If this is already an integer valued double, including `-0.0`, or it is not
  /// a finite value, the value is returned unmodified.
  ///
  /// For the purpose of rounding, `-0.0` is considered to be below `0.0`.
  /// A number `d` in the range `-1.0 < d < 0.0` will return `-0.0`.
  /// ```dart
  /// print(1.99999.ceilToDouble()); // 2.0
  /// print(2.0.ceilToDouble()); // 2.0
  /// print(2.00001.ceilToDouble()); // 3.0
  /// print((-1.99999).ceilToDouble()); // -1.0
  /// print((-2.0).ceilToDouble()); // -2.0
  /// print((-2.00001).ceilToDouble()); // -2.0
  /// ```
  double ceilToDouble();

  /// Returns the integer double value obtained by discarding any fractional
  /// digits from `this`.
  ///
  /// If this is already an integer valued double, including `-0.0`, or it is not
  /// a finite value, the value is returned unmodified.
  ///
  /// For the purpose of rounding, `-0.0` is considered to be below `0.0`.
  /// A number `d` in the range `-1.0 < d < 0.0` will return `-0.0`, and
  /// in the range `0.0 < d < 1.0` it will return 0.0.
  /// ```dart
  /// print(2.5.truncateToDouble()); // 2.0
  /// print(2.00001.truncateToDouble()); // 2.0
  /// print(1.99999.truncateToDouble()); // 1.0
  /// print(0.5.truncateToDouble()); // 0.0
  /// print((-0.5).truncateToDouble()); // -0.0
  /// print((-1.5).truncateToDouble()); // -1.0
  /// print((-2.5).truncateToDouble()); // -2.0
  /// ```
  double truncateToDouble();

  /// Provide a representation of this [double] value.
  ///
  /// The representation is a number literal such that the closest double value
  /// to the representation's mathematical value is this [double].
  ///
  /// Returns "NaN" for the Not-a-Number value.
  /// Returns "Infinity" and "-Infinity" for positive and negative Infinity.
  /// Returns "-0.0" for negative zero.
  ///
  /// For all doubles, `d`, converting to a string and parsing the string back
  /// gives the same value again: `d == double.parse(d.toString())` (except when
  /// `d` is NaN).
  String toString();

  /// Parse [source] as a double literal and return its value.
  ///
  /// Accepts an optional sign (`+` or `-`) followed by either the characters
  /// "Infinity", the characters "NaN" or a floating-point representation.
  /// A floating-point representation is composed of a mantissa and an optional
  /// exponent part. The mantissa is either a decimal point (`.`) followed by a
  /// sequence of (decimal) digits, or a sequence of digits
  /// optionally followed by a decimal point and optionally more digits. The
  /// (optional) exponent part consists of the character "e" or "E", an optional
  /// sign, and one or more digits.
  /// The [source] must not be `null`.
  ///
  /// Leading and trailing whitespace is ignored.
  ///
  /// Throws a [FormatException] if the [source] string is not
  /// a valid double literal.
  ///
  /// Rather than throwing and immediately catching the [FormatException],
  /// instead use [tryParse] to handle a potential parsing error.
  ///
  /// Examples of accepted strings:
  /// ```
  /// "3.14"
  /// "  3.14 \xA0"
  /// "0."
  /// ".0"
  /// "-1.e3"
  /// "1234E+7"
  /// "+.12e-9"
  /// "-NaN"
  /// ```
  external static double parse(String source);

  /// Parse [source] as a double literal and return its value.
  ///
  /// Like [parse], except that this function returns `null` for invalid inputs
  /// instead of throwing.
  ///
  /// Example:
  /// ```dart
  /// var value = double.tryParse('3.14'); // 3.14
  /// value = double.tryParse('  3.14 \xA0'); // 3.14
  /// value = double.tryParse('0.'); // 0.0
  /// value = double.tryParse('.0'); // 0.0
  /// value = double.tryParse('-1.e3'); // -1000.0
  /// value = double.tryParse('1234E+7'); // 12340000000.0
  /// value = double.tryParse('+.12e-9'); // 1.2e-10
  /// value = double.tryParse('-NaN'); // NaN
  /// value = double.tryParse('0xFF'); // null
  /// value = double.tryParse(double.infinity.toString()); // Infinity
  /// ```
  external static double? tryParse(String source);
}

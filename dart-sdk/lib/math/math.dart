// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Mathematical constants and functions, plus a random number generator.
///
/// To use this library in your code:
/// ```dart
/// import 'dart:math';
/// ```
///
/// ## Random
/// [Random] is a generator of [bool], [int] or [double] values.
/// ```dart
/// var intValue = Random().nextInt(10); // Value is >= 0 and < 10.
/// var doubleValue = Random().nextDouble(); // Value is >= 0.0 and < 1.0.
/// var boolValue = Random().nextBool(); // true or false, with equal chance.
/// ```
///
/// ## Point
/// [Point] is a utility class for representing two-dimensional positions.
/// ```dart
/// var leftTop = const Point(0, 0);
/// var rightBottom = const Point(200, 400);
/// ```
///
/// ## Rectangle
/// [Rectangle] is a class for representing two-dimensional axis-aligned
/// rectangles whose properties are immutable.
///
/// Create a rectangle spanned by the points.
/// ```dart
/// var leftTop = const Point(20, 50);
/// var rightBottom = const Point(300, 600);
/// var rectangle = Rectangle.fromPoints(leftTop, rightBottom);
/// print(rectangle.left); // 20
/// print(rectangle.top); // 50
/// print(rectangle.right); // 300
/// print(rectangle.bottom); // 600
/// ```
///
/// Create a rectangle spanned by `(left, top)` and
/// `(left+width, top+height)`.
/// ```dart
/// var rectangle = const Rectangle(20, 50, 300, 600);
/// print(rectangle.left); // 20
/// print(rectangle.top); // 50
/// print(rectangle.right); // 320
/// print(rectangle.bottom); // 650
/// ```
///
/// ## MutableRectangle
/// [MutableRectangle] is a class for representing two-dimensional axis-aligned
/// rectangles with mutable properties.
///
/// Create a mutable rectangle spanned by `(left, top)` and
/// `(left+width, top+height)`.
/// ```dart
/// var rectangle = MutableRectangle(20, 50, 300, 600);
/// print(rectangle); // Rectangle (20, 50) 300 x 600
/// print(rectangle.left); // 20
/// print(rectangle.top); // 50
/// print(rectangle.right); // 320
/// print(rectangle.bottom); // 650
///
/// // Change rectangle width and height.
/// rectangle.width = 200;
/// rectangle.height = 100;
/// print(rectangle); // Rectangle (20, 50) 200 x 100
/// print(rectangle.left); // 20
/// print(rectangle.top); // 50
/// print(rectangle.right); // 220
/// print(rectangle.bottom); // 150
/// ```
///
/// {@category Core}
library dart.math;

import "dart:_internal" show SystemHash;

part "point.dart";
part "random.dart";
part "rectangle.dart";

/// Base of the natural logarithms.
///
/// Typically written as "e".
const double e = 2.718281828459045;

/// Natural logarithm of 10.
///
/// The natural logarithm of 10 is the number such that `pow(E, LN10) == 10`.
/// This value is not exact, but it is the closest representable double to the
/// exact mathematical value.
const double ln10 = 2.302585092994046;

/// Natural logarithm of 2.
///
/// The natural logarithm of 2 is the number such that `pow(E, LN2) == 2`.
/// This value is not exact, but it is the closest representable double to the
/// exact mathematical value.
const double ln2 = 0.6931471805599453;

/// Base-2 logarithm of [e].
const double log2e = 1.4426950408889634;

/// Base-10 logarithm of [e].
const double log10e = 0.4342944819032518;

/// The PI constant.
const double pi = 3.1415926535897932;

/// Square root of 1/2.
const double sqrt1_2 = 0.7071067811865476;

/// Square root of 2.
const double sqrt2 = 1.4142135623730951;

/// Returns the lesser of two numbers.
///
/// Returns NaN if either argument is NaN.
/// The lesser of `-0.0` and `0.0` is `-0.0`.
/// If the arguments are otherwise equal (including int and doubles with the
/// same mathematical value) then it is unspecified which of the two arguments
/// is returned.
external T min<T extends num>(T a, T b);

/// Returns the larger of two numbers.
///
/// Returns NaN if either argument is NaN.
/// The larger of `-0.0` and `0.0` is `0.0`. If the arguments are
/// otherwise equal (including int and doubles with the same mathematical value)
/// then it is unspecified which of the two arguments is returned.
external T max<T extends num>(T a, T b);

/// A variant of [atan].
///
/// Converts both arguments to [double]s.
///
/// Returns the angle in radians between the positive x-axis
/// and the vector ([b],[a]).
/// The result is in the range -PI..PI.
///
/// If [b] is positive, this is the same as `atan(a/b)`.
///
/// The result is negative when [a] is negative (including when [a] is the
/// double -0.0).
///
/// If [a] is equal to zero, the vector ([b],[a]) is considered parallel to
/// the x-axis, even if [b] is also equal to zero. The sign of [b] determines
/// the direction of the vector along the x-axis.
///
/// Returns NaN if either argument is NaN.
external double atan2(num a, num b);

/// Returns [x] to the power of [exponent].
///
/// If [x] is an [int] and [exponent] is a non-negative [int], the result is
/// an [int], otherwise both arguments are converted to doubles first, and the
/// result is a [double].
///
/// For integers, the power is always equal to the mathematical result of `x` to
/// the power `exponent`, only limited by the available memory.
///
/// For doubles, `pow(x, y)` handles edge cases as follows:
///
/// - if `y` is zero (0.0 or -0.0), the result is always 1.0.
/// - if `x` is 1.0, the result is always 1.0.
/// - otherwise, if either `x` or `y` is NaN, then the result is NaN.
/// - if `x` is negative (but not -0.0) and `y` is a finite non-integer, the
///   result is NaN.
/// - if `x` is Infinity and `y` is negative, the result is 0.0.
/// - if `x` is Infinity and `y` is positive, the result is Infinity.
/// - if `x` is 0.0 and `y` is negative, the result is Infinity.
/// - if `x` is 0.0 and `y` is positive, the result is 0.0.
/// - if `x` is -Infinity or -0.0 and `y` is an odd integer, then the result is
///   `-pow(-x ,y)`.
/// - if `x` is -Infinity or -0.0 and `y` is not an odd integer, then the result
///   is the same as `pow(-x , y)`.
/// - if `y` is Infinity and the absolute value of `x` is less than 1, the
///   result is 0.0.
/// - if `y` is Infinity and `x` is -1, the result is 1.0.
/// - if `y` is Infinity and the absolute value of `x` is greater than 1,
///   the result is Infinity.
/// - if `y` is -Infinity, the result is `1/pow(x, Infinity)`.
///
/// This corresponds to the `pow` function defined in the IEEE Standard
/// 754-2008.
///
/// Notice that the result may overflow. If integers are represented as 64-bit
/// numbers, an integer result may be truncated, and a double result may
/// overflow to positive or negative [double.infinity].
external num pow(num x, num exponent);

/// Converts [radians] to a [double] and returns the sine of the value.
///
/// If [radians] is not a finite number, the result is NaN.
external double sin(num radians);

/// Converts [radians] to a [double] and returns the cosine of the value.
///
/// If [radians] is not a finite number, the result is NaN.
external double cos(num radians);

/// Converts [radians] to a [double] and returns the tangent of the value.
///
/// The tangent function is equivalent to `sin(radians)/cos(radians)` and may be
/// infinite (positive or negative) when `cos(radians)` is equal to zero.
/// If [radians] is not a finite number, the result is NaN.
external double tan(num radians);

/// Converts [x] to a [double] and returns its arc cosine in radians.
///
/// Returns a value in the range 0..PI, or NaN if [x] is outside
/// the range -1..1.
external double acos(num x);

/// Converts [x] to a [double] and returns its arc sine in radians.
///
/// Returns a value in the range -PI/2..PI/2, or NaN if [x] is outside
/// the range -1..1.
external double asin(num x);

/// Converts [x] to a [double] and returns its arc tangent in radians.
///
/// Returns a value in the range -PI/2..PI/2, or NaN if [x] is NaN.
external double atan(num x);

/// Converts [x] to a [double] and returns the positive square root of the
/// value.
///
/// Returns -0.0 if [x] is -0.0, and NaN if [x] is otherwise negative or NaN.
/// ```dart
/// var result = sqrt(9.3);
/// print(result); // 3.0495901363953815
/// result = sqrt(2);
/// print(result); // 1.4142135623730951
/// result = sqrt(0);
/// print(result); // 0.0
/// result = sqrt(-2.2);
/// print(result); // NaN
/// ```
external double sqrt(num x);

/// Converts [x] to a [double] and returns the natural exponent, [e],
/// to the power [x].
///
/// Returns NaN if [x] is NaN.
external double exp(num x);

/// Converts [x] to a [double] and returns the natural logarithm of the value.
///
/// Returns negative infinity if [x] is equal to zero.
/// Returns NaN if [x] is NaN or less than zero.
external double log(num x);

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// The signature of a generic comparison function.
///
/// A comparison function represents an ordering on a type of objects.
/// A total ordering on a type means that for two values, either they
/// are equal or one is greater than the other (and the latter must then be
/// smaller than the former).
///
/// A [Comparator] function represents such a total ordering by returning
///
/// * a negative integer if [a] is smaller than [b],
/// * zero if [a] is equal to [b], and
/// * a positive integer if [a] is greater than [b].
typedef Comparator<T> = int Function(T a, T b);

/// Interface used by types that have an intrinsic ordering.
///
/// The [compareTo] operation defines a total ordering of objects,
/// which can be used for ordering and sorting.
///
/// The [Comparable] interface should be used for the natural ordering of a type.
/// If a type can be ordered in more than one way,
/// and none of them is the obvious natural ordering,
/// then it might be better not to use the [Comparable] interface,
/// and to provide separate [Comparator]s instead.
///
/// It is recommended that the order of a [Comparable] agrees
/// with its operator [operator ==] equality (`a.compareTo(b) == 0` iff `a == b`),
/// but this is not a requirement.
/// For example, [double] and [DateTime] have `compareTo` methods
/// that do not agree with operator [operator ==].
/// For doubles the [compareTo] method is more precise than the equality,
/// and for [DateTime] it is less precise.
///
/// Examples:
/// ```dart
/// (0.0).compareTo(-0.0);   // => 1
/// 0.0 == -0.0;             // => true
/// var now = DateTime.now();
/// var utcNow = now.toUtc();
/// now == utcNow;           // => false
/// now.compareTo(utcNow);   // => 0
/// ```
/// The [Comparable] interface does not imply the existence
/// of the comparison operators `<`, `<=`, `>` and `>=`.
/// These should only be defined
/// if the ordering is a less-than/greater-than ordering,
/// that is, an ordering where you would naturally
/// use the words "less than" about the order of two elements.
///
/// If the equality operator and [compareTo] disagree,
/// the comparison operators should follow the equality operator,
/// and will likely also disagree with [compareTo].
/// Otherwise they should match the [compareTo] method,
/// so that `a < b` iff `a.compareTo(b) < 0`.
///
/// The [double] class defines comparison operators
/// that are compatible with equality.
/// The operators differ from [double.compareTo] on -0.0 and NaN.
///
/// The [DateTime] class has no comparison operators, instead it has the more
/// precisely named [DateTime.isBefore] and [DateTime.isAfter], which both
/// agree with [DateTime.compareTo].
abstract interface class Comparable<T> {
  /// Compares this object to another object.
  ///
  /// Returns a value like a [Comparator] when comparing `this` to [other].
  /// That is, it returns a negative integer if `this` is ordered before [other],
  /// a positive integer if `this` is ordered after [other],
  /// and zero if `this` and [other] are ordered together.
  ///
  /// The [other] argument must be a value that is comparable to this object.
  int compareTo(T other);

  /// A [Comparator] that compares one comparable to another.
  ///
  /// It returns the result of `a.compareTo(b)`.
  /// The call may fail at run-time
  /// if `a` is not comparable to the type of `b`.
  ///
  /// This utility function is used as the default comparator
  /// for ordering collections, for example in the [List] sort function.
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}

// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility functions.

/// A [Comparator] that asserts that its first argument is comparable.
///
/// The function behaves just like [List.sort]'s
/// default comparison function. It is entirely dynamic in its testing.
///
/// Should be used when optimistically comparing object that are assumed
/// to be comparable.
/// If the elements are known to be comparable, use [compareComparable].
int defaultCompare(Object? value1, Object? value2) =>
    (value1 as Comparable<Object?>).compareTo(value2);

/// Ignore an argument.
///
/// Can be used to drop the result of a future like `future.then(ignore)`.
void ignore(_) {}

/// Create a single-element fixed-length list.
List<T> list1<T extends Object?>(T v1) => List<T>.filled(1, v1);

/// Create a two-element fixed-length list.
List<T> list2<T extends Object?>(T v1, T v2) => List<T>.filled(2, v1)..[1] = v2;

/// Create a three-element fixed-length list.
List<T> list3<T extends Object?>(T v1, T v2, T v3) => List<T>.filled(3, v1)
  ..[1] = v2
  ..[2] = v3;

/// Create a four-element fixed-length list.
List<T> list4<T extends Object?>(T v1, T v2, T v3, T v4) =>
    List<T>.filled(4, v1)
      ..[1] = v2
      ..[2] = v3
      ..[3] = v4;

/// Create a five-element fixed-length list.
List<T> list5<T extends Object?>(T v1, T v2, T v3, T v4, T v5) =>
    List<T>.filled(5, v1)
      ..[1] = v2
      ..[2] = v3
      ..[3] = v4
      ..[4] = v5;

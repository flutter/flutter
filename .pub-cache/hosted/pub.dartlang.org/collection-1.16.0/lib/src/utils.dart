// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// A reusable identity function at any type.
T identity<T>(T value) => value;

/// A reusable typed comparable comparator.
int compareComparable<T extends Comparable<T>>(T a, T b) => a.compareTo(b);

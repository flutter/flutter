// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(ianh): These should be on the Set and List classes themselves.

/// Compares two sets for deep equality.
///
/// Returns true if the sets are both null, or if they are both non-null, have
/// the same length, and contain the same members. Returns false otherwise.
/// Order is not compared.
///
/// The term "deep" above refers to the first level of equality: if the elements
/// are maps, lists, sets, or other collections/composite objects, then the
/// values of those elements are not compared element by element unless their
/// equality operators ([Object.operator==]) do so.
///
/// See also:
///
///  * [listEquals], which does something similar for lists.
///  * [mapEquals], which does something similar for maps.
bool setEquals<T>(Set<T> a, Set<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  if (identical(a, b))
    return true;
  for (T value in a) {
    if (!b.contains(value))
      return false;
  }
  return true;
}

/// Compares two lists for deep equality.
///
/// Returns true if the lists are both null, or if they are both non-null, have
/// the same length, and contain the same members in the same order. Returns
/// false otherwise.
///
/// The term "deep" above refers to the first level of equality: if the elements
/// are maps, lists, sets, or other collections/composite objects, then the
/// values of those elements are not compared element by element unless their
/// equality operators ([Object.operator==]) do so.
///
/// See also:
///
///  * [setEquals], which does something similar for sets.
///  * [mapEquals], which does something similar for maps.
bool listEquals<T>(List<T> a, List<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  if (identical(a, b))
    return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index])
      return false;
  }
  return true;
}

/// Compares two maps for deep equality.
///
/// Returns true if the maps are both null, or if they are both non-null, have
/// the same length, and contain the same keys associated with the same values.
/// Returns false otherwise.
///
/// The term "deep" above refers to the first level of equality: if the elements
/// are maps, lists, sets, or other collections/composite objects, then the
/// values of those elements are not compared element by element unless their
/// equality operators ([Object.operator==]) do so.
///
/// See also:
///
///  * [setEquals], which does something similar for sets.
///  * [listEquals], which does something similar for lists.
bool mapEquals<T, U>(Map<T, U> a, Map<T, U> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  if (identical(a, b))
    return true;
  for (T key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}


/// Returns the position of `value` in the `sortedList`, if it exists.
///
/// Returns `-1` if the `value` is not in the list. Requires the list items
/// to implement [Comparable] and the `sortedList` to already be ordered.
int binarySearch<T extends Comparable<Object>>(List<T> sortedList, T value) {
  int min = 0;
  int max = sortedList.length;
  while (min < max) {
    final int mid = min + ((max - min) >> 1);
    final T element = sortedList[mid];
    final int comp = element.compareTo(value);
    if (comp == 0) {
      return mid;
    }
    if (comp < 0) {
      min = mid + 1;
    } else {
      max = mid;
    }
  }
  return -1;
}

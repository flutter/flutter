// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns `true` if a and b contain equal elements in the same order.
bool listsEqual(List a, List b) {
  // TODO(rnystrom): package:collection also implements this, and analyzer
  // already transitively depends on that package. Consider using it instead.
  if (identical(a, b)) {
    return true;
  }

  if (a.length != b.length) {
    return false;
  }

  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }

  return true;
}

/// Methods for operating on integers as if they were arrays of booleans. These
/// arrays can be indexed by either integers or by enumeration constants.
class BooleanArray {
  /// Return the value of the element of the given [array] at the given [index].
  static bool get(int array, int index) {
    _checkIndex(index);
    return (array & (1 << index)) > 0;
  }

  /// Set the value of the element of the given [array] at the given [index] to
  /// the given [value].
  static int set(int array, int index, bool value) {
    _checkIndex(index);
    if (value) {
      return array | (1 << index);
    } else {
      return array & ~(1 << index);
    }
  }

  /// Throw an exception if the index is not within the bounds allowed for an
  /// integer-encoded array of boolean values.
  static void _checkIndex(int index) {
    if (index < 0 || index > 30) {
      throw RangeError("Index not between 0 and 30: $index");
    }
  }
}

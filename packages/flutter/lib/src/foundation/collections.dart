// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(ianh): These should be on the Set and List classes themselves.

/// Compares two sets for deep equality.
///
/// Returns true if the sets are both null, or if they are both non-null, have
/// the same length, and contain the same members. Returns false otherwise.
/// Order is not compared.
///
/// See also:
///
///   * [listEquals], which does something similar for lists.
bool setEquals<T>(Set<T> a, Set<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
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
/// See also:
///
///   * [setEquals], which does something similar for sets.
bool listEquals<T>(List<T> a, List<T> b) {
  if (a == null)
    return b == null;
  if (b == null || a.length != b.length)
    return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index])
      return false;
  }
  return true;
}

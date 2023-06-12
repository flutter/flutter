// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities that shouldn't be in this package.
library source_maps.utils;

/// Find the first entry in a sorted [list] that matches a monotonic predicate.
/// Given a result `n`, that all items before `n` will not match, `n` matches,
/// and all items after `n` match too. The result is -1 when there are no
/// items, 0 when all items match, and list.length when none does.
// TODO(sigmund): remove this function after dartbug.com/5624 is fixed.
int binarySearch(List list, bool Function(dynamic) matches) {
  if (list.isEmpty) return -1;
  if (matches(list.first)) return 0;
  if (!matches(list.last)) return list.length;

  var min = 0;
  var max = list.length - 1;
  while (min < max) {
    var half = min + ((max - min) ~/ 2);
    if (matches(list[half])) {
      max = half;
    } else {
      min = half + 1;
    }
  }
  return max;
}

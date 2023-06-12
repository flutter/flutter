// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Call [f] for each corresponding pair of elements from [list1] and [list2].
///
/// If one of the lists has less elements than other, the remainder is ignored.
void forCorrespondingPairs<T1, T2>(
  List<T1> list1,
  List<T2> list2,
  void Function(T1, T2) f,
) {
  var i1 = list1.iterator;
  var i2 = list2.iterator;
  while (i1.moveNext() && i2.moveNext()) {
    f(i1.current, i2.current);
  }
}

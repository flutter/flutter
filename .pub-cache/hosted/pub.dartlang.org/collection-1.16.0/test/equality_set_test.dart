// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('uses the given equality', () {
    var set = EqualitySet(const IterableEquality());
    expect(set, isEmpty);

    var list1 = [1, 2, 3];
    expect(set.add(list1), isTrue);
    expect(set, contains([1, 2, 3]));
    expect(set, contains(same(list1)));

    var list2 = [1, 2, 3];
    expect(set.add(list2), isFalse);
    expect(set, contains([1, 2, 3]));
    expect(set, contains(same(list1)));
    expect(set, isNot(contains(same(list2))));

    var list3 = [2, 3, 4];
    expect(set.add(list3), isTrue);
    expect(set, contains(same(list1)));
    expect(set, contains(same(list3)));
  });

  test('EqualitySet.from() prefers the lattermost equivalent value', () {
    var list1 = [1, 2, 3];
    var list2 = [2, 3, 4];
    var list3 = [1, 2, 3];
    var list4 = [2, 3, 4];
    var list5 = [1, 2, 3];
    var list6 = [1, 2, 3];

    var set = EqualitySet.from(
        const IterableEquality(), [list1, list2, list3, list4, list5, list6]);

    expect(set, contains(same(list1)));
    expect(set, contains(same(list2)));
    expect(set, isNot(contains(same(list3))));
    expect(set, isNot(contains(same(list4))));
    expect(set, isNot(contains(same(list5))));
    expect(set, isNot(contains(same(list6))));
  });
}

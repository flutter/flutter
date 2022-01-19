// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web identity set behaves like a regular Dart set', () {
    final Set<int> set = createIdentitySet();
    set.add(1);
    set.add(2);
    set.add(3);

    expect(set.contains(1), isTrue);
    expect(set.contains(2), isTrue);
    expect(set.contains(3), isTrue);
    expect(set.contains(4), isFalse);
  });

  test('Web identity set can remove items', () {
    final Set<int> set = createIdentitySet();
    set.add(1);

    expect(set.contains(1), isTrue);
    expect(set.remove(1), isTrue);
    expect(set.contains(1), isFalse);
  });

  test('Web identity set can iterate through items', () {
    final Set<int> set = createIdentitySet();
    set.add(1);
    set.add(2);
    set.add(3);

    expect(set.toList(), unorderedEquals(<int>[1, 2, 3]));
  });

  test('Web identity map behaves like a regular Dart map', () {
    final Map<int, int> map = createIdentityMap();
    map[1] = 100;
    map[2] = 200;
    map[3] = 300;

    expect(map.containsKey(1), isTrue);
    expect(map.containsKey(2), isTrue);
    expect(map.containsKey(3), isTrue);
    expect(map.containsKey(4), isFalse);

    expect(map.containsValue(100), isTrue);
    expect(map.containsValue(200), isTrue);
    expect(map.containsValue(300), isTrue);
    expect(map.containsValue(400), isFalse);
  });

  test('Web identity map can iterate through items', () {
    final Map<int, int> map = createIdentityMap();
    map[1] = 100;
    map[2] = 200;
    map[3] = 300;

    expect(map.keys.toList(), unorderedEquals(<int>[1, 2, 3]));
    expect(map.values.toList(), unorderedEquals(<int>[100, 200, 300]));
  });

  test('Web identity map can remove items', () {
   final Map<int, int> map = createIdentityMap();
    map[1] = 100;

    expect(map.containsKey(1), isTrue);
    expect(map.remove(1), 100);
    expect(map.containsKey(1), isFalse);
  });
}

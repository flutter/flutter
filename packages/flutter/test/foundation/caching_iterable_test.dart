// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

int yieldCount = 0;

Iterable<int> range(int start, int end) sync* {
  assert(yieldCount == 0);
  for (int index = start; index <= end; index += 1) {
    yieldCount += 1;
    yield index;
  }
}

void main() {
  setUp(() {
    yieldCount = 0;
  });

  test('The Caching Iterable: length caches', () {
    final Iterable<int> i = CachingIterable<int>(range(1, 5).iterator);
    expect(yieldCount, equals(0));
    expect(i.length, equals(5));
    expect(yieldCount, equals(5));

    expect(i.length, equals(5));
    expect(yieldCount, equals(5));

    expect(i.last, equals(5));
    expect(yieldCount, equals(5));

    expect(i, equals(<int>[1, 2, 3, 4, 5]));
    expect(yieldCount, equals(5));
  });

  test('The Caching Iterable: laziness', () {
    final Iterable<int> i = CachingIterable<int>(range(1, 5).iterator);
    expect(yieldCount, equals(0));

    expect(i.first, equals(1));
    expect(yieldCount, equals(1));

    expect(i.firstWhere((int i) => i == 3), equals(3));
    expect(yieldCount, equals(3));

    expect(i.last, equals(5));
    expect(yieldCount, equals(5));
  });

  test('The Caching Iterable: where and map', () {
    final Iterable<int> integers = CachingIterable<int>(range(1, 5).iterator);
    expect(yieldCount, equals(0));

    final Iterable<int> evens = integers.where((int i) => i.isEven);
    expect(yieldCount, equals(0));

    expect(evens.first, equals(2));
    expect(yieldCount, equals(2));

    expect(integers.first, equals(1));
    expect(yieldCount, equals(2));

    expect(evens.map<int>((int i) => i + 1), equals(<int>[3, 5]));
    expect(yieldCount, equals(5));

    expect(evens, equals(<int>[2, 4]));
    expect(yieldCount, equals(5));

    expect(integers, equals(<int>[1, 2, 3, 4, 5]));
    expect(yieldCount, equals(5));
  });

  test('The Caching Iterable: take and skip', () {
    final Iterable<int> integers = CachingIterable<int>(range(1, 5).iterator);
    expect(yieldCount, equals(0));

    final Iterable<int> secondTwo = integers.skip(1).take(2);

    expect(yieldCount, equals(0));
    expect(secondTwo, equals(<int>[2, 3]));
    expect(yieldCount, equals(3));

    final Iterable<int> result = integers.takeWhile((int i) => i < 4).skipWhile((int i) => i < 3);

    expect(result, equals(<int>[3]));
    expect(yieldCount, equals(4));
    expect(integers, equals(<int>[1, 2, 3, 4, 5]));
    expect(yieldCount, equals(5));
  });

  test('The Caching Iterable: expand', () {
    final Iterable<int> integers = CachingIterable<int>(range(1, 5).iterator);
    expect(yieldCount, equals(0));

    final Iterable<int> expanded1 = integers.expand<int>((int i) => <int>[i, i]);

    expect(yieldCount, equals(0));
    expect(expanded1, equals(<int>[1, 1, 2, 2, 3, 3, 4, 4, 5, 5]));
    expect(yieldCount, equals(5));

    final Iterable<int> expanded2 = integers.expand<int>((int i) => <int>[i, i]);

    expect(yieldCount, equals(5));
    expect(expanded2, equals(<int>[1, 1, 2, 2, 3, 3, 4, 4, 5, 5]));
    expect(yieldCount, equals(5));
  });

  test('The Caching Iterable: elementAt correctness', () {
    final Iterable<int> integers = CachingIterable<int>(range(1, 5).iterator);
    expect(yieldCount, equals(0));

    expect(() => integers.elementAt(-1), throwsRangeError);

    expect(integers.elementAt(1), equals(2));
    expect(integers.elementAt(0), equals(1));
    expect(integers.elementAt(2), equals(3));
    expect(integers.elementAt(4), equals(5));
    expect(integers.elementAt(3), equals(4));

    expect(() => integers.elementAt(5), throwsRangeError);
  });
}

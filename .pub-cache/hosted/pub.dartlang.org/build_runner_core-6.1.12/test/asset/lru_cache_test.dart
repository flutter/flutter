// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_runner_core/src/asset/lru_cache.dart';

void main() {
  LruCache<String, int> cache;
  final maxIndividualWeight = 10;
  final maxTotalWeight = 100;

  setUp(() {
    cache = LruCache(maxIndividualWeight, maxTotalWeight, (v) => v);
  });

  test('can cache values', () {
    cache['a'] = 1;
    cache['b'] = 2;
    expect(cache['a'], 1);
    expect(cache['b'], 2);
  });

  test('can remove entries by key', () {
    cache['a'] = 1;
    cache['b'] = 2;
    cache.remove('b');
    expect(cache['a'], 1);
    expect(cache['b'], null);
  });

  test('doesnt cache values over the max individual weight', () {
    cache['a'] = maxIndividualWeight;
    expect(cache['a'], maxIndividualWeight);

    cache['b'] = maxIndividualWeight + 1;
    expect(cache['b'], null);
  });

  test('removes least recently used items when full', () {
    // Populate the cache until full.
    var total = 0;
    var n = 0;
    while (total + maxIndividualWeight <= maxTotalWeight) {
      total += maxIndividualWeight;
      cache['$n'] = maxIndividualWeight;
      n++;
    }
    // Read all the items in order, the first is now the least recently used.
    for (var i = 0; i < n; i++) {
      expect(cache['$i'], maxIndividualWeight);
    }

    // Add another item, the first item should now be removed.
    cache['${n++}'] = maxIndividualWeight;
    expect(cache['0'], null);

    // Read the 2nd/3rd item, and add 2 new items. The 4rd/5th should now be
    // removed.
    expect(cache['1'], maxIndividualWeight);
    expect(cache['2'], maxIndividualWeight);
    cache['${n++}'] = maxIndividualWeight;
    cache['${n++}'] = maxIndividualWeight;
    expect(cache['1'], maxIndividualWeight);
    expect(cache['2'], maxIndividualWeight);
    expect(cache['3'], null);
    expect(cache['4'], null);
  });
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:ui/src/engine.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CrossFrameCache', () {
    test('Reuse returns no object when cache empty', () {
      final CrossFrameCache<TestItem> cache = CrossFrameCache();
      cache.commitFrame();
      TestItem requestedItem = cache.reuse('item1');
      expect(requestedItem, null);
    });

    test('Reuses object across frames', () {
      final CrossFrameCache<TestItem> cache = CrossFrameCache();
      final TestItem testItem1 = TestItem('item1');
      cache.cache(testItem1.label, testItem1);
      cache.commitFrame();
      TestItem requestedItem = cache.reuse('item1');
      expect(requestedItem, testItem1);
      requestedItem = cache.reuse('item1');
      expect(requestedItem, null);
    });

    test('Reuses objects that have same key across frames', () {
      final CrossFrameCache<TestItem> cache = CrossFrameCache();
      final TestItem testItem1 = TestItem('sameLabel');
      final TestItem testItem2 = TestItem('sameLabel');
      final TestItem testItemX = TestItem('X');
      cache.cache(testItem1.label, testItem1);
      cache.cache(testItemX.label, testItemX);
      cache.cache(testItem2.label, testItem2);
      cache.commitFrame();
      TestItem requestedItem = cache.reuse('sameLabel');
      expect(requestedItem, testItem1);
      requestedItem = cache.reuse('sameLabel');
      expect(requestedItem, testItem2);
      requestedItem = cache.reuse('sameLabel');
      expect(requestedItem, null);
    });

    test('Values don\'t survive beyond next frame', () {
      final CrossFrameCache<TestItem> cache = CrossFrameCache();
      final TestItem testItem1 = TestItem('item1');
      cache.cache(testItem1.label, testItem1);
      cache.commitFrame();
      cache.commitFrame();
      TestItem requestedItem = cache.reuse('item1');
      expect(requestedItem, null);
    });

    test('Values are evicted when not reused', () {
      final Set<TestItem> _evictedItems = {};
      final CrossFrameCache<TestItem> cache = CrossFrameCache();
      final TestItem testItem1 = TestItem('item1');
      final TestItem testItem2 = TestItem('item2');
      cache.cache(testItem1.label, testItem1, (TestItem item) {_evictedItems.add(item);});
      cache.cache(testItem2.label, testItem2, (TestItem item) {_evictedItems.add(item);});
      cache.commitFrame();
      expect(_evictedItems.length, 0);
      cache.reuse('item2');
      cache.commitFrame();
      expect(_evictedItems.contains(testItem1), true);
      expect(_evictedItems.contains(testItem2), false);
    });
  });
}

class TestItem {
  final String label;
  TestItem(this.label);
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/utils.dart';

import '../src/common.dart';

void main() {
  group('ItemListNotifier', () {
    test('sends notifications', () async {
      final ItemListNotifier<String> list = ItemListNotifier<String>();
      expect(list.items, isEmpty);

      final Future<List<String>> addedStreamItems = list.onAdded.toList();
      final Future<List<String>> removedStreamItems = list.onRemoved.toList();

      list.updateWithNewList(<String>['aaa']);
      list.removeItem('bogus');
      list.updateWithNewList(<String>['aaa', 'bbb', 'ccc']);
      list.updateWithNewList(<String>['bbb', 'ccc']);
      list.removeItem('bbb');

      expect(list.items, <String>['ccc']);
      list.dispose();

      final List<String> addedItems = await addedStreamItems;
      final List<String> removedItems = await removedStreamItems;

      expect(addedItems.length, 3);
      expect(addedItems.first, 'aaa');
      expect(addedItems[1], 'bbb');
      expect(addedItems[2], 'ccc');

      expect(removedItems.length, 2);
      expect(removedItems.first, 'aaa');
      expect(removedItems[1], 'bbb');
    });
  });
}

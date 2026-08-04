// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:flutter_tools/src/base/utils.dart';

import '../src/common.dart';

void main() {
  group('ItemListNotifier', () {
    test('sends notifications', () async {
      final list = ItemListNotifier<String>();
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

    test('becomes populated when item is added', () async {
      final list = ItemListNotifier<String>();
      expect(list.isPopulated, false);
      expect(list.items, isEmpty);

      // Becomes populated when a new list is added.
      list.updateWithNewList(<String>['a']);
      expect(list.isPopulated, true);
      expect(list.items, <String>['a']);

      // Remain populated even when the last item is removed.
      list.removeItem('a');
      expect(list.isPopulated, true);
      expect(list.items, isEmpty);
    });

    test('is populated by default if initialized with list of items', () async {
      final list = ItemListNotifier<String>.from(<String>['a']);
      expect(list.isPopulated, true);
      expect(list.items, <String>['a']);
    });
  });

  group('decodeUtf8OrUtf16', () {
    test('decodes UTF-8 without BOM', () {
      expect(decodeUtf8OrUtf16(utf8.encode('hello world')), 'hello world');
    });

    test('decodes UTF-8 with BOM', () {
      expect(
        decodeUtf8OrUtf16(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode('hello world')]),
        'hello world',
      );
    });

    test('decodes UTF-16 LE with BOM', () {
      final bytes = <int>[0xFF, 0xFE, 0x68, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x6F, 0x00];
      expect(decodeUtf8OrUtf16(bytes), 'hello');
    });

    test('decodes UTF-16 BE with BOM', () {
      final bytes = <int>[0xFE, 0xFF, 0x00, 0x68, 0x00, 0x65, 0x00, 0x6C, 0x00, 0x6C, 0x00, 0x6F];
      expect(decodeUtf8OrUtf16(bytes), 'hello');
    });

    test('throws FormatException on odd-length UTF-16 LE payload', () {
      final bytes = <int>[0xFF, 0xFE, 0x68];
      expect(() => decodeUtf8OrUtf16(bytes), throwsFormatException);
    });

    test('throws FormatException on odd-length UTF-16 BE payload', () {
      final bytes = <int>[0xFE, 0xFF, 0x68];
      expect(() => decodeUtf8OrUtf16(bytes), throwsFormatException);
    });

    test('throws FormatException on invalid UTF-8 bytes', () {
      expect(() => decodeUtf8OrUtf16(<int>[0xFF, 0xFF, 0xFF]), throwsFormatException);
    });
  });
}

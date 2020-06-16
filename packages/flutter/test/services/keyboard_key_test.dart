// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(PhysicalKeyboardKey, () {
    test('Various classes of keys can be looked up by code.', () async {
      // Check a letter key
      expect(PhysicalKeyboardKey.findKeyByCode(0x00070004), equals(PhysicalKeyboardKey.keyA));
      // Check a control key
      expect(PhysicalKeyboardKey.findKeyByCode(0x00070029), equals(PhysicalKeyboardKey.escape));
      // Check a modifier key
      expect(PhysicalKeyboardKey.findKeyByCode(0x000700e1), equals(PhysicalKeyboardKey.shiftLeft));
    });
    test('Equality is only based on HID code.', () async {
      const PhysicalKeyboardKey key1 = PhysicalKeyboardKey(0x01, debugName: 'key1');
      const PhysicalKeyboardKey key2 = PhysicalKeyboardKey(0x01, debugName: 'key2');
      expect(key1, equals(key1));
      expect(key1, equals(key2));
    });
  });
  group(LogicalKeyboardKey, () {
    test('Various classes of keys can be looked up by code', () async {
      // Check a letter key
      expect(LogicalKeyboardKey.findKeyByKeyId(0x0000000061), equals(LogicalKeyboardKey.keyA));
      // Check a control key
      expect(LogicalKeyboardKey.findKeyByKeyId(0x0100070029), equals(LogicalKeyboardKey.escape));
      // Check a modifier key
      expect(LogicalKeyboardKey.findKeyByKeyId(0x01000700e1), equals(LogicalKeyboardKey.shiftLeft));
    });
    test('Control characters are recognized as such', () async {
      // Check some common control characters
      expect(LogicalKeyboardKey.isControlCharacter('\x08'), isTrue); // BACKSPACE
      expect(LogicalKeyboardKey.isControlCharacter('\x0a'), isTrue); // LINE FEED
      expect(LogicalKeyboardKey.isControlCharacter('\x0d'), isTrue); // RETURN
      expect(LogicalKeyboardKey.isControlCharacter('\x1b'), isTrue); // ESC
      expect(LogicalKeyboardKey.isControlCharacter('\x7f'), isTrue); // DELETE
      // Check non-control characters
      expect(LogicalKeyboardKey.isControlCharacter('A'), isFalse);
      expect(LogicalKeyboardKey.isControlCharacter(' '), isFalse);
      expect(LogicalKeyboardKey.isControlCharacter('~'), isFalse);
      expect(LogicalKeyboardKey.isControlCharacter('\xa0'), isFalse); // NO-BREAK SPACE
    });
    test('Equality is only based on ID.', () async {
      const LogicalKeyboardKey key1 = LogicalKeyboardKey(0x01, keyLabel: 'label1', debugName: 'key1');
      const LogicalKeyboardKey key2 = LogicalKeyboardKey(0x01, keyLabel: 'label2', debugName: 'key2');
      expect(key1, equals(key1));
      expect(key1, equals(key2));
    });
    test('Basic synonyms can be looked up.', () async {
      expect(LogicalKeyboardKey.shiftLeft.synonyms.first, equals(LogicalKeyboardKey.shift));
      expect(LogicalKeyboardKey.controlLeft.synonyms.first, equals(LogicalKeyboardKey.control));
      expect(LogicalKeyboardKey.altLeft.synonyms.first, equals(LogicalKeyboardKey.alt));
      expect(LogicalKeyboardKey.metaLeft.synonyms.first, equals(LogicalKeyboardKey.meta));
      expect(LogicalKeyboardKey.shiftRight.synonyms.first, equals(LogicalKeyboardKey.shift));
      expect(LogicalKeyboardKey.controlRight.synonyms.first, equals(LogicalKeyboardKey.control));
      expect(LogicalKeyboardKey.altRight.synonyms.first, equals(LogicalKeyboardKey.alt));
      expect(LogicalKeyboardKey.metaRight.synonyms.first, equals(LogicalKeyboardKey.meta));
    });
    test('Synonyms get collapsed properly.', () async {
      expect(LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{}), isEmpty);
      expect(
          LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.metaLeft,
          }),
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.meta,
          }));
      expect(
          LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.metaRight,
          }),
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.meta,
          }));
      expect(
          LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{
            LogicalKeyboardKey.shiftLeft,
            LogicalKeyboardKey.controlLeft,
            LogicalKeyboardKey.altLeft,
            LogicalKeyboardKey.metaLeft,
            LogicalKeyboardKey.shiftRight,
            LogicalKeyboardKey.controlRight,
            LogicalKeyboardKey.altRight,
            LogicalKeyboardKey.metaRight,
          }),
          equals(<LogicalKeyboardKey>{
            LogicalKeyboardKey.shift,
            LogicalKeyboardKey.control,
            LogicalKeyboardKey.alt,
            LogicalKeyboardKey.meta,
          }));
    });
  });
}

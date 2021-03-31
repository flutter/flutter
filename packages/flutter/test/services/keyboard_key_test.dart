// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
    test('Values are equal', () async {
      expect(PhysicalKeyboardKey.keyA == PhysicalKeyboardKey(PhysicalKeyboardKey.keyA.usbHidUsage), true);
      // ignore: prefer_const_constructors, intentionally test if a const key is equal to a non-const key
      expect(const PhysicalKeyboardKey(0x12345) == PhysicalKeyboardKey(0x12345), true);
    });
    test('debugNames', () async {
      expect(PhysicalKeyboardKey.keyA.debugName, 'Key A');
      expect(PhysicalKeyboardKey.backslash.debugName, 'Backslash');
      expect(const PhysicalKeyboardKey(0x12345).debugName, 'Key with ID 0x00012345');
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
    test('Values are equal', () async {
      expect(LogicalKeyboardKey.keyA == LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId), true);
      // ignore: prefer_const_constructors, intentionally test if a const key is equal to a non-const key
      expect(const PhysicalKeyboardKey(0x12345) == PhysicalKeyboardKey(0x12345), true);
    });
    test('keyLabel', () async {
      expect(LogicalKeyboardKey.keyA.keyLabel, 'A');
      expect(LogicalKeyboardKey.backslash.keyLabel, r'\');
      expect(const LogicalKeyboardKey(0xD9).keyLabel, 'Ù');
      expect(const LogicalKeyboardKey(0xF9).keyLabel, 'Ù');
      expect(LogicalKeyboardKey.shiftLeft.keyLabel, 'Shift Left');
      expect(LogicalKeyboardKey.numpadDecimal.keyLabel, 'Numpad Decimal');
      expect(LogicalKeyboardKey.numpad1.keyLabel, 'Numpad 1');
      expect(LogicalKeyboardKey.delete.keyLabel, 'Delete');
      expect(LogicalKeyboardKey.f12.keyLabel, 'F12');
      expect(LogicalKeyboardKey.mediaPlay.keyLabel, 'Media Play');
      expect(const LogicalKeyboardKey(0x100012345).keyLabel, '');
    });
    test('debugName', () async {
      expect(LogicalKeyboardKey.keyA.debugName, 'Key A');
      expect(LogicalKeyboardKey.backslash.debugName, 'Backslash');
      expect(const LogicalKeyboardKey(0xD9).debugName, 'Key Ù');
      expect(LogicalKeyboardKey.mediaPlay.debugName, 'Media Play');
      expect(const LogicalKeyboardKey(0x100012345).debugName, 'Key with ID 0x00100012345');
    });
  });
}

// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';

void main() {
  group('FontWeight.lerp', () {
    test('works with non-null values', () {
      expect(FontWeight.lerp(FontWeight.w400, FontWeight.w600, .5), equals(FontWeight.w500));
    });

    test('returns null if a and b are null', () {
      expect(FontWeight.lerp(null, null, 0), isNull);
    });

    test('returns FontWeight.w400 if a is null', () {
      expect(FontWeight.lerp(null, FontWeight.w400, 0), equals(FontWeight.w400));
    });

    test('returns FontWeight.w400 if b is null', () {
      expect(FontWeight.lerp(FontWeight.w400, null, 1), equals(FontWeight.w400));
    });
  });
  group('TextRange', () {
    test('empty ranges are correct', () {
      const TextRange range = TextRange(start: -1, end: -1);
      expect(range, equals(const TextRange.collapsed(-1)));
      expect(range, equals(TextRange.empty));
    });
    test('isValid works', () {
      expect(TextRange.empty.isValid, isFalse);
      expect(const TextRange(start: 0, end: 0).isValid, isTrue);
      expect(const TextRange(start: 0, end: 10).isValid, isTrue);
      expect(const TextRange(start: 10, end: 10).isValid, isTrue);
      expect(const TextRange(start: -1, end: 10).isValid, isFalse);
      expect(const TextRange(start: 10, end: 0).isValid, isTrue);
      expect(const TextRange(start: 10, end: -1).isValid, isFalse);
    });
    test('isCollapsed works', () {
      expect(TextRange.empty.isCollapsed, isTrue);
      expect(const TextRange(start: 0, end: 0).isCollapsed, isTrue);
      expect(const TextRange(start: 0, end: 10).isCollapsed, isFalse);
      expect(const TextRange(start: 10, end: 10).isCollapsed, isTrue);
      expect(const TextRange(start: -1, end: 10).isCollapsed, isFalse);
      expect(const TextRange(start: 10, end: 0).isCollapsed, isFalse);
      expect(const TextRange(start: 10, end: -1).isCollapsed, isFalse);
    });
    test('isNormalized works', () {
      expect(TextRange.empty.isNormalized, isTrue);
      expect(const TextRange(start: 0, end: 0).isNormalized, isTrue);
      expect(const TextRange(start: 0, end: 10).isNormalized, isTrue);
      expect(const TextRange(start: 10, end: 10).isNormalized, isTrue);
      expect(const TextRange(start: -1, end: 10).isNormalized, isTrue);
      expect(const TextRange(start: 10, end: 0).isNormalized, isFalse);
      expect(const TextRange(start: 10, end: -1).isNormalized, isFalse);
    });
    test('textBefore works', () {
      expect(const TextRange(start: 0, end: 0).textBefore('hello'), isEmpty);
      expect(const TextRange(start: 1, end: 1).textBefore('hello'), equals('h'));
      expect(const TextRange(start: 1, end: 2).textBefore('hello'), equals('h'));
      expect(const TextRange(start: 5, end: 5).textBefore('hello'), equals('hello'));
      expect(const TextRange(start: 0, end: 5).textBefore('hello'), isEmpty);
    });
    test('textAfter works', () {
      expect(const TextRange(start: 0, end: 0).textAfter('hello'), equals('hello'));
      expect(const TextRange(start: 1, end: 1).textAfter('hello'), equals('ello'));
      expect(const TextRange(start: 1, end: 2).textAfter('hello'), equals('llo'));
      expect(const TextRange(start: 5, end: 5).textAfter('hello'), isEmpty);
      expect(const TextRange(start: 0, end: 5).textAfter('hello'), isEmpty);
    });
    test('textInside works', () {
      expect(const TextRange(start: 0, end: 0).textInside('hello'), isEmpty);
      expect(const TextRange(start: 1, end: 1).textInside('hello'), isEmpty);
      expect(const TextRange(start: 1, end: 2).textInside('hello'), equals('e'));
      expect(const TextRange(start: 5, end: 5).textInside('hello'), isEmpty);
      expect(const TextRange(start: 0, end: 5).textInside('hello'), equals('hello'));
    });
  });
  group('loadFontFromList', () {
    test('will send platform message after font is loaded', () async {
      final PlatformMessageCallback oldHandler = window.onPlatformMessage;
      String actualName;
      String message;
      window.onPlatformMessage = (String name, ByteData data, PlatformMessageResponseCallback callback) {
        actualName = name;
        final Uint8List list = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        message = utf8.decode(list);
      };
      final Uint8List fontData = Uint8List(0);
      await loadFontFromList(fontData, fontFamily: 'fake');
      window.onPlatformMessage = oldHandler;
      expect(actualName, 'flutter/system');
      expect(message, '{"type":"fontsChange"}');
    });
  });
}

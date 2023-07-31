// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

void main() {
  group('with ascii = false', () {
    setUpAll(() {
      glyph.ascii = false;
    });

    test('glyph getters return Unicode versions', () {
      expect(glyph.topLeftCorner, equals('┌'));
      expect(glyph.teeUpBold, equals('┻'));
      expect(glyph.longLeftArrow, equals('◀━'));
    });

    test('glyphOrAscii returns the first argument', () {
      expect(glyph.glyphOrAscii('A', 'B'), equals('A'));
    });

    test('glyphs returns unicodeGlyphs', () {
      expect(glyph.glyphs, equals(glyph.unicodeGlyphs));
    });

    test('asciiGlyphs still returns ASCII characters', () {
      expect(glyph.asciiGlyphs.topLeftCorner, equals(','));
      expect(glyph.asciiGlyphs.teeUpBold, equals('+'));
      expect(glyph.asciiGlyphs.longLeftArrow, equals('<='));
    });
  });

  group('with ascii = true', () {
    setUpAll(() {
      glyph.ascii = true;
    });

    test('glyphs return ASCII versions', () {
      expect(glyph.topLeftCorner, equals(','));
      expect(glyph.teeUpBold, equals('+'));
      expect(glyph.longLeftArrow, equals('<='));
    });

    test('glyphOrAscii returns the second argument', () {
      expect(glyph.glyphOrAscii('A', 'B'), equals('B'));
    });

    test('glyphs returns asciiGlyphs', () {
      expect(glyph.glyphs, equals(glyph.asciiGlyphs));
    });

    test('unicodeGlyphs still returns Unicode characters', () {
      expect(glyph.unicodeGlyphs.topLeftCorner, equals('┌'));
      expect(glyph.unicodeGlyphs.teeUpBold, equals('┻'));
      expect(glyph.unicodeGlyphs.longLeftArrow, equals('◀━'));
    });
  });
}

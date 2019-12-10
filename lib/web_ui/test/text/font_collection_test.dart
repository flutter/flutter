// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:ui/src/engine.dart';

import 'package:test/test.dart';

void main() {
  group('$FontManager', () {
    FontManager fontManager;
    const String _testFontUrl = 'packages/ui/assets/ahem.ttf';

    setUp(() {
      fontManager = FontManager();
    });

    tearDown(() {
      html.document.fonts.clear();
    });

    test('Register Asset with no special characters', () async {
      final String _testFontFamily = "Ahem";
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(1));
      expect(fontFamilyList.first, 'Ahem');
    });

    test('Register Asset with white space in the family name', () async {
      final String _testFontFamily = "Ahem ahem ahem";
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(1));
      expect(fontFamilyList.first, 'Ahem ahem ahem');
    });

    test('Register Asset with capital case letters', () async {
      final String _testFontFamily = "AhEm";
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(1));
      expect(fontFamilyList.first, 'AhEm');
    });

    test('Register Asset twice with special character slash', () async {
      final String _testFontFamily = '/Ahem';
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(2));
      expect(fontFamilyList, contains('\'/Ahem\''));
      expect(fontFamilyList, contains('/Ahem'));
    }, skip: (browserEngine == BrowserEngine.firefox));

    test('Register Asset twice with exclamation mark', () async {
      final String _testFontFamily = 'Ahem!!ahem';
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(2));
      expect(fontFamilyList, contains('\'Ahem!!ahem\''));
      expect(fontFamilyList, contains('Ahem!!ahem'));
    }, skip: (browserEngine == BrowserEngine.firefox));

    test('Register Asset twice with coma', () async {
      final String _testFontFamily = 'Ahem ,ahem';
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(2));
      expect(fontFamilyList, contains('\'Ahem ,ahem\''));
      expect(fontFamilyList, contains('Ahem ,ahem'));
    }, // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
        skip: (browserEngine == BrowserEngine.firefox));

    test('Register Asset twice with a digit at the start of a token', () async {
      final String testFontFamily = 'Ahem 1998';
      final List<String> fontFamilyList = List<String>();

      fontManager.registerAsset(
          testFontFamily, 'url($_testFontUrl)', const <String, String>{});
      await fontManager.ensureFontsLoaded();
      html.document.fonts
          .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
        fontFamilyList.add(f.family);
      });

      expect(fontFamilyList.length, equals(2));
      expect(fontFamilyList, contains('Ahem 1998'));
      expect(fontFamilyList, contains('\'Ahem 1998\''));
    });
  }, // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      skip: (browserEngine == BrowserEngine.firefox));
}

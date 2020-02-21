// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
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

    group('regular special characters', () {
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
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          skip: browserEngine == BrowserEngine.edge);

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
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          // TODO(nurhan): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.edge ||
              browserEngine == BrowserEngine.webkit);

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
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          skip: browserEngine == BrowserEngine.edge);
    });

    group('fonts with special characters', () {
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

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains('\'/Ahem\''));
          expect(fontFamilyList, contains('/Ahem'));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '\"/Ahem\"');
        }
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          // TODO(nurhan): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.edge ||
              browserEngine == BrowserEngine.webkit);

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

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains('\'Ahem!!ahem\''));
          expect(fontFamilyList, contains('Ahem!!ahem'));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '\"Ahem!!ahem\"');
        }
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          // TODO(nurhan): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.edge ||
              browserEngine == BrowserEngine.webkit);

      test('Register Asset twice with comma', () async {
        final String _testFontFamily = 'Ahem ,ahem';
        final List<String> fontFamilyList = List<String>();

        fontManager.registerAsset(
            _testFontFamily, 'url($_testFontUrl)', const <String, String>{});
        await fontManager.ensureFontsLoaded();
        html.document.fonts
            .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
          fontFamilyList.add(f.family);
        });

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains('\'Ahem ,ahem\''));
          expect(fontFamilyList, contains('Ahem ,ahem'));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '\"Ahem ,ahem\"');
        }
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          // TODO(nurhan): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.edge ||
              browserEngine == BrowserEngine.webkit);

      test('Register Asset twice with a digit at the start of a token',
          () async {
        final String testFontFamily = 'Ahem 1998';
        final List<String> fontFamilyList = List<String>();

        fontManager.registerAsset(
            testFontFamily, 'url($_testFontUrl)', const <String, String>{});
        await fontManager.ensureFontsLoaded();
        html.document.fonts
            .forEach((html.FontFace f, html.FontFace f2, html.FontFaceSet s) {
          fontFamilyList.add(f.family);
        });

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains('Ahem 1998'));
          expect(fontFamilyList, contains('\'Ahem 1998\''));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '\"Ahem 1998\"');
        }
      },
          // TODO(nurhan): https://github.com/flutter/flutter/issues/50770
          // TODO(nurhan): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.edge ||
              browserEngine == BrowserEngine.webkit);
    });
  });
}

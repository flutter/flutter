// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$FontManager', () {
    late FontManager fontManager;
    const String testFontUrl = '/assets/fonts/ahem.ttf';

    setUp(() {
      fontManager = FontManager();
    });

    tearDown(() {
      domDocument.fonts!.clear();
    });

    group('regular special characters', () {
      test('Register Asset with no special characters', () async {
        const String testFontFamily = 'Ahem';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'Ahem');
      });

      test('Register Asset with white space in the family name', () async {
        const String testFontFamily = 'Ahem ahem ahem';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'Ahem ahem ahem');
      },
          // TODO(mdebbar): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.webkit);

      test('Register Asset with capital case letters', () async {
        const String testFontFamily = 'AhEm';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'AhEm');
      });
    });

    group('fonts with special characters', () {
      test('Register Asset twice with special character slash', () async {
        const String testFontFamily = '/Ahem';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains("'/Ahem'"));
          expect(fontFamilyList, contains('/Ahem'));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '"/Ahem"');
        }
      },
          // TODO(mdebbar): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.webkit);

      test('Register Asset twice with exclamation mark', () async {
        const String testFontFamily = 'Ahem!!ahem';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains("'Ahem!!ahem'"));
          expect(fontFamilyList, contains('Ahem!!ahem'));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '"Ahem!!ahem"');
        }
      },
          // TODO(mdebbar): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.webkit);

      test('Register Asset twice with comma', () async {
        const String testFontFamily = 'Ahem ,ahem';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains("'Ahem ,ahem'"));
          expect(fontFamilyList, contains('Ahem ,ahem'));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '"Ahem ,ahem"');
        }
      },
          // TODO(mdebbar): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.webkit);

      test('Register Asset twice with a digit at the start of a token',
          () async {
        const String testFontFamily = 'Ahem 1998';
        final List<String> fontFamilyList = <String>[];

        fontManager.downloadAsset(
            testFontFamily, 'url($testFontUrl)', const <String, String>{});
        await fontManager.downloadAllFonts();
        fontManager.registerDownloadedFonts();
        domDocument.fonts!
            .forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        if (browserEngine != BrowserEngine.firefox) {
          expect(fontFamilyList.length, equals(2));
          expect(fontFamilyList, contains('Ahem 1998'));
          expect(fontFamilyList, contains("'Ahem 1998'"));
        } else {
          expect(fontFamilyList.length, equals(1));
          expect(fontFamilyList.first, '"Ahem 1998"');
        }
      },
          // TODO(mdebbar): https://github.com/flutter/flutter/issues/51142
          skip: browserEngine == BrowserEngine.webkit);
    });
  });
}

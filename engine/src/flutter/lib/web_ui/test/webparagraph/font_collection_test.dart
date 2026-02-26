// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

import '../common/fake_asset_manager.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$WebFontCollection', () {
    setUpUnitTests();

    const testFontUrl = '/assets/fonts/ahem.ttf';

    late FakeAssetScope testScope;
    setUp(() {
      testScope = fakeAssetManager.pushAssetScope();
      testScope.setAssetPassthrough(testFontUrl);

      // Clear the fonts before the test begins to wipe out the fonts from the
      // test initialization.
      domDocument.fonts!.clear();
    });

    tearDown(() {
      fakeAssetManager.popAssetScope(testScope);
    });

    group('regular special characters', () {
      test('Register Asset with no special characters', () async {
        const testFontFamily = 'Ahem';
        final fontFamilyList = <String>[];
        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'Ahem');
      });

      test('Register Asset with white space in the family name', () async {
        const testFontFamily = 'Ahem ahem ahem';
        final fontFamilyList = <String>[];

        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'Ahem ahem ahem');
      });

      test('Register Asset with capital case letters', () async {
        const testFontFamily = 'AhEm';
        final fontFamilyList = <String>[];

        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'AhEm');
      });

      test('Register Asset with descriptor', () async {
        const testFontFamily = 'Ahem';
        final fontFamilyList = <String>[];
        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[
              FontAsset(testFontUrl, <String, String>{'weight': 'bold'}),
            ]),
          ]),
        );

        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          expect(f.weight, 'bold');
          expect(f2.weight, 'bold');
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, 'Ahem');
      });
    });

    group('fonts with special characters', () {
      test('Register Asset once with special character slash', () async {
        const testFontFamily = '/Ahem';
        final fontFamilyList = <String>[];

        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, testFontFamily);
      });

      test('Register Asset once with exclamation mark', () async {
        const testFontFamily = 'Ahem!!ahem';
        final fontFamilyList = <String>[];

        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, testFontFamily);
      });

      test('Register Asset once with comma', () async {
        const testFontFamily = 'Ahem ,ahem';
        final fontFamilyList = <String>[];

        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, testFontFamily);
      });

      test('Register Asset once with a digit at the start of a token', () async {
        const testFontFamily = 'Ahem 1998';
        final fontFamilyList = <String>[];

        final collection = WebFontCollection();
        await collection.loadAssetFonts(
          FontManifest(<FontFamily>[
            FontFamily(testFontFamily, <FontAsset>[FontAsset(testFontUrl, <String, String>{})]),
          ]),
        );
        domDocument.fonts!.forEach((DomFontFace f, DomFontFace f2, DomFontFaceSet s) {
          fontFamilyList.add(f.family!);
        });

        expect(fontFamilyList.length, equals(1));
        expect(fontFamilyList.first, testFontFamily);
      });
    });
  });
}

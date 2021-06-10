// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'package:ui/src/engine.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$SkiaFontCollection', () {
    List<String> warnings = <String>[];
    late void Function(String) oldPrintWarning;

    setUpAll(() async {
      await initializeCanvasKit();
      oldPrintWarning = printWarning;
      printWarning = (String warning) {
        warnings.add(warning);
      };
    });

    tearDownAll(() {
      printWarning = oldPrintWarning;
    });

    setUp(() {
      warnings.clear();
    });

    test('logs no warnings with the default mock asset manager', () {
      final SkiaFontCollection fontCollection = SkiaFontCollection();
      final WebOnlyMockAssetManager mockAssetManager =
          WebOnlyMockAssetManager();
      expect(fontCollection.registerFonts(mockAssetManager), completes);
      expect(fontCollection.ensureFontsLoaded(), completes);
      expect(warnings, isEmpty);
    });

    test('logs a warning if one of the registered fonts is invalid', () async {
      final SkiaFontCollection fontCollection = SkiaFontCollection();
      final WebOnlyMockAssetManager mockAssetManager =
          WebOnlyMockAssetManager();
      mockAssetManager.defaultFontManifest = '''
[
   {
      "family":"Roboto",
      "fonts":[{"asset":"packages/ui/assets/Roboto-Regular.ttf"}]
   },
   {
      "family": "BrokenFont",
      "fonts":[{"asset":"packages/bogus/BrokenFont.ttf"}]
   }
  ]
      ''';
      // It should complete without error, but emit a warning about BrokenFont.
      await fontCollection.registerFonts(mockAssetManager);
      await fontCollection.ensureFontsLoaded();
      expect(
        warnings,
        containsAllInOrder(
          <String>[
            'Failed to load font BrokenFont at packages/bogus/BrokenFont.ttf',
            'Verify that packages/bogus/BrokenFont.ttf contains a valid font.',
          ],
        ),
      );
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

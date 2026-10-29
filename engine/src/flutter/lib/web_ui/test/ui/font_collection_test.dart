// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/fake_asset_manager.dart';
import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  final warnings = <String>[];
  late void Function(String) oldPrintWarning;

  setUpAll(() {
    oldPrintWarning = printWarning;
    printWarning = warnings.add;
  });

  tearDownAll(() {
    printWarning = oldPrintWarning;
  });

  late FakeAssetScope testScope;
  setUp(() {
    mockHttpFetchResponseFactory = null;
    testScope = fakeAssetManager.pushAssetScope();
    warnings.clear();
  });

  tearDown(() {
    fakeAssetManager.popAssetScope(testScope);
  });

  test('Loading valid font from data succeeds without family name', () async {
    final collection = renderer.fontCollection as EngineFontCollection;
    final ByteBuffer ahemData = await httpFetchByteBuffer('/assets/fonts/ahem.ttf');
    expect(await collection.loadFontFromBytes(ahemData.asUint8List()), isTrue);

    // The family name comes from the font itself.
    final RegisteredFont registered = collection.debugRegisteredFonts.last;
    expect(registered.family, 'Ahem');
    expect(registered.typefaceFamilyName, 'Ahem');
    expect(registered.bytes.length, ahemData.lengthInBytes);
  });

  test('Loading valid font from data succeeds with family name', () async {
    final collection = renderer.fontCollection as EngineFontCollection;
    final ByteBuffer ahemData = await httpFetchByteBuffer('/assets/fonts/ahem.ttf');
    expect(
      await collection.loadFontFromBytes(ahemData.asUint8List(), fontFamily: 'FamilyName'),
      true,
    );

    final RegisteredFont registered = collection.debugRegisteredFonts.last;
    expect(registered.family, 'FamilyName');
    expect(registered.typefaceFamilyName, 'Ahem');
  });

  test('Loading invalid font from data returns false', () async {
    final FlutterFontCollection collection = renderer.fontCollection;
    final List<int> invalidFontData = utf8.encode('This is not valid font data');
    expect(
      await collection.loadFontFromBytes(
        Uint8List.fromList(invalidFontData),
        fontFamily: 'FamilyName',
      ),
      false,
    );
    expect(warnings, <String>['Failed to parse font family "FamilyName"']);
  });

  test('Loading asset fonts logs no warnings with the default asset manager', () async {
    final FlutterFontCollection collection = renderer.fontCollection;
    await collection.loadAssetFonts(await fetchFontManifest(fakeAssetManager));
    expect(warnings, isEmpty);
  });

  test('Loading valid asset fonts succeeds', () async {
    testScope.setAssetPassthrough(robotoVariableFontUrl);
    testScope.setAssetPassthrough(robotoTestFontUrl);
    testScope.setAssetPassthrough(ahemFontUrl);

    final collection = renderer.fontCollection as EngineFontCollection;
    final int registeredBefore = collection.debugRegisteredFonts.length;
    final AssetFontsResult result = await collection.loadAssetFonts(
      FontManifest(<FontFamily>[
        FontFamily(robotoFontFamily, <FontAsset>[
          FontAsset(robotoVariableFontUrl, <String, String>{}),
          FontAsset(robotoTestFontUrl, <String, String>{'weight': 'bold'}),
        ]),
        FontFamily(ahemFontFamily, <FontAsset>[FontAsset(ahemFontUrl, <String, String>{})]),
      ]),
    );
    expect(result.loadedFonts, <String>[robotoVariableFontUrl, robotoTestFontUrl, ahemFontUrl]);
    expect(result.fontFailures, isEmpty);
    expect(warnings, isEmpty);

    // Fonts are registered under the manifest family name, in manifest order.
    final List<RegisteredFont> registered = collection.debugRegisteredFonts.sublist(
      registeredBefore,
    );
    expect(registered.map((RegisteredFont font) => font.family), <String>[
      robotoFontFamily,
      robotoFontFamily,
      ahemFontFamily,
    ]);
    final ByteBuffer ahemData = await httpFetchByteBuffer(ahemFontUrl);
    expect(registered.last.bytes.length, ahemData.lengthInBytes);
  });

  test('Loading asset fonts reports when font not found', () async {
    testScope.setAssetPassthrough(robotoVariableFontUrl);
    testScope.setAssetPassthrough(robotoTestFontUrl);

    const invalidFontUrl = 'assets/invalid_font_url.ttf';

    final FlutterFontCollection collection = renderer.fontCollection;
    final AssetFontsResult result = await collection.loadAssetFonts(
      FontManifest(<FontFamily>[
        FontFamily(robotoFontFamily, <FontAsset>[
          FontAsset(robotoVariableFontUrl, <String, String>{}),
          FontAsset(robotoTestFontUrl, <String, String>{'weight': 'bold'}),
        ]),
        FontFamily(ahemFontFamily, <FontAsset>[FontAsset(invalidFontUrl, <String, String>{})]),
      ]),
    );
    expect(result.loadedFonts, <String>[robotoVariableFontUrl, robotoTestFontUrl]);
    expect(result.fontFailures, hasLength(1));
    expect(result.fontFailures[invalidFontUrl], isA<FontNotFoundError>());
    expect(warnings, <String>['Font family Ahem not found (404) at $invalidFontUrl']);
  });

  test('Loading asset fonts reports when a font has invalid data', () async {
    const invalidFontUrl = 'assets/invalid_font_data.ttf';

    testScope.setAssetPassthrough(robotoVariableFontUrl);
    testScope.setAssetPassthrough(robotoTestFontUrl);
    testScope.setAsset(invalidFontUrl, stringAsUtf8Data('this is invalid data'));

    final FlutterFontCollection collection = renderer.fontCollection;
    final AssetFontsResult result = await collection.loadAssetFonts(
      FontManifest(<FontFamily>[
        FontFamily(robotoFontFamily, <FontAsset>[
          FontAsset(robotoVariableFontUrl, <String, String>{}),
          FontAsset(robotoTestFontUrl, <String, String>{'weight': 'bold'}),
        ]),
        FontFamily(ahemFontFamily, <FontAsset>[FontAsset(invalidFontUrl, <String, String>{})]),
      ]),
    );
    expect(result.loadedFonts, <String>[robotoVariableFontUrl, robotoTestFontUrl]);
    expect(result.fontFailures, hasLength(1));
    expect(result.fontFailures[invalidFontUrl], isA<FontInvalidDataError>());
    expect(warnings, <String>[
      'Failed to load font Ahem at $invalidFontUrl',
      'Verify that $invalidFontUrl contains a valid font.',
    ]);
  });

  test('Font manifest with numeric and string descriptor values parses correctly', () async {
    testScope.setAsset(
      'FontManifest.json',
      stringAsUtf8Data(r'''
[
  {
    "family": "FakeFont",
    "fonts": [
      {
        "asset": "fonts/FakeFont.ttf",
        "style": "italic",
        "weight": 400
      }
    ]
  }
]
'''),
    );
    final FontManifest manifest = await fetchFontManifest(fakeAssetManager);
    expect(manifest.families.length, 1);

    final FontFamily family = manifest.families.single;
    expect(family.name, 'FakeFont');
    expect(family.fontAssets.length, 1);

    final FontAsset fontAsset = family.fontAssets.single;
    expect(fontAsset.asset, 'fonts/FakeFont.ttf');
    expect(fontAsset.descriptors.length, 2);
    expect(fontAsset.descriptors['style'], 'italic');
    expect(fontAsset.descriptors['weight'], '400');
  });
}

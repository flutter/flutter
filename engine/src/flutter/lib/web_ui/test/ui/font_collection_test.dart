// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

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

  test('Loading valid font from a non-zero-offset Uint8List view succeeds', () async {
    final collection = renderer.fontCollection as EngineFontCollection;
    final Uint8List ahemBytes = (await httpFetchByteBuffer(ahemFontUrl)).asUint8List();
    final padded = Uint8List(ahemBytes.length + 16)..fillRange(0, ahemBytes.length + 16, 0xFF);
    padded.setRange(8, 8 + ahemBytes.length, ahemBytes);
    final subview = Uint8List.sublistView(padded, 8, 8 + ahemBytes.length);

    expect(await collection.loadFontFromBytes(subview, fontFamily: 'SubviewAhem'), isTrue);
    final RegisteredFont registered = collection.debugRegisteredFonts.last;
    expect(registered.family, 'SubviewAhem');
    expect(registered.typefaceFamilyName, 'Ahem');
  });

  test('clear() unregisters previously loaded fonts from paragraph layout', () async {
    final collection = renderer.fontCollection as EngineFontCollection;
    addTearDown(() async {
      collection.clear();
      await collection.loadAssetFonts(await fetchFontManifest(fakeAssetManager));
    });

    final Uint8List ahemBytes = (await httpFetchByteBuffer(ahemFontUrl)).asUint8List();
    expect(await collection.loadFontFromBytes(ahemBytes, fontFamily: 'ClearTestFamily'), isTrue);

    ui.Paragraph buildNarrowGlyphParagraph() {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontFamily: 'ClearTestFamily', fontSize: 20),
      )..addText('i');
      final ui.Paragraph paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 200));
      addTearDown(paragraph.dispose);
      return paragraph;
    }

    // With Ahem registered under ClearTestFamily, 'i' measures 1em (20px).
    expect(buildNarrowGlyphParagraph().maxIntrinsicWidth, closeTo(20.0, 0.01));

    collection.clear();
    expect(collection.debugRegisteredFonts, isEmpty);
    await collection.loadAssetFonts(await fetchFontManifest(fakeAssetManager));

    // After clear() + reloading default fonts, ClearTestFamily is unregistered
    // and falls back to Roboto where 'i' is much narrower than 1em.
    expect(buildNarrowGlyphParagraph().maxIntrinsicWidth, lessThan(12.0));
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

  test('Loading asset fonts downloads fallback Roboto when absent from manifest', () async {
    final ByteBuffer robotoBytes = await httpFetchByteBuffer(robotoTestFontUrl);
    final requestedUrls = <String>[];
    mockHttpFetchResponseFactory = (String url) async {
      requestedUrls.add(url);
      if (url.endsWith('roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2')) {
        return MockHttpFetchResponse(
          url: url,
          status: 200,
          payload: MockHttpFetchPayload(byteBuffer: robotoBytes),
        );
      }
      return null;
    };
    testScope.setAssetPassthrough(ahemFontUrl);

    final collection = renderer.fontCollection as EngineFontCollection;
    final int registeredBefore = collection.debugRegisteredFonts.length;
    final AssetFontsResult result = await collection.loadAssetFonts(
      FontManifest(<FontFamily>[
        FontFamily(ahemFontFamily, <FontAsset>[FontAsset(ahemFontUrl, <String, String>{})]),
      ]),
    );

    expect(warnings, isEmpty);
    expect(result.fontFailures, isEmpty);
    expect(
      requestedUrls,
      contains('assets/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2'),
    );
    expect(
      collection.debugRegisteredFonts
          .sublist(registeredBefore)
          .map((RegisteredFont font) => font.family),
      <String>[ahemFontFamily, robotoFontFamily],
    );
  });

  test(
    'Loading asset fonts registers in manifest order when downloads finish out of order',
    () async {
      final ByteBuffer ahemBuffer = await httpFetchByteBuffer(ahemFontUrl);
      final firstAssetCompleter = Completer<ByteBuffer>();
      const slowAsset = 'fonts/slow_first.ttf';
      const fastAsset = 'fonts/fast_second.ttf';

      mockHttpFetchResponseFactory = (String url) async {
        if (url == slowAsset) {
          final ByteBuffer buffer = await firstAssetCompleter.future;
          return MockHttpFetchResponse(
            url: url,
            status: 200,
            payload: MockHttpFetchPayload(byteBuffer: buffer),
          );
        }
        if (url == fastAsset) {
          // Resolve slowAsset only after fastAsset has already returned.
          scheduleMicrotask(() {
            if (!firstAssetCompleter.isCompleted) {
              firstAssetCompleter.complete(ahemBuffer);
            }
          });
          return MockHttpFetchResponse(
            url: url,
            status: 200,
            payload: MockHttpFetchPayload(byteBuffer: ahemBuffer),
          );
        }
        return null;
      };
      testScope.setAssetPassthrough(slowAsset);
      testScope.setAssetPassthrough(fastAsset);
      testScope.setAssetPassthrough(robotoTestFontUrl);

      final collection = renderer.fontCollection as EngineFontCollection;
      final int registeredBefore = collection.debugRegisteredFonts.length;
      await collection.loadAssetFonts(
        FontManifest(<FontFamily>[
          FontFamily('FirstFamily', <FontAsset>[FontAsset(slowAsset, <String, String>{})]),
          FontFamily('SecondFamily', <FontAsset>[FontAsset(fastAsset, <String, String>{})]),
          FontFamily(robotoFontFamily, <FontAsset>[
            FontAsset(robotoTestFontUrl, <String, String>{}),
          ]),
        ]),
      );

      expect(
        collection.debugRegisteredFonts
            .sublist(registeredBefore)
            .map((RegisteredFont font) => font.family),
        <String>['FirstFamily', 'SecondFamily', robotoFontFamily],
      );
    },
  );

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

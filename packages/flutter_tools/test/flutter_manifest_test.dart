// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';

import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  group('FlutterManifest', () {
    testUsingContext('is empty when the pubspec.yaml file is empty', () async {
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString('');
      expect(flutterManifest.isEmpty, true);
      expect(flutterManifest.appName, '');
      expect(flutterManifest.usesMaterialDesign, false);
      expect(flutterManifest.fontsDescriptor, isEmpty);
      expect(flutterManifest.fonts, isEmpty);
      expect(flutterManifest.assets, isEmpty);
    });

    test('has no fonts or assets when the "flutter" section is empty', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);
      expect(flutterManifest, isNotNull);
      expect(flutterManifest.isEmpty, false);
      expect(flutterManifest.appName, 'test');
      expect(flutterManifest.usesMaterialDesign, false);
      expect(flutterManifest.fontsDescriptor, isEmpty);
      expect(flutterManifest.fonts, isEmpty);
      expect(flutterManifest.assets, isEmpty);
    });

    test('knows if material design is used', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);
      expect(flutterManifest.usesMaterialDesign, true);
    });

    test('has two assets', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  assets:
    - a/foo
    - a/bar
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);
      expect(flutterManifest.assets.length, 2);
      expect(flutterManifest.assets[0], Uri.parse('a/foo'));
      expect(flutterManifest.assets[1], Uri.parse('a/bar'));
    });

    test('has one font family with one asset', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - asset: a/bar
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);

      expect(flutterManifest.fontsDescriptor.toString(), '[{fonts: [{asset: a/bar}], family: foo}]');
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font font = fonts[0];
      const String fontDescriptor = '{family: foo, fonts: [{asset: a/bar}]}';
      expect(font.descriptor.toString(), fontDescriptor);
      expect(font.familyName, 'foo');
      final List<FontAsset> assets = font.fontAssets;
      expect(assets.length, 1);
      final FontAsset fontAsset = assets[0];
      expect(fontAsset.assetUri.path, 'a/bar');
      expect(fontAsset.weight, isNull);
      expect(fontAsset.style, isNull);
    });

    test('has one font family with a simple asset and one with weight', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - asset: a/bar
        - asset: a/bar
          weight: 400
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);

      const String expectedFontsDescriptor = '[{fonts: [{asset: a/bar}, {weight: 400, asset: a/bar}], family: foo}]';
      expect(flutterManifest.fontsDescriptor.toString(), expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font font = fonts[0];
      const String fontDescriptor = '{family: foo, fonts: [{asset: a/bar}, {weight: 400, asset: a/bar}]}';
      expect(font.descriptor.toString(), fontDescriptor);
      expect(font.familyName, 'foo');
      final List<FontAsset> assets = font.fontAssets;
      expect(assets.length, 2);
      final FontAsset fontAsset0 = assets[0];
      expect(fontAsset0.assetUri.path, 'a/bar');
      expect(fontAsset0.weight, isNull);
      expect(fontAsset0.style, isNull);
      final FontAsset fontAsset1 = assets[1];
      expect(fontAsset1.assetUri.path, 'a/bar');
      expect(fontAsset1.weight, 400);
      expect(fontAsset1.style, isNull);
    });

    test('has one font family with a simple asset and one with weight and style', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - asset: a/bar
        - asset: a/bar
          weight: 400
          style: italic
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);

      const String expectedFontsDescriptor = '[{fonts: [{asset: a/bar}, {style: italic, weight: 400, asset: a/bar}], family: foo}]';
      expect(flutterManifest.fontsDescriptor.toString(), expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font font = fonts[0];
      const String fontDescriptor = '{family: foo, fonts: [{asset: a/bar}, {weight: 400, style: italic, asset: a/bar}]}';
      expect(font.descriptor.toString(), fontDescriptor);
      expect(font.familyName, 'foo');
      final List<FontAsset> assets = font.fontAssets;
      expect(assets.length, 2);
      final FontAsset fontAsset0 = assets[0];
      expect(fontAsset0.assetUri.path, 'a/bar');
      expect(fontAsset0.weight, isNull);
      expect(fontAsset0.style, isNull);
      final FontAsset fontAsset1 = assets[1];
      expect(fontAsset1.assetUri.path, 'a/bar');
      expect(fontAsset1.weight, 400);
      expect(fontAsset1.style, 'italic');
    });

    test('has two font families, each with one simple asset and one with weight and style', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - asset: a/bar
        - asset: a/bar
          weight: 400
          style: italic
    - family: bar
      fonts:
        - asset: a/baz
        - weight: 400
          asset: a/baz
          style: italic
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);

      const String expectedFontsDescriptor = '[{fonts: [{asset: a/bar}, {style: italic, weight: 400, asset: a/bar}], family: foo},'
                                             ' {fonts: [{asset: a/baz}, {style: italic, weight: 400, asset: a/baz}], family: bar}]';
      expect(flutterManifest.fontsDescriptor.toString(), expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 2);

      final Font fooFont = fonts[0];
      const String barFontDescriptor = '{family: foo, fonts: [{asset: a/bar}, {weight: 400, style: italic, asset: a/bar}]}';
      expect(fooFont.descriptor.toString(), barFontDescriptor);
      expect(fooFont.familyName, 'foo');
      final List<FontAsset> fooAassets = fooFont.fontAssets;
      expect(fooAassets.length, 2);
      final FontAsset fooFontAsset0 = fooAassets[0];
      expect(fooFontAsset0.assetUri.path, 'a/bar');
      expect(fooFontAsset0.weight, isNull);
      expect(fooFontAsset0.style, isNull);
      final FontAsset fooFontAsset1 = fooAassets[1];
      expect(fooFontAsset1.assetUri.path, 'a/bar');
      expect(fooFontAsset1.weight, 400);
      expect(fooFontAsset1.style, 'italic');

      final Font barFont = fonts[1];
      const String fontDescriptor = '{family: bar, fonts: [{asset: a/baz}, {weight: 400, style: italic, asset: a/baz}]}';
      expect(barFont.descriptor.toString(), fontDescriptor);
      expect(barFont.familyName, 'bar');
      final List<FontAsset> barAssets = barFont.fontAssets;
      expect(barAssets.length, 2);
      final FontAsset barFontAsset0 = barAssets[0];
      expect(barFontAsset0.assetUri.path, 'a/baz');
      expect(barFontAsset0.weight, isNull);
      expect(barFontAsset0.style, isNull);
      final FontAsset barFontAsset1 = barAssets[1];
      expect(barFontAsset1.assetUri.path, 'a/baz');
      expect(barFontAsset1.weight, 400);
      expect(barFontAsset1.style, 'italic');
    });

    testUsingContext('has only one of two font families when one declaration is missing the "family" option', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - asset: a/bar
        - asset: a/bar
          weight: 400
          style: italic
    - fonts:
        - asset: a/baz
        - asset: a/baz
          weight: 400
          style: italic
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);


      const String expectedFontsDescriptor = '[{fonts: [{asset: a/bar}, {style: italic, weight: 400, asset: a/bar}], family: foo},'
                                             ' {fonts: [{asset: a/baz}, {style: italic, weight: 400, asset: a/baz}]}]';
      expect(flutterManifest.fontsDescriptor.toString(), expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font fooFont = fonts[0];
      const String barFontDescriptor = '{family: foo, fonts: [{asset: a/bar}, {weight: 400, style: italic, asset: a/bar}]}';
      expect(fooFont.descriptor.toString(), barFontDescriptor);
      expect(fooFont.familyName, 'foo');
      final List<FontAsset> fooAassets = fooFont.fontAssets;
      expect(fooAassets.length, 2);
      final FontAsset fooFontAsset0 = fooAassets[0];
      expect(fooFontAsset0.assetUri.path, 'a/bar');
      expect(fooFontAsset0.weight, isNull);
      expect(fooFontAsset0.style, isNull);
      final FontAsset fooFontAsset1 = fooAassets[1];
      expect(fooFontAsset1.assetUri.path, 'a/bar');
      expect(fooFontAsset1.weight, 400);
      expect(fooFontAsset1.style, 'italic');
    });

    testUsingContext('has only one of two font families when one declaration is missing the "fonts" option', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - asset: a/bar
        - asset: a/bar
          weight: 400
          style: italic
    - family: bar
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);

      const String expectedFontsDescriptor = '[{fonts: [{asset: a/bar}, {style: italic, weight: 400, asset: a/bar}], family: foo},'
                                             ' {family: bar}]';
      expect(flutterManifest.fontsDescriptor.toString(), expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font fooFont = fonts[0];
      const String barFontDescriptor = '{family: foo, fonts: [{asset: a/bar}, {weight: 400, style: italic, asset: a/bar}]}';
      expect(fooFont.descriptor.toString(), barFontDescriptor);
      expect(fooFont.familyName, 'foo');
      final List<FontAsset> fooAassets = fooFont.fontAssets;
      expect(fooAassets.length, 2);
      final FontAsset fooFontAsset0 = fooAassets[0];
      expect(fooFontAsset0.assetUri.path, 'a/bar');
      expect(fooFontAsset0.weight, isNull);
      expect(fooFontAsset0.style, isNull);
      final FontAsset fooFontAsset1 = fooAassets[1];
      expect(fooFontAsset1.assetUri.path, 'a/bar');
      expect(fooFontAsset1.weight, 400);
      expect(fooFontAsset1.style, 'italic');
    });

    testUsingContext('has no font family when declaration is missing the "asset" option', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
  fonts:
    - family: foo
      fonts:
        - weight: 400
''';
      final FlutterManifest flutterManifest = await FlutterManifest.createFromString(manifest);

      const String expectedFontsDescriptor = '[{fonts: [{weight: 400}], family: foo}]';
      expect(flutterManifest.fontsDescriptor.toString(), expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 0);
    });
  });
}

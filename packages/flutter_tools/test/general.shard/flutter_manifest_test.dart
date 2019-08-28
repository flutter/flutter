// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/pubspec_schema.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  group('FlutterManifest', () {
    testUsingContext('is empty when the pubspec.yaml file is empty', () async {
      final FlutterManifest flutterManifest = FlutterManifest.createFromString('');
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      final dynamic expectedFontsDescriptor = [{'fonts': [{'asset': 'a/bar'}], 'family': 'foo'}]; // ignore: always_specify_types
      expect(flutterManifest.fontsDescriptor, expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font font = fonts[0];
      final dynamic fooFontDescriptor = {'family': 'foo', 'fonts': [{'asset': 'a/bar'}]}; // ignore: always_specify_types
      expect(font.descriptor, fooFontDescriptor);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      final dynamic expectedFontsDescriptor = [{'fonts': [{'asset': 'a/bar'}, {'weight': 400, 'asset': 'a/bar'}], 'family': 'foo'}]; // ignore: always_specify_types
      expect(flutterManifest.fontsDescriptor, expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font font = fonts[0];
      final dynamic fooFontDescriptor = {'family': 'foo', 'fonts': [{'asset': 'a/bar'}, {'weight': 400, 'asset': 'a/bar'}]}; // ignore: always_specify_types
      expect(font.descriptor, fooFontDescriptor);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      final dynamic expectedFontsDescriptor = [{'fonts': [{'asset': 'a/bar'}, {'style': 'italic', 'weight': 400, 'asset': 'a/bar'}], 'family': 'foo'}]; // ignore: always_specify_types

      expect(flutterManifest.fontsDescriptor, expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font font = fonts[0];
      final dynamic fooFontDescriptor = {'family': 'foo', 'fonts': [{'asset': 'a/bar'}, {'weight': 400, 'style': 'italic', 'asset': 'a/bar'}]}; // ignore: always_specify_types
      expect(font.descriptor, fooFontDescriptor);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      final dynamic expectedFontsDescriptor = <dynamic>[
          {'fonts': [{'asset': 'a/bar'}, {'style': 'italic', 'weight': 400, 'asset': 'a/bar'}], 'family': 'foo'}, // ignore: always_specify_types
          {'fonts': [{'asset': 'a/baz'}, {'style': 'italic', 'weight': 400, 'asset': 'a/baz'}], 'family': 'bar'}, // ignore: always_specify_types
      ];
      expect(flutterManifest.fontsDescriptor, expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 2);

      final Font fooFont = fonts[0];
      final dynamic fooFontDescriptor = {'family': 'foo', 'fonts': [{'asset': 'a/bar'}, {'weight': 400, 'style': 'italic', 'asset': 'a/bar'}]}; // ignore: always_specify_types
      expect(fooFont.descriptor, fooFontDescriptor);
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
      const String fontDescriptor = '{family: bar, fonts: [{asset: a/baz}, {weight: 400, style: italic, asset: a/baz}]}'; // ignore: always_specify_types
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);

      final dynamic expectedFontsDescriptor = [{'fonts': [{'asset': 'a/bar'}, {'style': 'italic', 'weight': 400, 'asset': 'a/bar'}], 'family': 'foo'}]; // ignore: always_specify_types
      expect(flutterManifest.fontsDescriptor, expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font fooFont = fonts[0];
      final dynamic fooFontDescriptor = {'family': 'foo', 'fonts': [{'asset': 'a/bar'}, {'weight': 400, 'style': 'italic', 'asset': 'a/bar'}]}; // ignore: always_specify_types
      expect(fooFont.descriptor, fooFontDescriptor);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      final dynamic expectedFontsDescriptor = [{'fonts': [{'asset': 'a/bar'}, {'style': 'italic', 'weight': 400, 'asset': 'a/bar'}], 'family': 'foo'}]; // ignore: always_specify_types
      expect(flutterManifest.fontsDescriptor, expectedFontsDescriptor);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 1);
      final Font fooFont = fonts[0];
      final dynamic fooFontDescriptor = {'family': 'foo', 'fonts': [{'asset': 'a/bar'}, {'weight': 400, 'style': 'italic', 'asset': 'a/bar'}]}; // ignore: always_specify_types
      expect(fooFont.descriptor, fooFontDescriptor);
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
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);

      expect(flutterManifest.fontsDescriptor, <dynamic>[]);
      final List<Font> fonts = flutterManifest.fonts;
      expect(fonts.length, 0);
    });

    test('allows a blank flutter section', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest.isEmpty, false);
      expect(flutterManifest.isModule, false);
      expect(flutterManifest.isPlugin, false);
      expect(flutterManifest.androidPackage, null);
    });

    test('allows a module declaration', () async {
      const String manifest = '''
name: test
flutter:
  module:
    androidPackage: com.example
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest.isModule, true);
      expect(flutterManifest.androidPackage, 'com.example');
    });

    test('allows a legacy plugin declaration', () async {
      const String manifest = '''
name: test
flutter:
  plugin:
    androidPackage: com.example
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest.isPlugin, true);
      expect(flutterManifest.androidPackage, 'com.example');
    });
    test('allows a multi-plat plugin declaration', () async {
      const String manifest = '''
name: test
flutter:
    plugin:
      platforms:
        android:
          package: com.example
          pluginClass: TestPlugin
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest.isPlugin, true);
      expect(flutterManifest.androidPackage, 'com.example');
    });


    Future<void> checkManifestVersion({
      String manifest,
      String expectedAppVersion,
      String expectedBuildName,
      String expectedBuildNumber,
    }) async {
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest.appVersion, expectedAppVersion);
      expect(flutterManifest.buildName, expectedBuildName);
      expect(flutterManifest.buildNumber, expectedBuildNumber);
    }

    test('parses major.minor.patch+build version clause 1', () async {
      const String manifest = '''
name: test
version: 1.0.0+2
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkManifestVersion(
        manifest: manifest,
        expectedAppVersion: '1.0.0+2',
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '2',
      );
    });

    test('parses major.minor.patch with no build version', () async {
      const String manifest = '''
name: test
version: 0.0.1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkManifestVersion(
        manifest: manifest,
        expectedAppVersion: '0.0.1',
        expectedBuildName: '0.0.1',
        expectedBuildNumber: null,
      );
    });

    test('parses major.minor.patch+build version clause 2', () async {
      const String manifest = '''
name: test
version: 1.0.0-beta+exp.sha.5114f85
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkManifestVersion(
        manifest: manifest,
        expectedAppVersion: '1.0.0-beta+exp.sha.5114f85',
        expectedBuildName: '1.0.0-beta',
        expectedBuildNumber: 'exp.sha.5114f85',
      );
    });

    test('parses major.minor+build version clause', () async {
      const String manifest = '''
name: test
version: 1.0+2
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkManifestVersion(
        manifest: manifest,
        expectedAppVersion: '1.0+2',
        expectedBuildName: '1.0',
        expectedBuildNumber: '2',
      );
    });

    test('parses empty version clause', () async {
      const String manifest = '''
name: test
version:
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkManifestVersion(
        manifest: manifest,
        expectedAppVersion: null,
        expectedBuildName: null,
        expectedBuildNumber: null,
      );
    });

    test('parses no version clause', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkManifestVersion(
        manifest: manifest,
        expectedAppVersion: null,
        expectedBuildName: null,
        expectedBuildNumber: null,
      );
    });

    // Regression test for https://github.com/flutter/flutter/issues/31764
    testUsingContext('Returns proper error when font detail is malformed', () async {
      final BufferLogger logger = context.get<Logger>();
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  fonts:
    - family: foo
      fonts:
        -asset: a/bar
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);

      expect(flutterManifest, null);
      expect(logger.errorText, contains('Expected "fonts" to either be null or a list.'));
    });

    testUsingContext('Returns proper error when font is a map instead of a list', () async {
      final BufferLogger logger = context.get<Logger>();
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
  fonts:
    family: foo
    fonts:
      -asset: a/bar
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);

      expect(flutterManifest, null);
      expect(logger.errorText, contains('Expected "fonts" to be a list'));
    });

    testUsingContext('Returns proper error when second font family is invalid', () async {
      final BufferLogger logger = context.get<Logger>();
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
    - string
''';
      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest, null);
      expect(logger.errorText, contains('Expected a map.'));
    });
  });

  group('FlutterManifest with MemoryFileSystem', () {
    Future<void> assertSchemaIsReadable() async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      final FlutterManifest flutterManifest = FlutterManifest.createFromString(manifest);
      expect(flutterManifest.isEmpty, false);
    }

    void testUsingContextAndFs(
      String description,
      FileSystem filesystem,
      dynamic testMethod(),
    ) {
      testUsingContext(
        description,
        () async {
          writeEmptySchemaFile(filesystem);
          testMethod();
        },
        overrides: <Type, Generator>{
          FileSystem: () => filesystem,
        },
      );
    }

    testUsingContext('Validate manifest on original fs', () {
      assertSchemaIsReadable();
    });

    testUsingContextAndFs(
      'Validate manifest on Posix FS',
      MemoryFileSystem(style: FileSystemStyle.posix),
      () {
        assertSchemaIsReadable();
      },
    );

    testUsingContextAndFs(
      'Validate manifest on Windows FS',
      MemoryFileSystem(style: FileSystemStyle.windows),
      () {
        assertSchemaIsReadable();
      },
    );

  });

}


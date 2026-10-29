// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/matchers.dart';

@JS('_flutter')
external set _testFlutter(JSAny? value);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('AssetManager getAssetUrl', () {
    setUp(() {
      // Remove the meta-tag from the environment before each test.
      removeAssetBaseMeta();
    });

    test('initializes with default values', () {
      final assets = ui_web.AssetManager();

      expect(
        assets.getAssetUrl('asset.txt'),
        'assets/asset.txt',
        reason: 'Default `assetsDir` is "assets".',
      );
    });

    test('assetsDir changes the directory where assets are stored', () {
      final assets = ui_web.AssetManager(assetsDir: 'static');

      expect(assets.getAssetUrl('asset.txt'), 'static/asset.txt');
    });

    test('assetBase must end with slash', () {
      expect(() {
        ui_web.AssetManager(assetBase: '/deployment');
      }, throwsAssertionError);
    });

    test('assetBase can be relative', () {
      final assets = ui_web.AssetManager(assetBase: 'base/');

      expect(assets.getAssetUrl('asset.txt'), 'base/assets/asset.txt');
    });

    test('assetBase can be absolute', () {
      final assets = ui_web.AssetManager(assetBase: 'https://www.gstatic.com/my-app/');

      expect(assets.getAssetUrl('asset.txt'), 'https://www.gstatic.com/my-app/assets/asset.txt');
    });

    test('assetBase in conjunction with assetsDir, fully custom paths', () {
      final assets = ui_web.AssetManager(assetBase: '/asset/base/', assetsDir: 'static');

      expect(assets.getAssetUrl('asset.txt'), '/asset/base/static/asset.txt');
    });

    test('Fully-qualified asset URLs are untouched', () {
      final assets = ui_web.AssetManager();

      expect(
        assets.getAssetUrl('https://static.my-app.com/favicon.ico'),
        'https://static.my-app.com/favicon.ico',
      );
    });

    test('Fully-qualified asset URLs are untouched (even with assetBase)', () {
      final assets = ui_web.AssetManager(assetBase: 'https://static.my-app.com/');

      expect(
        assets.getAssetUrl('https://static.my-app.com/favicon.ico'),
        'https://static.my-app.com/favicon.ico',
      );
    });
  });

  group('AssetManager getAssetUrl with <meta name=assetBase> tag', () {
    setUp(() {
      removeAssetBaseMeta();
      addAssetBaseMeta('/dom/base/');
    });

    test('reads value from DOM', () {
      final assets = ui_web.AssetManager();

      expect(assets.getAssetUrl('asset.txt'), '/dom/base/assets/asset.txt');
    });

    test('reads value from DOM (only once!)', () {
      final firstManager = ui_web.AssetManager();
      expect(firstManager.getAssetUrl('asset.txt'), '/dom/base/assets/asset.txt');

      removeAssetBaseMeta();
      final anotherManager = ui_web.AssetManager();

      expect(
        firstManager.getAssetUrl('asset.txt'),
        '/dom/base/assets/asset.txt',
        reason: 'The old value of the assetBase meta should be cached.',
      );
      expect(anotherManager.getAssetUrl('asset.txt'), 'assets/asset.txt');
    });
  });

  group('AssetManager getAssetUrl with setContentHashedAssetMap (content hashing)', () {
    setUp(() {
      removeAssetBaseMeta();
      setContentHashedAssetMap(const <String, String>{});
    });

    tearDown(() {
      setContentHashedAssetMap(const <String, String>{});
    });

    test('resolves logical asset keys and manifest filenames to hashed paths', () {
      final assets = ui_web.AssetManager();
      // Note: `hashWebAssets` stores `Uri.decodeFull` paths (e.g.
      // `'assets/sub dir/space file.99887766.txt'`) in `AssetManifest.bin.json`
      // to match `_createAssetManifest`. `setContentHashedAssetMap` normalizes
      // values to their on-disk `%20`-encoded paths so `getAssetUrl`'s final
      // `Uri.encodeFull` produces `%2520` (double-encoded). When the browser
      // requests `%2520`, the HTTP server URL-decodes it once to `%20`, which
      // matches the physical `%20`-encoded filename written to `build/web/assets/`
      // by `copyAssets` — and avoids `%252520` triple-encoding when `Image.asset`
      // (`AssetImage`) passes the variant path through `PlatformAssetBundle`.
      setContentHashedAssetMap(<String, String>{
        'AssetManifest.bin.json': 'AssetManifest.bin.12345678.json',
        'FontManifest.json': 'FontManifest.87654321.json',
        'NOTICES.Z': 'NOTICES.abcdef01.Z',
        'shaders/ink_sparkle.frag': 'shaders/ink_sparkle.fedcba98.frag',
        'assets/data/config.json': 'assets/data/config.53e706a7.json',
        'assets/sub dir/space file.txt': 'assets/sub dir/space file.99887766.txt',
      });

      expect(
        assets.getAssetUrl('AssetManifest.bin.json'),
        'assets/AssetManifest.bin.12345678.json',
      );
      expect(assets.getAssetUrl('FontManifest.json'), 'assets/FontManifest.87654321.json');
      expect(assets.getAssetUrl('NOTICES.Z'), 'assets/NOTICES.abcdef01.Z');
      expect(
        assets.getAssetUrl('shaders/ink_sparkle.frag'),
        'assets/shaders/ink_sparkle.fedcba98.frag',
      );
      expect(
        assets.getAssetUrl('assets/data/config.json'),
        'assets/assets/data/config.53e706a7.json',
      );
      // Unencoded logical key, PlatformAssetBundle `%20`-encoded logical key,
      // decoded hashed variant key, and PlatformAssetBundle `%20`-encoded hashed
      // variant key (used by `Image.asset` / `AssetImage`) all resolve to `%2520`
      // (never `%252520` triple-encoded):
      expect(
        assets.getAssetUrl('assets/sub dir/space file.txt'),
        'assets/assets/sub%2520dir/space%2520file.99887766.txt',
      );
      expect(
        assets.getAssetUrl('assets/sub%20dir/space%20file.txt'),
        'assets/assets/sub%2520dir/space%2520file.99887766.txt',
      );
      expect(
        assets.getAssetUrl('assets/sub dir/space file.99887766.txt'),
        'assets/assets/sub%2520dir/space%2520file.99887766.txt',
      );
      expect(
        assets.getAssetUrl('assets/sub%20dir/space%20file.99887766.txt'),
        'assets/assets/sub%2520dir/space%2520file.99887766.txt',
      );
      // Already-hashed variant keys pass through untouched:
      expect(
        assets.getAssetUrl('assets/2.0x/logo.74f81fe1.png'),
        'assets/assets/2.0x/logo.74f81fe1.png',
      );
    });

    test('debugStripContentHash strips trailing 8-hex hash across single, compound, and extensionless names', () {
      expect(
        debugStripContentHash('assets/images/2.0x/logo.cdd74878.png'),
        'assets/images/2.0x/logo.png',
      );
      expect(
        debugStripContentHash('assets/images/logo.deadbeef.cdd74878.png'),
        'assets/images/logo.deadbeef.png',
      );
      expect(debugStripContentHash('assets/worker.12345678.js.map'), 'assets/worker.js.map');
      expect(debugStripContentHash('assets/module.89abcdef.wasm.map'), 'assets/module.wasm.map');
      expect(debugStripContentHash('assets/runtime.01234567.mjs.map'), 'assets/runtime.mjs.map');
      expect(debugStripContentHash('NOTICES.abcdef01'), 'NOTICES');
      expect(debugStripContentHash('NOTICES.abcdef01.Z'), 'NOTICES.Z');
    });

    test('debugLoadContentHashedAssetManifest clears stale asset mappings when buildConfig has no assetManifest', () async {
      final assets = ui_web.AssetManager();
      setContentHashedAssetMap(<String, String>{
        'assets/data/config.json': 'assets/data/config.53e706a7.json',
      });
      expect(
        assets.getAssetUrl('assets/data/config.json'),
        'assets/assets/data/config.53e706a7.json',
      );

      await debugLoadContentHashedAssetManifest(assets);
      expect(assets.getAssetUrl('assets/data/config.json'), 'assets/assets/data/config.json');
    });

    test('debugLoadContentHashedAssetManifest registers fontManifest and extraAssets from _flutter.buildConfig', () async {
      final assets = ui_web.AssetManager();
      _testFlutter = <String, Object?>{
        'buildConfig': <String, Object?>{
          'fontManifest': 'FontManifest.87654321.json',
          'extraAssets': <String, Object?>{
            'NOTICES': 'NOTICES.abcdef01',
            'shaders/ink_sparkle.frag': 'shaders/ink_sparkle.fedcba98.frag',
          },
        },
      }.jsify();
      try {
        await debugLoadContentHashedAssetManifest(assets);
        expect(assets.getAssetUrl('FontManifest.json'), 'assets/FontManifest.87654321.json');
        expect(assets.getAssetUrl('NOTICES'), 'assets/NOTICES.abcdef01');
        expect(
          assets.getAssetUrl('shaders/ink_sparkle.frag'),
          'assets/shaders/ink_sparkle.fedcba98.frag',
        );
      } finally {
        _testFlutter = null;
      }
    });
  });
}

/// Removes all meta-tags with name=assetBase.
void removeAssetBaseMeta() {
  domWindow.document.querySelectorAll('meta[name=assetBase]').forEach((DomElement element) {
    element.remove();
  });
}

/// Adds a meta-tag with name=assetBase and the passed-in [value].
void addAssetBaseMeta(String value) {
  final DomHTMLMetaElement meta = createDomHTMLMetaElement()
    ..name = 'assetBase'
    ..content = value;

  domDocument.head!.append(meta);
}

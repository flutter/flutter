// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../matchers.dart';

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
      final AssetManager assets = AssetManager();

      expect(
        assets.getAssetUrl('asset.txt'),
        'assets/asset.txt',
        reason: 'Default `assetsDir` is "assets".',
      );
    });

    test('assetsDir changes the directory where assets are stored', () {
      final AssetManager assets = AssetManager(assetsDir: 'static');

      expect(assets.getAssetUrl('asset.txt'), 'static/asset.txt');
    });

    test('assetBase must end with slash', () {
      expect(() {
        AssetManager(assetBase: '/deployment');
      }, throwsAssertionError);
    });

    test('assetBase can be relative', () {
      final AssetManager assets = AssetManager(assetBase: 'base/');

      expect(assets.getAssetUrl('asset.txt'), 'base/assets/asset.txt');
    });

    test('assetBase can be absolute', () {
      final AssetManager assets = AssetManager(
        assetBase: 'https://www.gstatic.com/my-app/',
      );

      expect(
        assets.getAssetUrl('asset.txt'),
        'https://www.gstatic.com/my-app/assets/asset.txt',
      );
    });

    test('assetBase in conjunction with assetsDir, fully custom paths', () {
      final AssetManager assets = AssetManager(
        assetBase: '/asset/base/',
        assetsDir: 'static',
      );

      expect(assets.getAssetUrl('asset.txt'), '/asset/base/static/asset.txt');
    });

    test('Fully-qualified asset URLs are untouched', () {
      final AssetManager assets = AssetManager();

      expect(
        assets.getAssetUrl('https://static.my-app.com/favicon.ico'),
        'https://static.my-app.com/favicon.ico',
      );
    });

    test('Fully-qualified asset URLs are untouched (even with assetBase)', () {
      final AssetManager assets = AssetManager(
        assetBase: 'https://static.my-app.com/',
      );

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
      final AssetManager assets = AssetManager();

      expect(assets.getAssetUrl('asset.txt'), '/dom/base/assets/asset.txt');
    });

    test('reads value from DOM (only once!)', () {
      final AssetManager firstManager = AssetManager();
      expect(
        firstManager.getAssetUrl('asset.txt'),
        '/dom/base/assets/asset.txt',
      );

      removeAssetBaseMeta();
      final AssetManager anotherManager = AssetManager();

      expect(
        firstManager.getAssetUrl('asset.txt'),
        '/dom/base/assets/asset.txt',
        reason: 'The old value of the assetBase meta should be cached.',
      );
      expect(anotherManager.getAssetUrl('asset.txt'), 'assets/asset.txt');
    });
  });
}

/// Removes all meta-tags with name=assetBase.
void removeAssetBaseMeta() {
  domWindow.document
      .querySelectorAll('meta[name=assetBase]')
      .forEach((DomElement element) {
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

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class SkiaFontCollection {
  final List<Future<ByteBuffer>> _loadingFontBuffers = <Future<ByteBuffer>>[];

  Future<void> ensureFontsLoaded() async {
    final List<Uint8List> fontBuffers =
        (await Future.wait<ByteBuffer>(_loadingFontBuffers))
            .map((ByteBuffer buffer) => buffer.asUint8List())
            .toList();
    skFontMgr = canvasKit['SkFontMgr'].callMethod('FromData', fontBuffers);
  }

  Future<void> registerFonts(AssetManager assetManager) async {
    ByteData byteData;

    try {
      byteData = await assetManager.load('FontManifest.json');
    } on AssetManagerException catch (e) {
      if (e.httpStatus == 404) {
        html.window.console
            .warn('Font manifest does not exist at `${e.url}` – ignoring.');
        return;
      } else {
        rethrow;
      }
    }

    if (byteData == null) {
      throw AssertionError(
          'There was a problem trying to load FontManifest.json');
    }

    final List<dynamic> fontManifest =
        json.decode(utf8.decode(byteData.buffer.asUint8List()));
    if (fontManifest == null) {
      throw AssertionError(
          'There was a problem trying to load FontManifest.json');
    }

    for (Map<String, dynamic> fontFamily in fontManifest) {
      final String family = fontFamily['family'];
      final List<dynamic> fontAssets = fontFamily['fonts'];

      for (dynamic fontAssetItem in fontAssets) {
        final Map<String, dynamic> fontAsset = fontAssetItem;
        final String asset = fontAsset['asset'];
        _loadingFontBuffers.add(html.window
            .fetch(assetManager.getAssetUrl(asset))
            .then((dynamic fetchResult) => fetchResult.arrayBuffer()));
      }
    }
  }

  js.JsObject skFontMgr;
}

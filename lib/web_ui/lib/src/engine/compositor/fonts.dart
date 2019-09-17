// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

class SkiaFontCollection {
  final Map<String, Map<Map<String, String>, js.JsObject>>
      _registeredTypefaces = <String, Map<Map<String, String>, js.JsObject>>{};

  final List<Future<void>> _fontLoadingFutures = <Future<void>>[];

  Future<void> ensureFontsLoaded() async {
    await Future.wait(_fontLoadingFutures);
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
        final Map<String, String> descriptors = <String, String>{};
        for (String descriptor in fontAsset.keys) {
          if (descriptor != 'asset') {
            descriptors[descriptor] = '${fontAsset[descriptor]}';
          }
        }
        _fontLoadingFutures.add(_registerFont(
            family, assetManager.getAssetUrl(asset), descriptors));
      }
    }
  }

  Future<void> _registerFont(
      String family, String url, Map<String, String> descriptors) async {
    final dynamic fetchResult = await html.window.fetch(url);
    final ByteBuffer resultBuffer = await fetchResult.arrayBuffer();
    final js.JsObject skTypeFace = skFontMgr.callMethod(
        'MakeTypefaceFromData', <Uint8List>[resultBuffer.asUint8List()]);
    _registeredTypefaces.putIfAbsent(
        family, () => <Map<String, String>, js.JsObject>{});
    _registeredTypefaces[family][descriptors] = skTypeFace;
  }

  js.JsObject getFont(String family, double size) {
    if (_registeredTypefaces[family] == null) {
      if (assertionsEnabled) {
        html.window.console.warn('Using unregistered font: $family');
      }
      return js.JsObject(canvasKit['SkFont'], <dynamic>[null, size]);
    }

    // We don't attempt to find a Typeface matching the text style. Instead, we
    // try to find the "default" typeface. The default typeface either has no
    // descriptors, or only has a descriptor of font-weight 400 (the default).
    final Map<Map<String, String>, js.JsObject> typefaces =
        _registeredTypefaces[family];
    js.JsObject skTypeface;

    for (MapEntry<Map<String, String>, js.JsObject> entry
        in typefaces.entries) {
      final Map<String, String> descriptors = entry.key;
      if (descriptors.isEmpty ||
          (descriptors.length == 1 && descriptors['weight'] == '400')) {
        skTypeface = entry.value;
        break;
      }
    }

    // If we couldn't find a suitable default, just use any typeface in the
    // family.
    if (skTypeface == null) {
      skTypeface = typefaces.values.first;
    }

    return js.JsObject(canvasKit['SkFont'], <dynamic>[skTypeface, size]);
  }

  final js.JsObject skFontMgr =
      js.JsObject(canvasKit['SkFontMgr']['RefDefault']);
}

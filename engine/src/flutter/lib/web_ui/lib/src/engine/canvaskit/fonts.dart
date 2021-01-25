// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

// This URL was found by using the Google Fonts Developer API to find the URL
// for Roboto. The API warns that this URL is not stable. In order to update
// this, list out all of the fonts and find the URL for the regular
// Roboto font. The API reference is here:
// https://developers.google.com/fonts/docs/developer_api
const String _robotoUrl =
    'https://fonts.gstatic.com/s/roboto/v20/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf';

/// Manages the fonts used in the Skia-based backend.
class SkiaFontCollection {
  /// Fonts that have been registered but haven't been loaded yet.
  final List<Future<_RegisteredFont?>> _unloadedFonts =
      <Future<_RegisteredFont?>>[];

  /// Fonts which have been registered and loaded.
  final List<_RegisteredFont> _registeredFonts = <_RegisteredFont>[];

  /// Fallback fonts which have been registered and loaded.
  final List<_RegisteredFont> _registeredFallbackFonts = <_RegisteredFont>[];

  final Map<String, List<SkTypeface>> familyToTypefaceMap =
      <String, List<SkTypeface>>{};

  final List<String> globalFontFallbacks = <String>['Roboto'];

  final Map<String, int> _fontFallbackCounts = <String, int>{};

  Future<void> ensureFontsLoaded() async {
    await _loadFonts();

    if (fontProvider != null) {
      fontProvider!.delete();
      fontProvider = null;
    }
    fontProvider = canvasKit.TypefaceFontProvider.Make();
    familyToTypefaceMap.clear();

    for (var font in _registeredFonts) {
      fontProvider!.registerFont(font.bytes, font.family);
      familyToTypefaceMap
          .putIfAbsent(font.family, () => <SkTypeface>[])
          .add(font.typeface);
    }

    for (var font in _registeredFallbackFonts) {
      fontProvider!.registerFont(font.bytes, font.family);
      familyToTypefaceMap
          .putIfAbsent(font.family, () => <SkTypeface>[])
          .add(font.typeface);
    }
  }

  /// Loads all of the unloaded fonts in [_unloadedFonts] and adds them
  /// to [_registeredFonts].
  Future<void> _loadFonts() async {
    if (_unloadedFonts.isEmpty) {
      return;
    }
    final List<_RegisteredFont?> loadedFonts =
        await Future.wait(_unloadedFonts);
    for (_RegisteredFont? font in loadedFonts) {
      if (font != null) {
        _registeredFonts.add(font);
      }
    }
    _unloadedFonts.clear();
  }

  Future<void> loadFontFromList(Uint8List list, {String? fontFamily}) async {
    if (fontFamily == null) {
      fontFamily = _readActualFamilyName(list);
      if (fontFamily == null) {
        html.window.console
            .warn('Failed to read font family name. Aborting font load.');
        return;
      }
    }

    _registeredFonts.add(_RegisteredFont(list, fontFamily));
    await ensureFontsLoaded();
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

    final List<dynamic>? fontManifest =
        json.decode(utf8.decode(byteData.buffer.asUint8List()));
    if (fontManifest == null) {
      throw AssertionError(
          'There was a problem trying to load FontManifest.json');
    }

    bool registeredRoboto = false;

    for (Map<String, dynamic> fontFamily
        in fontManifest.cast<Map<String, dynamic>>()) {
      final String family = fontFamily['family']!;
      final List<dynamic> fontAssets = fontFamily['fonts'];

      if (family == 'Roboto') {
        registeredRoboto = true;
      }

      for (dynamic fontAssetItem in fontAssets) {
        final Map<String, dynamic> fontAsset = fontAssetItem;
        final String asset = fontAsset['asset'];
        _unloadedFonts
            .add(_registerFont(assetManager.getAssetUrl(asset), family));
      }
    }

    /// We need a default fallback font for CanvasKit, in order to
    /// avoid crashing while laying out text with an unregistered font. We chose
    /// Roboto to match Android.
    if (!registeredRoboto) {
      // Download Roboto and add it to the font buffers.
      _unloadedFonts.add(_registerFont(_robotoUrl, 'Roboto'));
    }
  }

  Future<_RegisteredFont?> _registerFont(String url, String family) async {
    ByteBuffer buffer;
    try {
      buffer = await html.window.fetch(url).then(_getArrayBuffer);
    } catch (e) {
      html.window.console.warn('Failed to load font $family at $url');
      html.window.console.warn(e);
      return null;
    }

    final Uint8List bytes = buffer.asUint8List();
    return _RegisteredFont(bytes, family);
  }

  void registerFallbackFont(String family, Uint8List bytes) {
    _fontFallbackCounts.putIfAbsent(family, () => 0);
    int fontFallbackTag = _fontFallbackCounts[family]!;
    _fontFallbackCounts[family] = _fontFallbackCounts[family]! + 1;
    String countedFamily = '$family $fontFallbackTag';
    _registeredFallbackFonts.add(_RegisteredFont(bytes, countedFamily));
    globalFontFallbacks.add(countedFamily);
  }

  String? _readActualFamilyName(Uint8List bytes) {
    final SkFontMgr tmpFontMgr = canvasKit.FontMgr.FromData([bytes])!;
    String? actualFamily = tmpFontMgr.getFamilyName(0);
    tmpFontMgr.delete();
    return actualFamily;
  }

  Future<ByteBuffer> _getArrayBuffer(dynamic fetchResult) {
    // TODO(yjbanov): fetchResult.arrayBuffer is a dynamic invocation. Clean it up.
    return fetchResult
        .arrayBuffer()
        .then<ByteBuffer>((dynamic x) => x as ByteBuffer);
  }

  /// Resets the fallback fonts. Used for tests.
  void debugResetFallbackFonts() {
    _registeredFallbackFonts.clear();
    globalFontFallbacks.clear();
    globalFontFallbacks.add('Roboto');
    _fontFallbackCounts.clear();
  }

  SkFontMgr? skFontMgr;
  TypefaceFontProvider? fontProvider;
}

/// Represents a font that has been registered.
class _RegisteredFont {
  /// The font family name for this font.
  final String family;

  /// The byte data for this font.
  final Uint8List bytes;

  /// The [SkTypeface] created from this font's [bytes].
  ///
  /// This is used to determine which code points are supported by this font.
  final SkTypeface typeface;

  _RegisteredFont(this.bytes, this.family)
      : this.typeface =
            canvasKit.FontMgr.RefDefault().MakeTypefaceFromData(bytes);
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import '../assets.dart';
import '../dom.dart';
import '../util.dart';
import 'canvaskit_api.dart';
import 'font_fallbacks.dart';

// This URL was found by using the Google Fonts Developer API to find the URL
// for Roboto. The API warns that this URL is not stable. In order to update
// this, list out all of the fonts and find the URL for the regular
// Roboto font. The API reference is here:
// https://developers.google.com/fonts/docs/developer_api
const String _robotoUrl =
    'https://fonts.gstatic.com/s/roboto/v20/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf';

// URL for the Ahem font, only used in tests.
const String _ahemUrl = '/assets/fonts/ahem.ttf';

/// Manages the fonts used in the Skia-based backend.
class SkiaFontCollection {
  final Set<String> _registeredFontFamilies = <String>{};

  /// Fonts that started the download process.
  ///
  /// Once downloaded successfully, this map is cleared and the resulting
  /// [RegisteredFont]s are added to [_downloadedFonts].
  final List<Future<RegisteredFont?>> _pendingFonts = <Future<RegisteredFont?>>[];

  /// Fonts that have been downloaded and parsed into [SkTypeface].
  ///
  /// These fonts may not yet have been registered with the [fontProvider]. This
  /// happens after [ensureFontsLoaded] completes.
  final List<RegisteredFont> _downloadedFonts = <RegisteredFont>[];

  /// Returns fonts that have been downloaded and parsed.
  ///
  /// This should only be used in tests.
  List<RegisteredFont>? get debugDownloadedFonts {
    if (!assertionsEnabled) {
      return null;
    }
    return _downloadedFonts;
  }

  final Map<String, List<SkFont>> familyToFontMap = <String, List<SkFont>>{};

  Future<void> ensureFontsLoaded() async {
    await _loadFonts();

    if (fontProvider != null) {
      fontProvider!.delete();
      fontProvider = null;
    }
    fontProvider = canvasKit.TypefaceFontProvider.Make();
    familyToFontMap.clear();

    for (final RegisteredFont font in _downloadedFonts) {
      fontProvider!.registerFont(font.bytes, font.family);
      familyToFontMap
          .putIfAbsent(font.family, () => <SkFont>[])
          .add(SkFont(font.typeface));
    }

    for (final RegisteredFont font
        in FontFallbackData.instance.registeredFallbackFonts) {
      fontProvider!.registerFont(font.bytes, font.family);
      familyToFontMap
          .putIfAbsent(font.family, () => <SkFont>[])
          .add(SkFont(font.typeface));
    }
  }

  /// Loads all of the unloaded fonts in [_pendingFonts] and adds them
  /// to [_downloadedFonts].
  Future<void> _loadFonts() async {
    if (_pendingFonts.isEmpty) {
      return;
    }
    final List<RegisteredFont?> loadedFonts = await Future.wait(_pendingFonts);
    for (final RegisteredFont? font in loadedFonts) {
      if (font != null) {
        _downloadedFonts.add(font);
      }
    }
    _pendingFonts.clear();
  }

  Future<void> loadFontFromList(Uint8List list, {String? fontFamily}) async {
    if (fontFamily == null) {
      fontFamily = _readActualFamilyName(list);
      if (fontFamily == null) {
        printWarning('Failed to read font family name. Aborting font load.');
        return;
      }
    }

    final SkTypeface? typeface =
        canvasKit.Typeface.MakeFreeTypeFaceFromData(list.buffer);
    if (typeface != null) {
      _downloadedFonts.add(RegisteredFont(list, fontFamily, typeface));
      await ensureFontsLoaded();
    } else {
      printWarning('Failed to parse font family "$fontFamily"');
      return;
    }
  }

  /// Loads fonts from `FontManifest.json`.
  Future<void> registerFonts(AssetManager assetManager) async {
    ByteData byteData;

    try {
      byteData = await assetManager.load('FontManifest.json');
    } on AssetManagerException catch (e) {
      if (e.httpStatus == 404) {
        printWarning('Font manifest does not exist at `${e.url}` – ignoring.');
        return;
      } else {
        rethrow;
      }
    }

    final List<dynamic>? fontManifest =
        json.decode(utf8.decode(byteData.buffer.asUint8List())) as List<dynamic>?;
    if (fontManifest == null) {
      throw AssertionError(
          'There was a problem trying to load FontManifest.json');
    }

    for (final Map<String, dynamic> fontFamily
        in fontManifest.cast<Map<String, dynamic>>()) {
      final String family = fontFamily.readString('family');
      final List<dynamic> fontAssets = fontFamily.readList('fonts');
      for (final dynamic fontAssetItem in fontAssets) {
        final Map<String, dynamic> fontAsset = fontAssetItem as Map<String, dynamic>;
        final String asset = fontAsset.readString('asset');
        _registerFont(assetManager.getAssetUrl(asset), family);
      }
    }

    /// We need a default fallback font for CanvasKit, in order to
    /// avoid crashing while laying out text with an unregistered font. We chose
    /// Roboto to match Android.
    if (!_isFontFamilyRegistered('Roboto')) {
      // Download Roboto and add it to the font buffers.
      _registerFont(_robotoUrl, 'Roboto');
    }
  }

  /// Whether the [fontFamily] was registered and/or loaded.
  bool _isFontFamilyRegistered(String fontFamily) {
    return _registeredFontFamilies.contains(fontFamily);
  }

  /// Loads the Ahem font, unless it's already been loaded using
  /// `FontManifest.json` (see [registerFonts]).
  ///
  /// `FontManifest.json` has higher priority than the default test font URLs.
  /// This allows customizing test environments where fonts are loaded from
  /// different URLs.
  void debugRegisterTestFonts() {
    if (!_isFontFamilyRegistered('Ahem')) {
      _registerFont(_ahemUrl, 'Ahem');
    }

    // Ahem must be added to font fallbacks list regardless of where it was
    // downloaded from.
    FontFallbackData.instance.globalFontFallbacks.add('Ahem');
  }

  void _registerFont(String url, String family) {
    Future<RegisteredFont?> _downloadFont() async {
      ByteBuffer buffer;
      try {
        buffer = await httpFetch(url).then(_getArrayBuffer);
      } catch (e) {
        printWarning('Failed to load font $family at $url');
        printWarning(e.toString());
        return null;
      }

      final Uint8List bytes = buffer.asUint8List();
      final SkTypeface? typeface =
          canvasKit.Typeface.MakeFreeTypeFaceFromData(bytes.buffer);
      if (typeface != null) {
        return RegisteredFont(bytes, family, typeface);
      } else {
        printWarning('Failed to load font $family at $url');
        printWarning('Verify that $url contains a valid font.');
        return null;
      }
    }

    _registeredFontFamilies.add(family);
    _pendingFonts.add(_downloadFont());
  }


  String? _readActualFamilyName(Uint8List bytes) {
    final SkFontMgr tmpFontMgr =
        canvasKit.FontMgr.FromData(<Uint8List>[bytes])!;
    final String? actualFamily = tmpFontMgr.getFamilyName(0);
    tmpFontMgr.delete();
    return actualFamily;
  }

  Future<ByteBuffer> _getArrayBuffer(DomResponse fetchResult) {
    return fetchResult
        .arrayBuffer()
        .then<ByteBuffer>((dynamic x) => x as ByteBuffer);
  }

  SkFontMgr? skFontMgr;
  TypefaceFontProvider? fontProvider;
}

/// Represents a font that has been registered.
class RegisteredFont {
  /// The font family name for this font.
  final String family;

  /// The byte data for this font.
  final Uint8List bytes;

  /// The [SkTypeface] created from this font's [bytes].
  ///
  /// This is used to determine which code points are supported by this font.
  final SkTypeface typeface;

  RegisteredFont(this.bytes, this.family, this.typeface) {
    // This is a hack which causes Skia to cache the decoded font.
    final SkFont skFont = SkFont(typeface);
    skFont.getGlyphBounds(<int>[0], null, null);
  }
}

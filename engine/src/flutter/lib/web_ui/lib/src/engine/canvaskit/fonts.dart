// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_test_fonts/web_test_fonts.dart';

import '../assets.dart';
import '../dom.dart';
import '../fonts.dart';
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

/// Manages the fonts used in the Skia-based backend.
class SkiaFontCollection implements FontCollection {
  final Set<String> _downloadedFontFamilies = <String>{};

  /// Fonts that started the download process, but are not yet registered.
  ///
  /// /// Once downloaded successfully, this map is cleared and the resulting
  /// [UnregisteredFont]s are added to [_registeredFonts].
  final List<UnregisteredFont> _unregisteredFonts = <UnregisteredFont>[];

  final List<RegisteredFont> _registeredFonts = <RegisteredFont>[];

  /// Returns fonts that have been downloaded, registered, and parsed.
  ///
  /// This should only be used in tests.
  List<RegisteredFont>? get debugRegisteredFonts {
    if (!assertionsEnabled) {
      return null;
    }
    return _registeredFonts;
  }

  final Map<String, List<SkFont>> familyToFontMap = <String, List<SkFont>>{};

  void _registerWithFontProvider() {
    if (fontProvider != null) {
      fontProvider!.delete();
      fontProvider = null;
    }
    fontProvider = canvasKit.TypefaceFontProvider.Make();
    familyToFontMap.clear();

    for (final RegisteredFont font in _registeredFonts) {
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

  @override
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
      _registeredFonts.add(RegisteredFont(list, fontFamily, typeface));
      _registerWithFontProvider();
    } else {
      printWarning('Failed to parse font family "$fontFamily"');
      return;
    }
  }

  /// Loads fonts from `FontManifest.json`.
  @override
  Future<void> downloadAssetFonts(AssetManager assetManager) async {
    final HttpFetchResponse response = await assetManager.loadAsset('FontManifest.json');

    if (!response.hasPayload) {
      printWarning('Font manifest does not exist at `${response.url}` - ignoring.');
      return;
    }

    final Uint8List data = await response.asUint8List();
    final List<dynamic>? fontManifest = json.decode(utf8.decode(data)) as List<dynamic>?;
    if (fontManifest == null) {
      throw AssertionError(
          'There was a problem trying to load FontManifest.json');
    }

    final List<Future<UnregisteredFont?>> pendingFonts = <Future<UnregisteredFont?>>[];

    for (final Map<String, dynamic> fontFamily
        in fontManifest.cast<Map<String, dynamic>>()) {
      final String family = fontFamily.readString('family');
      final List<dynamic> fontAssets = fontFamily.readList('fonts');
      for (final dynamic fontAssetItem in fontAssets) {
        final Map<String, dynamic> fontAsset = fontAssetItem as Map<String, dynamic>;
        final String asset = fontAsset.readString('asset');
        _downloadFont(pendingFonts, assetManager.getAssetUrl(asset), family);
      }
    }

    /// We need a default fallback font for CanvasKit, in order to
    /// avoid crashing while laying out text with an unregistered font. We chose
    /// Roboto to match Android.
    if (!_isFontFamilyDownloaded('Roboto')) {
      // Download Roboto and add it to the font buffers.
      _downloadFont(pendingFonts, _robotoUrl, 'Roboto');
    }

    final List<UnregisteredFont?> completedPendingFonts = await Future.wait(pendingFonts);
    _unregisteredFonts.addAll(completedPendingFonts.whereType<UnregisteredFont>());
  }

  @override
  void registerDownloadedFonts() {
    RegisteredFont? makeRegisterFont(ByteBuffer buffer, String url, String family) {
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

    for (final UnregisteredFont unregisteredFont in _unregisteredFonts) {
      final RegisteredFont? registeredFont = makeRegisterFont(
        unregisteredFont.bytes,
        unregisteredFont.url,
        unregisteredFont.family
      );
      if (registeredFont != null) {
        _registeredFonts.add(registeredFont);
      }
    }

    _unregisteredFonts.clear();
    _registerWithFontProvider();
  }

  /// Whether the [fontFamily] was registered and/or loaded.
  bool _isFontFamilyDownloaded(String fontFamily) {
    return _downloadedFontFamilies.contains(fontFamily);
  }

  /// Loads the Ahem font, unless it's already been loaded using
  /// `FontManifest.json` (see [downloadAssetFonts]).
  ///
  /// `FontManifest.json` has higher priority than the default test font URLs.
  /// This allows customizing test environments where fonts are loaded from
  /// different URLs.
  @override
  Future<void> debugDownloadTestFonts() async {
    final List<Future<UnregisteredFont?>> pendingFonts = <Future<UnregisteredFont?>>[];
    for (final MapEntry<String, String> fontEntry in testFontUrls.entries) {
      if (!_isFontFamilyDownloaded(fontEntry.key)) {
        _downloadFont(pendingFonts, fontEntry.value, fontEntry.key);
      }
    }
    final List<UnregisteredFont?> completedPendingFonts = await Future.wait(pendingFonts);
    completedPendingFonts.add(UnregisteredFont(
        EmbeddedTestFont.flutterTest.data.buffer,
        '<embedded>',
        EmbeddedTestFont.flutterTest.fontFamily,
    ));
    _unregisteredFonts.addAll(completedPendingFonts.whereType<UnregisteredFont>());

    // Ahem must be added to font fallbacks list regardless of where it was
    // downloaded from.
    FontFallbackData.instance.globalFontFallbacks.add(ahemFontFamily);
  }

  void _downloadFont(
    List<Future<UnregisteredFont?>> waitUnregisteredFonts,
    String url,
    String family
  ) {
    Future<UnregisteredFont?> downloadFont() async {
      // Try to get the font leniently. Do not crash the app when failing to
      // fetch the font in the spirit of "gradual degradation of functionality".
      try {
        final ByteBuffer data = await httpFetchByteBuffer(url);
        return UnregisteredFont(data, url, family);
      } catch (e) {
        printWarning('Failed to load font $family at $url');
        printWarning(e.toString());
        return null;
      }
    }

    _downloadedFontFamilies.add(family);
    waitUnregisteredFonts.add(downloadFont());
  }


  String? _readActualFamilyName(Uint8List bytes) {
    final SkFontMgr tmpFontMgr =
        canvasKit.FontMgr.FromData(<Uint8List>[bytes])!;
    final String? actualFamily = tmpFontMgr.getFamilyName(0);
    tmpFontMgr.delete();
    return actualFamily;
  }

  TypefaceFontProvider? fontProvider;

  @override
  void clear() {}
}

/// Represents a font that has been registered.
class RegisteredFont {
  RegisteredFont(this.bytes, this.family, this.typeface) {
    // This is a hack which causes Skia to cache the decoded font.
    final SkFont skFont = SkFont(typeface);
    skFont.getGlyphBounds(<int>[0], null, null);
  }

  /// The font family name for this font.
  final String family;

  /// The byte data for this font.
  final Uint8List bytes;

  /// The [SkTypeface] created from this font's [bytes].
  ///
  /// This is used to determine which code points are supported by this font.
  final SkTypeface typeface;
}

/// Represents a font that has been downloaded but not registered.
class UnregisteredFont {
  const UnregisteredFont(this.bytes, this.url, this.family);
  final ByteBuffer bytes;
  final String url;
  final String family;
}

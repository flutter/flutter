// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ui/src/engine/fonts.dart';
import 'package:web_test_fonts/web_test_fonts.dart';

import '../assets.dart';
import '../dom.dart';
import '../util.dart';
import 'layout_service.dart';

/// This class is responsible for registering and loading fonts.
///
/// Once an asset manager has been set in the framework, call
/// [downloadAssetFonts] with it to register fonts declared in the
/// font manifest. If test fonts are enabled, then call
/// [debugDownloadTestFonts] as well.
class HtmlFontCollection implements FlutterFontCollection {
  FontManager? _assetFontManager;
  FontManager? _testFontManager;

  /// Reads the font manifest using the [assetManager] and downloads all of the
  /// fonts declared within.
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

    _assetFontManager = FontManager();

    for (final Map<String, dynamic> fontFamily
        in fontManifest.cast<Map<String, dynamic>>()) {
      final String? family = fontFamily.tryString('family');
      final List<Map<String, dynamic>> fontAssets = fontFamily.castList<Map<String, dynamic>>('fonts');

      for (final Map<String, dynamic> fontAsset in fontAssets) {
        final String asset = fontAsset.readString('asset');
        final Map<String, String> descriptors = <String, String>{};
        for (final String descriptor in fontAsset.keys) {
          if (descriptor != 'asset') {
            descriptors[descriptor] = '${fontAsset[descriptor]}';
          }
        }
        _assetFontManager!.downloadAsset(
            family!, 'url(${assetManager.getAssetUrl(asset)})', descriptors);
      }
    }
    await _assetFontManager!.downloadAllFonts();
  }

  @override
  Future<void> loadFontFromList(Uint8List list, {String? fontFamily}) {
    if (fontFamily == null) {
      throw AssertionError('Font family must be provided to HtmlFontCollection.');
    }
    return _assetFontManager!._loadFontFaceBytes(fontFamily, list);
  }

  /// Downloads fonts that are used by tests.
  @override
  Future<void> debugDownloadTestFonts() async {
    final FontManager fontManager = _testFontManager = FontManager();
    fontManager._downloadedFonts.add(createDomFontFace(
      EmbeddedTestFont.flutterTest.fontFamily,
      EmbeddedTestFont.flutterTest.data,
    ));
    for (final MapEntry<String, String> fontEntry in testFontUrls.entries) {
      fontManager.downloadAsset(fontEntry.key, 'url(${fontEntry.value})', const <String, String>{});
    }
    await fontManager.downloadAllFonts();
  }

  @override
  void registerDownloadedFonts() {
    _assetFontManager?.registerDownloadedFonts();
    _testFontManager?.registerDownloadedFonts();
  }

  /// Unregister all fonts that have been registered.
  @override
  void clear() {
    _assetFontManager = null;
    _testFontManager = null;
    domDocument.fonts!.clear();
  }
}

/// Manages a collection of fonts and ensures they are loaded.
class FontManager {

  /// Fonts that started the downloading process. Once the fonts have downloaded
  /// without error, they are moved to [_downloadedFonts]. Those fonts
  /// are subsequently registered by [registerDownloadedFonts].
  final List<Future<DomFontFace?>> _fontLoadingFutures = <Future<DomFontFace?>>[];

  final List<DomFontFace> _downloadedFonts = <DomFontFace>[];

  // Regular expression to detect a string with no punctuations.
  // For example font family 'Ahem!' does not fall into this category
  // so the family name will be wrapped in quotes.
  static final RegExp notPunctuation =
      RegExp(r'[a-z0-9\s]+', caseSensitive: false);
  // Regular expression to detect tokens starting with a digit.
  // For example font family 'Goudy Bookletter 1911' falls into this
  // category.
  static final RegExp startWithDigit = RegExp(r'\b\d');

  /// Registers assets to Flutter Web Engine.
  ///
  /// Browsers and browsers versions differ significantly on how a valid font
  /// family name should be formatted. Notable issues are:
  ///
  /// Safari 12 and Firefox crash if you create a [DomFontFace] with a font
  /// family that is not correct CSS syntax. Font family names with invalid
  /// characters are accepted on these browsers, when wrapped it in
  /// quotes.
  ///
  /// Additionally, for Safari 12 to work [DomFontFace] name should be
  /// loaded correctly on the first try.
  ///
  /// A font in Chrome is not usable other than inside a '<p>' tag, if a
  /// [DomFontFace] is loaded wrapped with quotes. Unlike Safari 12 if a
  /// valid version of the font is also loaded afterwards it will show
  /// that font normally.
  ///
  /// In Safari 13 the [DomFontFace] should be loaded with unquoted family
  /// names.
  ///
  /// In order to avoid all these browser compatibility issues this method:
  /// * Detects the family names that might cause a conflict.
  /// * Loads it with the quotes.
  /// * Loads it again without the quotes.
  /// * For all the other family names [DomFontFace] is loaded only once.
  ///
  /// See also:
  ///
  /// * https://developer.mozilla.org/en-US/docs/Web/CSS/font-family#Valid_family_names
  /// * https://drafts.csswg.org/css-fonts-3/#font-family-prop
  void downloadAsset(
    String family,
    String asset,
    Map<String, String> descriptors,
  ) {
    if (startWithDigit.hasMatch(family) ||
        notPunctuation.stringMatch(family) != family) {
      // Load a font family name with special characters once here wrapped in
      // quotes.
      _loadFontFace("'$family'", asset, descriptors);
    }
    // Load all fonts, without quoted family names.
    _loadFontFace(family, asset, descriptors);
  }

  void _loadFontFace(
    String family,
    String asset,
    Map<String, String> descriptors,
  ) {
    Future<DomFontFace?> fontFaceLoad(DomFontFace fontFace) async {
      try {
        final DomFontFace loadedFontFace = await fontFace.load();
        return loadedFontFace;
      } catch (e) {
        printWarning('Error while trying to load font family "$family":\n$e');
        return null;
      }
    }
    // try/catch because `new FontFace` can crash with an improper font family.
    try {
      final DomFontFace fontFace = createDomFontFace(family, asset, descriptors);
      _fontLoadingFutures.add(fontFaceLoad(fontFace));
    } catch (e) {
      printWarning('Error while loading font family "$family":\n$e');
    }
  }

  void registerDownloadedFonts() {
    if (_downloadedFonts.isEmpty) {
      return;
    }
    _downloadedFonts.forEach(domDocument.fonts!.add);
  }


  Future<void> downloadAllFonts() async {
    final List<DomFontFace?> loadedFonts = await Future.wait(_fontLoadingFutures);
    _downloadedFonts.addAll(loadedFonts.whereType<DomFontFace>());
  }

  // Loads a font from bytes, surfacing errors through the future.
  Future<void> _loadFontFaceBytes(String family, Uint8List list) {
    // Since these fonts are loaded by user code, surface the error
    // through the returned future.
    final DomFontFace fontFace = createDomFontFace(family, list);
    return fontFace.load().then((_) {
      domDocument.fonts!.add(fontFace);
      // There might be paragraph measurements for this new font before it is
      // loaded. They were measured using fallback font, so we should clear the
      // cache.
      Spanometer.clearRulersCache();
    }, onError: (dynamic exception) {
      // Failures here will throw an DomException which confusingly
      // does not implement Exception or Error. Rethrow an Exception so it can
      // be caught in user code without depending on dart:html or requiring a
      // catch block without "on".
      throw Exception(exception.toString());
    });
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../dom.dart';
import '../fonts.dart';
import '../util.dart';

/// This class is responsible for registering and loading fonts.
///
/// Once an asset manager has been set in the framework, call [loadAssetFonts] with it to register
/// fonts declared in the font manifest.
class WebFontCollection implements FlutterFontCollection {
  /// Reads the font manifest using the [ui_web.assetManager] and downloads all of the
  /// fonts declared within.
  @override
  Future<AssetFontsResult> loadAssetFonts(FontManifest manifest) async {
    final pendingFonts = <Future<(String, FontLoadError?)>>[];
    for (final FontFamily family in manifest.families) {
      for (final FontAsset fontAsset in family.fontAssets) {
        pendingFonts.add(() async {
          return (
            fontAsset.asset,
            await _loadFontAsset(family.name, fontAsset.asset, fontAsset.descriptors),
          );
        }());
      }
    }

    final loadedFonts = <String>[];
    final fontFailures = <String, FontLoadError>{};
    for (final (String asset, FontLoadError? error) in await Future.wait(pendingFonts)) {
      if (error == null) {
        loadedFonts.add(asset);
      } else {
        fontFailures[asset] = error;
      }
    }
    return AssetFontsResult(loadedFonts, fontFailures);
  }

  @override
  Future<bool> loadFontFromList(Uint8List list, {String? fontFamily}) async {
    if (fontFamily == null) {
      printWarning('Font family must be provided to WebFontCollection.');
      return false;
    }
    return _loadFontFaceBytes(fontFamily, list);
  }

  @override
  Null get fontFallbackManager => null;

  /// Unregister all fonts that have been registered.
  @override
  void clear() {
    domDocument.fonts!.clear();
  }

  // Regular expression to detect a string with no punctuations.
  // For example font family 'Ahem!' does not fall into this category
  // so the family name will be wrapped in quotes.
  static final RegExp notPunctuation = RegExp(r'[a-z0-9\s]+', caseSensitive: false);
  // Regular expression to detect tokens starting with a digit.
  // For example font family 'Goudy Bookletter 1911' falls into this
  // category.
  static final RegExp startWithDigit = RegExp(r'\b\d');

  /// Registers assets to Flutter Web Engine.
  Future<FontLoadError?> _loadFontAsset(
    String family,
    String asset,
    Map<String, String> descriptors,
  ) async {
    try {
      // Right now, this is only used in Chrome which accepts unquoted font family names.
      // However, in the future, we should examine other browsers and see if they require
      // quoting for certain font family names.
      final DomFontFace fontFace = await _loadFontFace(family, asset, descriptors);
      domDocument.fonts!.add(fontFace);
    } on FontLoadError catch (error) {
      return error;
    } catch (e) {
      return FontInvalidDataError(asset);
    }
    return null;
  }

  Future<DomFontFace> _loadFontFace(
    String family,
    String asset,
    Map<String, String> descriptors,
  ) async {
    // try/catch because `new FontFace` can crash with an improper font family.
    try {
      final DomFontFace fontFace = createDomFontFace(
        family,
        'url(${ui_web.assetManager.getAssetUrl(asset)})',
        descriptors,
      );
      return await fontFace.load();
    } catch (e) {
      printWarning('Error while loading font family "$family":\n$e');
      throw FontDownloadError(asset, e);
    }
  }

  // Loads a font from bytes, surfacing errors through the future.
  Future<bool> _loadFontFaceBytes(String family, Uint8List list) async {
    // Since these fonts are loaded by user code, surface the error
    // through the returned future.
    try {
      final DomFontFace fontFace = createDomFontFace(family, list);
      if (fontFace.status == 'error') {
        // Font failed to load.
        return false;
      }
      domDocument.fonts!.add(fontFace);

      // There might be paragraph measurements for this new font before it is
      // loaded. They were measured using fallback fonts, so we should clear the
      // cache.
      // TODO(rusino): https://github.com/flutter/flutter/issues/168001
    } catch (e) {
      // Failures here will throw a DomException. Return false.
      printWarning('Failed to load font "$family" from bytes: $e');
      return false;
    }
    return true;
  }

  @override
  void debugResetFallbackFonts() {}
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

// This URL was found by using the Google Fonts Developer API to find the URL
// for Roboto. The API warns that this URL is not stable. In order to update
// this, list out all of the fonts and find the URL for the regular
// Roboto font. The API reference is here:
// https://developers.google.com/fonts/docs/developer_api
String get _robotoUrl =>
    Uri.parse(configuration.fontFallbackBaseUrl)
        .resolve('roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2')
        .toString();

/// A font that has been parsed and registered with the backend.
class RegisteredFont {
  RegisteredFont(this.bytes, this.family, this.typeface);

  /// The byte data for this font.
  final Uint8List bytes;

  /// The font family name this font is registered under.
  final String family;

  /// The typeface parsed from [bytes].
  final BackendTypeface typeface;
}

/// Manages the fonts used by the CanvasKit and Skwasm backends.
///
/// Downloads asset fonts, keeps track of registered fonts, and owns the font
/// fallback machinery. The [BackendFontCollection] only parses font bytes and
/// makes typefaces available to the paragraphs it builds.
class EngineFontCollection implements FlutterFontCollection {
  EngineFontCollection(this._backend) {
    _fallbackRegistry = _FallbackFontRegistry(this);
    fontFallbackManager = FontFallbackManager(_fallbackRegistry);
    _backend.setFallbackFontFamilies(fontFallbackManager.globalFontFallbacks);
  }

  final BackendFontCollection _backend;

  @override
  late FontFallbackManager fontFallbackManager;

  late FallbackFontRegistry _fallbackRegistry;

  @override
  FallbackFontRegistry get fallbackFontRegistry => _fallbackRegistry;

  @visibleForTesting
  @override
  set fallbackFontRegistry(FallbackFontRegistry? registry) {
    _fallbackRegistry = registry!;
  }

  final List<RegisteredFont> _registeredFonts = <RegisteredFont>[];

  /// Fonts that have been parsed and registered, in registration order.
  @visibleForTesting
  List<RegisteredFont> get debugRegisteredFonts =>
      List<RegisteredFont>.unmodifiable(_registeredFonts);

  @override
  Future<bool> loadFontFromBytes(Uint8List list, {String? fontFamily}) async {
    final BackendTypeface? typeface = await _backend.createTypeface(list);
    if (typeface == null) {
      printWarning('Failed to parse font family "$fontFamily"');
      return false;
    }
    _register(list, fontFamily ?? typeface.familyName, typeface);
    return true;
  }

  @override
  Future<AssetFontsResult> loadAssetFonts(FontManifest manifest) async {
    final pendingDownloads = <Future<_FontDownloadResult>>[];
    var hasRoboto = false;
    for (final FontFamily family in manifest.families) {
      if (family.name == 'Roboto') {
        hasRoboto = true;
      }
      for (final FontAsset fontAsset in family.fontAssets) {
        pendingDownloads.add(_downloadFont(fontAsset.asset, family.name));
      }
    }

    // We need a default fallback font in order to avoid crashing while laying
    // out text with an unregistered font. We chose Roboto to match Android.
    if (!hasRoboto) {
      pendingDownloads.add(_downloadFontFromUrl(_robotoUrl, 'Roboto'));
    }

    final loadedFonts = <String>[];
    final fontFailures = <String, FontLoadError>{};
    // Register in manifest order so that registration order is deterministic
    // regardless of which download completes first.
    for (final _FontDownloadResult result in await Future.wait(pendingDownloads)) {
      switch (result) {
        case _FailedFontDownload(:final String asset, :final FontLoadError error):
          fontFailures[asset] = error;
        case _DownloadedFont(
          :final String asset,
          :final String family,
          :final String url,
          :final Uint8List bytes,
        ):
          final BackendTypeface? typeface = await _backend.createTypeface(bytes);
          if (typeface == null) {
            printWarning('Failed to load font $family at $url');
            printWarning('Verify that $url contains a valid font.');
            fontFailures[asset] = FontInvalidDataError(url);
          } else {
            loadedFonts.add(asset);
            _register(bytes, family, typeface);
          }
      }
    }
    return AssetFontsResult(loadedFonts, fontFailures);
  }

  Future<_FontDownloadResult> _downloadFont(String asset, String family) {
    final String url = ui_web.assetManager.getAssetUrl(asset);
    return _fetchFont(
      asset: asset,
      url: url,
      family: family,
      fetch: () async => await ui_web.assetManager.loadAsset(asset) as HttpFetchResponse,
    );
  }

  Future<_FontDownloadResult> _downloadFontFromUrl(String url, String family) {
    return _fetchFont(asset: url, url: url, family: family, fetch: () => httpFetch(url));
  }

  Future<_FontDownloadResult> _fetchFont({
    required String asset,
    required String url,
    required String family,
    required Future<HttpFetchResponse> Function() fetch,
  }) async {
    // Try to get the font leniently. Do not crash the app when failing to
    // fetch the font in the spirit of "gradual degradation of functionality".
    try {
      final HttpFetchResponse response = await fetch();
      if (!response.hasPayload) {
        printWarning('Font family $family not found (404) at $url');
        return _FailedFontDownload(asset, FontNotFoundError(url));
      }
      return _DownloadedFont(asset, family, url, await response.asUint8List());
    } catch (e) {
      printWarning('Failed to load font $family at $url');
      printWarning(e.toString());
      return _FailedFontDownload(asset, FontDownloadError(url, e));
    }
  }

  void _register(Uint8List bytes, String family, BackendTypeface typeface) {
    _registeredFonts.add(RegisteredFont(bytes, family, typeface));
    _backend.registerTypeface(typeface, family);
  }

  @override
  void clear() {
    _registeredFonts.clear();
    _backend.clear();
  }

  @override
  void debugResetFallbackFonts() {
    // ignore: invalid_use_of_visible_for_testing_member
    FallbackFontService.instance.debugReset();
    fontFallbackManager = FontFallbackManager(_fallbackRegistry);
    _backend.setFallbackFontFamilies(fontFallbackManager.globalFontFallbacks);
  }
}

sealed class _FontDownloadResult {
  const _FontDownloadResult(this.asset);

  /// The asset key the font was requested under.
  final String asset;
}

class _DownloadedFont extends _FontDownloadResult {
  const _DownloadedFont(super.asset, this.family, this.url, this.bytes);

  final String family;
  final String url;
  final Uint8List bytes;
}

class _FailedFontDownload extends _FontDownloadResult {
  const _FailedFontDownload(super.asset, this.error);

  final FontLoadError error;
}

class _FallbackFontRegistry implements FallbackFontRegistry {
  _FallbackFontRegistry(this._fontCollection);

  final EngineFontCollection _fontCollection;

  @override
  Future<bool> loadFallbackFont(String familyName, Uint8List bytes) =>
      _fontCollection.loadFontFromBytes(bytes, fontFamily: familyName);

  @override
  void updateFallbackFontFamilies(List<String> families) =>
      _fontCollection._backend.setFallbackFontFamilies(families);
}

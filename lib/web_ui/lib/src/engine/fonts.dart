// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'assets.dart';

abstract class FlutterFontCollection {

  /// Fonts loaded with [loadFontFromList] do not need to be registered
  /// with [registerDownloadedFonts]. Fonts are both downloaded and registered
  /// with [loadFontFromList] calls.
  Future<void> loadFontFromList(Uint8List list, {String? fontFamily});

  /// Completes when fonts from FontManifest.json have been downloaded.
  Future<void> downloadAssetFonts(AssetManager assetManager);

  /// Registers both downloaded fonts and fallback fonts with the TypefaceFontProvider.
  ///
  /// Downloading of fonts happens separately from registering of fonts so that
  /// the download step can happen concurrently with the initalization of the renderer.
  ///
  /// The correct order of calls to register downloaded fonts:
  /// 1) [downloadAssetFonts]
  /// 2) [registerDownloadedFonts]
  ///
  /// For fallbackFonts, call registerFallbackFont (see font_fallbacks.dart)
  /// for each fallback font before calling [registerDownloadedFonts]
  void registerDownloadedFonts();
  FutureOr<void> debugDownloadTestFonts();
  void clear();
}

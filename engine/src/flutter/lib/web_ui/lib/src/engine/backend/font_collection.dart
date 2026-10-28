// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

/// A typeface parsed by a [BackendFontCollection].
abstract class BackendTypeface {
  /// The family name embedded in the font data.
  String get familyName;
}

/// Backend-specific font registry behind `EngineFontCollection`.
///
/// `EngineFontCollection` owns downloading, the font fallback machinery and the
/// bookkeeping of registered fonts. Implementations only parse font bytes and
/// make the resulting typefaces available to the paragraphs they build.
abstract class BackendFontCollection {
  /// Parses [bytes] into a typeface, or returns null if [bytes] is not a valid
  /// font.
  ///
  /// This is asynchronous because CanvasKit cannot parse fonts until its wasm
  /// module has finished loading.
  Future<BackendTypeface?> createTypeface(Uint8List bytes);

  /// Registers [typeface] under [family].
  ///
  /// Paragraphs built after this call can resolve [family] to [typeface].
  void registerTypeface(BackendTypeface typeface, String family);

  /// Sets the font families that are tried, in order, after the families of a
  /// text style when resolving glyphs.
  void setFallbackFontFamilies(List<String> families);

  /// Unregisters all fonts.
  void clear();
}

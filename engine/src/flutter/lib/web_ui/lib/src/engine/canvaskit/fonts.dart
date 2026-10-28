// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:ui/src/engine.dart';

class CkTypeface implements BackendTypeface {
  CkTypeface(this.bytes, this.skiaObject) {
    // This is a hack which causes Skia to cache the decoded font.
    SkFont(skiaObject).getGlyphBounds(<int>[0], null, null);
  }

  /// The font data [skiaObject] was parsed from.
  ///
  /// CanvasKit's `TypefaceFontProvider.registerFont` parses the font again from
  /// bytes; it has no API to register an existing `SkTypeface`.
  final Uint8List bytes;

  final SkTypeface skiaObject;

  @override
  String get familyName => skiaObject.getFamilyName();
}

/// The CanvasKit font registry behind [EngineFontCollection].
class CkFontCollection implements BackendFontCollection {
  TypefaceFontProvider? _fontProvider;
  SkFontCollection? _skFontCollection;

  TypefaceFontProvider get _provider => _fontProvider ??= canvasKit.TypefaceFontProvider.Make();

  /// The CanvasKit font collection paragraph builders are created from.
  ///
  /// `FontCollection` caches family lookups, so it is recreated lazily after
  /// every registration to make newly registered typefaces resolvable.
  SkFontCollection get skFontCollection {
    return _skFontCollection ??= canvasKit.FontCollection.Make()
      ..enableFontFallback()
      ..setDefaultFontManager(_provider);
  }

  List<String> _fallbackFontFamilies = const <String>[];

  /// Returns [fontFamilies] followed by the current fallback font families.
  List<String> withFallbackFontFamilies(List<String> fontFamilies) {
    return <String>[...fontFamilies, ..._fallbackFontFamilies];
  }

  @override
  Future<BackendTypeface?> createTypeface(Uint8List bytes) async {
    // Make sure CanvasKit is actually loaded.
    await renderer.initialize();
    // `MakeFreeTypeFaceFromData` takes a whole `ArrayBuffer`, so a view into a
    // larger buffer has to be copied out first.
    final bool isWholeBuffer =
        bytes.offsetInBytes == 0 && bytes.lengthInBytes == bytes.buffer.lengthInBytes;
    final ByteBuffer buffer = isWholeBuffer ? bytes.buffer : Uint8List.fromList(bytes).buffer;
    final SkTypeface? typeface = canvasKit.Typeface.MakeFreeTypeFaceFromData(buffer);
    if (typeface == null) {
      return null;
    }
    return CkTypeface(bytes, typeface);
  }

  @override
  void registerTypeface(BackendTypeface typeface, String family) {
    _provider.registerFont((typeface as CkTypeface).bytes, family);
    _skFontCollection?.delete();
    _skFontCollection = null;
  }

  @override
  void setFallbackFontFamilies(List<String> families) {
    _fallbackFontFamilies = List<String>.of(families);
  }

  @override
  void clear() {
    _skFontCollection?.delete();
    _skFontCollection = null;
    _fontProvider?.delete();
    _fontProvider = null;
  }
}

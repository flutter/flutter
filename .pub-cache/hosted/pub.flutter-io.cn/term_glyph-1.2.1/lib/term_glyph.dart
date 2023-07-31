// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'src/generated/ascii_glyph_set.dart';
import 'src/generated/glyph_set.dart';
import 'src/generated/unicode_glyph_set.dart';

export 'src/generated/glyph_set.dart';
export 'src/generated/top_level.dart';

/// A [GlyphSet] that always returns ASCII glyphs.
const GlyphSet asciiGlyphs = AsciiGlyphSet();

/// A [GlyphSet] that always returns Unicode glyphs.
const GlyphSet unicodeGlyphs = UnicodeGlyphSet();

/// Returns [asciiGlyphs] if [ascii] is `true` or [unicodeGlyphs] otherwise.
///
/// Returns [unicodeGlyphs] by default.
GlyphSet get glyphs => _glyphs;
GlyphSet _glyphs = unicodeGlyphs;

/// Whether the glyph getters return plain ASCII, as opposed to Unicode
/// characters or sequences.
///
/// Defaults to `false`.
bool get ascii => glyphs == asciiGlyphs;

set ascii(bool value) {
  _glyphs = value ? asciiGlyphs : unicodeGlyphs;
}

/// Returns [glyph] if Unicode glyph are allowed, and [alternative] if they
/// aren't.
String glyphOrAscii(String glyph, String alternative) =>
    glyphs.glyphOrAscii(glyph, alternative);

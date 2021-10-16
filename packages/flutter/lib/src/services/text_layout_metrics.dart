// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'text_editing.dart';

/// A read-only interface for accessing visual information about the
/// implementing text.
abstract class TextLayoutMetrics {
  // TODO(gspencergoog): replace when we expose this ICU information.
  /// Check if the given code unit is a white space or separator
  /// character.
  ///
  /// Includes newline characters from ASCII and separators from the
  /// [unicode separator category](https://www.compart.com/en/unicode/category/Zs)
  static bool isWhitespace(int codeUnit) {
    switch (codeUnit) {
      case 0x9: // horizontal tab
      case 0xA: // line feed
      case 0xB: // vertical tab
      case 0xC: // form feed
      case 0xD: // carriage return
      case 0x1C: // file separator
      case 0x1D: // group separator
      case 0x1E: // record separator
      case 0x1F: // unit separator
      case 0x20: // space
      case 0xA0: // no-break space
      case 0x1680: // ogham space mark
      case 0x2000: // en quad
      case 0x2001: // em quad
      case 0x2002: // en space
      case 0x2003: // em space
      case 0x2004: // three-per-em space
      case 0x2005: // four-er-em space
      case 0x2006: // six-per-em space
      case 0x2007: // figure space
      case 0x2008: // punctuation space
      case 0x2009: // thin space
      case 0x200A: // hair space
      case 0x202F: // narrow no-break space
      case 0x205F: // medium mathematical space
      case 0x3000: // ideographic space
        break;
      default:
        return false;
    }
    return true;
  }

  /// {@template flutter.services.TextLayoutMetrics.getLineAtOffset}
  /// Return a [TextSelection] containing the line of the given [TextPosition].
  /// {@endtemplate}
  TextSelection getLineAtOffset(TextPosition position);

  /// {@macro flutter.painting.TextPainter.getWordBoundary}
  TextRange getWordBoundary(TextPosition position);

  /// {@template flutter.services.TextLayoutMetrics.getTextPositionAbove}
  /// Returns the TextPosition above the given offset into the text.
  ///
  /// If the offset is already on the first line, the given offset will be
  /// returned.
  /// {@endtemplate}
  TextPosition getTextPositionAbove(TextPosition position);

  /// {@template flutter.services.TextLayoutMetrics.getTextPositionBelow}
  /// Returns the TextPosition below the given offset into the text.
  ///
  /// If the offset is already on the last line, the given offset will be
  /// returned.
  /// {@endtemplate}
  TextPosition getTextPositionBelow(TextPosition position);
}

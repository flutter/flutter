// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Constants for useful Unicode characters and utility methods.
///
/// See also:
///
///  * <https://unicode.org/charts/>, which lists all Unicode code points.
class Unicode {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  Unicode._();
  /// `U+202A LEFT-TO-RIGHT EMBEDDING`
  ///
  /// Treat the following text as embedded left-to-right.
  ///
  /// Use [PDF] to end the embedding.
  static const int LRE = 0x202A;

  /// `U+202B RIGHT-TO-LEFT EMBEDDING`
  ///
  /// Treat the following text as embedded right-to-left.
  ///
  /// Use [PDF] to end the embedding.
  static const int RLE = 0x202B;

  /// `U+202C POP DIRECTIONAL FORMATTING`
  ///
  /// End the scope of the last [LRE], [RLE], [RLO], or [LRO].
  static const int PDF = 0x202C;

  /// `U+202A LEFT-TO-RIGHT OVERRIDE`
  ///
  /// Force following characters to be treated as strong left-to-right characters.
  ///
  /// For example, this causes Hebrew text to render backwards.
  ///
  /// Use [PDF] to end the override.
  static const int LRO = 0x202D;

  /// `U+202B RIGHT-TO-LEFT OVERRIDE`
  ///
  /// Force following characters to be treated as strong right-to-left characters.
  ///
  /// For example, this causes English text to render backwards.
  ///
  /// Use [PDF] to end the override.
  static const int RLO = 0x202E;

  /// `U+2066 LEFT-TO-RIGHT ISOLATE`
  ///
  /// Treat the following text as isolated and left-to-right.
  ///
  /// Use [PDI] to end the isolated scope.
  static const int LRI = 0x2066;

  /// `U+2067 RIGHT-TO-LEFT ISOLATE`
  ///
  /// Treat the following text as isolated and right-to-left.
  ///
  /// Use [PDI] to end the isolated scope.
  static const int RLI = 0x2067;

  /// `U+2068 FIRST STRONG ISOLATE`
  ///
  /// Treat the following text as isolated and in the direction of its first
  /// strong directional character that is not inside a nested isolate.
  ///
  /// This essentially "auto-detects" the directionality of the text. It is not
  /// 100% reliable. For example, Arabic text that starts with an English quote
  /// will be detected as LTR, not RTL, which will lead to the text being in a
  /// weird order.
  ///
  /// Use [PDI] to end the isolated scope.
  static const int FSI = 0x2068;

  /// `U+2069 POP DIRECTIONAL ISOLATE`
  ///
  /// End the scope of the last [LRI], [RLI], or [FSI].
  static const int PDI = 0x2069;

  /// `U+200E LEFT-TO-RIGHT MARK`
  ///
  /// Left-to-right zero-width character.
  static const int LRM = 0x200E;

  /// `U+200F RIGHT-TO-LEFT MARK`
  ///
  /// Right-to-left zero-width non-Arabic character.
  static const int RLM = 0x200F;

  /// `U+061C ARABIC LETTER MARK`
  ///
  /// Right-to-left zero-width Arabic character.
  static const int ALM = 0x061C;

  /// `U+2026 HORIZONTAL ELLIPSIS`
  static const int HE = 0x2026;

  /// `U+FFFC Object Replacement Character`
  static const int ORC = 0xFFFC;

  /// `U+FFFD Replacement Character`
  static const int RC = 0xFFFD;

  /// `U+FFFC Object Replacement Character` String literal.
  ///
  /// This is needed in a few places as const String.fromCharCode() isn't
  /// possible (see https://github.com/dart-lang/sdk/issues/49407).
  static const String stringORC = '\uFFFC';

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

  /// Check if the given code unit is a line terminator character.
  ///
  /// Includes newline characters from ASCII
  /// (https://www.unicode.org/standard/reports/tr13/tr13-5.html).
  static bool isLineTerminator(int codeUnit) {
    switch (codeUnit) {
      case 0x0A: // line feed
      case 0x0B: // vertical feed
      case 0x0C: // form feed
      case 0x0D: // carriage return
      case 0x85: // new line
      case 0x2028: // line separator
      case 0x2029: // paragraph separator
        return true;
      default:
        return false;
    }
  }
}

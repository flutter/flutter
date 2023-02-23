// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Constants for useful Unicode characters.
///
/// Currently, these characters are all related to bidirectional text.
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

  /// `U+FFFC Object Replacement Character`
  static const int OBJECTREPLACEMENTCHAR = 0xFFFC;

  /// `U+FFFD Replacement Character`
  static const int REPLACEMENTCHAR = 0xFFFD;
}

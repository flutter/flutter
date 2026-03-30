// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Constants for useful Unicode characters.
///
/// Currently, these characters are all related to bidirectional text.
///
/// See also:
///
///  * <http://unicode.org/reports/tr9/>, which describes the Unicode
///    bidirectional text algorithm.
abstract final class Unicode {
  /// The `U+202A LEFT-TO-RIGHT EMBEDDING` character.
  ///
  /// Treat the following text as embedded left-to-right.
  ///
  /// Use [PDF] to end the embedding.
  static const String LRE = '\u202A';

  /// The `U+202B RIGHT-TO-LEFT EMBEDDING` character.
  ///
  /// Treat the following text as embedded right-to-left.
  ///
  /// Use [PDF] to end the embedding.
  static const String RLE = '\u202B';

  /// The `U+202C POP DIRECTIONAL FORMATTING` character.
  ///
  /// End the scope of the last [LRE], [RLE], [RLO], or [LRO].
  static const String PDF = '\u202C';

  /// The `U+202D LEFT-TO-RIGHT OVERRIDE` character.
  ///
  /// Force following characters to be treated as strong left-to-right characters.
  ///
  /// For example, this causes Hebrew text to render backwards.
  ///
  /// Use [PDF] to end the override.
  static const String LRO = '\u202D';

  /// The `U+202E RIGHT-TO-LEFT OVERRIDE` character.
  ///
  /// Force following characters to be treated as strong right-to-left characters.
  ///
  /// For example, this causes English text to render backwards.
  ///
  /// Use [PDF] to end the override.
  static const String RLO = '\u202E';

  /// The `U+2066 LEFT-TO-RIGHT ISOLATE` character.
  ///
  /// Treat the following text as isolated and left-to-right.
  ///
  /// Use [PDI] to end the isolated scope.
  static const String LRI = '\u2066';

  /// The `U+2067 RIGHT-TO-LEFT ISOLATE` character.
  ///
  /// Treat the following text as isolated and right-to-left.
  ///
  /// Use [PDI] to end the isolated scope.
  static const String RLI = '\u2067';

  /// The `U+2068 FIRST STRONG ISOLATE` character.
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
  static const String FSI = '\u2068';

  /// The `U+2069 POP DIRECTIONAL ISOLATE` character.
  ///
  /// End the scope of the last [LRI], [RLI], or [FSI].
  static const String PDI = '\u2069';

  /// The `U+200E LEFT-TO-RIGHT MARK` character.
  ///
  /// Left-to-right zero-width character.
  static const String LRM = '\u200E';

  /// The `U+200F RIGHT-TO-LEFT MARK` character.
  ///
  /// Right-to-left zero-width non-Arabic character.
  static const String RLM = '\u200F';

  /// The `U+061C ARABIC LETTER MARK` character.
  ///
  /// Right-to-left zero-width Arabic character.
  static const String ALM = '\u061C';
}

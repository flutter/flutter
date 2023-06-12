// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.token;

import 'token.dart' as analyzer;
import 'token.dart' show Token, TokenType;

import 'token_constants.dart' show IDENTIFIER_TOKEN;

import 'string_canonicalizer.dart';

/**
 * A String-valued token. Represents identifiers, string literals,
 * number literals, comments, and error tokens, using the corresponding
 * precedence info.
 */
class StringToken extends analyzer.SimpleToken implements analyzer.StringToken {
  /**
   * The length threshold above which substring tokens are computed lazily.
   *
   * For string tokens that are substrings of the program source, the actual
   * substring extraction is performed lazily. This is beneficial because
   * not all scanned code are actually used. For unused parts, the substrings
   * are never computed and allocated.
   */
  static const int LAZY_THRESHOLD = 4;

  dynamic /* String | LazySubstring */ valueOrLazySubstring;

  /**
   * Creates a non-lazy string token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  StringToken.fromString(TokenType type, String value, int charOffset,
      {bool canonicalize: false, analyzer.CommentToken? precedingComments})
      : valueOrLazySubstring = canonicalizedString(
            value, /* start = */ 0, value.length, canonicalize),
        super(type, charOffset, precedingComments);

  /**
   * Creates a lazy string token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  StringToken.fromSubstring(
      TokenType type, String data, int start, int end, int charOffset,
      {bool canonicalize: false, analyzer.CommentToken? precedingComments})
      : super(type, charOffset, precedingComments) {
    int length = end - start;
    if (length <= LAZY_THRESHOLD) {
      valueOrLazySubstring =
          canonicalizedString(data, start, end, canonicalize);
    } else {
      valueOrLazySubstring =
          new _LazySubstring(data, start, length, canonicalize);
    }
  }

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  StringToken.fromUtf8Bytes(TokenType type, List<int> data, int start, int end,
      bool asciiOnly, int charOffset,
      {analyzer.CommentToken? precedingComments})
      : super(type, charOffset, precedingComments) {
    int length = end - start;
    if (length <= LAZY_THRESHOLD) {
      valueOrLazySubstring = decodeUtf8(data, start, end, asciiOnly);
    } else {
      valueOrLazySubstring = new _LazySubstring(data, start, length, asciiOnly);
    }
  }

  StringToken._(TokenType type, this.valueOrLazySubstring, int charOffset,
      [analyzer.CommentToken? precedingComments])
      : super(type, charOffset, precedingComments);

  @override
  String get lexeme {
    if (valueOrLazySubstring is String) {
      return valueOrLazySubstring;
    } else {
      assert(valueOrLazySubstring is _LazySubstring);
      dynamic data = valueOrLazySubstring.data;
      int start = valueOrLazySubstring.start;
      int end = start + (valueOrLazySubstring as _LazySubstring).length;
      if (data is String) {
        valueOrLazySubstring = canonicalizedString(
            data, start, end, valueOrLazySubstring.boolValue);
      } else {
        valueOrLazySubstring =
            decodeUtf8(data, start, end, valueOrLazySubstring.boolValue);
      }
      return valueOrLazySubstring;
    }
  }

  @override
  bool get isIdentifier => identical(kind, IDENTIFIER_TOKEN);

  @override
  String toString() => lexeme;

  static final StringCanonicalizer canonicalizer = new StringCanonicalizer();

  static String canonicalizedString(
      String s, int start, int end, bool canonicalize) {
    if (!canonicalize) return s;
    return canonicalizer.canonicalize(s, start, end, /* asciiOnly = */ false);
  }

  static String decodeUtf8(List<int> data, int start, int end, bool asciiOnly) {
    return canonicalizer.canonicalize(data, start, end, asciiOnly);
  }

  @override
  Token copy() => new StringToken._(
      type, valueOrLazySubstring, charOffset, copyComments(precedingComments));

  @override
  String value() => lexeme;
}

/**
 * A String-valued token that does not exist in the original source.
 */
class SyntheticStringToken extends StringToken
    implements analyzer.SyntheticStringToken {
  SyntheticStringToken(TokenType type, String value, int offset,
      [analyzer.CommentToken? precedingComments])
      : super._(type, value, offset, precedingComments);

  @override
  int get length => 0;

  @override
  Token copy() => new SyntheticStringToken(
      type, valueOrLazySubstring, offset, copyComments(precedingComments));
}

class CommentToken extends StringToken implements analyzer.CommentToken {
  @override
  analyzer.SimpleToken? parent;

  /**
   * Creates a lazy comment token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  CommentToken.fromSubstring(
      TokenType type, String data, int start, int end, int charOffset,
      {bool canonicalize: false})
      : super.fromSubstring(type, data, start, end, charOffset,
            canonicalize: canonicalize);

  /**
   * Creates a non-lazy comment token.
   */
  CommentToken.fromString(TokenType type, String lexeme, int charOffset)
      : super.fromString(type, lexeme, charOffset);

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  CommentToken.fromUtf8Bytes(TokenType type, List<int> data, int start, int end,
      bool asciiOnly, int charOffset)
      : super.fromUtf8Bytes(type, data, start, end, asciiOnly, charOffset);

  CommentToken._(TokenType type, valueOrLazySubstring, int charOffset)
      : super._(type, valueOrLazySubstring, charOffset);

  @override
  CommentToken copy() =>
      new CommentToken._(type, valueOrLazySubstring, charOffset);

  @override
  void remove() {
    if (previous != null) {
      previous!.setNextWithoutSettingPrevious(next);
      next?.previous = previous;
    } else {
      assert(parent!.precedingComments == this);
      parent!.precedingComments = next as CommentToken;
    }
  }
}

class LanguageVersionToken extends CommentToken
    implements analyzer.LanguageVersionToken {
  @override
  int major;

  @override
  int minor;

  LanguageVersionToken.from(String text, int offset, this.major, this.minor)
      : super.fromString(TokenType.SINGLE_LINE_COMMENT, text, offset);

  LanguageVersionToken.fromSubstring(
      String string, int start, int end, int tokenStart, this.major, this.minor,
      {bool canonicalize: false})
      : super.fromSubstring(
            TokenType.SINGLE_LINE_COMMENT, string, start, end, tokenStart,
            canonicalize: canonicalize);

  LanguageVersionToken.fromUtf8Bytes(List<int> bytes, int start, int end,
      int tokenStart, this.major, this.minor)
      : super.fromUtf8Bytes(
            TokenType.SINGLE_LINE_COMMENT, bytes, start, end, true, tokenStart);

  @override
  LanguageVersionToken copy() =>
      new LanguageVersionToken.from(lexeme, offset, major, minor);
}

class DartDocToken extends CommentToken
    implements analyzer.DocumentationCommentToken {
  /**
   * Creates a lazy comment token. If [canonicalize] is true, the string
   * is canonicalized before the token is created.
   */
  DartDocToken.fromSubstring(
      TokenType type, String data, int start, int end, int charOffset,
      {bool canonicalize: false})
      : super.fromSubstring(type, data, start, end, charOffset,
            canonicalize: canonicalize);

  /**
   * Creates a lazy string token. If [asciiOnly] is false, the byte array
   * is passed through a UTF-8 decoder.
   */
  DartDocToken.fromUtf8Bytes(TokenType type, List<int> data, int start, int end,
      bool asciiOnly, int charOffset)
      : super.fromUtf8Bytes(type, data, start, end, asciiOnly, charOffset);

  DartDocToken._(TokenType type, valueOrLazySubstring, int charOffset)
      : super._(type, valueOrLazySubstring, charOffset);

  @override
  DartDocToken copy() =>
      new DartDocToken._(type, valueOrLazySubstring, charOffset);
}

/**
 * This class represents the necessary information to compute a substring
 * lazily. The substring can either originate from a string or from
 * a [:List<int>:] of UTF-8 bytes.
 */
abstract class _LazySubstring {
  /** The original data, either a string or a List<int> */
  get data;

  int get start;
  int get length;

  /**
   * If this substring is based on a String, the [boolValue] indicates whether
   * the resulting substring should be canonicalized.
   *
   * For substrings based on a byte array, the [boolValue] is true if the
   * array only holds ASCII characters. The resulting substring will be
   * canonicalized after decoding.
   */
  bool get boolValue;

  _LazySubstring.internal();

  factory _LazySubstring(data, int start, int length, bool b) {
    // See comment on [CompactLazySubstring].
    if (start < 0x100000 && length < 0x200) {
      int fields = (start << 9);
      fields = fields | length;
      fields = fields << 1;
      if (b) fields |= 1;
      return new _CompactLazySubstring(data, fields);
    } else {
      return new _FullLazySubstring(data, start, length, b);
    }
  }
}

/**
 * This class encodes [start], [length] and [boolValue] in a single
 * 30 bit integer. It uses 20 bits for [start], which covers source files
 * of 1MB. [length] has 9 bits, which covers 512 characters.
 *
 * The file html_dart2js.dart is currently around 1MB.
 */
class _CompactLazySubstring extends _LazySubstring {
  final dynamic data;
  final int fields;

  _CompactLazySubstring(this.data, this.fields) : super.internal();

  int get start => fields >> 10;
  int get length => (fields >> 1) & 0x1ff;
  bool get boolValue => (fields & 1) == 1;
}

class _FullLazySubstring extends _LazySubstring {
  final dynamic data;
  final int start;
  final int length;
  final bool boolValue;
  _FullLazySubstring(this.data, this.start, this.length, this.boolValue)
      : super.internal();
}

bool isUserDefinableOperator(String value) {
  return isBinaryOperator(value) ||
      isMinusOperator(value) ||
      isTernaryOperator(value) ||
      isUnaryOperator(value);
}

bool isUnaryOperator(String value) => identical(value, "~");

bool isBinaryOperator(String value) {
  return identical(value, "==") ||
      identical(value, "[]") ||
      identical(value, "*") ||
      identical(value, "/") ||
      identical(value, "%") ||
      identical(value, "~/") ||
      identical(value, "+") ||
      identical(value, "<<") ||
      identical(value, ">>") ||
      identical(value, ">>>") ||
      identical(value, ">=") ||
      identical(value, ">") ||
      identical(value, "<=") ||
      identical(value, "<") ||
      identical(value, "&") ||
      identical(value, "^") ||
      identical(value, "|");
}

bool isTernaryOperator(String value) => identical(value, "[]=");

bool isMinusOperator(String value) => identical(value, "-");

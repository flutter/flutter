// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../parser.dart';

/// A single token in the Dart language.
class Token {
  /// A member of [TokenKind] specifying what kind of token this is.
  final int kind;

  /// The location where this token was parsed from.
  final FileSpan span;

  /// The start offset of this token.
  int get start => span.start.offset;

  /// The end offset of this token.
  int get end => span.end.offset;

  /// Returns the source text corresponding to this [Token].
  String get text => span.text;

  Token(this.kind, this.span);

  /// Returns a pretty representation of this token for error messages.
  @override
  String toString() {
    var kindText = TokenKind.kindToString(kind);
    var actualText = text.trim();
    if (kindText != actualText) {
      if (actualText.length > 10) {
        actualText = '${actualText.substring(0, 8)}...';
      }
      return '$kindText($actualText)';
    } else {
      return kindText;
    }
  }
}

/// A token containing a parsed literal value.
class LiteralToken extends Token {
  dynamic value;
  LiteralToken(int kind, FileSpan span, this.value) : super(kind, span);
}

/// A token containing error information.
class ErrorToken extends Token {
  String? message;
  ErrorToken(int kind, FileSpan span, this.message) : super(kind, span);
}

/// CSS ident-token.
///
/// See <http://dev.w3.org/csswg/css-syntax/#typedef-ident-token> and
/// <http://dev.w3.org/csswg/css-syntax/#ident-token-diagram>.
class IdentifierToken extends Token {
  @override
  final String text;

  IdentifierToken(this.text, int kind, FileSpan span) : super(kind, span);
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

/// A token in a boolean selector.
class Token {
  /// The type of the token.
  final TokenType type;

  /// The span indicating where this token came from.
  ///
  /// This is a [FileSpan] because the tokens are parsed from a single
  /// continuous string, but the string itself isn't actually a file. It might
  /// come from a statically-parsed annotation or from a parameter.
  final FileSpan span;

  Token(this.type, this.span);
}

/// A token representing an identifier.
class IdentifierToken implements Token {
  @override
  final type = TokenType.identifier;
  @override
  final FileSpan span;

  /// The name of the identifier.
  final String name;

  IdentifierToken(this.name, this.span);

  @override
  String toString() => 'identifier "$name"';
}

/// An enumeration of types of tokens.
class TokenType {
  /// A `(` character.
  static const leftParen = TokenType._('left paren');

  /// A `)` character.
  static const rightParen = TokenType._('right paren');

  /// A `||` sequence.
  static const or = TokenType._('or');

  /// A `&&` sequence.
  static const and = TokenType._('and');

  /// A `!` character.
  static const not = TokenType._('not');

  /// A `?` character.
  static const questionMark = TokenType._('question mark');

  /// A `:` character.
  static const colon = TokenType._('colon');

  /// A named identifier.
  static const identifier = TokenType._('identifier');

  /// The end of the selector.
  static const endOfFile = TokenType._('end of file');

  /// The name of the token type.
  final String name;

  const TokenType._(this.name);

  @override
  String toString() => name;
}

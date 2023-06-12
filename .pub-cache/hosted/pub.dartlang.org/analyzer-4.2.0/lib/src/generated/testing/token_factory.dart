// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:meta/meta.dart';

/// A set of utility methods that can be used to create tokens.
@internal
class TokenFactory {
  static Token tokenFromKeyword(Keyword keyword) => KeywordToken(keyword, 0);

  static Token tokenFromString(String lexeme) =>
      StringToken(TokenType.STRING, lexeme, 0);

  static Token tokenFromType(TokenType type) => Token(type, 0);

  static Token tokenFromTypeAndString(TokenType type, String lexeme) =>
      StringToken(type, lexeme, 0);
}

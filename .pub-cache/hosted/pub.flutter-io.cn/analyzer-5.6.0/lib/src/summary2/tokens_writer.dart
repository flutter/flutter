// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';

class TokensWriter {
  static UnlinkedTokenType astToBinaryTokenType(TokenType type) {
    if (type == Keyword.ABSTRACT) {
      return UnlinkedTokenType.ABSTRACT;
    } else if (type == TokenType.AMPERSAND) {
      return UnlinkedTokenType.AMPERSAND;
    } else if (type == TokenType.AMPERSAND_AMPERSAND) {
      return UnlinkedTokenType.AMPERSAND_AMPERSAND;
    } else if (type == TokenType.AMPERSAND_EQ) {
      return UnlinkedTokenType.AMPERSAND_EQ;
    } else if (type == TokenType.AS) {
      return UnlinkedTokenType.AS;
    } else if (type == Keyword.ASSERT) {
      return UnlinkedTokenType.ASSERT;
    } else if (type == Keyword.ASYNC) {
      return UnlinkedTokenType.ASYNC;
    } else if (type == TokenType.AT) {
      return UnlinkedTokenType.AT;
    } else if (type == Keyword.AWAIT) {
      return UnlinkedTokenType.AWAIT;
    } else if (type == TokenType.BACKPING) {
      return UnlinkedTokenType.BACKPING;
    } else if (type == TokenType.BACKSLASH) {
      return UnlinkedTokenType.BACKSLASH;
    } else if (type == TokenType.BANG) {
      return UnlinkedTokenType.BANG;
    } else if (type == TokenType.BANG_EQ) {
      return UnlinkedTokenType.BANG_EQ;
    } else if (type == TokenType.BANG_EQ_EQ) {
      return UnlinkedTokenType.BANG_EQ_EQ;
    } else if (type == TokenType.BAR) {
      return UnlinkedTokenType.BAR;
    } else if (type == TokenType.BAR_BAR) {
      return UnlinkedTokenType.BAR_BAR;
    } else if (type == TokenType.BAR_EQ) {
      return UnlinkedTokenType.BAR_EQ;
    } else if (type == Keyword.BREAK) {
      return UnlinkedTokenType.BREAK;
    } else if (type == TokenType.CARET) {
      return UnlinkedTokenType.CARET;
    } else if (type == TokenType.CARET_EQ) {
      return UnlinkedTokenType.CARET_EQ;
    } else if (type == Keyword.CASE) {
      return UnlinkedTokenType.CASE;
    } else if (type == Keyword.CATCH) {
      return UnlinkedTokenType.CATCH;
    } else if (type == Keyword.CLASS) {
      return UnlinkedTokenType.CLASS;
    } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
      return UnlinkedTokenType.CLOSE_CURLY_BRACKET;
    } else if (type == TokenType.CLOSE_PAREN) {
      return UnlinkedTokenType.CLOSE_PAREN;
    } else if (type == TokenType.CLOSE_SQUARE_BRACKET) {
      return UnlinkedTokenType.CLOSE_SQUARE_BRACKET;
    } else if (type == TokenType.COLON) {
      return UnlinkedTokenType.COLON;
    } else if (type == TokenType.COMMA) {
      return UnlinkedTokenType.COMMA;
    } else if (type == Keyword.CONST) {
      return UnlinkedTokenType.CONST;
    } else if (type == Keyword.CONTINUE) {
      return UnlinkedTokenType.CONTINUE;
    } else if (type == Keyword.COVARIANT) {
      return UnlinkedTokenType.COVARIANT;
    } else if (type == Keyword.DEFAULT) {
      return UnlinkedTokenType.DEFAULT;
    } else if (type == Keyword.DEFERRED) {
      return UnlinkedTokenType.DEFERRED;
    } else if (type == Keyword.DO) {
      return UnlinkedTokenType.DO;
    } else if (type == TokenType.DOUBLE) {
      return UnlinkedTokenType.DOUBLE;
    } else if (type == Keyword.DYNAMIC) {
      return UnlinkedTokenType.DYNAMIC;
    } else if (type == Keyword.ELSE) {
      return UnlinkedTokenType.ELSE;
    } else if (type == Keyword.ENUM) {
      return UnlinkedTokenType.ENUM;
    } else if (type == TokenType.EOF) {
      return UnlinkedTokenType.EOF;
    } else if (type == TokenType.EQ) {
      return UnlinkedTokenType.EQ;
    } else if (type == TokenType.EQ_EQ) {
      return UnlinkedTokenType.EQ_EQ;
    } else if (type == TokenType.EQ_EQ_EQ) {
      return UnlinkedTokenType.EQ_EQ_EQ;
    } else if (type == Keyword.EXPORT) {
      return UnlinkedTokenType.EXPORT;
    } else if (type == Keyword.EXTENDS) {
      return UnlinkedTokenType.EXTENDS;
    } else if (type == Keyword.EXTERNAL) {
      return UnlinkedTokenType.EXTERNAL;
    } else if (type == Keyword.FACTORY) {
      return UnlinkedTokenType.FACTORY;
    } else if (type == Keyword.FALSE) {
      return UnlinkedTokenType.FALSE;
    } else if (type == Keyword.FINAL) {
      return UnlinkedTokenType.FINAL;
    } else if (type == Keyword.FINALLY) {
      return UnlinkedTokenType.FINALLY;
    } else if (type == Keyword.FOR) {
      return UnlinkedTokenType.FOR;
    } else if (type == Keyword.FUNCTION) {
      return UnlinkedTokenType.FUNCTION_KEYWORD;
    } else if (type == TokenType.FUNCTION) {
      return UnlinkedTokenType.FUNCTION;
    } else if (type == Keyword.GET) {
      return UnlinkedTokenType.GET;
    } else if (type == TokenType.GT) {
      return UnlinkedTokenType.GT;
    } else if (type == TokenType.GT_EQ) {
      return UnlinkedTokenType.GT_EQ;
    } else if (type == TokenType.GT_GT) {
      return UnlinkedTokenType.GT_GT;
    } else if (type == TokenType.GT_GT_EQ) {
      return UnlinkedTokenType.GT_GT_EQ;
    } else if (type == TokenType.GT_GT_GT) {
      return UnlinkedTokenType.GT_GT_GT;
    } else if (type == TokenType.GT_GT_GT_EQ) {
      return UnlinkedTokenType.GT_GT_GT_EQ;
    } else if (type == TokenType.HASH) {
      return UnlinkedTokenType.HASH;
    } else if (type == TokenType.HEXADECIMAL) {
      return UnlinkedTokenType.HEXADECIMAL;
    } else if (type == Keyword.HIDE) {
      return UnlinkedTokenType.HIDE;
    } else if (type == TokenType.IDENTIFIER) {
      return UnlinkedTokenType.IDENTIFIER;
    } else if (type == Keyword.IF) {
      return UnlinkedTokenType.IF;
    } else if (type == Keyword.IMPLEMENTS) {
      return UnlinkedTokenType.IMPLEMENTS;
    } else if (type == Keyword.IMPORT) {
      return UnlinkedTokenType.IMPORT;
    } else if (type == Keyword.IN) {
      return UnlinkedTokenType.IN;
    } else if (type == TokenType.INDEX) {
      return UnlinkedTokenType.INDEX;
    } else if (type == TokenType.INDEX_EQ) {
      return UnlinkedTokenType.INDEX_EQ;
    } else if (type == Keyword.INOUT) {
      return UnlinkedTokenType.INOUT;
    } else if (type == TokenType.INT) {
      return UnlinkedTokenType.INT;
    } else if (type == Keyword.INTERFACE) {
      return UnlinkedTokenType.INTERFACE;
    } else if (type == TokenType.IS) {
      return UnlinkedTokenType.IS;
    } else if (type == Keyword.LATE) {
      return UnlinkedTokenType.LATE;
    } else if (type == Keyword.LIBRARY) {
      return UnlinkedTokenType.LIBRARY;
    } else if (type == TokenType.LT) {
      return UnlinkedTokenType.LT;
    } else if (type == TokenType.LT_EQ) {
      return UnlinkedTokenType.LT_EQ;
    } else if (type == TokenType.LT_LT) {
      return UnlinkedTokenType.LT_LT;
    } else if (type == TokenType.LT_LT_EQ) {
      return UnlinkedTokenType.LT_LT_EQ;
    } else if (type == TokenType.MINUS) {
      return UnlinkedTokenType.MINUS;
    } else if (type == TokenType.MINUS_EQ) {
      return UnlinkedTokenType.MINUS_EQ;
    } else if (type == TokenType.MINUS_MINUS) {
      return UnlinkedTokenType.MINUS_MINUS;
    } else if (type == Keyword.MIXIN) {
      return UnlinkedTokenType.MIXIN;
    } else if (type == TokenType.MULTI_LINE_COMMENT) {
      return UnlinkedTokenType.MULTI_LINE_COMMENT;
    } else if (type == Keyword.NATIVE) {
      return UnlinkedTokenType.NATIVE;
    } else if (type == Keyword.NEW) {
      return UnlinkedTokenType.NEW;
    } else if (type == Keyword.NULL) {
      return UnlinkedTokenType.NULL;
    } else if (type == Keyword.OF) {
      return UnlinkedTokenType.OF;
    } else if (type == Keyword.ON) {
      return UnlinkedTokenType.ON;
    } else if (type == TokenType.OPEN_CURLY_BRACKET) {
      return UnlinkedTokenType.OPEN_CURLY_BRACKET;
    } else if (type == TokenType.OPEN_PAREN) {
      return UnlinkedTokenType.OPEN_PAREN;
    } else if (type == TokenType.OPEN_SQUARE_BRACKET) {
      return UnlinkedTokenType.OPEN_SQUARE_BRACKET;
    } else if (type == Keyword.OPERATOR) {
      return UnlinkedTokenType.OPERATOR;
    } else if (type == Keyword.OUT) {
      return UnlinkedTokenType.OUT;
    } else if (type == Keyword.PART) {
      return UnlinkedTokenType.PART;
    } else if (type == Keyword.PATCH) {
      return UnlinkedTokenType.PATCH;
    } else if (type == TokenType.PERCENT) {
      return UnlinkedTokenType.PERCENT;
    } else if (type == TokenType.PERCENT_EQ) {
      return UnlinkedTokenType.PERCENT_EQ;
    } else if (type == TokenType.PERIOD) {
      return UnlinkedTokenType.PERIOD;
    } else if (type == TokenType.PERIOD_PERIOD) {
      return UnlinkedTokenType.PERIOD_PERIOD;
    } else if (type == TokenType.PERIOD_PERIOD_PERIOD) {
      return UnlinkedTokenType.PERIOD_PERIOD_PERIOD;
    } else if (type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
      return UnlinkedTokenType.PERIOD_PERIOD_PERIOD_QUESTION;
    } else if (type == TokenType.PLUS) {
      return UnlinkedTokenType.PLUS;
    } else if (type == TokenType.PLUS_EQ) {
      return UnlinkedTokenType.PLUS_EQ;
    } else if (type == TokenType.PLUS_PLUS) {
      return UnlinkedTokenType.PLUS_PLUS;
    } else if (type == TokenType.QUESTION) {
      return UnlinkedTokenType.QUESTION;
    } else if (type == TokenType.QUESTION_PERIOD) {
      return UnlinkedTokenType.QUESTION_PERIOD;
    } else if (type == TokenType.QUESTION_QUESTION) {
      return UnlinkedTokenType.QUESTION_QUESTION;
    } else if (type == TokenType.QUESTION_QUESTION_EQ) {
      return UnlinkedTokenType.QUESTION_QUESTION_EQ;
    } else if (type == Keyword.REQUIRED) {
      return UnlinkedTokenType.REQUIRED;
    } else if (type == Keyword.RETHROW) {
      return UnlinkedTokenType.RETHROW;
    } else if (type == Keyword.RETURN) {
      return UnlinkedTokenType.RETURN;
    } else if (type == TokenType.SCRIPT_TAG) {
      return UnlinkedTokenType.SCRIPT_TAG;
    } else if (type == TokenType.SEMICOLON) {
      return UnlinkedTokenType.SEMICOLON;
    } else if (type == Keyword.SET) {
      return UnlinkedTokenType.SET;
    } else if (type == Keyword.SHOW) {
      return UnlinkedTokenType.SHOW;
    } else if (type == TokenType.SINGLE_LINE_COMMENT) {
      return UnlinkedTokenType.SINGLE_LINE_COMMENT;
    } else if (type == TokenType.SLASH) {
      return UnlinkedTokenType.SLASH;
    } else if (type == TokenType.SLASH_EQ) {
      return UnlinkedTokenType.SLASH_EQ;
    } else if (type == Keyword.SOURCE) {
      return UnlinkedTokenType.SOURCE;
    } else if (type == TokenType.STAR) {
      return UnlinkedTokenType.STAR;
    } else if (type == TokenType.STAR_EQ) {
      return UnlinkedTokenType.STAR_EQ;
    } else if (type == Keyword.STATIC) {
      return UnlinkedTokenType.STATIC;
    } else if (type == TokenType.STRING) {
      return UnlinkedTokenType.STRING;
    } else if (type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
      return UnlinkedTokenType.STRING_INTERPOLATION_EXPRESSION;
    } else if (type == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
      return UnlinkedTokenType.STRING_INTERPOLATION_IDENTIFIER;
    } else if (type == Keyword.SUPER) {
      return UnlinkedTokenType.SUPER;
    } else if (type == Keyword.SWITCH) {
      return UnlinkedTokenType.SWITCH;
    } else if (type == Keyword.SYNC) {
      return UnlinkedTokenType.SYNC;
    } else if (type == Keyword.THIS) {
      return UnlinkedTokenType.THIS;
    } else if (type == Keyword.THROW) {
      return UnlinkedTokenType.THROW;
    } else if (type == TokenType.TILDE) {
      return UnlinkedTokenType.TILDE;
    } else if (type == TokenType.TILDE_SLASH) {
      return UnlinkedTokenType.TILDE_SLASH;
    } else if (type == TokenType.TILDE_SLASH_EQ) {
      return UnlinkedTokenType.TILDE_SLASH_EQ;
    } else if (type == Keyword.TRUE) {
      return UnlinkedTokenType.TRUE;
    } else if (type == Keyword.TRY) {
      return UnlinkedTokenType.TRY;
    } else if (type == Keyword.TYPEDEF) {
      return UnlinkedTokenType.TYPEDEF;
    } else if (type == Keyword.VAR) {
      return UnlinkedTokenType.VAR;
    } else if (type == Keyword.VOID) {
      return UnlinkedTokenType.VOID;
    } else if (type == Keyword.WHILE) {
      return UnlinkedTokenType.WHILE;
    } else if (type == Keyword.WITH) {
      return UnlinkedTokenType.WITH;
    } else if (type == Keyword.YIELD) {
      return UnlinkedTokenType.YIELD;
    } else {
      throw StateError('Unexpected type: $type');
    }
  }
}

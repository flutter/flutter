// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';

class Tokens {
  static Token as_() => TokenFactory.tokenFromKeyword(Keyword.AS);

  static Token assert_() => TokenFactory.tokenFromKeyword(Keyword.ASSERT);

  static Token async_() => TokenFactory.tokenFromKeyword(Keyword.ASYNC);

  static Token at() => TokenFactory.tokenFromType(TokenType.AT);

  static Token await_() => TokenFactory.tokenFromKeyword(Keyword.AWAIT);

  static Token bang() => TokenFactory.tokenFromType(TokenType.BANG);

  static Token break_() => TokenFactory.tokenFromKeyword(Keyword.BREAK);

  static Token case_() => TokenFactory.tokenFromKeyword(Keyword.CASE);

  static Token catch_() => TokenFactory.tokenFromKeyword(Keyword.CATCH);

  static Token? choose(bool if1, Token then1, bool if2, Token then2,
      [bool? if3, Token? then3]) {
    if (if1) return then1;
    if (if2) return then2;
    if (if3 == true) return then3!;
    return null;
  }

  static Token class_() => TokenFactory.tokenFromKeyword(Keyword.CLASS);

  static Token closeCurlyBracket() =>
      TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET);

  static Token closeParenthesis() =>
      TokenFactory.tokenFromType(TokenType.CLOSE_PAREN);

  static Token closeSquareBracket() =>
      TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET);

  static Token colon() => TokenFactory.tokenFromType(TokenType.COLON);

  static Token comma() => TokenFactory.tokenFromType(TokenType.COMMA);

  static Token const_() => TokenFactory.tokenFromKeyword(Keyword.CONST);

  static Token continue_() => TokenFactory.tokenFromKeyword(Keyword.CONTINUE);

  static Token covariant_() => TokenFactory.tokenFromKeyword(Keyword.COVARIANT);

  static Token default_() => TokenFactory.tokenFromKeyword(Keyword.DEFAULT);

  static Token do_() => TokenFactory.tokenFromKeyword(Keyword.DO);

  static Token else_() => TokenFactory.tokenFromKeyword(Keyword.ELSE);

  static Token enum_() => TokenFactory.tokenFromKeyword(Keyword.ENUM);

  static Token eq() => TokenFactory.tokenFromType(TokenType.EQ);

  static Token export_() => TokenFactory.tokenFromKeyword(Keyword.EXPORT);

  static Token extends_() => TokenFactory.tokenFromKeyword(Keyword.EXTENDS);

  static Token extension_() => TokenFactory.tokenFromKeyword(Keyword.EXTENSION);

  static Token external_() => TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);

  static Token factory_() => TokenFactory.tokenFromKeyword(Keyword.FACTORY);

  static Token false_() => TokenFactory.tokenFromKeyword(Keyword.FALSE);

  static Token final_() => TokenFactory.tokenFromKeyword(Keyword.FINAL);

  static Token finally_() => TokenFactory.tokenFromKeyword(Keyword.FINALLY);

  static Token for_() => TokenFactory.tokenFromKeyword(Keyword.FOR);

  static Token fromType(UnlinkedTokenType type) {
    return TokenFactory.tokenFromType(
      TokensContext.binaryToAstTokenType(type),
    );
  }

  static Token function() => TokenFactory.tokenFromKeyword(Keyword.FUNCTION);

  static Token get_() => TokenFactory.tokenFromKeyword(Keyword.GET);

  static Token gt() => TokenFactory.tokenFromType(TokenType.GT);

  static Token hash() => TokenFactory.tokenFromType(TokenType.HASH);

  static Token hide_() => TokenFactory.tokenFromKeyword(Keyword.HIDE);

  static Token if_() => TokenFactory.tokenFromKeyword(Keyword.IF);

  static Token implements_() => TokenFactory.tokenFromKeyword(Keyword.IMPORT);

  static Token import_() => TokenFactory.tokenFromKeyword(Keyword.IMPLEMENTS);

  static Token in_() => TokenFactory.tokenFromKeyword(Keyword.IN);

  static Token is_() => TokenFactory.tokenFromKeyword(Keyword.IS);

  static Token late_() => TokenFactory.tokenFromKeyword(Keyword.LATE);

  static Token library_() => TokenFactory.tokenFromKeyword(Keyword.LIBRARY);

  static Token lt() => TokenFactory.tokenFromType(TokenType.LT);

  static Token mixin_() => TokenFactory.tokenFromKeyword(Keyword.MIXIN);

  static Token native_() => TokenFactory.tokenFromKeyword(Keyword.NATIVE);

  static Token new_() => TokenFactory.tokenFromKeyword(Keyword.NEW);

  static Token null_() => TokenFactory.tokenFromKeyword(Keyword.NULL);

  static Token of_() => TokenFactory.tokenFromKeyword(Keyword.OF);

  static Token on_() => TokenFactory.tokenFromKeyword(Keyword.ON);

  static Token openCurlyBracket() =>
      TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET);

  static Token openParenthesis() =>
      TokenFactory.tokenFromType(TokenType.OPEN_PAREN);

  static Token openSquareBracket() =>
      TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET);

  static Token operator_() => TokenFactory.tokenFromKeyword(Keyword.OPERATOR);

  static Token part_() => TokenFactory.tokenFromKeyword(Keyword.PART);

  static Token period() => TokenFactory.tokenFromType(TokenType.PERIOD);

  static Token periodPeriod() =>
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD);

  static Token periodPeriodPeriod() =>
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD);

  static Token periodPeriodPeriodQuestion() =>
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD_PERIOD_QUESTION);

  static Token question() => TokenFactory.tokenFromType(TokenType.QUESTION);

  static Token questionPeriod() =>
      TokenFactory.tokenFromType(TokenType.QUESTION_PERIOD);

  static Token questionPeriodPeriod() =>
      TokenFactory.tokenFromType(TokenType.QUESTION_PERIOD_PERIOD);

  static Token required_() => TokenFactory.tokenFromKeyword(Keyword.REQUIRED);

  static Token rethrow_() => TokenFactory.tokenFromKeyword(Keyword.RETHROW);

  static Token return_() => TokenFactory.tokenFromKeyword(Keyword.RETURN);

  static Token semicolon() => TokenFactory.tokenFromType(TokenType.SEMICOLON);

  static Token set_() => TokenFactory.tokenFromKeyword(Keyword.SET);

  static Token show_() => TokenFactory.tokenFromKeyword(Keyword.SHOW);

  static Token star() => TokenFactory.tokenFromType(TokenType.STAR);

  static Token static_() => TokenFactory.tokenFromKeyword(Keyword.STATIC);

  static Token stringInterpolationExpression() =>
      TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION);

  static Token super_() => TokenFactory.tokenFromKeyword(Keyword.SUPER);

  static Token switch_() => TokenFactory.tokenFromKeyword(Keyword.SWITCH);

  static Token sync_() => TokenFactory.tokenFromKeyword(Keyword.SYNC);

  static Token this_() => TokenFactory.tokenFromKeyword(Keyword.THIS);

  static Token throw_() => TokenFactory.tokenFromKeyword(Keyword.THROW);

  static Token true_() => TokenFactory.tokenFromKeyword(Keyword.TRUE);

  static Token try_() => TokenFactory.tokenFromKeyword(Keyword.TRY);

  static Token typedef_() => TokenFactory.tokenFromKeyword(Keyword.TYPEDEF);

  static Token var_() => TokenFactory.tokenFromKeyword(Keyword.VAR);

  static Token while_() => TokenFactory.tokenFromKeyword(Keyword.WHILE);

  static Token with_() => TokenFactory.tokenFromKeyword(Keyword.WITH);

  static Token yield_() => TokenFactory.tokenFromKeyword(Keyword.YIELD);
}

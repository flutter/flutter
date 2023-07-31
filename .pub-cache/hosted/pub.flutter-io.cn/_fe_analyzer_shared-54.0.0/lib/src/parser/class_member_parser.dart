// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.class_member_parser;

import '../scanner/token.dart' show Token;

import 'error_delegation_listener.dart' show ErrorDelegationListener;

import 'parser_impl.dart' show Parser;

/// Parser similar to [TopLevelParser] but also parses class members (excluding
/// their bodies).
class ClassMemberParser extends Parser {
  Parser? skipParser;

  ClassMemberParser(super.listener,
      {super.useImplicitCreationExpression, super.allowPatterns});

  @override
  Token parseExpression(Token token) {
    return skipExpression(token);
  }

  @override
  Token parseIdentifierExpression(Token token) {
    return token.next!;
  }

  Token skipExpression(Token token) {
    // TODO(askesc): We listen to errors occurring during expression parsing,
    // since the parser may rewrite the token stream such that the error is
    // not triggered during the second parse.
    // When the parser supports not doing token stream rewriting, use that
    // feature together with a no-op listener instead.
    this.skipParser ??= new Parser(new ErrorDelegationListener(listener),
        useImplicitCreationExpression: useImplicitCreationExpression,
        allowPatterns: allowPatterns);
    Parser skipParser = this.skipParser!;
    skipParser.mayParseFunctionExpressions = mayParseFunctionExpressions;
    skipParser.asyncState = asyncState;
    skipParser.loopState = loopState;
    return skipParser.parseExpression(token);
  }

  // This method is overridden for two reasons:
  // 1. Avoid generating events for arguments.
  // 2. Avoid calling skip expression for each argument (which doesn't work).
  @override
  Token parseArgumentsOpt(Token token, {bool forPattern = false}) =>
      skipArgumentsOpt(token);

  @override
  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    return skipFunctionBody(token, isExpression, allowAbstract);
  }

  @override
  Token parseInvalidBlock(Token token) => skipBlock(token);
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library _fe_analyzer_shared.parser;

import '../scanner/token.dart' show Token;

import 'listener.dart' show Listener;

import 'parser_impl.dart' show Parser;

import 'parser_error.dart' show ParserError;

import '../messages/codes.dart'
    show Message, messageNativeClauseShouldBeAnnotation;

export 'assert.dart' show Assert;

export 'block_kind.dart' show BlockKind;

export 'class_member_parser.dart' show ClassMemberParser;

export 'constructor_reference_context.dart' show ConstructorReferenceContext;

export 'formal_parameter_kind.dart' show FormalParameterKind;

export 'identifier_context.dart' show IdentifierContext;

export 'listener.dart' show Listener;

export 'declaration_kind.dart' show DeclarationKind;

export 'directive_context.dart' show DirectiveContext;

export 'member_kind.dart' show MemberKind;

export 'parser_impl.dart' show Parser;

export 'parser_error.dart' show ParserError;

export 'top_level_parser.dart' show TopLevelParser;

export 'util.dart' show lengthForToken, lengthOfSpan, optional;

class ErrorCollectingListener extends Listener {
  final List<ParserError> recoverableErrors = <ParserError>[];

  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation) {
      return;
    }
    recoverableErrors
        .add(new ParserError.fromTokens(startToken, endToken, message));
  }
}

List<ParserError> parse(Token tokens,
    {bool useImplicitCreationExpression: true}) {
  ErrorCollectingListener listener = new ErrorCollectingListener();
  Parser parser = new Parser(listener,
      useImplicitCreationExpression: useImplicitCreationExpression);
  parser.parseUnit(tokens);
  return listener.recoverableErrors;
}

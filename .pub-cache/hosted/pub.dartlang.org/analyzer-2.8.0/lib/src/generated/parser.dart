// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.parser;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' as fasta;
import 'package:_fe_analyzer_shared/src/parser/type_info.dart' as fasta;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/fasta/ast_builder.dart';
import 'package:analyzer/src/generated/source.dart';

export 'package:analyzer/src/dart/error/syntactic_errors.dart';

/// A parser used to parse tokens into an AST structure.
class Parser {
  late Token currentToken;

  /// The fasta parser being wrapped.
  late final fasta.Parser fastaParser;

  /// The builder which creates the analyzer AST data structures
  /// based on the Fasta parser.
  final AstBuilder astBuilder;

  Parser(Source source, AnalysisErrorListener errorListener,
      {required FeatureSet featureSet, bool allowNativeClause = true})
      : astBuilder = AstBuilder(
            ErrorReporter(
              errorListener,
              source,
              isNonNullableByDefault:
                  featureSet.isEnabled(Feature.non_nullable),
            ),
            source.uri,
            true,
            featureSet) {
    fastaParser = fasta.Parser(astBuilder);
    astBuilder.parser = fastaParser;
    astBuilder.allowNativeClause = allowNativeClause;
  }

  set allowNativeClause(bool value) {
    astBuilder.allowNativeClause = value;
  }

  bool get enableOptionalNewAndConst => false;

  set enableOptionalNewAndConst(bool enable) {}

  set enableSetLiterals(bool value) {
    // TODO(danrubel): Remove this method once the reference to this flag
    // has been removed from dart format.
  }

  set parseFunctionBodies(bool parseFunctionBodies) {
    astBuilder.parseFunctionBodies = parseFunctionBodies;
  }

  /// Append the given token to the end of the token stream,
  /// and update the token's offset.
  void appendToken(Token token, Token newToken) {
    while (!token.next!.isEof) {
      token = token.next!;
    }
    newToken
      ..offset = token.end
      ..setNext(token.next!);
    token.setNext(newToken);
  }

  Expression parseAdditiveExpression() => parseExpression2();

  Expression parseArgument() {
    currentToken = SimpleToken(TokenType.OPEN_PAREN, 0)..setNext(currentToken);
    appendToken(currentToken, SimpleToken(TokenType.CLOSE_PAREN, 0));
    currentToken = fastaParser
        .parseArguments(fastaParser.syntheticPreviousToken(currentToken))
        .next!;
    var invocation = astBuilder.pop() as MethodInvocation;
    return invocation.argumentList.arguments[0];
  }

  Expression parseAssignableExpression(bool primaryAllowed) =>
      parseExpression2();

  Expression parseBitwiseAndExpression() => parseExpression2();

  Expression parseBitwiseOrExpression() => parseExpression2();

  Expression parseBitwiseXorExpression() => parseExpression2();

  CompilationUnitImpl parseCompilationUnit(Token token) {
    currentToken = token;
    return parseCompilationUnit2();
  }

  CompilationUnitImpl parseCompilationUnit2() {
    currentToken = fastaParser.parseUnit(currentToken);
    return astBuilder.pop() as CompilationUnitImpl;
  }

  Expression parseConditionalExpression() => parseExpression2();

  Configuration parseConfiguration() {
    currentToken = fastaParser
        .parseConditionalUri(fastaParser.syntheticPreviousToken(currentToken))
        .next!;
    return astBuilder.pop() as Configuration;
  }

  Expression parseConstExpression() => parseExpression2();

  CompilationUnit parseDirectives(Token token) {
    currentToken = token;
    return parseDirectives2();
  }

  CompilationUnit parseDirectives2() {
    currentToken = fastaParser.parseDirectives(currentToken);
    return astBuilder.pop() as CompilationUnit;
  }

  DottedName parseDottedName() {
    currentToken = fastaParser
        .parseDottedName(fastaParser.syntheticPreviousToken(currentToken))
        .next!;
    return astBuilder.pop() as DottedName;
  }

  Expression parseEqualityExpression() => parseExpression2();

  Expression parseExpression(Token token) {
    currentToken = token;
    return parseExpression2();
  }

  Expression parseExpression2() {
    currentToken = fastaParser
        .parseExpression(fastaParser.syntheticPreviousToken(currentToken))
        .next!;
    return astBuilder.pop() as Expression;
  }

  Expression parseExpressionWithoutCascade() => parseExpression2();

  FormalParameterList parseFormalParameterList({bool inFunctionType = false}) {
    currentToken = fastaParser
        .parseFormalParametersRequiredOpt(
            fastaParser.syntheticPreviousToken(currentToken),
            inFunctionType
                ? fasta.MemberKind.GeneralizedFunctionType
                : fasta.MemberKind.NonStaticMethod)
        .next!;
    return astBuilder.pop() as FormalParameterList;
  }

  FunctionBody parseFunctionBody(
      bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    currentToken = fastaParser.parseAsyncModifierOpt(
        fastaParser.syntheticPreviousToken(currentToken));
    currentToken =
        fastaParser.parseFunctionBody(currentToken, inExpression, mayBeEmpty);
    return astBuilder.pop() as FunctionBody;
  }

  FunctionExpression parseFunctionExpression() =>
      parseExpression2() as FunctionExpression;

  Expression parseLogicalAndExpression() => parseExpression2();

  Expression parseLogicalOrExpression() => parseExpression2();

  Expression parseMultiplicativeExpression() => parseExpression2();

  InstanceCreationExpression parseNewExpression() =>
      parseExpression2() as InstanceCreationExpression;

  Expression parsePostfixExpression() => parseExpression2();

  Identifier parsePrefixedIdentifier() => parseExpression2() as Identifier;

  Expression parsePrimaryExpression() {
    currentToken = fastaParser
        .parsePrimary(fastaParser.syntheticPreviousToken(currentToken),
            fasta.IdentifierContext.expression)
        .next!;
    return astBuilder.pop() as Expression;
  }

  Expression parseRelationalExpression() => parseExpression2();

  Expression parseRethrowExpression() => parseExpression2();

  Expression parseShiftExpression() => parseExpression2();

  SimpleIdentifier parseSimpleIdentifier(
          {bool allowKeyword = false, bool isDeclaration = false}) =>
      parseExpression2() as SimpleIdentifier;

  Statement parseStatement(Token token) {
    currentToken = token;
    return parseStatement2();
  }

  Statement parseStatement2() {
    currentToken = fastaParser
        .parseStatement(fastaParser.syntheticPreviousToken(currentToken))
        .next!;
    return astBuilder.pop() as Statement;
  }

  StringLiteral parseStringLiteral() => parseExpression2() as StringLiteral;

  SymbolLiteral parseSymbolLiteral() => parseExpression2() as SymbolLiteral;

  Expression parseThrowExpression() => parseExpression2();

  Expression parseThrowExpressionWithoutCascade() => parseExpression2();

  AnnotatedNode parseTopLevelDeclaration(bool isDirective) {
    currentToken = fastaParser.parseTopLevelDeclaration(currentToken);
    return (isDirective ? astBuilder.directives : astBuilder.declarations)
        .removeLast();
  }

  TypeAnnotation parseTypeAnnotation(bool inExpression) {
    Token previous = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeType(previous, true, !inExpression)
        .parseType(previous, fastaParser)
        .next!;
    return astBuilder.pop() as TypeAnnotation;
  }

  TypeArgumentList parseTypeArgumentList() {
    Token previous = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeTypeParamOrArg(previous)
        .parseArguments(previous, fastaParser)
        .next!;
    return astBuilder.pop() as TypeArgumentList;
  }

  NamedType parseTypeName(bool inExpression) {
    Token previous = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeType(previous, true, !inExpression)
        .parseType(previous, fastaParser)
        .next!;
    return astBuilder.pop() as NamedType;
  }

  TypeParameter parseTypeParameter() {
    currentToken = SyntheticBeginToken(TokenType.LT, 0)
      ..endGroup = SyntheticToken(TokenType.GT, 0)
      ..setNext(currentToken);
    appendToken(currentToken, currentToken.endGroup!);
    TypeParameterList typeParams = parseTypeParameterList()!;
    return typeParams.typeParameters[0];
  }

  TypeParameterList? parseTypeParameterList() {
    Token token = fastaParser.syntheticPreviousToken(currentToken);
    currentToken = fasta
        .computeTypeParamOrArg(token, true)
        .parseVariables(token, fastaParser)
        .next!;
    return astBuilder.pop() as TypeParameterList?;
  }

  Expression parseUnaryExpression() => parseExpression2();
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' as analyzer;
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StatementParserTest);
  });
}

/// Tests of the fasta parser based on [StatementParserTestMixin].
@reflectiveTest
class StatementParserTest extends FastaParserTestCase {
  void test_35177() {
    var statement = parseStatement('(f)()<int>();') as ExpressionStatement;

    var funct1 = statement.expression as FunctionExpressionInvocation;
    List<TypeAnnotation> typeArgs = funct1.typeArguments!.arguments;
    expect(typeArgs, hasLength(1));
    var typeName = typeArgs[0] as NamedType;
    expect(typeName.name.name, 'int');
    expect(funct1.argumentList.arguments, hasLength(0));

    var funct2 = funct1.function as FunctionExpressionInvocation;
    expect(funct2.typeArguments, isNull);
    expect(funct2.argumentList.arguments, hasLength(0));

    var expression = funct2.function as ParenthesizedExpression;
    var identifier = expression.expression as SimpleIdentifier;
    expect(identifier.name, 'f');
  }

  void test_invalid_typeArg_34850() {
    var unit = parseCompilationUnit('foo Future<List<int>> bar() {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 4),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 4, 6),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 22, 3),
    ]);
    // Validate that recovery has properly updated the token stream.
    analyzer.Token token = unit.beginToken;
    while (!token.isEof) {
      expect(token.type, isNot(TokenType.GT_GT));
      analyzer.Token next = token.next!;
      expect(next.previous, token);
      token = next;
    }
  }

  void test_invalid_typeParamAnnotation() {
    parseCompilationUnit('main() { C<@Foo T> v; }', errors: [
      expectedError(ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT, 11, 4)
    ]);
  }

  void test_invalid_typeParamAnnotation2() {
    parseCompilationUnit('main() { C<@Foo.bar(1) T> v; }', errors: [
      expectedError(ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT, 11, 11)
    ]);
  }

  void test_invalid_typeParamAnnotation3() {
    parseCompilationUnit('''
main() {
  C<@Foo.bar(const [], const [1], const{"":r""}, 0xFF + 2, .3, 4.5) T,
    F Function<G>(int, String, {Bar b}),
    void Function<H>(int i, [String j, K]),
    A<B<C>>,
    W<X<Y<Z>>>
  > v;
}''', errors: [
      expectedError(ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT, 13, 63)
    ]);
  }

  void test_parseAssertStatement() {
    var statement = parseStatement('assert (x);') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNull);
    expect(statement.message, isNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_messageLowPrecedence() {
    // Using a throw expression as an assert message would be silly in
    // practice, but it's the lowest precedence expression type, so verifying
    // that it works should give us high confidence that other expression types
    // will work as well.
    var statement =
        parseStatement('assert (x, throw "foo");') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_messageString() {
    var statement = parseStatement('assert (x, "foo");') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_trailingComma_message() {
    var statement = parseStatement('assert (x, "m",);') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_trailingComma_noMessage() {
    var statement = parseStatement('assert (x,);') as AssertStatement;
    assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNull);
    expect(statement.message, isNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseBlock_empty() {
    var block = parseStatement('{}') as Block;
    assertNoErrors();
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(0));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBlock_nonEmpty() {
    var block = parseStatement('{;}') as Block;
    assertNoErrors();
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(1));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBreakStatement_label() {
    var labeledStatement =
        parseStatement('foo: while (true) { break foo; }') as LabeledStatement;
    var whileStatement = labeledStatement.statement as WhileStatement;
    var statement =
        (whileStatement.body as Block).statements[0] as BreakStatement;
    assertNoErrors();
    expect(statement.breakKeyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseBreakStatement_noLabel() {
    var whileStatement =
        parseStatement('while (true) { break; }') as WhileStatement;
    var statement =
        (whileStatement.body as Block).statements[0] as BreakStatement;
    assertNoErrors();
    expect(statement.breakKeyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseContinueStatement_label() {
    var labeledStatement = parseStatement('foo: while (true) { continue foo; }')
        as LabeledStatement;
    var whileStatement = labeledStatement.statement as WhileStatement;
    var statement =
        (whileStatement.body as Block).statements[0] as ContinueStatement;
    assertNoErrors();
    expect(statement.continueKeyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseContinueStatement_noLabel() {
    var whileStatement =
        parseStatement('while (true) { continue; }') as WhileStatement;
    var statement =
        (whileStatement.body as Block).statements[0] as ContinueStatement;
    assertNoErrors();
    expect(statement.continueKeyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseDoStatement() {
    var statement = parseStatement('do {} while (x);') as DoStatement;
    assertNoErrors();
    expect(statement.doKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseElseAlone() {
    parseCompilationUnit('main() { else return 0; } ', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 4),
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 9, 4),
    ]);
  }

  void test_parseEmptyStatement() {
    var statement = parseStatement(';') as EmptyStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
  }

  void test_parseForStatement_each_await() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    String code = 'await for (element in list) {}';
    var forStatement = _parseAsyncStatement(code) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNotNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forEachParts.identifier, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_await2() {
    var forStatement = parseStatement(
      'await for (element in list) {}',
      inAsync: true,
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNotNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_finalExternal() {
    var forStatement = parseStatement(
      'for (final external in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forLoopParts.loopVariable.name.lexeme, 'external');
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_finalRequired() {
    var forStatement = parseStatement(
      'for (final required in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forLoopParts.loopVariable.name.lexeme, 'required');
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_genericFunctionType() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (void Function<T>(T) element in list) {}')
            as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_genericFunctionType2() {
    var forStatement = parseStatement(
      'for (void Function<T>(T) element in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_identifier() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forEachParts.identifier, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_identifier2() {
    var forStatement = parseStatement(
      'for (element in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithIdentifier;
    expect(forLoopParts.identifier, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_noType_metadata() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (@A var element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.loopVariable.metadata, hasLength(1));
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_noType_metadata2() {
    var forStatement = parseStatement(
      'for (@A var element in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.loopVariable.metadata, hasLength(1));
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_type() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (A element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_type2() {
    var forStatement = parseStatement(
      'for (A element in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_var() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var element in list) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forEachParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forEachParts.loopVariable, isNotNull);
    expect(forEachParts.inKeyword, isNotNull);
    expect(forEachParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_var2() {
    var forStatement = parseStatement(
      'for (var element in list) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForEachPartsWithDeclaration;
    expect(forLoopParts.loopVariable, isNotNull);
    expect(forLoopParts.inKeyword, isNotNull);
    expect(forLoopParts.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_c() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement = parseStatement('for (; i < count;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_c2() {
    var forStatement = parseStatement(
      'for (; i < count;) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forLoopParts.initialization, isNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_cu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (; i < count; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_cu2() {
    var forStatement = parseStatement(
      'for (; i < count; i++) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forLoopParts.initialization, isNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ecu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (i--; i < count; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNotNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ecu2() {
    var forStatement = parseStatement(
      'for (i--; i < count; i++) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forLoopParts.initialization, isNotNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement = parseStatement('for (var i = 0;;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(0));
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i2() {
    var forStatement = parseStatement(
      'for (var i = 0;;) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(0));
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i_withMetadata() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (@A var i = 0;;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(1));
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i_withMetadata2() {
    var forStatement = parseStatement(
      'for (@A var i = 0;;) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(1));
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ic() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var i = 0; i < count;) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ic2() {
    var forStatement = parseStatement(
      'for (var i = 0; i < count;) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_icu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var i = 0; i < count; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_icu2() {
    var forStatement = parseStatement(
      'for (var i = 0; i < count; i++) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iicuu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (int i = 0, j = count; i < j; i++, j--) {}')
            as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(2));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNotNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(2));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iicuu2() {
    var forStatement = parseStatement(
      'for (int i = 0, j = count; i < j; i++, j--) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(2));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNotNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(2));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iu() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement =
        parseStatement('for (var i = 0;; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iu2() {
    var forStatement = parseStatement(
      'for (var i = 0;; i++) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithDeclarations;
    VariableDeclarationList variables = forLoopParts.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_u() {
    // TODO(danrubel): remove this once control flow and spread collection
    // entry parsing is enabled by default
    var forStatement = parseStatement('for (;; i++) {}') as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forParts.initialization, isNull);
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.condition, isNull);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_u2() {
    var forStatement = parseStatement(
      'for (;; i++) {}',
    ) as ForStatement;
    assertNoErrors();
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    var forLoopParts = forStatement.forLoopParts as ForPartsWithExpression;
    expect(forLoopParts.initialization, isNull);
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.condition, isNull);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseFunctionDeclarationStatement() {
    var statement = parseStatement('void f(int p) => p * 2;')
        as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameters() {
    var statement =
        parseStatement('E f<E>(E p) => p * 2;') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
    expect(statement.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameters_noReturnType() {
    var statement =
        parseStatement('f<E>(E p) => p * 2;') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
    expect(statement.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseIfStatement_else_block() {
    var statement = parseStatement('if (x) {} else {}') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_else_emptyStatements() {
    var statement = parseStatement('if (true) ; else ;') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_else_statement() {
    var statement = parseStatement('if (x) f(x); else f(y);') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_noElse_block() {
    var statement = parseStatement('if (x) {}') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseIfStatement_noElse_statement() {
    var statement = parseStatement('if (x) f(x);') as IfStatement;
    assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseLocalVariable_external() {
    parseStatement('external int i;');
    assertErrors(errors: [
      expectedError(ParserErrorCode.EXTRANEOUS_MODIFIER, 0, 8),
    ]);
  }

  void test_parseNonLabeledStatement_const_list_empty() {
    var statement = parseStatement('const [];') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    var statement = parseStatement('const [1, 2];') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_empty() {
    var statement = parseStatement('const {};') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    // TODO(brianwilkerson) Implement more tests for this method.
    var statement = parseStatement("const {'a' : 1};") as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object() {
    var statement = parseStatement('const A();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    var statement = parseStatement('const A<B>.c();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters_34403() {
    var statement = parseStatement('const A<B>.c<C>();') as ExpressionStatement;
    assertErrorsWithCodes([ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS]);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_constructorInvocation() {
    var statement = parseStatement('new C().m();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_false() {
    var statement = parseStatement('false;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_functionDeclaration() {
    var statement = parseStatement('f() {}') as FunctionDeclarationStatement;
    assertNoErrors();
    var function = statement.functionDeclaration.functionExpression;
    expect(function.parameters!.parameters, isEmpty);
    expect(function.body, isNotNull);
  }

  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    var statement =
        parseStatement('f(void g()) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    var function = statement.functionDeclaration.functionExpression;
    expect(function.parameters!.parameters, hasLength(1));
    expect(function.body, isNotNull);
  }

  void test_parseNonLabeledStatement_functionExpressionIndex() {
    var statement = parseStatement('() {}[0] = null;') as ExpressionStatement;
    assertNoErrors();
    expect(statement, isNotNull);
  }

  void test_parseNonLabeledStatement_functionInvocation() {
    var statement = parseStatement('f();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    var statement =
        parseStatement('(a) {return a + a;} (3);') as ExpressionStatement;
    assertNoErrors();
    var invocation = statement.expression as FunctionExpressionInvocation;

    FunctionExpression expression = invocation.function as FunctionExpression;
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList.arguments, hasLength(1));
  }

  void test_parseNonLabeledStatement_localFunction_gftReturnType() {
    var statement = parseStatement('int Function(int) f(String s) => null;')
        as FunctionDeclarationStatement;
    assertNoErrors();
    FunctionDeclaration function = statement.functionDeclaration;
    expect(function.returnType, isGenericFunctionType);
  }

  void test_parseNonLabeledStatement_null() {
    var statement = parseStatement('null;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    var statement = parseStatement('library.getName();') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_true() {
    var statement = parseStatement('true;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_typeCast() {
    var statement = parseStatement('double.nan as num;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_variableDeclaration_final_namedFunction() {
    var statement = parseStatement('final int Function = 0;')
        as VariableDeclarationStatement;
    assertNoErrors();
    List<VariableDeclaration> variables = statement.variables.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'Function');
  }

  void test_parseNonLabeledStatement_variableDeclaration_gftType() {
    var statement =
        parseStatement('int Function(int) v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_functionReturnType() {
    var statement = parseStatement(
            'Function Function(int x1, {Function x}) Function<B extends core.int>(int x) v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType() {
    var statement = parseStatement('Function(int) Function(int) v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_gftReturnType2() {
    var statement = parseStatement('int Function(int) Function(int) v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_noReturnType() {
    var statement =
        parseStatement('Function(int) v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void test_parseNonLabeledStatement_variableDeclaration_gftType_returnType() {
    var statement =
        parseStatement('int Function<T>() v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void
      test_parseNonLabeledStatement_variableDeclaration_gftType_voidReturnType() {
    var statement =
        parseStatement('void Function() v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    expect(variableList.type, isGenericFunctionType);
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam() {
    var statement = parseStatement('C<T> v;') as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    var typeName = variableList.type as NamedType;
    expect(typeName.name.name, 'C');
    expect(typeName.typeArguments!.arguments, hasLength(1));
    var typeArgument = typeName.typeArguments!.arguments[0] as NamedType;
    expect(typeArgument.name.name, 'T');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam2() {
    var statement = parseStatement('C<T /* ignored comment */ > v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    var typeName = variableList.type as NamedType;
    expect(typeName.name.name, 'C');
    expect(typeName.typeArguments!.arguments, hasLength(1));
    var typeArgument = typeName.typeArguments!.arguments[0] as NamedType;
    expect(typeArgument.name.name, 'T');
  }

  void test_parseNonLabeledStatement_variableDeclaration_typeParam3() {
    var statement = parseStatement('C<T Function(String s)> v;')
        as VariableDeclarationStatement;
    assertNoErrors();
    VariableDeclarationList variableList = statement.variables;
    List<VariableDeclaration> variables = variableList.variables;
    expect(variables, hasLength(1));
    expect(variables[0].name.lexeme, 'v');
    var typeName = variableList.type as NamedType;
    expect(typeName.name.name, 'C');
    expect(typeName.typeArguments!.arguments, hasLength(1));
    expect(typeName.typeArguments!.arguments[0], isGenericFunctionType);
  }

  void test_parseStatement_emptyTypeArgumentList() {
    var declaration = parseStatement('C<> c;') as VariableDeclarationStatement;
    assertErrorsWithCodes([ParserErrorCode.EXPECTED_TYPE_NAME]);
    VariableDeclarationList variables = declaration.variables;
    var type = variables.type as NamedType;
    var argumentList = type.typeArguments!;
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.arguments[0].isSynthetic, isTrue);
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseStatement_function_gftReturnType() {
    var statement =
        parseStatement('void Function<A>(core.List<core.int> x) m() => null;')
            as FunctionDeclarationStatement;
    expect(statement.functionDeclaration.functionExpression.body,
        isExpressionFunctionBody);
  }

  void test_parseStatement_functionDeclaration_noReturnType() {
    var statement = parseStatement('true;') as ExpressionStatement;
    assertNoErrors();
    expect(statement.expression, isNotNull);
  }

  void test_parseStatement_functionDeclaration_noReturnType_typeParameters() {
    var statement =
        parseStatement('f<E>(a, b) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_functionDeclaration_returnType() {
    // TODO(brianwilkerson) Implement more tests for this method.
    var statement =
        parseStatement('int f(a, b) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_functionDeclaration_returnType_typeParameters() {
    var statement =
        parseStatement('int f<E>(a, b) {}') as FunctionDeclarationStatement;
    assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_multipleLabels() {
    var statement = parseStatement('l: m: return x;') as LabeledStatement;
    expect(statement.labels, hasLength(2));
    expect(statement.statement, isNotNull);
  }

  void test_parseStatement_noLabels() {
    var statement = parseStatement('return x;') as ReturnStatement;
    assertNoErrors();
    expect(statement, isNotNull);
  }

  void test_parseStatement_singleLabel() {
    var statement = parseStatement('l: return x;') as LabeledStatement;
    assertNoErrors();
    expect(statement.labels, hasLength(1));
    expect(statement.labels[0].label.inDeclarationContext(), isTrue);
    expect(statement.statement, isNotNull);
  }

  void test_parseSwitchStatement_case() {
    var statement =
        parseStatement('switch (a) {case 1: return "I";}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_empty() {
    var statement = parseStatement('switch (a) {}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(0));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledCase() {
    var statement =
        parseStatement('switch (a) {l1: l2: l3: case(1):}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(3));
      expect(labels[0].label.inDeclarationContext(), isTrue);
      expect(labels[1].label.inDeclarationContext(), isTrue);
      expect(labels[2].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledCase2() {
    var statement =
        parseStatement('switch (a) {l1: case 0: l2: case 1: return;}')
            as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(2));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    {
      List<Label> labels = statement.members[1].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledDefault() {
    var statement =
        parseStatement('switch (a) {l1: l2: l3: default:}') as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(3));
      expect(labels[0].label.inDeclarationContext(), isTrue);
      expect(labels[1].label.inDeclarationContext(), isTrue);
      expect(labels[2].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledDefault2() {
    var statement =
        parseStatement('switch (a) {l1: case 0: l2: default: return;}')
            as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(2));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    {
      List<Label> labels = statement.members[1].labels;
      expect(labels, hasLength(1));
      expect(labels[0].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledStatementInCase() {
    var statement = parseStatement('switch (a) {case 0: f(); l1: g(); break;}')
        as SwitchStatement;
    assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.members[0].statements, hasLength(3));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseTryStatement_catch() {
    var statement = parseStatement('try {} catch (e) {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_invalidCatchParam() {
    CompilationUnit unit = parseCompilationUnit(
        'main() { try {} catch (int e) { } }',
        errors: [expectedError(ParserErrorCode.CATCH_SYNTAX, 27, 1)]);
    var method = unit.declarations[0] as FunctionDeclaration;
    var body = method.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as TryStatement;
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter!.name.lexeme, 'int');
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter!.name.lexeme, 'e');
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_missingCatchParam() {
    var statement = parseStatement('try {} catch () {}') as TryStatement;
    listener.assertErrors([expectedError(ParserErrorCode.CATCH_SYNTAX, 14, 1)]);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_missingCatchParen() {
    var statement = parseStatement('try {} catch {}') as TryStatement;
    listener.assertErrors([expectedError(ParserErrorCode.CATCH_SYNTAX, 13, 1)]);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_error_missingCatchTrace() {
    var statement = parseStatement('try {} catch (e,) {}') as TryStatement;
    listener.assertErrors([expectedError(ParserErrorCode.CATCH_SYNTAX, 16, 1)]);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_finally() {
    var statement =
        parseStatement('try {} catch (e, s) {} finally {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_finally() {
    var statement = parseStatement('try {} finally {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(0));
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_multiple() {
    var statement =
        parseStatement('try {} on NPE catch (e) {} on Error {} catch (e) {}')
            as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(3));
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on() {
    var statement = parseStatement('try {} on Error {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNull);
    expect(clause.exceptionParameter, isNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on_catch() {
    var statement =
        parseStatement('try {} on Error catch (e, s) {}') as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on_catch_finally() {
    var statement = parseStatement('try {} on Error catch (e, s) {} finally {}')
        as TryStatement;
    assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseVariableDeclaration_equals_builtIn() {
    var statement =
        parseStatement('int set = 0;') as VariableDeclarationStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    var declarationList = parseVariableDeclarationList('const a = 0');
    assertNoErrors();
    expect(declarationList.keyword!.lexeme, 'const');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    var declarationList = parseVariableDeclarationList('const A a');
    assertNoErrors();
    expect(declarationList.keyword!.lexeme, 'const');
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    var declarationList = parseVariableDeclarationList('final a');
    assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    var declarationList = parseVariableDeclarationList('final A a');
    assertNoErrors();
    expect(declarationList.keyword!.lexeme, 'final');
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    var declarationList = parseVariableDeclarationList('A a, b, c');
    assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    var declarationList = parseVariableDeclarationList('A a');
    assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    var declarationList = parseVariableDeclarationList('var a, b, c');
    assertNoErrors();
    expect(declarationList.keyword!.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    var declarationList = parseVariableDeclarationList('var a');
    assertNoErrors();
    expect(declarationList.keyword!.lexeme, 'var');
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    var statement =
        parseStatement('var x, y, z;') as VariableDeclarationStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    var statement = parseStatement('var x;') as VariableDeclarationStatement;
    assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(1));
  }

  void test_parseWhileStatement() {
    var statement = parseStatement('while (x) {}') as WhileStatement;
    assertNoErrors();
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseYieldStatement_each() {
    var statement =
        _parseAsyncStatement('yield* x;', isGenerator: true) as YieldStatement;
    assertNoErrors();
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseYieldStatement_normal() {
    var statement =
        _parseAsyncStatement('yield x;', isGenerator: true) as YieldStatement;
    assertNoErrors();
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_partial_typeArg1_34850() {
    var unit = parseCompilationUnit('<bar<', errors: [
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 0, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 4, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 0),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 5, 0),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 5, 0),
    ]);
    // Validate that recovery has properly updated the token stream.
    analyzer.Token token = unit.beginToken;
    while (!token.isEof) {
      expect(token.type, isNot(TokenType.GT_GT));
      analyzer.Token next = token.next!;
      expect(next.previous, token);
      token = next;
    }
  }

  void test_partial_typeArg2_34850() {
    var unit = parseCompilationUnit('foo <bar<', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 0),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 9, 0),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 0),
    ]);
    // Validate that recovery has properly updated the token stream.
    analyzer.Token token = unit.beginToken;
    while (!token.isEof) {
      expect(token.type, isNot(TokenType.GT_GT));
      analyzer.Token next = token.next!;
      expect(next.previous, token);
      token = next;
    }
  }

  Statement _parseAsyncStatement(String code, {bool isGenerator = false}) {
    var star = isGenerator ? '*' : '';
    var localFunction = parseStatement('wrapper() async$star { $code }')
        as FunctionDeclarationStatement;
    var localBody = localFunction.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    return localBody.block.statements.single;
  }
}

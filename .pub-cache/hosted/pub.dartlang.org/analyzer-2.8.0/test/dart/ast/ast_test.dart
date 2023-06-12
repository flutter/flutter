// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test_base.dart' show ParserTestCase;

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
    defineReflectiveTests(ClassTypeAliasTest);
    defineReflectiveTests(ConstructorDeclarationTest);
    defineReflectiveTests(FieldFormalParameterTest);
    defineReflectiveTests(IndexExpressionTest);
    defineReflectiveTests(InterpolationStringTest);
    defineReflectiveTests(MethodDeclarationTest);
    defineReflectiveTests(MethodInvocationTest);
    defineReflectiveTests(NodeListTest);
    defineReflectiveTests(NormalFormalParameterTest);
    defineReflectiveTests(PreviousTokenTest);
    defineReflectiveTests(PropertyAccessTest);
    defineReflectiveTests(SimpleIdentifierTest);
    defineReflectiveTests(SimpleStringLiteralTest);
    defineReflectiveTests(SpreadElementTest);
    defineReflectiveTests(StringInterpolationTest);
    defineReflectiveTests(VariableDeclarationTest);
  });
}

@reflectiveTest
class ClassDeclarationTest extends ParserTestCase {
  void test_getConstructor() {
    List<ConstructorInitializer> initializers = <ConstructorInitializer>[];
    ConstructorDeclaration defaultConstructor =
        AstTestFactory.constructorDeclaration(
            AstTestFactory.identifier3("Test"),
            null,
            AstTestFactory.formalParameterList(),
            initializers);
    ConstructorDeclaration aConstructor = AstTestFactory.constructorDeclaration(
        AstTestFactory.identifier3("Test"),
        "a",
        AstTestFactory.formalParameterList(),
        initializers);
    ConstructorDeclaration bConstructor = AstTestFactory.constructorDeclaration(
        AstTestFactory.identifier3("Test"),
        "b",
        AstTestFactory.formalParameterList(),
        initializers);
    ClassDeclaration clazz = AstTestFactory.classDeclaration(null, "Test", null,
        null, null, null, [defaultConstructor, aConstructor, bConstructor]);
    expect(clazz.getConstructor(null), same(defaultConstructor));
    expect(clazz.getConstructor("a"), same(aConstructor));
    expect(clazz.getConstructor("b"), same(bConstructor));
    expect(clazz.getConstructor("noSuchConstructor"), isNull);
  }

  void test_getField() {
    VariableDeclaration aVar = AstTestFactory.variableDeclaration("a");
    VariableDeclaration bVar = AstTestFactory.variableDeclaration("b");
    VariableDeclaration cVar = AstTestFactory.variableDeclaration("c");
    ClassDeclaration clazz =
        AstTestFactory.classDeclaration(null, "Test", null, null, null, null, [
      AstTestFactory.fieldDeclaration2(false, null, [aVar]),
      AstTestFactory.fieldDeclaration2(false, null, [bVar, cVar])
    ]);
    expect(clazz.getField("a"), same(aVar));
    expect(clazz.getField("b"), same(bVar));
    expect(clazz.getField("c"), same(cVar));
    expect(clazz.getField("noSuchField"), isNull);
  }

  void test_getMethod() {
    MethodDeclaration aMethod = AstTestFactory.methodDeclaration(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("a"),
        AstTestFactory.formalParameterList());
    MethodDeclaration bMethod = AstTestFactory.methodDeclaration(
        null,
        null,
        null,
        null,
        AstTestFactory.identifier3("b"),
        AstTestFactory.formalParameterList());
    ClassDeclaration clazz = AstTestFactory.classDeclaration(
        null, "Test", null, null, null, null, [aMethod, bMethod]);
    expect(clazz.getMethod("a"), same(aMethod));
    expect(clazz.getMethod("b"), same(bMethod));
    expect(clazz.getMethod("noSuchMethod"), isNull);
  }

  void test_isAbstract() {
    expect(
        AstTestFactory.classDeclaration(null, "A", null, null, null, null)
            .isAbstract,
        isFalse);
    expect(
        AstTestFactory.classDeclaration(
                Keyword.ABSTRACT, "B", null, null, null, null)
            .isAbstract,
        isTrue);
  }
}

@reflectiveTest
class ClassTypeAliasTest extends ParserTestCase {
  void test_isAbstract() {
    expect(
        AstTestFactory.classTypeAlias(
                "A",
                null,
                null,
                AstTestFactory.namedType4('B'),
                AstTestFactory.withClause([AstTestFactory.namedType4('M')]),
                null)
            .isAbstract,
        isFalse);
    expect(
        AstTestFactory.classTypeAlias(
                "B",
                null,
                Keyword.ABSTRACT,
                AstTestFactory.namedType4('A'),
                AstTestFactory.withClause([AstTestFactory.namedType4('M')]),
                null)
            .isAbstract,
        isTrue);
  }
}

@reflectiveTest
class ConstructorDeclarationTest {
  void test_firstTokenAfterCommentAndMetadata_all_inverted() {
    Token externalKeyword = TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    externalKeyword.offset = 14;
    var declaration = AstTestFactory.constructorDeclaration2(
        Keyword.CONST,
        Keyword.FACTORY,
        AstTestFactory.identifier3('int'),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.emptyFunctionBody());
    declaration.externalKeyword = externalKeyword;
    declaration.constKeyword!.offset = 8;
    Token factoryKeyword = declaration.factoryKeyword!;
    factoryKeyword.offset = 0;
    expect(declaration.firstTokenAfterCommentAndMetadata, factoryKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_all_normal() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    token.offset = 0;
    var declaration = AstTestFactory.constructorDeclaration2(
        Keyword.CONST,
        Keyword.FACTORY,
        AstTestFactory.identifier3('int'),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.emptyFunctionBody());
    declaration.externalKeyword = token;
    declaration.constKeyword!.offset = 9;
    declaration.factoryKeyword!.offset = 15;
    expect(declaration.firstTokenAfterCommentAndMetadata, token);
  }

  void test_firstTokenAfterCommentAndMetadata_constOnly() {
    ConstructorDeclaration declaration = AstTestFactory.constructorDeclaration2(
        Keyword.CONST,
        null,
        AstTestFactory.identifier3('int'),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.constKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_externalOnly() {
    Token externalKeyword = TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    var declaration = AstTestFactory.constructorDeclaration2(
        null,
        null,
        AstTestFactory.identifier3('int'),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.emptyFunctionBody());
    declaration.externalKeyword = externalKeyword;
    expect(declaration.firstTokenAfterCommentAndMetadata, externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_factoryOnly() {
    ConstructorDeclaration declaration = AstTestFactory.constructorDeclaration2(
        null,
        Keyword.FACTORY,
        AstTestFactory.identifier3('int'),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.factoryKeyword);
  }
}

@reflectiveTest
class FieldFormalParameterTest {
  void test_endToken_noParameters() {
    FieldFormalParameter parameter =
        AstTestFactory.fieldFormalParameter2('field');
    expect(parameter.endToken, parameter.identifier.endToken);
  }

  void test_endToken_parameters() {
    FieldFormalParameter parameter = AstTestFactory.fieldFormalParameter(
        null, null, 'field', AstTestFactory.formalParameterList([]));
    expect(parameter.endToken, parameter.parameters!.endToken);
  }
}

@reflectiveTest
class IndexExpressionTest {
  void test_inGetterContext_assignment_compound_left() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // a[b] += c
    AstTestFactory.assignmentExpression(
        expression, TokenType.PLUS_EQ, AstTestFactory.identifier3("c"));
    expect(expression.inGetterContext(), isTrue);
  }

  void test_inGetterContext_assignment_simple_left() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // a[b] = c
    AstTestFactory.assignmentExpression(
        expression, TokenType.EQ, AstTestFactory.identifier3("c"));
    expect(expression.inGetterContext(), isFalse);
  }

  void test_inGetterContext_nonAssignment() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // a[b] + c
    AstTestFactory.binaryExpression(
        expression, TokenType.PLUS, AstTestFactory.identifier3("c"));
    expect(expression.inGetterContext(), isTrue);
  }

  void test_inSetterContext_assignment_compound_left() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // a[b] += c
    AstTestFactory.assignmentExpression(
        expression, TokenType.PLUS_EQ, AstTestFactory.identifier3("c"));
    expect(expression.inSetterContext(), isTrue);
  }

  void test_inSetterContext_assignment_compound_right() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // c += a[b]
    AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("c"), TokenType.PLUS_EQ, expression);
    expect(expression.inSetterContext(), isFalse);
  }

  void test_inSetterContext_assignment_simple_left() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // a[b] = c
    AstTestFactory.assignmentExpression(
        expression, TokenType.EQ, AstTestFactory.identifier3("c"));
    expect(expression.inSetterContext(), isTrue);
  }

  void test_inSetterContext_assignment_simple_right() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // c = a[b]
    AstTestFactory.assignmentExpression(
        AstTestFactory.identifier3("c"), TokenType.EQ, expression);
    expect(expression.inSetterContext(), isFalse);
  }

  void test_inSetterContext_nonAssignment() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    AstTestFactory.binaryExpression(
        expression, TokenType.PLUS, AstTestFactory.identifier3("c"));
    // a[b] + cc
    expect(expression.inSetterContext(), isFalse);
  }

  void test_inSetterContext_postfix_bang() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // a[b]!
    AstTestFactory.postfixExpression(expression, TokenType.BANG);
    expect(expression.inSetterContext(), isFalse);
  }

  void test_inSetterContext_postfix_plusPlus() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    AstTestFactory.postfixExpression(expression, TokenType.PLUS_PLUS);
    // a[b]++
    expect(expression.inSetterContext(), isTrue);
  }

  void test_inSetterContext_prefix_bang() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // !a[b]
    AstTestFactory.prefixExpression(TokenType.BANG, expression);
    expect(expression.inSetterContext(), isFalse);
  }

  void test_inSetterContext_prefix_minusMinus() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // --a[b]
    AstTestFactory.prefixExpression(TokenType.MINUS_MINUS, expression);
    expect(expression.inSetterContext(), isTrue);
  }

  void test_inSetterContext_prefix_plusPlus() {
    IndexExpression expression = AstTestFactory.indexExpression(
      target: AstTestFactory.identifier3("a"),
      index: AstTestFactory.identifier3("b"),
    );
    // ++a[b]
    AstTestFactory.prefixExpression(TokenType.PLUS_PLUS, expression);
    expect(expression.inSetterContext(), isTrue);
  }

  void test_isNullAware_cascade_false() {
    final expression = AstTestFactory.indexExpressionForCascade(
        AstTestFactory.nullLiteral(),
        AstTestFactory.nullLiteral(),
        TokenType.PERIOD_PERIOD,
        TokenType.OPEN_SQUARE_BRACKET);
    AstTestFactory.cascadeExpression(
      AstTestFactory.nullLiteral(),
      [expression],
    );
    expect(expression.isNullAware, isFalse);
  }

  void test_isNullAware_cascade_true() {
    final expression = AstTestFactory.indexExpressionForCascade(
        AstTestFactory.nullLiteral(),
        AstTestFactory.nullLiteral(),
        TokenType.QUESTION_PERIOD_PERIOD,
        TokenType.OPEN_SQUARE_BRACKET);
    AstTestFactory.cascadeExpression(
      AstTestFactory.nullLiteral(),
      [expression],
    );
    expect(expression.isNullAware, isTrue);
  }

  void test_isNullAware_false() {
    final expression = AstTestFactory.indexExpression(
      target: AstTestFactory.nullLiteral(),
      index: AstTestFactory.nullLiteral(),
    );
    expect(expression.isNullAware, isFalse);
  }

  void test_isNullAware_regularIndex() {
    final expression = AstTestFactory.indexExpression(
      target: AstTestFactory.nullLiteral(),
      index: AstTestFactory.nullLiteral(),
    );
    expect(expression.isNullAware, isFalse);
  }

  void test_isNullAware_true() {
    final expression = AstTestFactory.indexExpression(
      target: AstTestFactory.nullLiteral(),
      hasQuestion: true,
      index: AstTestFactory.nullLiteral(),
    );
    expect(expression.isNullAware, isTrue);
  }
}

@reflectiveTest
class InterpolationStringTest extends ParserTestCase {
  /// This field is updated in [_parseStringInterpolation].
  /// It is used in [_assertContentsOffsetEnd].
  var _baseOffset = 0;

  void test_contentsOffset_doubleQuote_first() {
    var interpolation = _parseStringInterpolation('"foo\$x last"');
    var node = interpolation.firstString;
    _assertContentsOffsetEnd(node, 1, 4);
  }

  void test_contentsOffset_doubleQuote_last() {
    var interpolation = _parseStringInterpolation('"first \$x foo"');
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 9, 13);
  }

  void test_contentsOffset_doubleQuote_last_empty() {
    var interpolation = _parseStringInterpolation('"first \$x"');
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 9, 9);
  }

  void test_contentsOffset_doubleQuote_last_unterminated() {
    var interpolation = _parseStringInterpolation('"first \$x foo');
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 9, 13);
  }

  void test_contentsOffset_doubleQuote_multiline_first() {
    var interpolation = _parseStringInterpolation('"""foo\n\$x last"""');
    var node = interpolation.firstString;
    _assertContentsOffsetEnd(node, 3, 7);
  }

  void test_contentsOffset_doubleQuote_multiline_last() {
    var interpolation = _parseStringInterpolation('"""first\$x foo\n"""');
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 10, 15);
  }

  void test_contentsOffset_doubleQuote_multiline_last_empty() {
    var interpolation = _parseStringInterpolation('"""first\$x"""');
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 10, 10);
  }

  void test_contentsOffset_doubleQuote_multiline_last_unterminated() {
    var interpolation = _parseStringInterpolation('"""first\$x foo\n');
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 10, 15);
  }

  void test_contentsOffset_escapeCharacters() {
    // Contents offset cannot use 'value' string, because of escape sequences.
    var interpolation = _parseStringInterpolation(r'"foo\nbar$x last"');
    var node = interpolation.firstString;
    _assertContentsOffsetEnd(node, 1, 9);
  }

  void test_contentsOffset_middle() {
    var interpolation =
        _parseStringInterpolation(r'"first $x foo\nbar $y last"');
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 9, 19);
  }

  void test_contentsOffset_middle_quoteBegin() {
    var interpolation = _parseStringInterpolation('"first \$x \'foo\$y last"');
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 9, 14);
  }

  void test_contentsOffset_middle_quoteBeginEnd() {
    var interpolation =
        _parseStringInterpolation('"first \$x \'foo\'\$y last"');
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 9, 15);
  }

  void test_contentsOffset_middle_quoteEnd() {
    var interpolation = _parseStringInterpolation('"first \$x foo\'\$y last"');
    var node = interpolation.elements[2] as InterpolationString;
    _assertContentsOffsetEnd(node, 9, 14);
  }

  void test_contentsOffset_singleQuote_first() {
    var interpolation = _parseStringInterpolation("'foo\$x last'");
    var node = interpolation.firstString;
    _assertContentsOffsetEnd(node, 1, 4);
  }

  void test_contentsOffset_singleQuote_last() {
    var interpolation = _parseStringInterpolation("'first \$x foo'");
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 9, 13);
  }

  void test_contentsOffset_singleQuote_last_empty() {
    var interpolation = _parseStringInterpolation("'first \$x'");
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 9, 9);
  }

  void test_contentsOffset_singleQuote_last_unterminated() {
    var interpolation = _parseStringInterpolation("'first \$x");
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 9, 9);
  }

  void test_contentsOffset_singleQuote_multiline_first() {
    var interpolation = _parseStringInterpolation("'''foo\n\$x last'''");
    var node = interpolation.firstString;
    _assertContentsOffsetEnd(node, 3, 7);
  }

  void test_contentsOffset_singleQuote_multiline_last() {
    var interpolation = _parseStringInterpolation("'''first\$x foo\n'''");
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 10, 15);
  }

  void test_contentsOffset_singleQuote_multiline_last_empty() {
    var interpolation = _parseStringInterpolation("'''first\$x'''");
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 10, 10);
  }

  void test_contentsOffset_singleQuote_multiline_last_unterminated() {
    var interpolation = _parseStringInterpolation("'''first\$x'''");
    var node = interpolation.lastString;
    _assertContentsOffsetEnd(node, 10, 10);
  }

  void _assertContentsOffsetEnd(InterpolationString node, int offset, int end) {
    expect(node.contentsOffset, _baseOffset + offset);
    expect(node.contentsEnd, _baseOffset + end);
  }

  StringInterpolation _parseStringInterpolation(String code) {
    var unitCode = 'var x = ';
    _baseOffset = unitCode.length;
    unitCode += code;
    var unit = parseString(
      content: unitCode,
      throwIfDiagnostics: false,
    ).unit;
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    return declaration.variables.variables[0].initializer
        as StringInterpolation;
  }
}

@reflectiveTest
class MethodDeclarationTest {
  void test_firstTokenAfterCommentAndMetadata_external() {
    MethodDeclaration declaration = AstTestFactory.methodDeclaration4(
        external: true, name: 'm', body: AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_external_getter() {
    MethodDeclaration declaration = AstTestFactory.methodDeclaration4(
        external: true,
        property: Keyword.GET,
        name: 'm',
        body: AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_external_operator() {
    MethodDeclaration declaration = AstTestFactory.methodDeclaration4(
        external: true,
        operator: true,
        name: 'm',
        body: AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.externalKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_getter() {
    MethodDeclaration declaration = AstTestFactory.methodDeclaration4(
        property: Keyword.GET,
        name: 'm',
        body: AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.propertyKeyword);
  }

  void test_firstTokenAfterCommentAndMetadata_operator() {
    MethodDeclaration declaration = AstTestFactory.methodDeclaration4(
        operator: true, name: 'm', body: AstTestFactory.emptyFunctionBody());
    expect(declaration.firstTokenAfterCommentAndMetadata,
        declaration.operatorKeyword);
  }
}

@reflectiveTest
class MethodInvocationTest extends ParserTestCase {
  void test_isNullAware_cascade() {
    var invocation = astFactory.methodInvocation(
      null,
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD),
      AstTestFactory.identifier3('foo'),
      null,
      AstTestFactory.argumentList(),
    );
    AstTestFactory.cascadeExpression(
      AstTestFactory.nullLiteral(),
      [invocation],
    );
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_cascade_true() {
    var invocation = astFactory.methodInvocation(
      null,
      TokenFactory.tokenFromType(TokenType.QUESTION_PERIOD_PERIOD),
      AstTestFactory.identifier3('foo'),
      null,
      AstTestFactory.argumentList(),
    );
    AstTestFactory.cascadeExpression(
      AstTestFactory.nullLiteral(),
      [invocation],
    );
    expect(invocation.isNullAware, isTrue);
  }

  void test_isNullAware_regularInvocation() {
    final invocation = AstTestFactory.methodInvocation3(
        AstTestFactory.nullLiteral(), 'foo', null, [], TokenType.PERIOD);
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_true() {
    final invocation = AstTestFactory.methodInvocation3(
        AstTestFactory.nullLiteral(),
        'foo',
        null,
        [],
        TokenType.QUESTION_PERIOD);
    expect(invocation.isNullAware, isTrue);
  }
}

@reflectiveTest
class NodeListTest {
  void test_add() {
    AstNode parent = AstTestFactory.argumentList();
    AstNode firstNode = AstTestFactory.booleanLiteral(true);
    AstNode secondNode = AstTestFactory.booleanLiteral(false);
    NodeList<AstNode> list = astFactory.nodeList<AstNode>(parent);
    list.insert(0, secondNode);
    list.insert(0, firstNode);
    expect(list, hasLength(2));
    expect(list[0], same(firstNode));
    expect(list[1], same(secondNode));
    expect(firstNode.parent, same(parent));
    expect(secondNode.parent, same(parent));
    AstNode thirdNode = AstTestFactory.booleanLiteral(false);
    list.insert(1, thirdNode);
    expect(list, hasLength(3));
    expect(list[0], same(firstNode));
    expect(list[1], same(thirdNode));
    expect(list[2], same(secondNode));
    expect(firstNode.parent, same(parent));
    expect(secondNode.parent, same(parent));
    expect(thirdNode.parent, same(parent));
  }

  void test_add_negative() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list.insert(-1, AstTestFactory.booleanLiteral(true));
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_add_tooBig() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list.insert(1, AstTestFactory.booleanLiteral(true));
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_addAll() {
    AstNode parent = AstTestFactory.argumentList();
    List<AstNode> firstNodes = <AstNode>[];
    AstNode firstNode = AstTestFactory.booleanLiteral(true);
    AstNode secondNode = AstTestFactory.booleanLiteral(false);
    firstNodes.add(firstNode);
    firstNodes.add(secondNode);
    NodeList<AstNode> list = astFactory.nodeList<AstNode>(parent);
    list.addAll(firstNodes);
    expect(list, hasLength(2));
    expect(list[0], same(firstNode));
    expect(list[1], same(secondNode));
    expect(firstNode.parent, same(parent));
    expect(secondNode.parent, same(parent));
    List<AstNode> secondNodes = <AstNode>[];
    AstNode thirdNode = AstTestFactory.booleanLiteral(true);
    AstNode fourthNode = AstTestFactory.booleanLiteral(false);
    secondNodes.add(thirdNode);
    secondNodes.add(fourthNode);
    list.addAll(secondNodes);
    expect(list, hasLength(4));
    expect(list[0], same(firstNode));
    expect(list[1], same(secondNode));
    expect(list[2], same(thirdNode));
    expect(list[3], same(fourthNode));
    expect(firstNode.parent, same(parent));
    expect(secondNode.parent, same(parent));
    expect(thirdNode.parent, same(parent));
    expect(fourthNode.parent, same(parent));
  }

  void test_creation() {
    AstNode owner = AstTestFactory.argumentList();
    NodeList<AstNode> list = astFactory.nodeList<AstNode>(owner);
    expect(list, isNotNull);
    expect(list, hasLength(0));
    expect(list.owner, same(owner));
  }

  void test_get_negative() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list[-1];
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_get_tooBig() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list[1];
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_getBeginToken_empty() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    expect(list.beginToken, isNull);
  }

  void test_getBeginToken_nonEmpty() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    AstNode node = AstTestFactory.parenthesizedExpression(
        AstTestFactory.booleanLiteral(true));
    list.add(node);
    expect(list.beginToken, same(node.beginToken));
  }

  void test_getEndToken_empty() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    expect(list.endToken, isNull);
  }

  void test_getEndToken_nonEmpty() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    AstNode node = AstTestFactory.parenthesizedExpression(
        AstTestFactory.booleanLiteral(true));
    list.add(node);
    expect(list.endToken, same(node.endToken));
  }

  void test_indexOf() {
    List<AstNode> nodes = <AstNode>[];
    AstNode firstNode = AstTestFactory.booleanLiteral(true);
    AstNode secondNode = AstTestFactory.booleanLiteral(false);
    AstNode thirdNode = AstTestFactory.booleanLiteral(true);
    AstNode fourthNode = AstTestFactory.booleanLiteral(false);
    nodes.add(firstNode);
    nodes.add(secondNode);
    nodes.add(thirdNode);
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    list.addAll(nodes);
    expect(list, hasLength(3));
    expect(list.indexOf(firstNode), 0);
    expect(list.indexOf(secondNode), 1);
    expect(list.indexOf(thirdNode), 2);
    expect(list.indexOf(fourthNode), -1);
  }

  void test_remove() {
    List<AstNode> nodes = <AstNode>[];
    AstNode firstNode = AstTestFactory.booleanLiteral(true);
    AstNode secondNode = AstTestFactory.booleanLiteral(false);
    AstNode thirdNode = AstTestFactory.booleanLiteral(true);
    nodes.add(firstNode);
    nodes.add(secondNode);
    nodes.add(thirdNode);
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    list.addAll(nodes);
    expect(list, hasLength(3));
    expect(list.removeAt(1), same(secondNode));
    expect(list, hasLength(2));
    expect(list[0], same(firstNode));
    expect(list[1], same(thirdNode));
  }

  void test_remove_negative() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list.removeAt(-1);
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_remove_tooBig() {
    NodeList<AstNode> list =
        astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list.removeAt(1);
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_set() {
    List<AstNode> nodes = <AstNode>[];
    AstNode firstNode = AstTestFactory.booleanLiteral(true);
    AstNode secondNode = AstTestFactory.booleanLiteral(false);
    AstNode thirdNode = AstTestFactory.booleanLiteral(true);
    nodes.add(firstNode);
    nodes.add(secondNode);
    nodes.add(thirdNode);
    var list = astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    list.addAll(nodes);
    expect(list, hasLength(3));
    AstNode fourthNode = AstTestFactory.integer(0);
    list[1] = fourthNode;
    expect(list, hasLength(3));
    expect(list[0], same(firstNode));
    expect(list[1], same(fourthNode));
    expect(list[2], same(thirdNode));
  }

  void test_set_negative() {
    AstNode node = AstTestFactory.booleanLiteral(true);
    var list = astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list[-1] = node;
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }

  void test_set_tooBig() {
    AstNode node = AstTestFactory.booleanLiteral(true);
    var list = astFactory.nodeList<AstNode>(AstTestFactory.argumentList());
    try {
      list[1] = node;
      fail("Expected IndexOutOfBoundsException");
    } on RangeError {
      // Expected
    }
  }
}

@reflectiveTest
class NormalFormalParameterTest extends ParserTestCase {
  test_sortedCommentAndAnnotations_noComment() {
    var result = parseString(content: '''
void f(int i) {}
''');
    var function = result.unit.declarations[0] as FunctionDeclaration;
    var parameters = function.functionExpression.parameters;
    var parameter = parameters?.parameters[0] as NormalFormalParameter;
    expect(parameter.sortedCommentAndAnnotations, isEmpty);
  }
}

@reflectiveTest
class PreviousTokenTest {
  static final String contents = '''
class A {
  B foo(C c) {
    return bar;
  }
  D get baz => null;
}
E f() => g;
''';

  CompilationUnit? _unit;

  CompilationUnit get unit {
    return _unit ??= parseString(content: contents).unit;
  }

  Token findToken(String lexeme) {
    Token token = unit.beginToken;
    while (!token.isEof) {
      if (token.lexeme == lexeme) {
        return token;
      }
      token = token.next!;
    }
    fail('Failed to find $lexeme');
  }

  void test_findPrevious_basic_class() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    expect(clazz.findPrevious(findToken('A'))!.lexeme, 'class');
  }

  void test_findPrevious_basic_method() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var method = clazz.members[0] as MethodDeclaration;
    expect(method.findPrevious(findToken('foo'))!.lexeme, 'B');
  }

  void test_findPrevious_basic_statement() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var method = clazz.members[0] as MethodDeclaration;
    var body = method.body as BlockFunctionBody;
    Statement statement = body.block.statements[0];
    expect(statement.findPrevious(findToken('bar'))!.lexeme, 'return');
    expect(statement.findPrevious(findToken(';'))!.lexeme, 'bar');
  }

  void test_findPrevious_missing() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var method = clazz.members[0] as MethodDeclaration;
    var body = method.body as BlockFunctionBody;
    Statement statement = body.block.statements[0];

    var missing = parseString(
      content: 'missing',
      throwIfDiagnostics: false,
    ).unit.beginToken;
    expect(statement.findPrevious(missing), null);
  }

  void test_findPrevious_parent_method() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var method = clazz.members[0] as MethodDeclaration;
    expect(method.findPrevious(findToken('B'))!.lexeme, '{');
  }

  void test_findPrevious_parent_statement() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var method = clazz.members[0] as MethodDeclaration;
    var body = method.body as BlockFunctionBody;
    Statement statement = body.block.statements[0];
    expect(statement.findPrevious(findToken('return'))!.lexeme, '{');
  }

  void test_findPrevious_sibling_class() {
    CompilationUnitMember declaration = unit.declarations[1];
    expect(declaration.findPrevious(findToken('E'))!.lexeme, '}');
  }

  void test_findPrevious_sibling_method() {
    var clazz = unit.declarations[0] as ClassDeclaration;
    var method = clazz.members[1] as MethodDeclaration;
    expect(method.findPrevious(findToken('D'))!.lexeme, '}');
  }
}

@reflectiveTest
class PropertyAccessTest extends ParserTestCase {
  void test_isNullAware_cascade() {
    final invocation = AstTestFactory.propertyAccess2(
        AstTestFactory.nullLiteral(), 'foo', TokenType.PERIOD_PERIOD);
    AstTestFactory.cascadeExpression(
      AstTestFactory.nullLiteral(),
      [invocation],
    );
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_cascade_true() {
    final invocation = AstTestFactory.propertyAccess2(
        null, 'foo', TokenType.QUESTION_PERIOD_PERIOD);
    AstTestFactory.cascadeExpression(
      AstTestFactory.nullLiteral(),
      [invocation],
    );
    expect(invocation.isNullAware, isTrue);
  }

  void test_isNullAware_regularPropertyAccess() {
    final invocation = AstTestFactory.propertyAccess2(
        AstTestFactory.nullLiteral(), 'foo', TokenType.PERIOD);
    expect(invocation.isNullAware, isFalse);
  }

  void test_isNullAware_true() {
    final invocation = AstTestFactory.propertyAccess2(
        AstTestFactory.nullLiteral(), 'foo', TokenType.QUESTION_PERIOD);
    expect(invocation.isNullAware, isTrue);
  }
}

@reflectiveTest
class SimpleIdentifierTest extends ParserTestCase {
  void test_inGetterContext() {
    for (_WrapperKind wrapper in _WrapperKind.values) {
      for (_AssignmentKind assignment in _AssignmentKind.values) {
        SimpleIdentifier identifier = _createIdentifier(wrapper, assignment);
        if (assignment == _AssignmentKind.SIMPLE_LEFT &&
            wrapper != _WrapperKind.PREFIXED_LEFT &&
            wrapper != _WrapperKind.PROPERTY_LEFT) {
          if (identifier.inGetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be false");
          }
        } else {
          if (!identifier.inGetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be true");
          }
        }
      }
    }
  }

  void test_inGetterContext_constructorFieldInitializer() {
    ConstructorFieldInitializer initializer =
        AstTestFactory.constructorFieldInitializer(
            false, 'f', AstTestFactory.integer(0));
    SimpleIdentifier identifier = initializer.fieldName;
    expect(identifier.inGetterContext(), isFalse);
  }

  void test_inGetterContext_fieldFormalParameter() {
    FieldFormalParameter parameter =
        AstTestFactory.fieldFormalParameter2('test');
    SimpleIdentifier identifier = parameter.identifier;
    expect(identifier.inGetterContext(), isFalse);
  }

  void test_inGetterContext_forEachLoop() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("a");
    Expression iterator = AstTestFactory.listLiteral();
    Statement body = AstTestFactory.block();
    AstTestFactory.forStatement(
        AstTestFactory.forEachPartsWithIdentifier(identifier, iterator), body);
    expect(identifier.inGetterContext(), isFalse);
  }

  void test_inGetterContext_variableDeclaration() {
    VariableDeclaration variable = AstTestFactory.variableDeclaration('test');
    SimpleIdentifier identifier = variable.name;
    expect(identifier.inGetterContext(), isFalse);
  }

  void test_inReferenceContext() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("id");
    AstTestFactory.namedExpression(
        AstTestFactory.label(identifier), AstTestFactory.identifier3("_"));
    expect(identifier.inGetterContext(), isFalse);
    expect(identifier.inSetterContext(), isFalse);
  }

  void test_inSetterContext() {
    for (_WrapperKind wrapper in _WrapperKind.values) {
      for (_AssignmentKind assignment in _AssignmentKind.values) {
        SimpleIdentifier identifier = _createIdentifier(wrapper, assignment);
        if (wrapper == _WrapperKind.PREFIXED_LEFT ||
            wrapper == _WrapperKind.PROPERTY_LEFT ||
            assignment == _AssignmentKind.BINARY ||
            assignment == _AssignmentKind.COMPOUND_RIGHT ||
            assignment == _AssignmentKind.POSTFIX_BANG ||
            assignment == _AssignmentKind.PREFIX_NOT ||
            assignment == _AssignmentKind.SIMPLE_RIGHT) {
          if (identifier.inSetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be false");
          }
        } else {
          if (!identifier.inSetterContext()) {
            fail("Expected ${_topMostNode(identifier).toSource()} to be true");
          }
        }
      }
    }
  }

  void test_inSetterContext_forEachLoop() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("a");
    Expression iterator = AstTestFactory.listLiteral();
    Statement body = AstTestFactory.block();
    AstTestFactory.forStatement(
        AstTestFactory.forEachPartsWithIdentifier(identifier, iterator), body);
    expect(identifier.inSetterContext(), isTrue);
  }

  void test_isQualified_inConstructorName() {
    ConstructorName constructor = AstTestFactory.constructorName(
        AstTestFactory.namedType4('MyClass'), "test");
    SimpleIdentifier name = constructor.name!;
    expect(name.isQualified, isTrue);
  }

  void test_isQualified_inMethodInvocation_noTarget() {
    MethodInvocation invocation = AstTestFactory.methodInvocation2(
        "test", [AstTestFactory.identifier3("arg0")]);
    SimpleIdentifier identifier = invocation.methodName;
    expect(identifier.isQualified, isFalse);
  }

  void test_isQualified_inMethodInvocation_withTarget() {
    MethodInvocation invocation = AstTestFactory.methodInvocation(
        AstTestFactory.identifier3("target"),
        "test",
        [AstTestFactory.identifier3("arg0")]);
    SimpleIdentifier identifier = invocation.methodName;
    expect(identifier.isQualified, isTrue);
  }

  void test_isQualified_inPrefixedIdentifier_name() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("test");
    AstTestFactory.identifier4("prefix", identifier);
    expect(identifier.isQualified, isTrue);
  }

  void test_isQualified_inPrefixedIdentifier_prefix() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("test");
    AstTestFactory.identifier(identifier, AstTestFactory.identifier3("name"));
    expect(identifier.isQualified, isFalse);
  }

  void test_isQualified_inPropertyAccess_name() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("test");
    AstTestFactory.propertyAccess(
        AstTestFactory.identifier3("target"), identifier);
    expect(identifier.isQualified, isTrue);
  }

  void test_isQualified_inPropertyAccess_target() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("test");
    AstTestFactory.propertyAccess(
        identifier, AstTestFactory.identifier3("name"));
    expect(identifier.isQualified, isFalse);
  }

  void test_isQualified_inReturnStatement() {
    SimpleIdentifier identifier = AstTestFactory.identifier3("test");
    AstTestFactory.returnStatement2(identifier);
    expect(identifier.isQualified, isFalse);
  }

  SimpleIdentifier _createIdentifier(
      _WrapperKind wrapper, _AssignmentKind assignment) {
    SimpleIdentifier identifier = AstTestFactory.identifier3("a");
    Expression expression = identifier;
    while (true) {
      if (wrapper == _WrapperKind.PREFIXED_LEFT) {
        expression = AstTestFactory.identifier(
            identifier, AstTestFactory.identifier3("_"));
      } else if (wrapper == _WrapperKind.PREFIXED_RIGHT) {
        expression = AstTestFactory.identifier(
            AstTestFactory.identifier3("_"), identifier);
      } else if (wrapper == _WrapperKind.PROPERTY_LEFT) {
        expression = AstTestFactory.propertyAccess2(expression, "_");
      } else if (wrapper == _WrapperKind.PROPERTY_RIGHT) {
        expression = AstTestFactory.propertyAccess(
            AstTestFactory.identifier3("_"), identifier);
      } else {
        throw UnimplementedError();
      }
      break;
    }
    while (true) {
      if (assignment == _AssignmentKind.BINARY) {
        AstTestFactory.binaryExpression(
            expression, TokenType.PLUS, AstTestFactory.identifier3("_"));
      } else if (assignment == _AssignmentKind.COMPOUND_LEFT) {
        AstTestFactory.assignmentExpression(
            expression, TokenType.PLUS_EQ, AstTestFactory.identifier3("_"));
      } else if (assignment == _AssignmentKind.COMPOUND_RIGHT) {
        AstTestFactory.assignmentExpression(
            AstTestFactory.identifier3("_"), TokenType.PLUS_EQ, expression);
      } else if (assignment == _AssignmentKind.POSTFIX_BANG) {
        AstTestFactory.postfixExpression(expression, TokenType.BANG);
      } else if (assignment == _AssignmentKind.POSTFIX_INC) {
        AstTestFactory.postfixExpression(expression, TokenType.PLUS_PLUS);
      } else if (assignment == _AssignmentKind.PREFIX_DEC) {
        AstTestFactory.prefixExpression(TokenType.MINUS_MINUS, expression);
      } else if (assignment == _AssignmentKind.PREFIX_INC) {
        AstTestFactory.prefixExpression(TokenType.PLUS_PLUS, expression);
      } else if (assignment == _AssignmentKind.PREFIX_NOT) {
        AstTestFactory.prefixExpression(TokenType.BANG, expression);
      } else if (assignment == _AssignmentKind.SIMPLE_LEFT) {
        AstTestFactory.assignmentExpression(
            expression, TokenType.EQ, AstTestFactory.identifier3("_"));
      } else if (assignment == _AssignmentKind.SIMPLE_RIGHT) {
        AstTestFactory.assignmentExpression(
            AstTestFactory.identifier3("_"), TokenType.EQ, expression);
      } else {
        throw UnimplementedError();
      }
      break;
    }
    return identifier;
  }

  /// Return the top-most node in the AST structure containing the given
  /// identifier.
  ///
  /// @param identifier the identifier in the AST structure being traversed
  /// @return the root of the AST structure containing the identifier
  AstNode _topMostNode(SimpleIdentifier identifier) {
    AstNode child = identifier;
    var parent = identifier.parent;
    while (parent != null) {
      child = parent;
      parent = parent.parent;
    }
    return child;
  }
}

@reflectiveTest
class SimpleStringLiteralTest extends ParserTestCase {
  void test_contentsEnd() {
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'X'"), "X")
            .contentsEnd,
        2);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString('"X"'), "X")
            .contentsEnd,
        2);

    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString('"""X"""'), "X")
            .contentsEnd,
        4);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'''X'''"), "X")
            .contentsEnd,
        4);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("'''  \nX'''"), "X")
            .contentsEnd,
        7);

    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'X'"), "X")
            .contentsEnd,
        3);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString('r"X"'), "X")
            .contentsEnd,
        3);

    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString('r"""X"""'), "X")
            .contentsEnd,
        5);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'''X'''"), "X")
            .contentsEnd,
        5);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("r'''  \nX'''"), "X")
            .contentsEnd,
        8);
  }

  void test_contentsOffset() {
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'X'"), "X")
            .contentsOffset,
        1);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("\"X\""), "X")
            .contentsOffset,
        1);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("\"\"\"X\"\"\""), "X")
            .contentsOffset,
        3);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'''X'''"), "X")
            .contentsOffset,
        3);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'X'"), "X")
            .contentsOffset,
        2);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r\"X\""), "X")
            .contentsOffset,
        2);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("r\"\"\"X\"\"\""), "X")
            .contentsOffset,
        4);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'''X'''"), "X")
            .contentsOffset,
        4);
    // leading whitespace
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("''' \ \nX''"), "X")
            .contentsOffset,
        6);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString('r""" \ \nX"""'), "X")
            .contentsOffset,
        7);
  }

  void test_isMultiline() {
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'X'"), "X")
            .isMultiline,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'X'"), "X")
            .isMultiline,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("\"X\""), "X")
            .isMultiline,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r\"X\""), "X")
            .isMultiline,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'''X'''"), "X")
            .isMultiline,
        isTrue);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'''X'''"), "X")
            .isMultiline,
        isTrue);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("\"\"\"X\"\"\""), "X")
            .isMultiline,
        isTrue);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("r\"\"\"X\"\"\""), "X")
            .isMultiline,
        isTrue);
  }

  void test_isRaw() {
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'X'"), "X")
            .isRaw,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("\"X\""), "X")
            .isRaw,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("\"\"\"X\"\"\""), "X")
            .isRaw,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("'''X'''"), "X")
            .isRaw,
        isFalse);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'X'"), "X")
            .isRaw,
        isTrue);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r\"X\""), "X")
            .isRaw,
        isTrue);
    expect(
        astFactory
            .simpleStringLiteral(
                TokenFactory.tokenFromString("r\"\"\"X\"\"\""), "X")
            .isRaw,
        isTrue);
    expect(
        astFactory
            .simpleStringLiteral(TokenFactory.tokenFromString("r'''X'''"), "X")
            .isRaw,
        isTrue);
  }

  void test_isSingleQuoted() {
    // '
    {
      var token = TokenFactory.tokenFromString("'X'");
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isTrue);
    }
    // '''
    {
      var token = TokenFactory.tokenFromString("'''X'''");
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isTrue);
    }
    // "
    {
      var token = TokenFactory.tokenFromString('"X"');
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isFalse);
    }
    // """
    {
      var token = TokenFactory.tokenFromString('"""X"""');
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isFalse);
    }
  }

  void test_isSingleQuoted_raw() {
    // r'
    {
      var token = TokenFactory.tokenFromString("r'X'");
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isTrue);
    }
    // r'''
    {
      var token = TokenFactory.tokenFromString("r'''X'''");
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isTrue);
    }
    // r"
    {
      var token = TokenFactory.tokenFromString('r"X"');
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isFalse);
    }
    // r"""
    {
      var token = TokenFactory.tokenFromString('r"""X"""');
      var node = astFactory.simpleStringLiteral(token, 'X');
      expect(node.isSingleQuoted, isFalse);
    }
  }

  void test_simple() {
    Token token = TokenFactory.tokenFromString("'value'");
    SimpleStringLiteral stringLiteral =
        astFactory.simpleStringLiteral(token, "value");
    expect(stringLiteral.literal, same(token));
    expect(stringLiteral.beginToken, same(token));
    expect(stringLiteral.endToken, same(token));
    expect(stringLiteral.value, "value");
  }
}

@reflectiveTest
class SpreadElementTest extends ParserTestCase {
  void test_notNullAwareSpread() {
    final spread = AstTestFactory.spreadElement(
        TokenType.PERIOD_PERIOD_PERIOD, AstTestFactory.nullLiteral());
    expect(spread.isNullAware, isFalse);
  }

  void test_nullAwareSpread() {
    final spread = AstTestFactory.spreadElement(
        TokenType.PERIOD_PERIOD_PERIOD_QUESTION, AstTestFactory.nullLiteral());
    expect(spread.isNullAware, isTrue);
  }
}

@reflectiveTest
class StringInterpolationTest extends ParserTestCase {
  void test_contentsOffsetEnd() {
    var bb = AstTestFactory.interpolationExpression(
        AstTestFactory.identifier3('bb'));
    // 'a${bb}ccc'
    {
      var ae = AstTestFactory.interpolationString("'a", "a");
      var cToken = StringToken(TokenType.STRING, "ccc'", 10);
      var cElement = astFactory.interpolationString(cToken, 'ccc');
      StringInterpolation node = AstTestFactory.string([ae, bb, cElement]);
      expect(node.contentsOffset, 1);
      expect(node.contentsEnd, 10 + 4 - 1);
    }
    // '''a${bb}ccc'''
    {
      var ae = AstTestFactory.interpolationString("'''a", "a");
      var cToken = StringToken(TokenType.STRING, "ccc'''", 10);
      var cElement = astFactory.interpolationString(cToken, 'ccc');
      StringInterpolation node = AstTestFactory.string([ae, bb, cElement]);
      expect(node.contentsOffset, 3);
      expect(node.contentsEnd, 10 + 4 - 1);
    }
    // """a${bb}ccc"""
    {
      var ae = AstTestFactory.interpolationString('"""a', "a");
      var cToken = StringToken(TokenType.STRING, 'ccc"""', 10);
      var cElement = astFactory.interpolationString(cToken, 'ccc');
      StringInterpolation node = AstTestFactory.string([ae, bb, cElement]);
      expect(node.contentsOffset, 3);
      expect(node.contentsEnd, 10 + 4 - 1);
    }
    // r'a${bb}ccc'
    {
      var ae = AstTestFactory.interpolationString("r'a", "a");
      var cToken = StringToken(TokenType.STRING, "ccc'", 10);
      var cElement = astFactory.interpolationString(cToken, 'ccc');
      StringInterpolation node = AstTestFactory.string([ae, bb, cElement]);
      expect(node.contentsOffset, 2);
      expect(node.contentsEnd, 10 + 4 - 1);
    }
    // r'''a${bb}ccc'''
    {
      var ae = AstTestFactory.interpolationString("r'''a", "a");
      var cToken = StringToken(TokenType.STRING, "ccc'''", 10);
      var cElement = astFactory.interpolationString(cToken, 'ccc');
      StringInterpolation node = AstTestFactory.string([ae, bb, cElement]);
      expect(node.contentsOffset, 4);
      expect(node.contentsEnd, 10 + 4 - 1);
    }
    // r"""a${bb}ccc"""
    {
      var ae = AstTestFactory.interpolationString('r"""a', "a");
      var cToken = StringToken(TokenType.STRING, 'ccc"""', 10);
      var cElement = astFactory.interpolationString(cToken, 'ccc');
      StringInterpolation node = AstTestFactory.string([ae, bb, cElement]);
      expect(node.contentsOffset, 4);
      expect(node.contentsEnd, 10 + 4 - 1);
    }
  }

  void test_isMultiline() {
    var b = AstTestFactory.interpolationExpression(
        AstTestFactory.identifier3('bb'));
    // '
    {
      var a = AstTestFactory.interpolationString("'a", "a");
      var c = AstTestFactory.interpolationString("ccc'", "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isMultiline, isFalse);
    }
    // '''
    {
      var a = AstTestFactory.interpolationString("'''a", "a");
      var c = AstTestFactory.interpolationString("ccc'''", "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isMultiline, isTrue);
    }
    // "
    {
      var a = AstTestFactory.interpolationString('"a', "a");
      var c = AstTestFactory.interpolationString('ccc"', "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isMultiline, isFalse);
    }
    // """
    {
      var a = AstTestFactory.interpolationString('"""a', "a");
      var c = AstTestFactory.interpolationString('ccc"""', "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isMultiline, isTrue);
    }
  }

  void test_isRaw() {
    var node = parseStringLiteral('"first \$x last"') as StringInterpolation;
    expect(node.isRaw, isFalse);
  }

  void test_isSingleQuoted() {
    var b = AstTestFactory.interpolationExpression(
        AstTestFactory.identifier3('bb'));
    // "
    {
      var a = AstTestFactory.interpolationString('"a', "a");
      var c = AstTestFactory.interpolationString('ccc"', "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isSingleQuoted, isFalse);
    }
    // """
    {
      var a = AstTestFactory.interpolationString('"""a', "a");
      var c = AstTestFactory.interpolationString('ccc"""', "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isSingleQuoted, isFalse);
    }
    // '
    {
      var a = AstTestFactory.interpolationString("'a", "a");
      var c = AstTestFactory.interpolationString("ccc'", "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isSingleQuoted, isTrue);
    }
    // '''
    {
      var a = AstTestFactory.interpolationString("'''a", "a");
      var c = AstTestFactory.interpolationString("ccc'''", "ccc");
      StringInterpolation node = AstTestFactory.string([a, b, c]);
      expect(node.isSingleQuoted, isTrue);
    }
  }
}

@reflectiveTest
class SuperFormalParameterTest {
  void test_endToken_noParameters() {
    SuperFormalParameter parameter =
        AstTestFactory.superFormalParameter2('field');
    expect(parameter.endToken, parameter.identifier.endToken);
  }

  void test_endToken_parameters() {
    SuperFormalParameter parameter = AstTestFactory.superFormalParameter(
        null, null, 'field', AstTestFactory.formalParameterList([]));
    expect(parameter.endToken, parameter.parameters!.endToken);
  }
}

@reflectiveTest
class VariableDeclarationTest extends ParserTestCase {
  void test_getDocumentationComment_onGrandParent() {
    VariableDeclaration varDecl = AstTestFactory.variableDeclaration("a");
    var decl =
        AstTestFactory.topLevelVariableDeclaration2(Keyword.VAR, [varDecl]);
    Comment comment = astFactory.documentationComment([]);
    expect(varDecl.documentationComment, isNull);
    decl.documentationComment = comment;
    expect(varDecl.documentationComment, isNotNull);
    expect(decl.documentationComment, isNotNull);
  }

  void test_getDocumentationComment_onNode() {
    var decl = AstTestFactory.variableDeclaration("a");
    Comment comment = astFactory.documentationComment([]);
    decl.documentationComment = comment;
    expect(decl.documentationComment, isNotNull);
  }

  test_sortedCommentAndAnnotations_noComment() {
    var result = parseString(content: '''
int i = 0;
''');
    var variables = result.unit.declarations[0] as TopLevelVariableDeclaration;
    var variable = variables.variables.variables[0];
    expect(variable.sortedCommentAndAnnotations, isEmpty);
  }
}

class _AssignmentKind {
  static const _AssignmentKind BINARY = _AssignmentKind('BINARY', 0);

  static const _AssignmentKind COMPOUND_LEFT =
      _AssignmentKind('COMPOUND_LEFT', 1);

  static const _AssignmentKind COMPOUND_RIGHT =
      _AssignmentKind('COMPOUND_RIGHT', 2);

  static const _AssignmentKind POSTFIX_BANG = _AssignmentKind('POSTFIX_INC', 3);

  static const _AssignmentKind POSTFIX_INC = _AssignmentKind('POSTFIX_INC', 4);

  static const _AssignmentKind PREFIX_DEC = _AssignmentKind('PREFIX_DEC', 5);

  static const _AssignmentKind PREFIX_INC = _AssignmentKind('PREFIX_INC', 6);

  static const _AssignmentKind PREFIX_NOT = _AssignmentKind('PREFIX_NOT', 7);

  static const _AssignmentKind SIMPLE_LEFT = _AssignmentKind('SIMPLE_LEFT', 8);

  static const _AssignmentKind SIMPLE_RIGHT =
      _AssignmentKind('SIMPLE_RIGHT', 9);

  static const List<_AssignmentKind> values = [
    BINARY,
    COMPOUND_LEFT,
    COMPOUND_RIGHT,
    POSTFIX_BANG,
    POSTFIX_INC,
    PREFIX_DEC,
    PREFIX_INC,
    PREFIX_NOT,
    SIMPLE_LEFT,
    SIMPLE_RIGHT,
  ];

  final String name;

  final int ordinal;

  const _AssignmentKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  int compareTo(_AssignmentKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

class _WrapperKind {
  static const _WrapperKind PREFIXED_LEFT = _WrapperKind('PREFIXED_LEFT', 0);

  static const _WrapperKind PREFIXED_RIGHT = _WrapperKind('PREFIXED_RIGHT', 1);

  static const _WrapperKind PROPERTY_LEFT = _WrapperKind('PROPERTY_LEFT', 2);

  static const _WrapperKind PROPERTY_RIGHT = _WrapperKind('PROPERTY_RIGHT', 3);

  static const List<_WrapperKind> values = [
    PREFIXED_LEFT,
    PREFIXED_RIGHT,
    PROPERTY_LEFT,
    PROPERTY_RIGHT,
  ];

  final String name;

  final int ordinal;

  const _WrapperKind(this.name, this.ordinal);

  @override
  int get hashCode => ordinal;

  int compareTo(_WrapperKind other) => ordinal - other.ordinal;

  @override
  String toString() => name;
}

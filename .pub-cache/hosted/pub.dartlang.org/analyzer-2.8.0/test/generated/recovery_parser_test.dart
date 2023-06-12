// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecoveryParserTest);
  });
}

/// The class `RecoveryParserTest` defines parser tests that test the parsing of
/// invalid code sequences to ensure that the correct recovery steps are taken
/// in the parser.
@reflectiveTest
class RecoveryParserTest extends FastaParserTestCase {
  void test_additiveExpression_missing_LHS() {
    var expression =
        parseExpression("+ y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_LHS_RHS() {
    var expression = parseExpression("+", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS() {
    var expression =
        parseExpression("x +", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS_super() {
    var expression =
        parseExpression("super +", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    var expression = parseExpression("* +", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    var expression = parseExpression("+ *", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_additiveExpression_super() {
    var expression = parseExpression("super + +", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_assignableSelector() {
    var expression =
        parseExpression("a.b[]", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as IndexExpression;
    var index = expression.index;
    expect(index, isSimpleIdentifier);
    expect(index.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound1() {
    var expression =
        parseExpression("= y = 0", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as AssignmentExpression;
    Expression syntheticExpression = expression.leftHandSide;
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound2() {
    var expression =
        parseExpression("x = = 0", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as AssignmentExpression;
    Expression syntheticExpression =
        (expression.rightHandSide as AssignmentExpression).leftHandSide;
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound3() {
    var expression =
        parseExpression("x = y =", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as AssignmentExpression;
    Expression syntheticExpression =
        (expression.rightHandSide as AssignmentExpression).rightHandSide;
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_LHS() {
    var expression =
        parseExpression("= 0", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as AssignmentExpression;
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.leftHandSide.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_RHS() {
    var expression =
        parseExpression("x =", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as AssignmentExpression;
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.rightHandSide.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS() {
    var expression =
        parseExpression("& y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS_RHS() {
    var expression = parseExpression("&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS() {
    var expression =
        parseExpression("x &", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS_super() {
    var expression =
        parseExpression("super &", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    var expression = parseExpression("== &&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    var expression = parseExpression("&& ==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_super() {
    var expression = parseExpression("super &  &", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_missing_LHS() {
    var expression =
        parseExpression("| y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_LHS_RHS() {
    var expression = parseExpression("|", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS() {
    var expression =
        parseExpression("x |", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS_super() {
    var expression =
        parseExpression("super |", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    var expression = parseExpression("^ |", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    var expression = parseExpression("| ^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_super() {
    var expression = parseExpression("super |  |", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_missing_LHS() {
    var expression =
        parseExpression("^ y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_LHS_RHS() {
    var expression = parseExpression("^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS() {
    var expression =
        parseExpression("x ^", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS_super() {
    var expression =
        parseExpression("super ^", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    var expression = parseExpression("& ^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    var expression = parseExpression("^ &", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_super() {
    var expression = parseExpression("super ^  ^", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_classTypeAlias_withBody() {
    parseCompilationUnit(r'''
class A {}
class B = Object with A {}''', codes:
// TODO(danrubel): Consolidate and improve error message.
            [
      ParserErrorCode.EXPECTED_EXECUTABLE,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
  }

  void test_combinator_badIdentifier() {
    createParser('import "/testB.dart" show @');
    parser.parseCompilationUnit2();
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 26, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 26, 1),
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 27, 0),
    ]);
  }

  void test_combinator_missingIdentifier() {
    createParser('import "/testB.dart" show ;');
    parser.parseCompilationUnit2();
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 26, 1)]);
  }

  void test_conditionalExpression_missingElse() {
    Expression expression =
        parseExpression('x ? y :', codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expectNotNullIfNoErrors(expression);
    expect(expression, isConditionalExpression);
    var conditionalExpression = expression as ConditionalExpression;
    expect(conditionalExpression.elseExpression, isSimpleIdentifier);
    expect(conditionalExpression.elseExpression.isSynthetic, isTrue);
  }

  void test_conditionalExpression_missingThen() {
    Expression expression =
        parseExpression('x ? : z', codes: [ParserErrorCode.MISSING_IDENTIFIER]);
    expectNotNullIfNoErrors(expression);
    expect(expression, isConditionalExpression);
    var conditionalExpression = expression as ConditionalExpression;
    expect(conditionalExpression.thenExpression, isSimpleIdentifier);
    expect(conditionalExpression.thenExpression.isSynthetic, isTrue);
  }

  void test_conditionalExpression_super() {
    parseExpression('x ? super : z', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 4, 5)
    ]);
  }

  void test_conditionalExpression_super2() {
    parseExpression('x ? z : super', errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 8, 5)
    ]);
  }

  void test_declarationBeforeDirective() {
    CompilationUnit unit = parseCompilationUnit(
        "class foo { } import 'bar.dart';",
        codes: [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.childEntities.first as ClassDeclaration;
    expect(classDecl, isNotNull);
    expect(classDecl.name.name, 'foo');
  }

  void test_equalityExpression_missing_LHS() {
    var expression =
        parseExpression("== y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_LHS_RHS() {
    var expression = parseExpression("==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS() {
    var expression =
        parseExpression("x ==", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS_super() {
    var expression =
        parseExpression("super ==", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_precedence_relational_right() {
    parseExpression("== is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  void test_equalityExpression_super() {
    var expression = parseExpression("super ==  ==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_equalityExpression_superRHS() {
    parseExpression("1 == super", errors: [
      expectedError(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 5, 5)
    ]);
  }

  void test_expressionList_multiple_end() {
    List<Expression> result = parseExpressionList(', 2, 3, 4');
    expectNotNullIfNoErrors(result);
// TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
//    listener.assertErrors(
//        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 1)]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[0];
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_middle() {
    List<Expression> result = parseExpressionList('1, 2, , 4');
    expectNotNullIfNoErrors(result);
// TODO(brianwilkerson) Convert codes to errors when highlighting is fixed.
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
//    listener.assertErrors(
//        [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1)]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[2];
    expect(syntheticExpression, isSimpleIdentifier);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_start() {
    List<Expression> result = parseExpressionList('1, 2, 3,');
    expectNotNullIfNoErrors(result);
// The fasta parser does not use parseExpressionList when parsing for loops
// and instead parseExpressionList is mapped to parseExpression('[$code]')
// which allows and ignores an optional trailing comma.
    assertNoErrors();
    expect(result, hasLength(3));
  }

  void test_functionExpression_in_ConstructorFieldInitializer() {
    CompilationUnit unit =
        parseCompilationUnit("class A { A() : a = (){}; var v; }", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_CLASS_MEMBER
    ]);
// Make sure we recovered and parsed "var v" correctly
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = declaration.members;
    ClassMember fieldDecl = members[1];
    expect(fieldDecl, isFieldDeclaration);
    NodeList<VariableDeclaration> vars =
        (fieldDecl as FieldDeclaration).fields.variables;
    expect(vars, hasLength(1));
    expect(vars[0].name.name, "v");
  }

  void test_functionExpression_named() {
    parseExpression("m(f() => 0);",
        expectedEndOffset: 11,
        codes: [ParserErrorCode.NAMED_FUNCTION_EXPRESSION]);
  }

  void test_ifStatement_noElse_statement() {
    parseStatement('if (x v) f(x);');
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1)]);
  }

  void test_importDirectivePartial_as() {
    CompilationUnit unit = parseCompilationUnit("import 'b.dart' d as b;",
        codes: [ParserErrorCode.UNEXPECTED_TOKEN]);
    var importDirective = unit.childEntities.first as ImportDirective;
    expect(importDirective.asKeyword, isNotNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_importDirectivePartial_hide() {
    CompilationUnit unit = parseCompilationUnit("import 'b.dart' d hide foo;",
        codes: [ParserErrorCode.UNEXPECTED_TOKEN]);
    var importDirective = unit.childEntities.first as ImportDirective;
    expect(importDirective.combinators, hasLength(1));
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_importDirectivePartial_show() {
    CompilationUnit unit = parseCompilationUnit("import 'b.dart' d show foo;",
        codes: [ParserErrorCode.UNEXPECTED_TOKEN]);
    var importDirective = unit.childEntities.first as ImportDirective;
    expect(importDirective.combinators, hasLength(1));
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_incomplete_conditionalExpression() {
    parseExpression("x ? 0", codes: [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  void test_incomplete_constructorInitializers_empty() {
    createParser('C() : {}');
    var member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.MISSING_INITIALIZER, 4, 1)]);
  }

  void test_incomplete_constructorInitializers_missingEquals() {
    createParser('C() : x(3) {}');
    var member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 1)
    ]);
    expect(member, isConstructorDeclaration);
    NodeList<ConstructorInitializer> initializers =
        (member as ConstructorDeclaration).initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    expect(initializer, isConstructorFieldInitializer);
    Expression expression =
        (initializer as ConstructorFieldInitializer).expression;
    expect(expression, isNotNull);
    expect(expression, isMethodInvocation);
  }

  void test_incomplete_constructorInitializers_this() {
    createParser('C() : this {}');
    var member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 1),
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 4)
    ]);
  }

  void test_incomplete_constructorInitializers_thisField() {
    createParser('C() : this.g {}');
    var member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 4)
    ]);
  }

  void test_incomplete_constructorInitializers_thisPeriod() {
    createParser('C() : this. {}');
    var member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 12, 1),
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 4)
    ]);
  }

  void test_incomplete_constructorInitializers_variable() {
    createParser('C() : x {}');
    var member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors([
      expectedError(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 6, 1)
    ]);
  }

  void test_incomplete_functionExpression() {
    var expression = parseExpression("() a => null",
        errors: [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 3, 1)]);
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.parameters!.parameters, hasLength(0));
  }

  void test_incomplete_functionExpression2() {
    var expression = parseExpression("() a {}",
        errors: [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 3, 1)]);
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.parameters!.parameters, hasLength(0));
  }

  void test_incomplete_returnType() {
    parseCompilationUnit(r'''
Map<Symbol, convertStringToSymbolMap(Map<String, dynamic> map) {
  if (map == null) return null;
  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();
  map.forEach((name, value) {
    result[new Symbol(name)] = value;
  });
  return result;
}''', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 24),
      expectedError(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, 0, 3)
    ]);
  }

  void test_incomplete_topLevelFunction() {
    parseCompilationUnit("foo();",
        codes: [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  void test_incomplete_topLevelVariable() {
    CompilationUnit unit = parseCompilationUnit("String", errors: [
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 0, 6),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 6)
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isFalse);
  }

  void test_incomplete_topLevelVariable_const() {
    CompilationUnit unit = parseCompilationUnit("const ", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_final() {
    CompilationUnit unit = parseCompilationUnit("final ", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_var() {
    CompilationUnit unit = parseCompilationUnit("var ", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isTopLevelVariableDeclaration);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incompleteField_const() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  const
}''', codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword!.keyword, Keyword.CONST);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_final() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  final
}''', codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword!.keyword, Keyword.FINAL);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_static() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  static c
}''', codes: [
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    var declaration = classMember as FieldDeclaration;
    expect(declaration.staticKeyword!.lexeme, 'static');
    VariableDeclarationList fieldList = declaration.fields;
    expect(fieldList.keyword, isNull);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isFalse);
  }

  void test_incompleteField_static2() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  static c x
}''', codes: [ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    var declaration = classMember as FieldDeclaration;
    expect(declaration.staticKeyword!.lexeme, 'static');
    VariableDeclarationList fieldList = declaration.fields;
    expect(fieldList.keyword, isNull);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isFalse);
  }

  void test_incompleteField_type() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  A
}''', codes: [
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    var type = fieldList.type;
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(type, isNull);
    expect(field.name.name, 'A');
  }

  void test_incompleteField_var() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  var
}''', codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    expect(unitMember, isClassDeclaration);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    expect(classMember, isFieldDeclaration);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword!.keyword, Keyword.VAR);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteForEach() {
// TODO(danrubel): remove this once control flow and spread collection
// entry parsing is enabled by default
    var statement = parseStatement('for (String item i) {}') as ForStatement;
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 17, 1)
    ]);
    expect(statement, isForStatement);
    expect(statement.toSource(), 'for (String item; i;) {}');
    var forParts = statement.forLoopParts as ForParts;
    expect(forParts.leftSeparator, isNotNull);
    expect(forParts.leftSeparator.type, TokenType.SEMICOLON);
    expect(forParts.rightSeparator, isNotNull);
    expect(forParts.rightSeparator.type, TokenType.SEMICOLON);
  }

  void test_incompleteForEach2() {
    var statement =
        parseStatement('for (String item i) {}', featureSet: controlFlow)
            as ForStatement;
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 12, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 17, 1)
    ]);
    expect(statement.toSource(), 'for (String item; i;) {}');
    var forLoopParts = statement.forLoopParts as ForPartsWithDeclarations;
    expect(forLoopParts.leftSeparator, isNotNull);
    expect(forLoopParts.leftSeparator.type, TokenType.SEMICOLON);
    expect(forLoopParts.rightSeparator, isNotNull);
    expect(forLoopParts.rightSeparator.type, TokenType.SEMICOLON);
  }

  void test_incompleteLocalVariable_atTheEndOfBlock() {
    Statement statement = parseStatement('String v }', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_atTheEndOfBlock_modifierOnly() {
    Statement statement = parseStatement('final }', expectedEndOffset: 6);
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 5),
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 6, 1),
    ]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'final ;');
  }

  void test_incompleteLocalVariable_beforeIdentifier() {
    Statement statement =
        parseStatement('String v String v2;', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeKeyword() {
    Statement statement =
        parseStatement('String v if (true) {}', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeNextBlock() {
    Statement statement = parseStatement('String v {}', expectedEndOffset: 9);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_parameterizedType() {
    Statement statement =
        parseStatement('List<String> v {}', expectedEndOffset: 15);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 13, 1)]);
    expect(statement, isVariableDeclarationStatement);
    expect(statement.toSource(), 'List<String> v;');
  }

  void test_incompleteTypeArguments_field() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  final List<int f;
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 23, 3)]);
// one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
// one field declaration
    List<ClassMember> members = classDecl.members;
    expect(members, hasLength(1));
    FieldDeclaration fieldDecl = members[0] as FieldDeclaration;
// one field
    VariableDeclarationList fieldList = fieldDecl.fields;
    List<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.name, 'f');
// validate the type
    var typeArguments = (fieldList.type as NamedType).typeArguments!;
    expect(typeArguments.arguments, hasLength(1));
// synthetic '>'
    Token token = typeArguments.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C<K {
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1)]);
// one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
// validate the type parameters
    var typeParameters = classDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(1));
// synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters2() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C<K extends L<T> {
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 21, 1)]);
// one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
// validate the type parameters
    var typeParameters = classDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(1));
// synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters3() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C<K extends L<T {
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 20, 1)]);
// one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
// validate the type parameters
    var typeParameters = classDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(1));
// synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_invalidFunctionBodyModifier() {
    parseCompilationUnit("f() sync {}",
        codes: [ParserErrorCode.MISSING_STAR_AFTER_SYNC]);
  }

  void test_invalidMapLiteral() {
    parseCompilationUnit("class C { var f = Map<A, B> {}; }", codes: [
      ParserErrorCode.LITERAL_WITH_CLASS,
    ]);
    parseCompilationUnit("class C { var f = new Map<A, B> {}; }", codes: [
      ParserErrorCode.LITERAL_WITH_CLASS_AND_NEW,
    ]);
    parseCompilationUnit("class C { var f = new <A, B> {}; }", codes: [
      ParserErrorCode.LITERAL_WITH_NEW,
    ]);
  }

  void test_invalidTypeParameters() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  G<int double> g;
}''', errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 18, 6)]);
// one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
// validate members
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    expect(classDecl.members, hasLength(1));
    var fields = classDecl.members.first as FieldDeclaration;
    expect(fields.fields.variables, hasLength(1));
    VariableDeclaration field = fields.fields.variables.first;
    expect(field.name.name, 'g');
  }

  void test_invalidTypeParameters_super() {
    parseCompilationUnit('class C<X super Y> {}', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 8, 1),
    ]);
  }

  void test_isExpression_noType() {
    CompilationUnit unit = parseCompilationUnit(
        "class Bar<T extends Foo> {m(x){if (x is ) return;if (x is !)}}",
        codes: [
          ParserErrorCode.EXPECTED_TYPE_NAME,
          ParserErrorCode.EXPECTED_TYPE_NAME,
          ParserErrorCode.MISSING_IDENTIFIER,
          ParserErrorCode.EXPECTED_TOKEN,
        ]);
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    MethodDeclaration method = declaration.members[0] as MethodDeclaration;
    BlockFunctionBody body = method.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[1] as IfStatement;
    IsExpression expression = ifStatement.condition as IsExpression;
    expect(expression.expression, isNotNull);
    expect(expression.isOperator, isNotNull);
    expect(expression.notOperator, isNotNull);
    TypeAnnotation type = expression.type;
    expect(type, isNotNull);
    expect(type is NamedType && type.name.isSynthetic, isTrue);
    var thenStatement = ifStatement.thenStatement as ExpressionStatement;
    expect(thenStatement.semicolon!.isSynthetic, isTrue);
    var simpleId = thenStatement.expression as SimpleIdentifier;
    expect(simpleId.isSynthetic, isTrue);
  }

  void test_issue_34610_get() {
    final unit =
        parseCompilationUnit('class C { get C.named => null; }', errors: [
      expectedError(ParserErrorCode.GETTER_CONSTRUCTOR, 10, 3),
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 14, 1),
    ]);
    var declaration = unit.declarations[0] as ClassDeclaration;
    var method = declaration.members[0] as ConstructorDeclaration;
    expect(method.name!.name, 'named');
    expect(method.parameters, isNotNull);
  }

  void test_issue_34610_initializers() {
    final unit = parseCompilationUnit('class C { C.named : super(); }',
        errors: [
          expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1)
        ]);
    var declaration = unit.declarations[0] as ClassDeclaration;
    var constructor = declaration.members[0] as ConstructorDeclaration;
    expect(constructor.name!.name, 'named');
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, hasLength(0));
  }

  void test_issue_34610_missing_param() {
    final unit = parseCompilationUnit('class C { C => null; }', errors: [
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1)
    ]);
    var declaration = unit.declarations[0] as ClassDeclaration;
    var constructor = declaration.members[0] as ConstructorDeclaration;
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, hasLength(0));
  }

  void test_issue_34610_named_missing_param() {
    final unit = parseCompilationUnit('class C { C.named => null; }', errors: [
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 10, 1)
    ]);
    var declaration = unit.declarations[0] as ClassDeclaration;
    var constructor = declaration.members[0] as ConstructorDeclaration;
    expect(constructor.name!.name, 'named');
    expect(constructor.parameters, isNotNull);
    expect(constructor.parameters.parameters, hasLength(0));
  }

  void test_issue_34610_set() {
    final unit =
        parseCompilationUnit('class C { set C.named => null; }', errors: [
      expectedError(ParserErrorCode.SETTER_CONSTRUCTOR, 10, 3),
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 14, 1),
    ]);
    var declaration = unit.declarations[0] as ClassDeclaration;
    var method = declaration.members[0] as ConstructorDeclaration;
    expect(method.name!.name, 'named');
    expect(method.parameters, isNotNull);
    expect(method.parameters.parameters, hasLength(0));
  }

  void test_keywordInPlaceOfIdentifier() {
// TODO(brianwilkerson) We could do better with this.
    parseCompilationUnit("do() {}",
        codes: [ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD]);
  }

  void test_logicalAndExpression_missing_LHS() {
    var expression =
        parseExpression("&& y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_LHS_RHS() {
    var expression = parseExpression("&&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_RHS() {
    var expression =
        parseExpression("x &&", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    var expression = parseExpression("| &&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    var expression = parseExpression("&& |", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_missing_LHS() {
    var expression =
        parseExpression("|| y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_LHS_RHS() {
    var expression = parseExpression("||", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_RHS() {
    var expression =
        parseExpression("x ||", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    var expression = parseExpression("&& ||", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    var expression = parseExpression("|| &&", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_method_missingBody() {
    parseCompilationUnit("class C { b() }",
        errors: [expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 14, 1)]);
  }

  void test_missing_commaInArgumentList() {
    var expression = parseExpression("f(x: 1 y: 2)",
            errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 1)])
        as MethodInvocation;
    NodeList<Expression> arguments = expression.argumentList.arguments;
    expect(arguments, hasLength(2));
  }

  void test_missingComma_beforeNamedArgument() {
    createParser('(a b: c)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener
        .assertErrors([expectedError(ParserErrorCode.EXPECTED_TOKEN, 3, 1)]);
    expect(argumentList.arguments, hasLength(2));
  }

  void test_missingGet() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  int length {}
  void foo() {}
}''', errors: [
      expectedError(ParserErrorCode.MISSING_METHOD_PARAMETERS, 16, 6)
    ]);
    expect(unit, isNotNull);
    ClassDeclaration classDeclaration =
        unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = classDeclaration.members;
    expect(members, hasLength(2));
    expect(members[0], isMethodDeclaration);
    ClassMember member = members[1];
    expect(member, isMethodDeclaration);
    expect((member as MethodDeclaration).name.name, "foo");
  }

  void test_missingIdentifier_afterAnnotation() {
    createParser('@override }', expectedEndOffset: 10);
    var member = parser.parseClassMemberOrNull('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [expectedError(ParserErrorCode.EXPECTED_CLASS_MEMBER, 10, 1)]);
// TODO(danrubel): Consider generating a sub method so that the
// existing annotation can be associated with a class member.
    expect(member, isNull);
  }

  void test_missingSemicolon_varialeDeclarationList() {
    void verify(CompilationUnitMember member, String expectedTypeName,
        String expectedName, String expectedSemicolon) {
      expect(member, isTopLevelVariableDeclaration);
      var declaration = member as TopLevelVariableDeclaration;
      VariableDeclarationList variableList = declaration.variables;
      expect(variableList, isNotNull);
      NodeList<VariableDeclaration> variables = variableList.variables;
      expect(variables, hasLength(1));
      VariableDeclaration variable = variables[0];
      expect(variableList.type.toString(), expectedTypeName);
      expect(variable.name.name, expectedName);
      if (expectedSemicolon.isEmpty) {
        expect(declaration.semicolon.isSynthetic, isTrue);
      } else {
        expect(declaration.semicolon.lexeme, expectedSemicolon);
      }
    }

// Fasta considers the `n` an extraneous modifier
// and parses this as a single top level declaration.
// TODO(danrubel): A better recovery
// would be to insert a synthetic comma after the `n`.
    CompilationUnit unit = parseCompilationUnit('String n x = "";', codes: [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    verify(declarations[0], 'String', 'n', '');
    verify(declarations[1], 'null', 'x', ';');
  }

  void test_multiplicativeExpression_missing_LHS() {
    var expression =
        parseExpression("* y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_LHS_RHS() {
    var expression = parseExpression("*", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS() {
    var expression =
        parseExpression("x *", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS_super() {
    var expression =
        parseExpression("super *", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    var expression =
        parseExpression("-x *", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    var expression =
        parseExpression("* -y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_super() {
    var expression = parseExpression("super ==  ==", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_namedParameterOutsideGroup() {
    CompilationUnit unit =
        parseCompilationUnit('class A { b(c: 0, Foo d: 0, e){} }', errors: [
      expectedError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, 13, 1),
      expectedError(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, 23, 1)
    ]);
    expect(unit.declarations, hasLength(1));
    var classA = unit.declarations[0] as ClassDeclaration;
    expect(classA.members, hasLength(1));
    var method = classA.members[0] as MethodDeclaration;
    List<FormalParameter> parameters = method.parameters!.parameters;
    expect(parameters, hasLength(3));
    expect(parameters[0].isNamed, isTrue);
    expect(parameters[1].isNamed, isTrue);
    expect(parameters[2].isRequired, isTrue);
  }

  void test_nonStringLiteralUri_import() {
    parseCompilationUnit("import dart:io; class C {}", errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 0, 6),
      expectedError(ParserErrorCode.EXPECTED_STRING_LITERAL, 7, 4),
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 7, 4),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 4),
      expectedError(ParserErrorCode.EXPECTED_EXECUTABLE, 11, 1),
      expectedError(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 12, 2)
    ]);
  }

  void test_prefixExpression_missing_operand_minus() {
    var expression =
        parseExpression("-", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as PrefixExpression;
    expect(expression.operand, isSimpleIdentifier);
    expect(expression.operand.isSynthetic, isTrue);
    expect(expression.operator.type, TokenType.MINUS);
  }

  void test_primaryExpression_argumentDefinitionTest() {
    var expression = parsePrimaryExpression('?a',
            expectedEndOffset: 0,
            errors: [expectedError(ParserErrorCode.MISSING_IDENTIFIER, 0, 1)])
        as SimpleIdentifier;
    expectNotNullIfNoErrors(expression);
    expect(expression.isSynthetic, isTrue);
  }

  void test_propertyAccess_missing_LHS_RHS() {
    Expression result = parseExpression(".", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    var expression = result as PrefixedIdentifier;
    expect(expression.prefix.isSynthetic, isTrue);
    expect(expression.period.lexeme, '.');
    expect(expression.identifier.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_LHS() {
    var expression =
        parseExpression("is y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as IsExpression;
    expect(expression.expression, isSimpleIdentifier);
    expect(expression.expression.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_LHS_RHS() {
    parseExpression("is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  void test_relationalExpression_missing_RHS() {
    var expression =
        parseExpression("x is", codes: [ParserErrorCode.EXPECTED_TYPE_NAME])
            as IsExpression;
    expect(expression.type, isNamedType);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_precedence_shift_right() {
    parseExpression("<< is", codes: [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
  }

  void test_shiftExpression_missing_LHS() {
    var expression =
        parseExpression("<< y", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_LHS_RHS() {
    var expression = parseExpression("<<", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.leftOperand.isSynthetic, isTrue);
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS() {
    var expression =
        parseExpression("x <<", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS_super() {
    var expression =
        parseExpression("super <<", codes: [ParserErrorCode.MISSING_IDENTIFIER])
            as BinaryExpression;
    expect(expression.rightOperand, isSimpleIdentifier);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_precedence_unary_left() {
    var expression = parseExpression("+ <<", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_unary_right() {
    var expression = parseExpression("<< +", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_shiftExpression_super() {
    var expression = parseExpression("super << <<", codes: [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]) as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_typedef_eof() {
    CompilationUnit unit = parseCompilationUnit("typedef n", codes: [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_TYPEDEF_PARAMETERS
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    expect(member, isFunctionTypeAlias);
  }

  void test_unaryPlus() {
    parseExpression("+2", codes: [ParserErrorCode.MISSING_IDENTIFIER]);
  }
}

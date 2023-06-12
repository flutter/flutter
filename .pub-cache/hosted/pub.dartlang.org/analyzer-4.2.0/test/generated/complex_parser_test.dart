// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComplexParserTest);
  });
}

/// The class `ComplexParserTest` defines parser tests that test the parsing of
/// more complex code fragments or the interactions between multiple parsing
/// methods. For example, tests to ensure that the precedence of operations is
/// being handled correctly should be defined in this class.
///
/// Simpler tests should be defined in the class [SimpleParserTest].
@reflectiveTest
class ComplexParserTest extends FastaParserTestCase {
  void test_additiveExpression_normal() {
    var expression = parseExpression("x + y - z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_noSpaces() {
    var expression = parseExpression("i+1") as BinaryExpression;
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.rightOperand, isIntegerLiteral);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    var expression = parseExpression("x * y + z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    var expression = parseExpression("super * y - z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    var expression = parseExpression("x + y * z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_additiveExpression_super() {
    var expression = parseExpression("super + y - z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_assignableExpression_arguments_normal_chain() {
    var propertyAccess1 = parseExpression("a(b)(c).d(e).f") as PropertyAccess;
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a(b)(c).d(e)
    //
    var invocation2 = propertyAccess1.target as MethodInvocation;
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a(b)(c)
    //
    var invocation3 = invocation2.target as FunctionExpressionInvocation;
    expect(invocation3.typeArguments, isNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    var invocation4 = invocation3.function as MethodInvocation;
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }

  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    _validate_assignableExpression_arguments_normal_chain_typeArguments(
        "a<E>(b)<F>(c).d<G>(e).f");
  }

  void test_assignmentExpression_compound() {
    var expression = parseExpression("x = y = 0") as AssignmentExpression;
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.rightHandSide, isAssignmentExpression);
  }

  void test_assignmentExpression_indexExpression() {
    var expression = parseExpression("x[1] = 0") as AssignmentExpression;
    expect(expression.leftHandSide, isIndexExpression);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_assignmentExpression_prefixedIdentifier() {
    var expression = parseExpression("x.y = 0") as AssignmentExpression;
    expect(expression.leftHandSide, isPrefixedIdentifier);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_assignmentExpression_propertyAccess() {
    var expression = parseExpression("super.y = 0") as AssignmentExpression;
    expect(expression.leftHandSide, isPropertyAccess);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_binary_operator_written_out_expression() {
    var expression = parseExpression('x xor y', errors: [
      expectedError(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 2, 3),
    ]) as BinaryExpression;
    var lhs = expression.leftOperand as SimpleIdentifier;
    expect(lhs.name, 'x');
    expect(expression.operator.lexeme, '^');
    var rhs = expression.rightOperand as SimpleIdentifier;
    expect(rhs.name, 'y');
  }

  void test_binary_operator_written_out_expression_logical() {
    var expression = parseExpression('x > 0 and y > 1', errors: [
      expectedError(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 6, 3),
    ]) as BinaryExpression;
    var lhs = expression.leftOperand as BinaryExpression;
    expect((lhs.leftOperand as SimpleIdentifier).name, 'x');
    expect(lhs.operator.lexeme, '>');
    expect((lhs.rightOperand as IntegerLiteral).value, 0);

    expect(expression.operator.lexeme, '&&');

    var rhs = expression.rightOperand as BinaryExpression;
    expect((rhs.leftOperand as SimpleIdentifier).name, 'y');
    expect(rhs.operator.lexeme, '>');
    expect((rhs.rightOperand as IntegerLiteral).value, 1);
  }

  void test_bitwiseAndExpression_normal() {
    var expression = parseExpression("x & y & z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    var expression = parseExpression("x == y && z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    var expression = parseExpression("x && y == z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_super() {
    var expression = parseExpression("super & y & z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_normal() {
    var expression = parseExpression("x | y | z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    var expression = parseExpression("x ^ y | z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    var expression = parseExpression("x | y ^ z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_super() {
    var expression = parseExpression("super | y | z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_normal() {
    var expression = parseExpression("x ^ y ^ z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    var expression = parseExpression("x & y ^ z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    var expression = parseExpression("x ^ y & z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_super() {
    var expression = parseExpression("super ^ y ^ z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_cascade_withAssignment() {
    var cascade =
        parseExpression("new Map()..[3] = 4 ..[0] = 11") as CascadeExpression;
    Expression target = cascade.target;
    for (Expression section in cascade.cascadeSections) {
      expect(section, isAssignmentExpression);
      Expression lhs = (section as AssignmentExpression).leftHandSide;
      expect(lhs, isIndexExpression);
      IndexExpression index = lhs as IndexExpression;
      expect(index.isCascaded, isTrue);
      expect(index.realTarget, same(target));
    }
  }

  void test_conditionalExpression_precedence_ifNullExpression() {
    var expression = parseExpression('a ?? b ? y : z') as ConditionalExpression;
    expect(expression.condition, isBinaryExpression);
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    var expression = parseExpression("a | b ? y : z") as ConditionalExpression;
    expect(expression.condition, isBinaryExpression);
  }

  void test_conditionalExpression_precedence_nullableType_as() {
    var statement =
        parseStatement('x as bool ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    Expression condition = expression.condition;
    expect(condition, isAsExpression);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_conditionalExpression_precedence_nullableType_as2() {
    var statement =
        parseStatement('x as bool? ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var asExpression = expression.condition as AsExpression;
    var type = asExpression.type as NamedType;
    expect(type.question!.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableType_as3() {
    var statement =
        parseStatement('(x as bool?) ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var condition = expression.condition as ParenthesizedExpression;
    var asExpression = condition.expression as AsExpression;
    var type = asExpression.type as NamedType;
    expect(type.question!.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableType_is() {
    var statement =
        parseStatement('x is String ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    Expression condition = expression.condition;
    expect(condition, isIsExpression);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_conditionalExpression_precedence_nullableType_is2() {
    var statement =
        parseStatement('x is String? ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var isExpression = expression.condition as IsExpression;
    var type = isExpression.type as NamedType;
    expect(type.question!.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableType_is3() {
    var statement =
        parseStatement('(x is String?) ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var condition = expression.condition as ParenthesizedExpression;
    var isExpression = condition.expression as IsExpression;
    var type = isExpression.type as NamedType;
    expect(type.question!.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1_is() {
    var statement =
        parseStatement('x is String<S> ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1GFT_is() {
    var statement = parseStatement('x is String<S> Function() ? (x + y) : z;')
        as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg2_is() {
    var statement = parseStatement('x is String<S,T> ? (x + y) : z;')
        as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_prefixedNullableType_is() {
    var statement =
        parseStatement('x is p.A ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;

    var condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_withAssignment() {
    var statement =
        parseStatement('b ? c = true : g();') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    expect(expression.condition, TypeMatcher<SimpleIdentifier>());
    expect(expression.thenExpression, TypeMatcher<AssignmentExpression>());
  }

  void test_conditionalExpression_precedence_withAssignment2() {
    var statement =
        parseStatement('b.x ? c = true : g();') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<AssignmentExpression>());
  }

  void test_conditionalExpression_prefixedValue() {
    var statement = parseStatement('a.b ? y : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_prefixedValue2() {
    var statement = parseStatement('a.b ? x.y : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<PrefixedIdentifier>());
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  C() :
    this.a = (b == null ? c : d) {
  }
}''');
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
  }

  void test_equalityExpression_normal() {
    var expression = parseExpression("x == y != z",
            codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND])
        as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_equalityExpression_precedence_relational_left() {
    var expression = parseExpression("x is y == z") as BinaryExpression;
    expect(expression.leftOperand, isIsExpression);
  }

  void test_equalityExpression_precedence_relational_right() {
    var expression = parseExpression("x == y is z") as BinaryExpression;
    expect(expression.rightOperand, isIsExpression);
  }

  void test_equalityExpression_super() {
    var expression = parseExpression("super == y != z",
            codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND])
        as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression() {
    var expression = parseExpression('x ?? y ?? z') as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression_precedence_logicalOr_left() {
    var expression = parseExpression('x || y ?? z') as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression_precedence_logicalOr_right() {
    var expression = parseExpression('x ?? y || z') as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalAndExpression() {
    var expression = parseExpression("x && y && z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    var expression = parseExpression("x | y < z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    var expression = parseExpression("x < y | z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalAndExpressionStatement() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    var statement = parseStatement("C<T && T>U;") as ExpressionStatement;
    var expression = statement.expression as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression() {
    var expression = parseExpression("x || y || z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    var expression = parseExpression("x && y || z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    var expression = parseExpression("x || y && z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_methodInvocation1() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    var statement = parseStatement("f(a < b, c > 3);") as ExpressionStatement;
    assertNoErrors();
    var method = statement.expression as MethodInvocation;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_methodInvocation2() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    var statement = parseStatement("f(a < b, c >> 3);") as ExpressionStatement;
    assertNoErrors();
    var method = statement.expression as MethodInvocation;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_methodInvocation3() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    var statement =
        parseStatement("f(a < b, c < d >> 3);") as ExpressionStatement;
    assertNoErrors();
    var method = statement.expression as MethodInvocation;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_multipleLabels_statement() {
    var statement = parseStatement("a: b: c: return x;") as LabeledStatement;
    expect(statement.labels, hasLength(3));
    expect(statement.statement, isReturnStatement);
  }

  void test_multiplicativeExpression_normal() {
    var expression = parseExpression("x * y / z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    var expression = parseExpression("-x * y") as BinaryExpression;
    expect(expression.leftOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    var expression = parseExpression("x * -y") as BinaryExpression;
    expect(expression.rightOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_super() {
    var expression = parseExpression("super * y / z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_relationalExpression_precedence_shift_right() {
    var expression = parseExpression("x << y is z") as IsExpression;
    expect(expression.expression, isBinaryExpression);
  }

  void test_shiftExpression_normal() {
    var expression = parseExpression("x >> 4 << 3") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_additive_left() {
    var expression = parseExpression("x + y << z") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_additive_right() {
    var expression = parseExpression("x << y + z") as BinaryExpression;
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_shiftExpression_super() {
    var expression = parseExpression("super >> 4 << 3") as BinaryExpression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_topLevelFunction_nestedGenericFunction() {
    parseCompilationUnit('''
void f() {
  void g<T>() {
  }
}
''');
  }

  void _validate_assignableExpression_arguments_normal_chain_typeArguments(
      String code,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    var propertyAccess1 =
        parseExpression(code, codes: errorCodes) as PropertyAccess;
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a<E>(b)<F>(c).d<G>(e)
    //
    var invocation2 = propertyAccess1.target as MethodInvocation;
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNotNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a<E>(b)<F>(c)
    //
    var invocation3 = invocation2.target as FunctionExpressionInvocation;
    expect(invocation3.typeArguments, isNotNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    var invocation4 = invocation3.function as MethodInvocation;
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNotNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }
}

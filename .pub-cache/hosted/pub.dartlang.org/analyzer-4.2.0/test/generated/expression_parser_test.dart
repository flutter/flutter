// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show AbstractScanner;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show InstanceCreationExpressionImpl;
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionParserTest);
  });
}

/// Tests of the fasta parser based on [ExpressionParserTestMixin].
@reflectiveTest
class ExpressionParserTest extends FastaParserTestCase {
  void test_binaryExpression_allOperators() {
    // https://github.com/dart-lang/sdk/issues/36255
    for (TokenType type in TokenType.all) {
      if (type.precedence > 0) {
        var source = 'a ${type.lexeme} b';
        try {
          parseExpression(source);
        } on TestFailure {
          // Ensure that there are no infinite loops or exceptions thrown
          // by the parser. Test failures are fine.
        }
      }
    }
  }

  void test_invalidExpression_37706() {
    // https://github.com/dart-lang/sdk/issues/37706
    parseExpression('<b?c>()', errors: [
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 1, 1),
      expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 0),
      expectedError(ParserErrorCode.MISSING_FUNCTION_BODY, 7, 0),
    ]);
  }

  void test_listLiteral_invalid_assert() {
    // https://github.com/dart-lang/sdk/issues/37674
    parseExpression('n=<.["\$assert', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 3, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 1),
      expectedError(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 7, 6),
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 12, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 13, 1),
    ]);
  }

  void test_listLiteral_invalidElement_37697() {
    // https://github.com/dart-lang/sdk/issues/37674
    parseExpression('[<y.<z>(){}]', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 4, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 6, 1),
    ]);
  }

  void test_lt_dot_bracket_quote() {
    // https://github.com/dart-lang/sdk/issues/37674
    var list = parseExpression('<.["', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 1, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 2, 1),
      expectedError(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, 3, 1),
      expectedError(ScannerErrorCode.EXPECTED_TOKEN, 4, 1),
    ]) as ListLiteral;
    expect(list.elements, hasLength(1));
    var first = list.elements[0] as StringLiteral;
    expect(first.length, 1);
  }

  void test_lt_dot_listLiteral() {
    // https://github.com/dart-lang/sdk/issues/37674
    var list = parseExpression('<.[]', errors: [
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 1, 1),
      expectedError(ParserErrorCode.EXPECTED_TYPE_NAME, 2, 2),
    ]) as ListLiteral;
    expect(list.elements, hasLength(0));
  }

  void test_mapLiteral() {
    var map = parseExpression('{3: 6}') as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));
    var entry = map.elements[0] as MapLiteralEntry;
    var key = entry.key as IntegerLiteral;
    expect(key.value, 3);
    var value = entry.value as IntegerLiteral;
    expect(value.value, 6);
  }

  void test_mapLiteral_const() {
    var map = parseExpression('const {3: 6}') as SetOrMapLiteral;
    expect(map.constKeyword, isNotNull);
    expect(map.typeArguments, isNull);
    expect(map.elements, hasLength(1));
    var entry = map.elements[0] as MapLiteralEntry;
    var key = entry.key as IntegerLiteral;
    expect(key.value, 3);
    var value = entry.value as IntegerLiteral;
    expect(value.value, 6);
  }

  @failingTest
  void test_mapLiteral_invalid_too_many_type_arguments1() {
    var map = parseExpression('<int, int, int>{}', errors: [
      // TODO(danrubel): Currently the resolver reports invalid number of
      // type arguments, but the parser could report this.
      expectedError(
          /* ParserErrorCode.EXPECTED_ONE_OR_TWO_TYPE_VARIABLES */
          ParserErrorCode.EXPECTED_TOKEN,
          11,
          3),
    ]) as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.elements, hasLength(0));
  }

  @failingTest
  void test_mapLiteral_invalid_too_many_type_arguments2() {
    var map = parseExpression('<int, int, int>{1}', errors: [
      // TODO(danrubel): Currently the resolver reports invalid number of
      // type arguments, but the parser could report this.
      expectedError(
          /* ParserErrorCode.EXPECTED_ONE_OR_TWO_TYPE_VARIABLES */
          ParserErrorCode.EXPECTED_TOKEN,
          11,
          3),
    ]) as SetOrMapLiteral;
    expect(map.constKeyword, isNull);
    expect(map.elements, hasLength(0));
  }

  void test_namedArgument() {
    var invocation = parseExpression('m(a: 1, b: 2)') as MethodInvocation;
    List<Expression> arguments = invocation.argumentList.arguments;

    var a = arguments[0] as NamedExpression;
    expect(a.name.label.name, 'a');
    expect(a.expression, isNotNull);

    var b = arguments[1] as NamedExpression;
    expect(b.name.label.name, 'b');
    expect(b.expression, isNotNull);
  }

  void test_nullableTypeInStringInterpolations_as_48999() {
    // https://github.com/dart-lang/sdk/issues/48999
    Expression expression = parseExpression(r'"${i as int?}"');
    expect(expression, isNotNull);
    assertNoErrors();

    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));

    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, '');

    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isAsExpression);
    var asExpression = element1.expression as AsExpression;
    expect(asExpression.expression, isSimpleIdentifier);
    expect(asExpression.type, isNamedType);
    var namedType = asExpression.type as NamedType;
    expect(namedType.name.name, "int");
    expect(namedType.question, isNotNull);

    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, '');
  }

  void test_nullableTypeInStringInterpolations_is_48999() {
    // https://github.com/dart-lang/sdk/issues/48999
    Expression expression = parseExpression(r'"${i is int?}"');
    expect(expression, isNotNull);
    assertNoErrors();

    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));

    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, '');

    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isIsExpression);
    var isExpression = element1.expression as IsExpression;
    expect(isExpression.expression, isSimpleIdentifier);
    expect(isExpression.type, isNamedType);
    var namedType = isExpression.type as NamedType;
    expect(namedType.name.name, "int");
    expect(namedType.question, isNotNull);

    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, '');
  }

  void test_parseAdditiveExpression_normal() {
    Expression expression = parseAdditiveExpression('x + y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.PLUS);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseAdditiveExpression_super() {
    Expression expression = parseAdditiveExpression('super + y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.PLUS);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot() {
    Expression expression = parseAssignableExpression('(x)(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot_typeArguments() {
    Expression expression = parseAssignableExpression('(x)<F>(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_dot() {
    Expression expression = parseAssignableExpression('(x).y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_index() {
    Expression expression = parseAssignableExpression('(x)[y]', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_expression_question_dot() {
    Expression expression = parseAssignableExpression('(x)?.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier() {
    Expression expression = parseAssignableExpression('x', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as SimpleIdentifier;
    expect(identifier, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot() {
    Expression expression = parseAssignableExpression('x(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot_typeArguments() {
    Expression expression = parseAssignableExpression('x<E>(y).z', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_dot() {
    Expression expression = parseAssignableExpression('x.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as PrefixedIdentifier;
    expect(identifier.prefix.name, 'x');
    expect(identifier.period, isNotNull);
    expect(identifier.period.type, TokenType.PERIOD);
    expect(identifier.identifier.name, 'y');
  }

  void test_parseAssignableExpression_identifier_index() {
    Expression expression = parseAssignableExpression('x[y]', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_identifier_question_dot() {
    Expression expression = parseAssignableExpression('x?.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_dot() {
    Expression expression = parseAssignableExpression('super.y', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target, isSuperExpression);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_index() {
    Expression expression = parseAssignableExpression('super[y]', false);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isSuperExpression);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_dot() {
    Expression expression = parseAssignableSelector('.x', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableSelector_index() {
    Expression expression = parseAssignableSelector('[x]', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_none() {
    Expression expression = parseAssignableSelector('', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as SimpleIdentifier;
    expect(identifier, isNotNull);
  }

  void test_parseAssignableSelector_question_dot() {
    Expression expression = parseAssignableSelector('?.x', true);
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAwaitExpression() {
    AwaitExpression expression = parseAwaitExpression('await x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.awaitKeyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseBitwiseAndExpression_normal() {
    Expression expression = parseBitwiseAndExpression('x & y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseAndExpression_super() {
    Expression expression = parseBitwiseAndExpression('super & y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_normal() {
    Expression expression = parseBitwiseOrExpression('x | y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_super() {
    Expression expression = parseBitwiseOrExpression('super | y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_normal() {
    Expression expression = parseBitwiseXorExpression('x ^ y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.CARET);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_super() {
    Expression expression = parseBitwiseXorExpression('super ^ y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.CARET);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseCascadeSection_i() {
    Expression expression = parseCascadeSection('..[i]');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as IndexExpression;
    expect(section.target, isNull);
    expect(section.leftBracket, isNotNull);
    expect(section.index, isNotNull);
    expect(section.rightBracket, isNotNull);
  }

  void test_parseCascadeSection_ia() {
    Expression expression = parseCascadeSection('..[i](b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isIndexExpression);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ia_typeArguments() {
    Expression expression = parseCascadeSection('..[i]<E>(b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isIndexExpression);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ii() {
    Expression expression = parseCascadeSection('..a(b).c(d)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isMethodInvocation);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_ii_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b).c<F>(d)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isMethodInvocation);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_p() {
    Expression expression = parseCascadeSection('..a');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_p_assign() {
    Expression expression = parseCascadeSection('..a = 3');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as AssignmentExpression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isNotNull);
  }

  void test_parseCascadeSection_p_assign_withCascade() {
    Expression expression = parseCascadeSection('..a = 3..m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as AssignmentExpression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isIntegerLiteral);
  }

  void test_parseCascadeSection_p_assign_withCascade_typeArguments() {
    Expression expression = parseCascadeSection('..a = 3..m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as AssignmentExpression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isIntegerLiteral);
  }

  void test_parseCascadeSection_p_builtIn() {
    Expression expression = parseCascadeSection('..as');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pa() {
    Expression expression = parseCascadeSection('..a(b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pa_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as MethodInvocation;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa() {
    Expression expression = parseCascadeSection('..a(b)(c)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b)<F>(c)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa() {
    Expression expression = parseCascadeSection('..a(b)(c).d(e)(f)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa_typeArguments() {
    Expression expression =
        parseCascadeSection('..a<E>(b)<F>(c).d<G>(e)<H>(f)');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as FunctionExpressionInvocation;
    expect(section.function, isMethodInvocation);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pap() {
    Expression expression = parseCascadeSection('..a(b).c');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pap_typeArguments() {
    Expression expression = parseCascadeSection('..a<E>(b).c');
    expect(expression, isNotNull);
    assertNoErrors();
    var section = expression as PropertyAccess;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseConditionalExpression() {
    ConditionalExpression expression = parseConditionalExpression('x ? y : z');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.condition, isNotNull);
    expect(expression.question, isNotNull);
    expect(expression.thenExpression, isNotNull);
    expect(expression.colon, isNotNull);
    expect(expression.elseExpression, isNotNull);
  }

  void test_parseConstExpression_instanceCreation() {
    Expression expression = parseConstExpression('const A()');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isInstanceCreationExpression);
    var instanceCreation = expression as InstanceCreationExpression;
    expect(instanceCreation.keyword, isNotNull);
    ConstructorName name = instanceCreation.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(instanceCreation.argumentList, isNotNull);
  }

  void test_parseConstExpression_listLiteral_typed() {
    Expression expression = parseConstExpression('const <A> []');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_listLiteral_untyped() {
    Expression expression = parseConstExpression('const []');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed() {
    Expression expression = parseConstExpression('const <A, B> {}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed_missingGt() {
    Expression expression = parseExpression('const <A, B {}',
        errors: [expectedError(ParserErrorCode.EXPECTED_TOKEN, 10, 1)]);
    expect(expression, isNotNull);
    var literal = expression as SetOrMapLiteral;
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_untyped() {
    Expression expression = parseConstExpression('const {}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNull);
  }

  void test_parseConstructorInitializer_functionExpression() {
    // https://github.com/dart-lang/sdk/issues/37414
    parseCompilationUnit('class C { C.n() : this()(); }', errors: [
      expectedError(ParserErrorCode.INVALID_INITIALIZER, 18, 8),
    ]);
  }

  void test_parseEqualityExpression_normal() {
    BinaryExpression expression = parseEqualityExpression('x == y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseEqualityExpression_super() {
    BinaryExpression expression = parseEqualityExpression('super == y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isSuperExpression);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseExpression_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    Expression expression = parseExpression('x = y');
    var assignmentExpression = expression as AssignmentExpression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpression_assign_compound() {
    if (AbstractScanner.LAZY_ASSIGNMENT_ENABLED) {
      Expression expression = parseExpression('x ||= y');
      var assignmentExpression = expression as AssignmentExpression;
      expect(assignmentExpression.leftHandSide, isNotNull);
      expect(assignmentExpression.operator, isNotNull);
      expect(assignmentExpression.operator.type, TokenType.BAR_BAR_EQ);
      expect(assignmentExpression.rightHandSide, isNotNull);
    }
  }

  void test_parseExpression_comparison() {
    Expression expression = parseExpression('--a.b == c');
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.EQ_EQ);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseExpression_constAndTypeParameters() {
    Expression expression = parseExpression('const <E>', codes: [
      // TODO(danrubel): Improve this error message.
      ParserErrorCode.EXPECTED_TOKEN
    ]);
    expect(expression, isNotNull);
  }

  void test_parseExpression_function_async() {
    Expression expression = parseExpression('() async {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isTrue);
    expect(functionExpression.body.isGenerator, isFalse);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_asyncStar() {
    Expression expression = parseExpression('() async* {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isTrue);
    expect(functionExpression.body.isGenerator, isTrue);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_sync() {
    Expression expression = parseExpression('() {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isFalse);
    expect(functionExpression.body.isGenerator, isFalse);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_syncStar() {
    Expression expression = parseExpression('() sync* {}');
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isFalse);
    expect(functionExpression.body.isGenerator, isTrue);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_invokeFunctionExpression() {
    Expression expression = parseExpression('(a) {return a + a;} (3)');
    var invocation = expression as FunctionExpressionInvocation;
    expect(invocation.function, isFunctionExpression);
    FunctionExpression functionExpression =
        invocation.function as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList list = invocation.argumentList;
    expect(list, isNotNull);
    expect(list.arguments, hasLength(1));
  }

  void test_parseExpression_nonAwait() {
    Expression expression = parseExpression('await()');
    var invocation = expression as MethodInvocation;
    expect(invocation.methodName.name, 'await');
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_sendWithTypeParam_afterIndex() {
    final unit = parseCompilationUnit('main() { factories[C]<num, int>(); }');
    expect(unit.declarations, hasLength(1));
    var mainMethod = unit.declarations[0] as FunctionDeclaration;
    var body = mainMethod.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    expect(statements, hasLength(1));
    var statement = statements[0] as ExpressionStatement;
    var expression = statement.expression as FunctionExpressionInvocation;

    var function = expression.function as IndexExpression;
    var target = function.target as SimpleIdentifier;
    expect(target.name, 'factories');
    var index = function.index as SimpleIdentifier;
    expect(index.name, 'C');

    List<TypeAnnotation> typeArguments = expression.typeArguments!.arguments;
    expect(typeArguments, hasLength(2));
    expect((typeArguments[0] as NamedType).name.name, 'num');
    expect((typeArguments[1] as NamedType).name.name, 'int');

    expect(expression.argumentList.arguments, hasLength(0));
  }

  void test_parseExpression_sendWithTypeParam_afterSend() {
    final unit = parseCompilationUnit('main() { factories(C)<num, int>(); }');
    expect(unit.declarations, hasLength(1));
    var mainMethod = unit.declarations[0] as FunctionDeclaration;
    var body = mainMethod.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    expect(statements, hasLength(1));
    var statement = statements[0] as ExpressionStatement;
    var expression = statement.expression as FunctionExpressionInvocation;

    var invocation = expression.function as MethodInvocation;
    expect(invocation.methodName.name, 'factories');
    NodeList<Expression> invocationArguments =
        invocation.argumentList.arguments;
    expect(invocationArguments, hasLength(1));
    var index = invocationArguments[0] as SimpleIdentifier;
    expect(index.name, 'C');

    List<TypeAnnotation> typeArguments = expression.typeArguments!.arguments;
    expect(typeArguments, hasLength(2));
    expect((typeArguments[0] as NamedType).name.name, 'num');
    expect((typeArguments[1] as NamedType).name.name, 'int');

    expect(expression.argumentList.arguments, hasLength(0));
  }

  void test_parseExpression_superMethodInvocation() {
    Expression expression = parseExpression('super.m()');
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation_typeArguments() {
    Expression expression = parseExpression('super.m<E>()');
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation_typeArguments_chained() {
    Expression expression = parseExpression('super.b.c<D>()');
    MethodInvocation invocation = expression as MethodInvocation;
    var target = invocation.target as Expression;
    expect(target, isPropertyAccess);
    expect(invocation.methodName, isNotNull);
    expect(invocation.methodName.name, 'c');
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpressionList_multiple() {
    List<Expression> result = parseExpressionList('1, 2, 3');
    expect(result, isNotNull);
    assertNoErrors();
    expect(result, hasLength(3));
  }

  void test_parseExpressionList_single() {
    List<Expression> result = parseExpressionList('1');
    expect(result, isNotNull);
    assertNoErrors();
    expect(result, hasLength(1));
  }

  void test_parseExpressionWithoutCascade_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    Expression expression = parseExpressionWithoutCascade('x = y');
    expect(expression, isNotNull);
    assertNoErrors();
    var assignmentExpression = expression as AssignmentExpression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpressionWithoutCascade_comparison() {
    Expression expression = parseExpressionWithoutCascade('--a.b == c');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.EQ_EQ);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    Expression expression = parseExpressionWithoutCascade('super.m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArguments() {
    Expression expression = parseExpressionWithoutCascade('super.m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var invocation = expression as MethodInvocation;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseFunctionExpression_body_inExpression() {
    FunctionExpression expression = parseFunctionExpression('(int i) => i++');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseFunctionExpression_constAndTypeParameters2() {
    FunctionExpression expression =
        parseFunctionExpression('const <E>(E i) => i++');
    expect(expression, isNotNull);
    assertErrorsWithCodes([ParserErrorCode.UNEXPECTED_TOKEN]);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseFunctionExpression_functionInPlaceOfTypeName() {
    Expression expression = parseExpression('<test(' ', (){});>[0, 1, 2]',
        codes: [ParserErrorCode.EXPECTED_TOKEN]);
    expect(expression, isNotNull);
    var literal = expression as ListLiteral;
    expect(literal.typeArguments!.arguments, hasLength(1));
  }

  void test_parseFunctionExpression_typeParameters() {
    FunctionExpression expression = parseFunctionExpression('<E>(E i) => i++');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type.name.name, 'A.B');
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B<E>.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments!.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.B<E>()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments!.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A.c()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    var expression = parseInstanceCreationExpression('A<B>.c()', token)
        as InstanceCreationExpressionImpl;
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments!.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
    expect(expression.typeArguments, isNull);
  }

  void test_parseInstanceCreationExpression_type_named_typeArguments_34403() {
    var expression = parseExpression('new a.b.c<C>()', errors: [
      expectedError(ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS, 8, 1)
    ]) as InstanceCreationExpressionImpl;
    expect(expression, isNotNull);
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
    expect(expression.typeArguments!.arguments, hasLength(1));
  }

  void test_parseInstanceCreationExpression_type_typeArguments() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression =
        parseInstanceCreationExpression('A<B>()', token);
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword!.keyword, Keyword.NEW);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    NamedType type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments!.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseListLiteral_empty_oneToken() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    ListLiteral literal = parseListLiteral(token, null, '[]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword!.keyword, Keyword.CONST);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_oneToken_withComment() {
    ListLiteral literal = parseListLiteral(null, null, '/* 0 */ []');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    Token leftBracket = literal.leftBracket;
    expect(leftBracket, isNotNull);
    expect(leftBracket.precedingComments, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_twoTokens() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    ListLiteral literal = parseListLiteral(token, null, '[ ]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword!.keyword, Keyword.CONST);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_multiple() {
    ListLiteral literal = parseListLiteral(null, null, '[1, 2, 3]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(3));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_single() {
    ListLiteral literal = parseListLiteral(null, null, '[1]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_single_withTypeArgument() {
    ListLiteral literal = parseListLiteral(null, '<int>', '[1]');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_noType() {
    TypedLiteral literal = parseListOrMapLiteral(null, '[1]');
    expect(literal, isNotNull);
    assertNoErrors();
    var listLiteral = literal as ListLiteral;
    expect(listLiteral.constKeyword, isNull);
    expect(listLiteral.typeArguments, isNull);
    expect(listLiteral.leftBracket, isNotNull);
    expect(listLiteral.elements, hasLength(1));
    expect(listLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_type() {
    TypedLiteral literal = parseListOrMapLiteral(null, '<int> [1]');
    expect(literal, isNotNull);
    assertNoErrors();
    var listLiteral = literal as ListLiteral;
    expect(listLiteral.constKeyword, isNull);
    expect(listLiteral.typeArguments, isNotNull);
    expect(listLiteral.leftBracket, isNotNull);
    expect(listLiteral.elements, hasLength(1));
    expect(listLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_noType() {
    TypedLiteral literal = parseListOrMapLiteral(null, "{'1' : 1}");
    expect(literal, isNotNull);
    assertNoErrors();
    var mapLiteral = literal as SetOrMapLiteral;
    expect(mapLiteral.constKeyword, isNull);
    expect(mapLiteral.typeArguments, isNull);
    expect(mapLiteral.leftBracket, isNotNull);
    expect(mapLiteral.elements, hasLength(1));
    expect(mapLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_type() {
    TypedLiteral literal =
        parseListOrMapLiteral(null, "<String, int> {'1' : 1}");
    expect(literal, isNotNull);
    assertNoErrors();
    var mapLiteral = literal as SetOrMapLiteral;
    expect(mapLiteral.constKeyword, isNull);
    expect(mapLiteral.typeArguments, isNotNull);
    expect(mapLiteral.leftBracket, isNotNull);
    expect(mapLiteral.elements, hasLength(1));
    expect(mapLiteral.rightBracket, isNotNull);
  }

  void test_parseLogicalAndExpression() {
    Expression expression = parseLogicalAndExpression('x && y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND_AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseLogicalOrExpression() {
    Expression expression = parseLogicalOrExpression('x || y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR_BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseMapLiteral_empty() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    SetOrMapLiteral literal = parseMapLiteral(token, '<String, int>', '{}');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.constKeyword!.keyword, Keyword.CONST);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_multiple() {
    SetOrMapLiteral literal = parseMapLiteral(null, null, "{'a' : b, 'x' : y}");
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(2));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_multiple_trailing_comma() {
    SetOrMapLiteral literal =
        parseMapLiteral(null, null, "{'a' : b, 'x' : y,}");
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(2));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_single() {
    SetOrMapLiteral literal = parseMapLiteral(null, null, "{'x' : y}");
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteralEntry_complex() {
    MapLiteralEntry entry = parseMapLiteralEntry('2 + 2 : y');
    expect(entry, isNotNull);
    assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_int() {
    MapLiteralEntry entry = parseMapLiteralEntry('0 : y');
    expect(entry, isNotNull);
    assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_string() {
    MapLiteralEntry entry = parseMapLiteralEntry("'x' : y");
    expect(entry, isNotNull);
    assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMultiplicativeExpression_normal() {
    Expression expression = parseMultiplicativeExpression('x * y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.STAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseMultiplicativeExpression_super() {
    Expression expression = parseMultiplicativeExpression('super * y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isSuperExpression);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.STAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseNewExpression() {
    InstanceCreationExpression expression = parseNewExpression('new A()');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.keyword, isNotNull);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_decrement() {
    Expression expression = parsePostfixExpression('i--');
    expect(expression, isNotNull);
    assertNoErrors();
    var postfixExpression = expression as PostfixExpression;
    expect(postfixExpression.operand, isNotNull);
    expect(postfixExpression.operator, isNotNull);
    expect(postfixExpression.operator.type, TokenType.MINUS_MINUS);
  }

  void test_parsePostfixExpression_increment() {
    Expression expression = parsePostfixExpression('i++');
    expect(expression, isNotNull);
    assertNoErrors();
    var postfixExpression = expression as PostfixExpression;
    expect(postfixExpression.operand, isNotNull);
    expect(postfixExpression.operator, isNotNull);
    expect(postfixExpression.operator.type, TokenType.PLUS_PLUS);
  }

  void test_parsePostfixExpression_none_indexExpression() {
    Expression expression = parsePostfixExpression('a[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    var indexExpression = expression as IndexExpression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.index, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation() {
    Expression expression = parsePostfixExpression('a.m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator!.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation_question_dot() {
    Expression expression = parsePostfixExpression('a?.m()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator!.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArguments() {
    Expression expression = parsePostfixExpression('a?.m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator!.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation_typeArguments() {
    Expression expression = parsePostfixExpression('a.m<E>()');
    expect(expression, isNotNull);
    assertNoErrors();
    var methodInvocation = expression as MethodInvocation;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator!.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_propertyAccess() {
    Expression expression = parsePostfixExpression('a.b');
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as PrefixedIdentifier;
    expect(identifier.prefix, isNotNull);
    expect(identifier.identifier, isNotNull);
  }

  void test_parsePrefixedIdentifier_noPrefix() {
    String lexeme = "bar";
    Identifier identifier = parsePrefixedIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    var simpleIdentifier = identifier as SimpleIdentifier;
    expect(simpleIdentifier.token, isNotNull);
    expect(simpleIdentifier.name, lexeme);
  }

  void test_parsePrefixedIdentifier_prefix() {
    String lexeme = "foo.bar";
    Identifier identifier = parsePrefixedIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    var prefixedIdentifier = identifier as PrefixedIdentifier;
    expect(prefixedIdentifier.prefix.name, "foo");
    expect(prefixedIdentifier.period, isNotNull);
    expect(prefixedIdentifier.identifier.name, "bar");
  }

  void test_parsePrimaryExpression_const() {
    Expression expression = parsePrimaryExpression('const A()');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isNotNull);
  }

  void test_parsePrimaryExpression_double() {
    String doubleLiteral = "3.2e4";
    Expression expression = parsePrimaryExpression(doubleLiteral);
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as DoubleLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, double.parse(doubleLiteral));
  }

  void test_parsePrimaryExpression_false() {
    Expression expression = parsePrimaryExpression('false');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as BooleanLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, isFalse);
  }

  void test_parsePrimaryExpression_function_arguments() {
    Expression expression = parsePrimaryExpression('(int i) => i + 1');
    expect(expression, isNotNull);
    assertNoErrors();
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
  }

  void test_parsePrimaryExpression_function_noArguments() {
    Expression expression = parsePrimaryExpression('() => 42');
    expect(expression, isNotNull);
    assertNoErrors();
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
  }

  void test_parsePrimaryExpression_genericFunctionExpression() {
    Expression expression =
        parsePrimaryExpression('<X, Y>(Map<X, Y> m, X x) => m[x]');
    expect(expression, isNotNull);
    assertNoErrors();
    var functionExpression = expression as FunctionExpression;
    expect(functionExpression.typeParameters, isNotNull);
  }

  void test_parsePrimaryExpression_hex() {
    String hexLiteral = "3F";
    Expression expression = parsePrimaryExpression('0x$hexLiteral');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as IntegerLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(hexLiteral, radix: 16));
  }

  void test_parsePrimaryExpression_identifier() {
    Expression expression = parsePrimaryExpression('a');
    expect(expression, isNotNull);
    assertNoErrors();
    var identifier = expression as SimpleIdentifier;
    expect(identifier, isNotNull);
  }

  void test_parsePrimaryExpression_int() {
    String intLiteral = "472";
    Expression expression = parsePrimaryExpression(intLiteral);
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as IntegerLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(intLiteral));
  }

  void test_parsePrimaryExpression_listLiteral() {
    Expression expression = parsePrimaryExpression('[ ]');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_index() {
    Expression expression = parsePrimaryExpression('[]');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_typed() {
    Expression expression = parsePrimaryExpression('<A>[ ]');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as ListLiteral;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments!.arguments, hasLength(1));
  }

  void test_parsePrimaryExpression_mapLiteral() {
    Expression expression = parsePrimaryExpression('{}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.typeArguments, isNull);
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_mapLiteral_typed() {
    Expression expression = parsePrimaryExpression('<A, B>{}');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SetOrMapLiteral;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments!.arguments, hasLength(2));
  }

  void test_parsePrimaryExpression_new() {
    Expression expression = parsePrimaryExpression('new A()');
    expect(expression, isNotNull);
    assertNoErrors();
    var creation = expression as InstanceCreationExpression;
    expect(creation, isNotNull);
  }

  void test_parsePrimaryExpression_null() {
    Expression expression = parsePrimaryExpression('null');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isNullLiteral);
    var literal = expression as NullLiteral;
    expect(literal.literal, isNotNull);
  }

  void test_parsePrimaryExpression_parenthesized() {
    Expression expression = parsePrimaryExpression('(x)');
    expect(expression, isNotNull);
    assertNoErrors();
    var parens = expression as ParenthesizedExpression;
    expect(parens, isNotNull);
  }

  void test_parsePrimaryExpression_string() {
    Expression expression = parsePrimaryExpression('"string"');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_multiline() {
    Expression expression = parsePrimaryExpression("'''string'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.isMultiline, isTrue);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_raw() {
    Expression expression = parsePrimaryExpression("r'string'");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isTrue);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_super() {
    Expression expression = parseExpression('super.x');
    expect(expression, isNotNull);
    assertNoErrors();
    var propertyAccess = expression as PropertyAccess;
    expect(propertyAccess.target is SuperExpression, isTrue);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parsePrimaryExpression_this() {
    Expression expression = parsePrimaryExpression('this');
    expect(expression, isNotNull);
    assertNoErrors();
    var thisExpression = expression as ThisExpression;
    expect(thisExpression.thisKeyword, isNotNull);
  }

  void test_parsePrimaryExpression_true() {
    Expression expression = parsePrimaryExpression('true');
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as BooleanLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, isTrue);
  }

  void test_parseRedirectingConstructorInvocation_named() {
    var invocation = parseConstructorInitializer('this.a()')
        as RedirectingConstructorInvocation;
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.thisKeyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseRedirectingConstructorInvocation_unnamed() {
    var invocation = parseConstructorInitializer('this()')
        as RedirectingConstructorInvocation;
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.thisKeyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseRelationalExpression_as_chained() {
    var asExpression = parseExpression('x as Y as Z',
            errors: [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 2)])
        as AsExpression;
    expect(asExpression, isNotNull);
    var identifier = asExpression.expression as SimpleIdentifier;
    expect(identifier.name, 'x');
    expect(asExpression.asOperator, isNotNull);
    var namedType = asExpression.type as NamedType;
    expect(namedType.name.name, 'Y');
  }

  void test_parseRelationalExpression_as_functionType_noReturnType() {
    Expression expression = parseRelationalExpression('x as Function(int)');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isGenericFunctionType);
  }

  void test_parseRelationalExpression_as_functionType_returnType() {
    Expression expression =
        parseRelationalExpression('x as String Function(int)');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isGenericFunctionType);
  }

  void test_parseRelationalExpression_as_generic() {
    Expression expression = parseRelationalExpression('x as C<D>');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isNamedType);
  }

  void test_parseRelationalExpression_as_simple() {
    Expression expression = parseRelationalExpression('x as Y');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isNamedType);
  }

  void test_parseRelationalExpression_as_simple_function() {
    Expression expression = parseRelationalExpression('x as Function');
    expect(expression, isNotNull);
    assertNoErrors();
    var asExpression = expression as AsExpression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isNamedType);
  }

  void test_parseRelationalExpression_is() {
    Expression expression = parseRelationalExpression('x is y');
    expect(expression, isNotNull);
    assertNoErrors();
    var isExpression = expression as IsExpression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_is_chained() {
    var isExpression = parseExpression('x is Y is! Z',
            errors: [expectedError(ParserErrorCode.UNEXPECTED_TOKEN, 7, 2)])
        as IsExpression;
    expect(isExpression, isNotNull);
    var identifier = isExpression.expression as SimpleIdentifier;
    expect(identifier.name, 'x');
    expect(isExpression.isOperator, isNotNull);
    var namedType = isExpression.type as NamedType;
    expect(namedType.name.name, 'Y');
  }

  void test_parseRelationalExpression_isNot() {
    Expression expression = parseRelationalExpression('x is! y');
    expect(expression, isNotNull);
    assertNoErrors();
    var isExpression = expression as IsExpression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNotNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_normal() {
    Expression expression = parseRelationalExpression('x < y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.LT);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseRelationalExpression_super() {
    Expression expression = parseRelationalExpression('super < y');
    expect(expression, isNotNull);
    assertNoErrors();
    var binaryExpression = expression as BinaryExpression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.LT);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseRethrowExpression() {
    RethrowExpression expression = parseRethrowExpression('rethrow');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.rethrowKeyword, isNotNull);
  }

  void test_parseShiftExpression_normal() {
    BinaryExpression expression = parseShiftExpression('x << y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseShiftExpression_super() {
    BinaryExpression expression = parseShiftExpression('super << y');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseSimpleIdentifier1_normalIdentifier() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseSimpleIdentifier_builtInIdentifier() {
    String lexeme = "as";
    SimpleIdentifier identifier = parseSimpleIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseSimpleIdentifier_normalIdentifier() {
    String lexeme = "foo";
    SimpleIdentifier identifier = parseSimpleIdentifier(lexeme);
    expect(identifier, isNotNull);
    assertNoErrors();
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseStringLiteral_adjacent() {
    Expression expression = parseStringLiteral("'a' 'b'");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as AdjacentStrings;
    NodeList<StringLiteral> strings = literal.strings;
    expect(strings, hasLength(2));
    StringLiteral firstString = strings[0];
    StringLiteral secondString = strings[1];
    expect((firstString as SimpleStringLiteral).value, "a");
    expect((secondString as SimpleStringLiteral).value, "b");
  }

  void test_parseStringLiteral_endsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'x$y'");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, 'x');
    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.leftBracket.lexeme, '\$');
    expect(element1.expression, isSimpleIdentifier);
    expect(element1.rightBracket, isNull);
    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, '');
  }

  void test_parseStringLiteral_interpolated() {
    Expression expression = parseStringLiteral("'a \${b} c \$this d'");
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression, isStringInterpolation);
    var literal = expression as StringInterpolation;
    NodeList<InterpolationElement> elements = literal.elements;
    expect(elements, hasLength(5));
    expect(elements[0] is InterpolationString, isTrue);
    expect(elements[1] is InterpolationExpression, isTrue);
    expect(elements[2] is InterpolationString, isTrue);
    expect(elements[3] is InterpolationExpression, isTrue);
    expect(elements[4] is InterpolationString, isTrue);
    expect((elements[1] as InterpolationExpression).leftBracket.lexeme, '\${');
    expect((elements[1] as InterpolationExpression).rightBracket!.lexeme, '}');
    expect((elements[3] as InterpolationExpression).leftBracket.lexeme, '\$');
    expect((elements[3] as InterpolationExpression).rightBracket, isNull);
  }

  void test_parseStringLiteral_interpolated_void() {
    Expression expression = parseStringLiteral(r"'<html>$void</html>'");
    expect(expression, isNotNull);
    assertErrors(errors: [
      expectedError(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 8, 4)
    ]);
    expect(expression, isStringInterpolation);
    var literal = expression as StringInterpolation;
    NodeList<InterpolationElement> elements = literal.elements;
    expect(elements, hasLength(3));
    expect(elements[0] is InterpolationString, isTrue);
    expect(elements[1] is InterpolationExpression, isTrue);
    expect(elements[2] is InterpolationString, isTrue);
    expect((elements[1] as InterpolationExpression).leftBracket.lexeme, '\$');
    expect((elements[1] as InterpolationExpression).rightBracket, isNull);
  }

  void test_parseStringLiteral_multiline_encodedSpace() {
    Expression expression = parseStringLiteral("'''\\x20\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, " \na");
  }

  void test_parseStringLiteral_multiline_endsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'''x$y'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, 'x');
    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, '');
  }

  void test_parseStringLiteral_multiline_escapedBackslash() {
    Expression expression = parseStringLiteral("'''\\\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\\na");
  }

  void test_parseStringLiteral_multiline_escapedBackslash_raw() {
    Expression expression = parseStringLiteral("r'''\\\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\\\\na");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker() {
    Expression expression = parseStringLiteral("'''\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker_raw() {
    Expression expression = parseStringLiteral("r'''\\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker() {
    Expression expression = parseStringLiteral("'''\\ \\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker_raw() {
    Expression expression = parseStringLiteral("r'''\\ \\\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedTab() {
    Expression expression = parseStringLiteral("'''\\t\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\t\na");
  }

  void test_parseStringLiteral_multiline_escapedTab_raw() {
    Expression expression = parseStringLiteral("r'''\\t\na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\t\na");
  }

  void test_parseStringLiteral_multiline_quoteAfterInterpolation() {
    Expression expression = parseStringLiteral(r"""'''$x'y'''""");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, "'y");
  }

  void test_parseStringLiteral_multiline_startsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'''${x}y'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, 'y');
  }

  void test_parseStringLiteral_multiline_twoSpaces() {
    Expression expression = parseStringLiteral("'''  \na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_twoSpaces_raw() {
    Expression expression = parseStringLiteral("r'''  \na'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_untrimmed() {
    Expression expression = parseStringLiteral("''' a\nb'''");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, " a\nb");
  }

  void test_parseStringLiteral_quoteAfterInterpolation() {
    Expression expression = parseStringLiteral(r"""'$x"'""");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, '"');
  }

  void test_parseStringLiteral_single() {
    Expression expression = parseStringLiteral("'a'");
    expect(expression, isNotNull);
    assertNoErrors();
    var literal = expression as SimpleStringLiteral;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_startsWithInterpolation() {
    Expression expression = parseStringLiteral(r"'${x}y'");
    expect(expression, isNotNull);
    assertNoErrors();
    var interpolation = expression as StringInterpolation;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], isInterpolationString);
    var element0 = interpolation.elements[0] as InterpolationString;
    expect(element0.value, '');
    expect(interpolation.elements[1], isInterpolationExpression);
    var element1 = interpolation.elements[1] as InterpolationExpression;
    expect(element1.expression, isSimpleIdentifier);
    expect(interpolation.elements[2], isInterpolationString);
    var element2 = interpolation.elements[2] as InterpolationString;
    expect(element2.value, 'y');
  }

  void test_parseSuperConstructorInvocation_named() {
    var invocation =
        parseConstructorInitializer('super.a()') as SuperConstructorInvocation;
    expect(invocation, isNotNull);
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.superKeyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseSuperConstructorInvocation_unnamed() {
    var invocation =
        parseConstructorInitializer('super()') as SuperConstructorInvocation;
    assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.superKeyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseSymbolLiteral_builtInIdentifier() {
    SymbolLiteral literal = parseSymbolLiteral('#dynamic.static.abstract');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "dynamic");
    expect(components[1].lexeme, "static");
    expect(components[2].lexeme, "abstract");
  }

  void test_parseSymbolLiteral_multiple() {
    SymbolLiteral literal = parseSymbolLiteral('#a.b.c');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "a");
    expect(components[1].lexeme, "b");
    expect(components[2].lexeme, "c");
  }

  void test_parseSymbolLiteral_operator() {
    SymbolLiteral literal = parseSymbolLiteral('#==');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "==");
  }

  void test_parseSymbolLiteral_single() {
    SymbolLiteral literal = parseSymbolLiteral('#a');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "a");
  }

  void test_parseSymbolLiteral_void() {
    SymbolLiteral literal = parseSymbolLiteral('#void');
    expect(literal, isNotNull);
    assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "void");
  }

  void test_parseThrowExpression() {
    Expression expression = parseThrowExpression('throw x');
    expect(expression, isNotNull);
    assertNoErrors();
    var throwExpression = expression as ThrowExpression;
    expect(throwExpression.throwKeyword, isNotNull);
    expect(throwExpression.expression, isNotNull);
  }

  void test_parseThrowExpressionWithoutCascade() {
    Expression expression = parseThrowExpressionWithoutCascade('throw x');
    expect(expression, isNotNull);
    assertNoErrors();
    var throwExpression = expression as ThrowExpression;
    expect(throwExpression.throwKeyword, isNotNull);
    expect(throwExpression.expression, isNotNull);
  }

  void test_parseUnaryExpression_decrement_identifier_index() {
    var expression = parseExpression('--a[0]') as PrefixExpression;
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_decrement_normal() {
    PrefixExpression expression = parseUnaryExpression('--x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    // TODO(danrubel) Reports a different error and different token stream.
    // Expected: TokenType:<MINUS>
    //   Actual: TokenType:<MINUS_MINUS>
    PrefixExpression expression = parseUnaryExpression('--super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    Expression innerExpression = expression.operand;
    expect(innerExpression, isNotNull);
    expect(innerExpression is PrefixExpression, isTrue);
    PrefixExpression operand = innerExpression as PrefixExpression;
    expect(operand.operator, isNotNull);
    expect(operand.operator.type, TokenType.MINUS);
    expect(operand.operand, isNotNull);
  }

  void test_parseUnaryExpression_decrement_super_propertyAccess() {
    PrefixExpression expression = parseUnaryExpression('--super.x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    // TODO(danrubel) Reports a different error and different token stream.
    // Expected: TokenType:<MINUS>
    //   Actual: TokenType:<MINUS_MINUS>

    PrefixExpression expression = parseUnaryExpression('/* 0 */ --super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operator.precedingComments, isNotNull);
    Expression innerExpression = expression.operand;
    expect(innerExpression, isNotNull);
    expect(innerExpression is PrefixExpression, isTrue);
    PrefixExpression operand = innerExpression as PrefixExpression;
    expect(operand.operator, isNotNull);
    expect(operand.operator.type, TokenType.MINUS);
    expect(operand.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_identifier_index() {
    var expression = parseExpression('++a[0]') as PrefixExpression;
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_increment_normal() {
    PrefixExpression expression = parseUnaryExpression('++x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_super_index() {
    PrefixExpression expression = parseUnaryExpression('++super[0]');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget is SuperExpression, isTrue);
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_increment_super_propertyAccess() {
    PrefixExpression expression = parseUnaryExpression('++super.x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_minus_identifier_index() {
    var expression = parseExpression('-a[0]') as PrefixExpression;
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_minus_normal() {
    PrefixExpression expression = parseUnaryExpression('-x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_minus_super() {
    PrefixExpression expression = parseUnaryExpression('-super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_normal() {
    PrefixExpression expression = parseUnaryExpression('!x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_super() {
    PrefixExpression expression = parseUnaryExpression('!super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_normal() {
    PrefixExpression expression = parseUnaryExpression('~x');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_super() {
    PrefixExpression expression = parseUnaryExpression('~super');
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilde_identifier_index() {
    var expression = parseExpression('~a[0]') as PrefixExpression;
    expect(expression, isNotNull);
    assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget, const TypeMatcher<SimpleIdentifier>());
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_setLiteral() {
    var set = parseExpression('{3}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(1));
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);
  }

  void test_setLiteral_const() {
    var set = parseExpression('const {3, 6}') as SetOrMapLiteral;
    expect(set.constKeyword, isNotNull);
    expect(set.typeArguments, isNull);
    expect(set.elements, hasLength(2));
    var value1 = set.elements[0] as IntegerLiteral;
    expect(value1.value, 3);
    var value2 = set.elements[1] as IntegerLiteral;
    expect(value2.value, 6);
  }

  void test_setLiteral_const_typed() {
    var set = parseExpression('const <int>{3}') as SetOrMapLiteral;
    expect(set.constKeyword, isNotNull);
    expect(set.typeArguments!.arguments, hasLength(1));
    var typeArg = set.typeArguments!.arguments[0] as NamedType;
    expect(typeArg.name.name, 'int');
    expect(set.elements.length, 1);
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);
  }

  void test_setLiteral_nested_typeArgument() {
    var set = parseExpression('<Set<int>>{{3}}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments!.arguments, hasLength(1));
    var typeArg1 = set.typeArguments!.arguments[0] as NamedType;
    expect(typeArg1.name.name, 'Set');
    expect(typeArg1.typeArguments!.arguments, hasLength(1));
    var typeArg2 = typeArg1.typeArguments!.arguments[0] as NamedType;
    expect(typeArg2.name.name, 'int');
    expect(set.elements.length, 1);
    var intSet = set.elements[0] as SetOrMapLiteral;
    expect(intSet.elements, hasLength(1));
    var value = intSet.elements[0] as IntegerLiteral;
    expect(value.value, 3);
  }

  void test_setLiteral_typed() {
    var set = parseExpression('<int>{3}') as SetOrMapLiteral;
    expect(set.constKeyword, isNull);
    expect(set.typeArguments!.arguments, hasLength(1));
    var typeArg = set.typeArguments!.arguments[0] as NamedType;
    expect(typeArg.name.name, 'int');
    expect(set.elements.length, 1);
    var value = set.elements[0] as IntegerLiteral;
    expect(value.value, 3);
  }
}

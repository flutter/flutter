// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/feature_sets.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionReferenceParserTest);
  });
}

/// Tests exercising the fasta parser's handling of generic instantiations.
@reflectiveTest
class FunctionReferenceParserTest extends FastaParserTestCase {
  /// Verifies that the given [node] matches `f<a, b>`.
  void expect_f_a_b(AstNode node) {
    var functionReference = node as FunctionReference;
    expect((functionReference.function as SimpleIdentifier).name, 'f');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void expect_two_args(MethodInvocation methodInvocation) {
    var arguments = methodInvocation.argumentList.arguments;
    expect(arguments, hasLength(2));
    expect(arguments[0], TypeMatcher<BinaryExpression>());
    expect(arguments[1], TypeMatcher<BinaryExpression>());
  }

  void test_feature_disabled() {
    expect_f_a_b(
        (parseStatement('f<a, b>;', featureSet: FeatureSets.language_2_13)
                as ExpressionStatement)
            .expression);
    listener.assertErrors([
      expectedError(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 1, 6),
    ]);
  }

  void test_followingToken_accepted_closeBrace() {
    expect_f_a_b((parseExpression('{f<a, b>}') as SetOrMapLiteral).elements[0]);
  }

  void test_followingToken_accepted_closeBracket() {
    expect_f_a_b((parseExpression('[f<a, b>]') as ListLiteral).elements[0]);
  }

  void test_followingToken_accepted_closeParen() {
    expect_f_a_b((parseExpression('g(f<a, b>)') as MethodInvocation)
        .argumentList
        .arguments[0]);
  }

  void test_followingToken_accepted_colon() {
    expect_f_a_b(((parseExpression('{f<a, b>: null}') as SetOrMapLiteral)
            .elements[0] as MapLiteralEntry)
        .key);
  }

  void test_followingToken_accepted_comma() {
    expect_f_a_b(
        (parseExpression('[f<a, b>, null]') as ListLiteral).elements[0]);
  }

  void test_followingToken_accepted_equals() {
    expect_f_a_b(
        (parseExpression('f<a, b> == null') as BinaryExpression).leftOperand);
  }

  void test_followingToken_accepted_not_equals() {
    expect_f_a_b(
        (parseExpression('f<a, b> != null') as BinaryExpression).leftOperand);
  }

  void test_followingToken_accepted_openParen() {
    // This is a special case because when a `(` follows `<typeArguments>` it is
    // parsed as a MethodInvocation rather than a GenericInstantiation.
    var methodInvocation = parseExpression('f<a, b>()') as MethodInvocation;
    expect(methodInvocation.methodName.name, 'f');
    var typeArgs = methodInvocation.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
    expect(methodInvocation.argumentList.arguments, isEmpty);
  }

  void test_followingToken_accepted_period_methodInvocation() {
    // This is a special case because `f<a, b>.methodName(...)` is parsed as an
    // InstanceCreationExpression.
    var instanceCreationExpression =
        parseExpression('f<a, b>.toString()') as InstanceCreationExpression;
    var constructorName = instanceCreationExpression.constructorName;
    var type = constructorName.type;
    expect((type.name as SimpleIdentifier).name, 'f');
    var typeArgs = type.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
    expect(constructorName.name!.name, 'toString');
    expect(instanceCreationExpression.argumentList.arguments, isEmpty);
  }

  void test_followingToken_accepted_period_methodInvocation_generic() {
    expect_f_a_b(
        (parseExpression('f<a, b>.foo<c>()') as MethodInvocation).target!);
  }

  void test_followingToken_accepted_period_propertyAccess() {
    expect_f_a_b(
        (parseExpression('f<a, b>.hashCode') as PropertyAccess).target!);
  }

  void test_followingToken_accepted_semicolon() {
    expect_f_a_b(
        (parseStatement('f<a, b>;') as ExpressionStatement).expression);
    listener.assertNoErrors();
  }

  void test_followingToken_rejected_ampersand() {
    expect_two_args(parseExpression('f(a<b,c>&d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_as() {
    expect_two_args(parseExpression('f(a<b,c>as)') as MethodInvocation);
  }

  void test_followingToken_rejected_asterisk() {
    expect_two_args(parseExpression('f(a<b,c>*d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_bang_openBracket() {
    expect_two_args(parseExpression('f(a<b,c>![d])') as MethodInvocation);
  }

  void test_followingToken_rejected_bang_paren() {
    expect_two_args(parseExpression('f(a<b,c>!(d))') as MethodInvocation);
  }

  void test_followingToken_rejected_bar() {
    expect_two_args(parseExpression('f(a<b,c>|d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_caret() {
    expect_two_args(parseExpression('f(a<b,c>^d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_is() {
    var methodInvocation = parseExpression('f(a<b,c> is int)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 2),
    ]) as MethodInvocation;
    var arguments = methodInvocation.argumentList.arguments;
    expect(arguments, hasLength(2));
    expect(arguments[0], TypeMatcher<BinaryExpression>());
    expect(arguments[1], TypeMatcher<IsExpression>());
  }

  void test_followingToken_rejected_lessThan() {
    // Note: in principle we could parse this as a generic instantiation of a
    // generic instantiation, but such an expression would be meaningless so we
    // reject it at the parser level.
    parseExpression('f<a><b>', errors: [
      expectedError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 3, 1),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 7, 0),
    ]);
  }

  void test_followingToken_rejected_minus() {
    expect_two_args(parseExpression('f(a<b,c>-d)') as MethodInvocation);
  }

  void test_followingToken_rejected_openBracket() {
    expect_two_args(parseExpression('f(a<b,c>[d])') as MethodInvocation);
  }

  void test_followingToken_rejected_openBracket_error() {
    // Note that theoretically this could be successfully parsed by interpreting
    // `<` and `>` as delimiting type arguments, but the parser doesn't have
    // enough lookahead to see that this is the only possible error-free parse;
    // it commits to interpreting `<` and `>` as operators when it sees the `[`.
    expect_two_args(parseExpression('f(a<b,c>[d]>e)', errors: [
      expectedError(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, 11, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_openBracket_unambiguous() {
    expect_two_args(parseExpression('f(a<b,c>[d, e])') as MethodInvocation);
  }

  void test_followingToken_rejected_percent() {
    expect_two_args(parseExpression('f(a<b,c>%d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_period_period() {
    var methodInvocation = parseExpression('f(a<b,c>..toString())', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 2),
    ]) as MethodInvocation;
    var arguments = methodInvocation.argumentList.arguments;
    expect(arguments, hasLength(2));
    expect(arguments[0], TypeMatcher<BinaryExpression>());
    expect(arguments[1], TypeMatcher<CascadeExpression>());
  }

  void test_followingToken_rejected_plus() {
    expect_two_args(parseExpression('f(a<b,c>+d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_question() {
    var methodInvocation = parseExpression('f(a<b,c> ? null : null)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 1),
    ]) as MethodInvocation;
    var arguments = methodInvocation.argumentList.arguments;
    expect(arguments, hasLength(2));
    expect(arguments[0], TypeMatcher<BinaryExpression>());
    expect(arguments[1], TypeMatcher<ConditionalExpression>());
  }

  void test_followingToken_rejected_question_period_methodInvocation() {
    expect_two_args(parseExpression('f(a<b,c>?.toString())', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 2),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_question_period_methodInvocation_generic() {
    expect_two_args(parseExpression('f(a<b,c>?.foo<c>())', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 2),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_question_period_period() {
    var methodInvocation = parseExpression('f(a<b,c>?..toString())', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 3),
      expectedError(ParserErrorCode.EXPECTED_TOKEN, 11, 8),
    ]) as MethodInvocation;
    var arguments = methodInvocation.argumentList.arguments;
    expect(arguments, hasLength(3));
    expect(arguments[0], TypeMatcher<BinaryExpression>());
    expect(arguments[1], TypeMatcher<BinaryExpression>());
    expect(arguments[2], TypeMatcher<MethodInvocation>());
  }

  void test_followingToken_rejected_question_period_propertyAccess() {
    expect_two_args(parseExpression('f(a<b,c>?.hashCode)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 2),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_question_question() {
    expect_two_args(parseExpression('f(a<b,c> ?? d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 9, 2),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_slash() {
    expect_two_args(parseExpression('f(a<b,c>/d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 1),
    ]) as MethodInvocation);
  }

  void test_followingToken_rejected_tilde_slash() {
    expect_two_args(parseExpression('f(a<b,c>~/d)', errors: [
      expectedError(ParserErrorCode.MISSING_IDENTIFIER, 8, 2),
    ]) as MethodInvocation);
  }

  void test_functionReference_after_indexExpression() {
    // Note: this is not legal Dart, but it's important that we do error
    // recovery and don't crash the parser.
    var functionReference = parseExpression('x[0]<a, b>') as FunctionReference;
    expect(functionReference.function, TypeMatcher<IndexExpression>());
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_functionReference_after_indexExpression_bang() {
    // Note: this is not legal Dart, but it's important that we do error
    // recovery and don't crash the parser.
    var functionReference = parseExpression('x[0]!<a, b>') as FunctionReference;
    expect(functionReference.function, TypeMatcher<PostfixExpression>());
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_functionReference_after_indexExpression_functionCall() {
    // Note: this is not legal Dart, but it's important that we do error
    // recovery and don't crash the parser.
    var functionReference =
        parseExpression('x[0]()<a, b>') as FunctionReference;
    expect(functionReference.function,
        TypeMatcher<FunctionExpressionInvocation>());
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_functionReference_after_indexExpression_nullAware() {
    // Note: this is not legal Dart, but it's important that we do error
    // recovery and don't crash the parser.
    var functionReference = parseExpression('x?[0]<a, b>') as FunctionReference;
    expect(functionReference.function, TypeMatcher<IndexExpression>());
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_methodTearoff() {
    var functionReference = parseExpression('f().m<a, b>') as FunctionReference;
    var function = functionReference.function as PropertyAccess;
    var target = function.target as MethodInvocation;
    expect(target.methodName.name, 'f');
    expect(function.propertyName.name, 'm');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_methodTearoff_cascaded() {
    var cascadeExpression =
        parseExpression('f()..m<a, b>') as CascadeExpression;
    var functionReference =
        cascadeExpression.cascadeSections[0] as FunctionReference;
    var function = functionReference.function as PropertyAccess;
    expect(function.target, isNull);
    expect(function.propertyName.name, 'm');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_prefixedIdentifier() {
    var functionReference =
        parseExpression('prefix.f<a, b>') as FunctionReference;
    var function = functionReference.function as PrefixedIdentifier;
    expect(function.prefix.name, 'prefix');
    expect(function.identifier.name, 'f');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }

  void test_three_identifiers() {
    var functionReference =
        parseExpression('prefix.ClassName.m<a, b>') as FunctionReference;
    var function = functionReference.function as PropertyAccess;
    var target = function.target as PrefixedIdentifier;
    expect(target.prefix.name, 'prefix');
    expect(target.identifier.name, 'ClassName');
    expect(function.propertyName.name, 'm');
    var typeArgs = functionReference.typeArguments!.arguments;
    expect(typeArgs, hasLength(2));
    expect(((typeArgs[0] as NamedType).name as SimpleIdentifier).name, 'a');
    expect(((typeArgs[1] as NamedType).name as SimpleIdentifier).name, 'b');
  }
}

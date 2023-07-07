// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';

/// Parenthesize the target of the [expressionStatement]'s expression (assumed
/// to [cascadeExpression]) before removing the cascade.
ExpressionStatement fixCascadeByParenthesizingTarget({
  required ExpressionStatement expressionStatement,
  required CascadeExpression cascadeExpression,
}) {
  assert(cascadeExpression.cascadeSections.length == 1);

  var newTarget = astFactory.parenthesizedExpression(
    Token(TokenType.OPEN_PAREN, 0)
      ..previous = expressionStatement.beginToken.previous
      ..next = cascadeExpression.target.beginToken,
    cascadeExpression.target,
    Token(TokenType.CLOSE_PAREN, 0)
      ..previous = cascadeExpression.target.endToken
      ..next = expressionStatement.semicolon,
  );

  return astFactory.expressionStatement(
    astFactory.cascadeExpression(
      newTarget,
      cascadeExpression.cascadeSections,
    ),
    expressionStatement.semicolon,
  );
}

/// Recursively insert [cascadeTarget] (the LHS of the cascade) into the
/// LHS of the assignment expression that used to be the cascade's RHS.
Expression insertCascadeTargetIntoExpression({
  required Expression expression,
  required Expression cascadeTarget,
}) {
  // Base case: We've recursed as deep as possible.
  if (expression == cascadeTarget) return cascadeTarget;

  // Otherwise, copy `expression` and recurse into its LHS.
  if (expression is AssignmentExpression) {
    return AssignmentExpressionImpl(
      leftHandSide: insertCascadeTargetIntoExpression(
        expression: expression.leftHandSide,
        cascadeTarget: cascadeTarget,
      ) as ExpressionImpl,
      operator: expression.operator,
      rightHandSide: expression.rightHandSide as ExpressionImpl,
    );
  } else if (expression is IndexExpression) {
    var expressionTarget = expression.realTarget;
    var question = expression.question;

    // A null-aware cascade treats the `?` in `?..` as part of the token, but
    // for a non-cascade index, it is a separate `?` token.
    if (expression.period?.type == TokenType.QUESTION_PERIOD_PERIOD) {
      question = _synthesizeToken(TokenType.QUESTION, expression.period!);
    }

    return astFactory.indexExpressionForTarget2(
      target: insertCascadeTargetIntoExpression(
        expression: expressionTarget,
        cascadeTarget: cascadeTarget,
      ),
      question: question,
      leftBracket: expression.leftBracket,
      index: expression.index,
      rightBracket: expression.rightBracket,
    );
  } else if (expression is MethodInvocation) {
    var expressionTarget = expression.realTarget!;
    return astFactory.methodInvocation(
      insertCascadeTargetIntoExpression(
        expression: expressionTarget,
        cascadeTarget: cascadeTarget,
      ),
      // If we've reached the end, replace the `..` operator with `.`
      expressionTarget == cascadeTarget
          ? _synthesizeToken(TokenType.PERIOD, expression.operator!)
          : expression.operator,
      expression.methodName,
      expression.typeArguments,
      expression.argumentList,
    );
  } else if (expression is PropertyAccess) {
    var expressionTarget = expression.realTarget;
    return astFactory.propertyAccess(
      insertCascadeTargetIntoExpression(
        expression: expressionTarget,
        cascadeTarget: cascadeTarget,
      ),
      // If we've reached the end, replace the `..` operator with `.`
      expressionTarget == cascadeTarget
          ? _synthesizeToken(TokenType.PERIOD, expression.operator)
          : expression.operator,
      expression.propertyName,
    );
  }
  throw UnimplementedError('Unhandled ${expression.runtimeType}'
      '($expression)');
}

/// Synthesize a token with [type] to replace the given [operator].
///
/// Offset, comments, and previous/next links are all preserved.
Token _synthesizeToken(TokenType type, Token operator) =>
    Token(type, operator.offset, operator.precedingComments)
      ..previous = operator.previous
      ..next = operator.next;

// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of code_builder.src.specs.expression;

/// Represents two expressions ([left] and [right]) and an [operator].
class BinaryExpression extends Expression {
  final Expression left;
  final Expression right;
  final String operator;
  final bool addSpace;
  final bool isConst;

  const BinaryExpression._(
    this.left,
    this.right,
    this.operator, {
    this.addSpace = true,
    this.isConst = false,
  });

  @override
  R accept<R>(ExpressionVisitor<R> visitor, [R context]) =>
      visitor.visitBinaryExpression(this, context);
}

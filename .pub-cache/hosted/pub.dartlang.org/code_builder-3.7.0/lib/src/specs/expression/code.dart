// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of code_builder.src.specs.expression;

/// Represents a [Code] block as an [Expression].
class CodeExpression extends Expression {
  @override
  final Code code;

  /// **INTERNAL ONLY**: Used to wrap [Code] as an [Expression].
  const CodeExpression(this.code);

  @override
  R accept<R>(ExpressionVisitor<R> visitor, [R context]) =>
      visitor.visitCodeExpression(this, context);
}

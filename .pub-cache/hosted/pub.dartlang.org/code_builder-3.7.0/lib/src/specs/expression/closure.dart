// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of code_builder.src.specs.expression;

/// Returns [method] as closure, removing its return type and type parameters.
Expression toClosure(Method method) {
  final withoutTypes = method.rebuild((b) {
    b.returns = null;
    b.types.clear();
  });
  return ClosureExpression._(withoutTypes);
}

/// Returns [method] as a (possibly) generic closure, removing its return type.
Expression toGenericClosure(Method method) {
  final withoutReturnType = method.rebuild((b) {
    b.returns = null;
  });
  return ClosureExpression._(withoutReturnType);
}

class ClosureExpression extends Expression {
  final Method method;

  const ClosureExpression._(this.method);

  @override
  R accept<R>(ExpressionVisitor<R> visitor, [R context]) =>
      visitor.visitClosureExpression(this, context);
}

// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ast.dart';
import 'visitor.dart';

/// A visitor for evaluating boolean selectors against a specific set of
/// semantics.
class Evaluator implements Visitor<bool> {
  final bool Function(String variable) _semantics;

  Evaluator(this._semantics);

  @override
  bool visitVariable(VariableNode node) => _semantics(node.name);

  @override
  bool visitNot(NotNode node) => !node.child.accept(this);

  @override
  bool visitOr(OrNode node) =>
      node.left.accept(this) || node.right.accept(this);

  @override
  bool visitAnd(AndNode node) =>
      node.left.accept(this) && node.right.accept(this);

  @override
  bool visitConditional(ConditionalNode node) => node.condition.accept(this)
      ? node.whenTrue.accept(this)
      : node.whenFalse.accept(this);
}

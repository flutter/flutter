// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'ast.dart';

/// The interface for visitors of the boolean selector AST.
abstract class Visitor<T> {
  T visitVariable(VariableNode node);
  T visitNot(NotNode node);
  T visitOr(OrNode node);
  T visitAnd(AndNode node);
  T visitConditional(ConditionalNode node);
}

/// An abstract superclass for side-effect-based visitors.
///
/// The default implementations of this visitor's methods just traverse the AST
/// and do nothing with it.
abstract class RecursiveVisitor implements Visitor<void> {
  const RecursiveVisitor();

  @override
  void visitVariable(VariableNode node) {}

  @override
  void visitNot(NotNode node) {
    node.child.accept(this);
  }

  @override
  void visitOr(OrNode node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitAnd(AndNode node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitConditional(ConditionalNode node) {
    node.condition.accept(this);
    node.whenTrue.accept(this);
    node.whenFalse.accept(this);
  }
}

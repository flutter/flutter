// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// [RecursiveAstVisitor] that delegates visit methods to functions.
class FunctionAstVisitor extends RecursiveAstVisitor<void> {
  final void Function(CatchClauseParameter)? catchClauseParameter;
  final void Function(DeclaredIdentifier)? declaredIdentifier;
  final void Function(DeclaredVariablePattern)? declaredVariablePattern;
  final void Function(ForElement)? forElement;
  final void Function(ForStatement)? forStatement;
  final void Function(FunctionDeclarationStatement)?
      functionDeclarationStatement;
  final void Function(FunctionExpression, bool)? functionExpression;
  final void Function(GuardedPattern)? guardedPattern;
  final void Function(IfElement)? ifElement;
  final void Function(IfStatement)? ifStatement;
  final void Function(Label)? label;
  final void Function(MethodInvocation)? methodInvocation;
  final void Function(PatternAssignment)? patternAssignment;
  final void Function(PatternVariableDeclaration)? patternVariableDeclaration;
  final void Function(PatternVariableDeclarationStatement)?
      patternVariableDeclarationStatement;
  final void Function(SimpleIdentifier)? simpleIdentifier;
  final void Function(SwitchExpression)? switchExpression;
  final void Function(SwitchExpressionCase)? switchExpressionCase;
  final void Function(SwitchPatternCase)? switchPatternCase;
  final void Function(VariableDeclaration)? variableDeclaration;

  FunctionAstVisitor({
    this.catchClauseParameter,
    this.declaredIdentifier,
    this.declaredVariablePattern,
    this.forElement,
    this.forStatement,
    this.functionDeclarationStatement,
    this.functionExpression,
    this.guardedPattern,
    this.ifElement,
    this.ifStatement,
    this.label,
    this.methodInvocation,
    this.patternAssignment,
    this.patternVariableDeclaration,
    this.patternVariableDeclarationStatement,
    this.simpleIdentifier,
    this.switchExpression,
    this.switchExpressionCase,
    this.switchPatternCase,
    this.variableDeclaration,
  });

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    catchClauseParameter?.call(node);
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (declaredIdentifier != null) {
      declaredIdentifier!(node);
    }
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    declaredVariablePattern?.call(node);
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitForElement(ForElement node) {
    if (forElement != null) {
      forElement!(node);
    }
    super.visitForElement(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    if (forStatement != null) {
      forStatement!(node);
    }
    super.visitForStatement(node);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (functionDeclarationStatement != null) {
      functionDeclarationStatement!(node);
    }
    super.visitFunctionDeclarationStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (functionExpression != null) {
      var local = node.parent is! FunctionDeclaration ||
          node.parent!.parent is FunctionDeclarationStatement;
      functionExpression!(node, local);
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitGuardedPattern(GuardedPattern node) {
    guardedPattern?.call(node);
    super.visitGuardedPattern(node);
  }

  @override
  void visitIfElement(IfElement node) {
    ifElement?.call(node);
    super.visitIfElement(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    ifStatement?.call(node);
    super.visitIfStatement(node);
  }

  @override
  void visitLabel(Label node) {
    if (label != null) {
      label!(node);
    }
    super.visitLabel(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (methodInvocation != null) {
      methodInvocation!(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPatternAssignment(PatternAssignment node) {
    patternAssignment?.call(node);
    super.visitPatternAssignment(node);
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    patternVariableDeclaration?.call(node);
    super.visitPatternVariableDeclaration(node);
  }

  @override
  void visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node) {
    patternVariableDeclarationStatement?.call(node);
    super.visitPatternVariableDeclarationStatement(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (simpleIdentifier != null) {
      simpleIdentifier!(node);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    switchExpression?.call(node);
    super.visitSwitchExpression(node);
  }

  @override
  void visitSwitchExpressionCase(SwitchExpressionCase node) {
    switchExpressionCase?.call(node);
    super.visitSwitchExpressionCase(node);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    switchPatternCase?.call(node);
    super.visitSwitchPatternCase(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (variableDeclaration != null) {
      variableDeclaration!(node);
    }
    super.visitVariableDeclaration(node);
  }
}

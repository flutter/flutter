// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class _SuperVisitor extends RecursiveAstVisitor<void> {
  final String name;
  final _Usage _usage;

  /// Set to `true` if a super invocation with the [name] is found.
  bool hasSuperInvocation = false;

  _SuperVisitor(this.name, this._usage);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (_usage == _Usage.writing) {
      var left = node.leftHandSide;
      if (left is PropertyAccess) {
        if (left.target is SuperExpression && left.propertyName.name == name) {
          hasSuperInvocation = true;
          return;
        }
      }
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (_usage == _Usage.reading) {
      if (node.leftOperand is SuperExpression && node.operator.lexeme == name) {
        hasSuperInvocation = true;
        return;
      }
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_usage == _Usage.reading) {
      if (node.target is SuperExpression && node.methodName.name == name) {
        hasSuperInvocation = true;
        return;
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_usage == _Usage.reading) {
      var parent = node.parent;
      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        // Not reading, skip.
      } else {
        if (node.target is SuperExpression && node.propertyName.name == name) {
          hasSuperInvocation = true;
          return;
        }
      }
    }
    super.visitPropertyAccess(node);
  }
}

enum _Usage { writing, reading }

extension MethodDeclarationExtension on MethodDeclaration {
  bool get invokesSuperSelf {
    var visitor = _SuperVisitor(
      name.lexeme,
      isSetter ? _Usage.writing : _Usage.reading,
    );
    body.accept(visitor);
    return visitor.hasSuperInvocation;
  }
}

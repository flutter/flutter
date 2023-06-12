// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';

/// An object used to locate the [Element] associated with a given [AstNode].
class ElementLocator {
  /// Return the element associated with the given [node], or `null` if there
  /// is no element associated with the node.
  static Element? locate(AstNode? node) {
    if (node == null) return null;

    var mapper = _ElementMapper();
    return node.accept(mapper);
  }
}

/// Visitor that maps nodes to elements.
class _ElementMapper extends GeneralizingAstVisitor<Element> {
  @override
  Element? visitAnnotation(Annotation node) {
    return node.element;
  }

  @override
  Element? visitAssignmentExpression(AssignmentExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitBinaryExpression(BinaryExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitClassDeclaration(ClassDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitCompilationUnit(CompilationUnit node) {
    return node.declaredElement;
  }

  @override
  Element? visitConstructorDeclaration(ConstructorDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitExportDirective(ExportDirective node) {
    return node.element;
  }

  @override
  Element? visitFunctionDeclaration(FunctionDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitIdentifier(Identifier node) {
    var parent = node.parent;
    if (parent is Annotation) {
      // Type name in Annotation
      if (identical(parent.name, node) && parent.constructorName == null) {
        return parent.element;
      }
    } else if (parent is ConstructorDeclaration) {
      // Extra work to map Constructor Declarations to their associated
      // Constructor Elements
      var returnType = parent.returnType;
      if (identical(returnType, node)) {
        var name = parent.name;
        if (name != null) {
          return name.staticElement;
        }
        var element = node.staticElement;
        if (element is ClassElement) {
          return element.unnamedConstructor;
        }
      }
    } else if (parent is LibraryIdentifier) {
      var grandParent = parent.parent;
      if (grandParent is PartOfDirective) {
        var element = grandParent.element;
        if (element is LibraryElement) {
          return element.definingCompilationUnit;
        }
      } else if (grandParent is LibraryDirective) {
        return grandParent.element;
      }
    }
    return node.writeOrReadElement;
  }

  @override
  Element? visitImportDirective(ImportDirective node) {
    return node.element;
  }

  @override
  Element? visitIndexExpression(IndexExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitInstanceCreationExpression(InstanceCreationExpression node) {
    return node.constructorName.staticElement;
  }

  @override
  Element? visitLibraryDirective(LibraryDirective node) {
    return node.element;
  }

  @override
  Element? visitMethodDeclaration(MethodDeclaration node) {
    return node.declaredElement;
  }

  @override
  Element? visitMethodInvocation(MethodInvocation node) {
    return node.methodName.staticElement;
  }

  @override
  Element? visitPartOfDirective(PartOfDirective node) {
    return node.element;
  }

  @override
  Element? visitPostfixExpression(PostfixExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitPrefixedIdentifier(PrefixedIdentifier node) {
    return node.staticElement;
  }

  @override
  Element? visitPrefixExpression(PrefixExpression node) {
    return node.staticElement;
  }

  @override
  Element? visitStringLiteral(StringLiteral node) {
    var parent = node.parent;
    if (parent is UriBasedDirective) {
      return parent.uriElement;
    }
    return null;
  }

  @override
  Element? visitVariableDeclaration(VariableDeclaration node) {
    return node.declaredElement;
  }
}

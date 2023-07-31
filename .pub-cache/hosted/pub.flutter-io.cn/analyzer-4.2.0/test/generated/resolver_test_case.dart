// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

/// An AST visitor used to verify that all of the nodes in an AST structure that
/// should have been resolved were resolved.
class ResolutionVerifier extends RecursiveAstVisitor<void> {
  /// A set containing nodes that are known to not be resolvable and should
  /// therefore not cause the test to fail.
  final Set<AstNode>? _knownExceptions;

  /// A list containing all of the AST nodes that were not resolved.
  final List<AstNode> _unresolvedNodes = <AstNode>[];

  /// A list containing all of the AST nodes that were resolved to an element of
  /// the wrong type.
  final List<AstNode> _wrongTypedNodes = <AstNode>[];

  /// Initialize a newly created verifier to verify that all of the identifiers
  /// in the visited AST structures that are expected to have been resolved have
  /// an element associated with them. Nodes in the set of [_knownExceptions]
  /// are not expected to have been resolved, even if they normally would have
  /// been expected to have been resolved.
  ResolutionVerifier([this._knownExceptions]);

  /// Assert that all of the visited identifiers were resolved.
  void assertResolved() {
    if (_unresolvedNodes.isNotEmpty || _wrongTypedNodes.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      if (_unresolvedNodes.isNotEmpty) {
        buffer.write("Failed to resolve ");
        buffer.write(_unresolvedNodes.length);
        buffer.writeln(" nodes:");
        _printNodes(buffer, _unresolvedNodes);
      }
      if (_wrongTypedNodes.isNotEmpty) {
        buffer.write("Resolved ");
        buffer.write(_wrongTypedNodes.length);
        buffer.writeln(" to the wrong type of element:");
        _printNodes(buffer, _wrongTypedNodes);
      }
      fail(buffer.toString());
    }
  }

  @override
  void visitAnnotation(Annotation node) {
    node.visitChildren(this);
    var elementAnnotation = node.elementAnnotation;
    if (elementAnnotation == null) {
      if (_knownExceptions == null || !_knownExceptions!.contains(node)) {
        _unresolvedNodes.add(node);
      }
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return;
    }
    var operandType = node.leftOperand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitCommentReference(CommentReference node) {}

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    _checkResolved(
        node, node.declaredElement, (node) => node is CompilationUnitElement);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _checkResolved(node, node.element, (node) => node is ExportElement);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    if (node.declaredElement is LibraryElement) {
      _wrongTypedNodes.add(node);
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    // TODO(brianwilkerson) If we start resolving function expressions, then
    // conditionally check to see whether the node was resolved correctly.
    //checkResolved(node, node.getElement(), FunctionElement.class);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    // Not sure how to test the combinators given that it isn't an error if the
    // names are not defined.
    _checkResolved(node, node.element, (node) => node is ImportElement);
    var prefix = node.prefix;
    if (prefix == null) {
      return;
    }
    _checkResolved(
        prefix, prefix.staticElement, (node) => node is PrefixElement);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    var targetType = node.realTarget.staticType;
    if (targetType == null || targetType.isDynamic) {
      return;
    }
    var parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _checkResolved(node, node.element, (node) => node is LibraryElement);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _checkResolved(
        node, node.element, (node) => node is CompilationUnitElement);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _checkResolved(node, node.element, (node) => node is LibraryElement);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return;
    }
    var operandType = node.operand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    prefix.accept(this);
    var prefixType = prefix.staticType;
    if (prefixType == null || prefixType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, null);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return;
    }
    var operandType = node.operand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    target.accept(this);
    var targetType = target.staticType;
    if (targetType == null || targetType.isDynamic) {
      return;
    }
    var parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      return;
    }
    node.propertyName.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "void") {
      return;
    }

    var staticType = node.staticType;
    if (staticType != null &&
        staticType.isDynamic &&
        node.staticElement == null) {
      return;
    }

    var parent = node.parent;
    if (parent is AssignmentExpression && parent.leftHandSide == node) {
      return;
    }
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      if (identical(invocation.methodName, node)) {
        var target = invocation.realTarget;
        var targetType = target?.staticType;
        if (targetType == null || targetType.isDynamic) {
          return;
        }
      }
    }
    _checkResolved(node, node.staticElement, null);
  }

  void _checkResolved(
    AstNode node,
    Element? element,
    bool Function(Element)? predicate,
  ) {
    if (element == null) {
      if (_knownExceptions == null || !_knownExceptions!.contains(node)) {
        _unresolvedNodes.add(node);
      }
    } else if (predicate != null) {
      if (!predicate(element)) {
        _wrongTypedNodes.add(node);
      }
    }
  }

  String _getFileName(AstNode? node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // StaticTypeVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.declaredElement != null) {
          return rootCU.declaredElement!.source.fullName;
        } else {
          return "<unknown file- CompilationUnit.getElement() returned null>";
        }
      } else {
        return "<unknown file- CompilationUnit.getRoot() is not a CompilationUnit>";
      }
    }
    return "<unknown file- ASTNode is null>";
  }

  void _printNodes(StringBuffer buffer, List<AstNode> nodes) {
    for (AstNode identifier in nodes) {
      buffer.write("  ");
      buffer.write(identifier.toString());
      buffer.write(" (");
      buffer.write(_getFileName(identifier));
      buffer.write(" : ");
      buffer.write(identifier.offset);
      buffer.writeln(")");
    }
  }
}

/// Shared infrastructure for [StaticTypeAnalyzer2Test].
class StaticTypeAnalyzer2TestShared extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  // TODO(https://github.com/dart-lang/sdk/issues/44666): Use null safety in
  //  test cases.

  /// Looks up the identifier with [name] and validates that its type type
  /// stringifies to [type] and that its generics match the given stringified
  /// output.
  FunctionType expectFunctionType(String name, String type,
      {String typeParams = '[]',
      String typeFormals = '[]',
      String? identifierType}) {
    identifierType ??= type;

    String typeParametersStr(List<TypeParameterElement> elements) {
      var elementsStr = elements.map((e) {
        return e.getDisplayString(withNullability: false);
      }).join(', ');
      return '[$elementsStr]';
    }

    SimpleIdentifier identifier = findNode.simple(name);
    var functionType = _getFunctionTypedElementType(identifier);
    assertType(functionType, type);
    expect(identifier.staticType, isNull);
    expect(typeParametersStr(functionType.typeFormals), typeFormals);
    return functionType;
  }

  /// Looks up the identifier with [name] and validates that its element type
  /// stringifies to [type] and that its generics match the given stringified
  /// output.
  FunctionType expectFunctionType2(String name, String type) {
    var identifier = findNode.simple(name);
    var functionType = _getFunctionTypedElementType(identifier);
    assertType(functionType, type);
    return functionType;
  }

  /// Looks up the identifier with [name] and validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectIdentifierType(String name, type) {
    SimpleIdentifier identifier = findNode.simple(name);
    _expectType(identifier.staticType, type);
  }

  /// Looks up the initializer for the declaration containing [identifier] and
  /// validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectInitializerType(String name, type) {
    SimpleIdentifier identifier = findNode.simple(name);
    var declaration = identifier.thisOrAncestorOfType<VariableDeclaration>()!;
    var initializer = declaration.initializer!;
    _expectType(initializer.staticType, type);
  }

  /// Validates that [type] matches [expected].
  ///
  /// If [expected] is a string, validates that the type stringifies to that
  /// text. Otherwise, [expected] is used directly a [Matcher] to match the
  /// type.
  _expectType(DartType? type, expected) {
    if (expected is String) {
      assertType(type, expected);
    } else {
      expect(type, expected);
    }
  }

  FunctionType _getFunctionTypedElementType(SimpleIdentifier identifier) {
    var element = identifier.staticElement;
    if (element is ExecutableElement) {
      return element.type;
    } else if (element is VariableElement) {
      return element.type as FunctionType;
    } else {
      fail('Unexpected element: (${element.runtimeType}) $element');
    }
  }
}

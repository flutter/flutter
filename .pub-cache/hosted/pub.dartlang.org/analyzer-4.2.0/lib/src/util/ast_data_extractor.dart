// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/testing/id.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

MemberId computeMemberId(Element element) {
  var enclosingElement = element.enclosingElement;
  if (enclosingElement is CompilationUnitElement) {
    var memberName = element.name!;
    if (element is PropertyAccessorElement && element.isSetter) {
      memberName += '=';
    }
    return MemberId.internal(memberName);
  } else if (enclosingElement is ClassElement) {
    var memberName = element.name!;
    var className = enclosingElement.name;
    return MemberId.internal(memberName, className: className);
  } else if (enclosingElement is ExtensionElement) {
    var memberName = element.name!;
    var extensionName = enclosingElement.name;
    if (element is PropertyAccessorElement) {
      memberName = '${element.isGetter ? 'get' : 'set'}#$memberName';
    }
    return MemberId.internal('$extensionName|$memberName');
  }
  throw UnimplementedError(
      'TODO(paulberry): $element (${element.runtimeType})');
}

/// Abstract IR visitor for computing data corresponding to a node or element,
/// and record it with a generic [Id]
abstract class AstDataExtractor<T> extends GeneralizingAstVisitor<void>
    with DataRegistry<T> {
  final Uri uri;

  @override
  final Map<Id, ActualData<T>> actualMap;

  AstDataExtractor(this.uri, this.actualMap);

  NodeId computeDefaultNodeId(AstNode node) =>
      NodeId(_nodeOffset(node), IdKind.node);

  T? computeElementValue(Id id, Element element) => null;

  void computeForClass(Declaration node, Id? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    registerValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForCollectionElement(CollectionElement node, NodeId? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    registerValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForFormalParameter(FormalParameter node, NodeId? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    registerValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForLibrary(LibraryElement library, Id? id) {
    if (id == null) return;
    T? value = computeElementValue(id, library);
    registerValue(uri, 0, id, value, library);
  }

  void computeForMember(Declaration node, Id? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    registerValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForStatement(Statement node, NodeId? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    registerValue(uri, _nodeOffset(node), id, value, node);
  }

  void computeForVariableDeclaration(VariableDeclaration node, NodeId? id) {
    if (id == null) return;
    T? value = computeNodeValue(id, node);
    registerValue(uri, _nodeOffset(node), id, value, node);
  }

  /// Implement this to compute the data corresponding to [node].
  ///
  /// If `null` is returned, [node] has no associated data.
  T? computeNodeValue(Id id, AstNode node);

  Id createClassId(Declaration node) {
    var element = node.declaredElement!;
    return ClassId(element.name!);
  }

  Id createLibraryId(LibraryElement node) {
    Uri uri = node.source.uri;
    if (uri.path.startsWith(r'/C:')) {
      // The `MemoryResourceProvider.convertPath` inserts '/C:' on Windows.
      uri = Uri(scheme: uri.scheme, path: uri.path.substring(3));
    }
    return LibraryId(uri);
  }

  Id createMemberId(Declaration node) {
    var element = node.declaredElement!;
    return computeMemberId(element);
  }

  NodeId createStatementId(Statement node) =>
      NodeId(_nodeOffset(node), IdKind.stmt);

  @override
  void fail(String message) {
    throw _Failure(message);
  }

  @override
  void report(Uri uri, int offset, String message) {
    // TODO(paulberry): find a way to print the error more nicely.
    print('$uri:$offset: $message');
  }

  void run(CompilationUnit unit) {
    unit.accept(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    computeForClass(node, createClassId(node));
    super.visitClassDeclaration(node);
  }

  @override
  void visitCollectionElement(CollectionElement node) {
    computeForCollectionElement(node, computeDefaultNodeId(node));
    super.visitCollectionElement(node);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var library = node.declaredElement!.library;
    computeForLibrary(library, createLibraryId(library));
    super.visitCompilationUnit(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitFormalParameter(FormalParameter node) {
    computeForFormalParameter(node, computeDefaultNodeId(node));
    super.visitFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is CompilationUnit) {
      computeForMember(node, createMemberId(node));
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    computeForMember(node, createMemberId(node));
    super.visitMethodDeclaration(node);
  }

  @override
  void visitStatement(Statement node) {
    computeForStatement(
        node,
        node is ExpressionStatement
            ? createStatementId(node)
            : computeDefaultNodeId(node));
    super.visitStatement(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.parent!.parent is TopLevelVariableDeclaration) {
      computeForMember(node, createMemberId(node));
    } else if (node.parent!.parent is FieldDeclaration) {
      computeForMember(node, createMemberId(node));
    } else {
      computeForVariableDeclaration(node, computeDefaultNodeId(node));
    }
    super.visitVariableDeclaration(node);
  }

  int _nodeOffset(AstNode node) {
    int offset;
    if (node is ConditionalExpression) {
      offset = node.question.offset;
    } else if (node is BinaryExpression) {
      offset = node.operator.offset;
    } else if (node is InstanceCreationExpression) {
      offset = node.argumentList.leftParenthesis.offset;
    } else if (node is InvocationExpression) {
      offset = node.argumentList.leftParenthesis.offset;
    } else if (node is PrefixedIdentifier) {
      offset = node.identifier.offset;
    } else {
      offset = node.offset;
    }
    assert(offset >= 0, "No fileOffset on $node (${node.runtimeType})");
    return offset;
  }
}

class _Failure implements Exception {
  final String? message;

  _Failure([this.message]);

  @override
  String toString() {
    if (message == null) return "Exception";
    return "Exception: $message";
  }
}

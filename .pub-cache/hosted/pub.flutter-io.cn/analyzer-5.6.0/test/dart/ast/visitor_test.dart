// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test_base.dart' show ParserTestCase;
import '../../util/ast_type_matchers.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BreadthFirstVisitorTest);
  });
}

@reflectiveTest
class BreadthFirstVisitorTest extends ParserTestCase {
  void test_it() {
    String source = r'''
class A {
  bool get g => true;
}
class B {
  int f() {
    num q() {
      return 3;
    }
  return q() + 4;
  }
}
A f(var p) {
  if ((p as A).g) {
    return p;
  } else {
    return null;
  }
}''';
    CompilationUnit unit = parseCompilationUnit(source);
    List<AstNode> nodes = <AstNode>[];
    _BreadthFirstVisitorTestHelper visitor =
        _BreadthFirstVisitorTestHelper(nodes);
    visitor.visitAllNodes(unit);
    expect(nodes, hasLength(52));
    expect(nodes[0], isCompilationUnit);
    expect(nodes[2], isClassDeclaration);
    expect(nodes[3], isFunctionDeclaration);
    expect(nodes[22], isFunctionDeclarationStatement);
    expect(nodes[51], isIntegerLiteral); // 3
  }
}

/// A helper class used to collect the nodes that were visited and to preserve
/// the order in which they were visited.
class _BreadthFirstVisitorTestHelper extends BreadthFirstVisitor<void> {
  List<AstNode> nodes;

  _BreadthFirstVisitorTestHelper(this.nodes) : super();

  @override
  void visitNode(AstNode node) {
    nodes.add(node);
    super.visitNode(node);
  }
}

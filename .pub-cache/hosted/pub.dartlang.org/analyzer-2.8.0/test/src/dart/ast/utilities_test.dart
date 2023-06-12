// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/parser_test_base.dart' show ParserTestCase;
import '../../../util/ast_type_matchers.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NodeLocatorTest);
    defineReflectiveTests(NodeLocator2Test);
  });
}

@reflectiveTest
class NodeLocator2Test extends ParserTestCase {
  void test_onlyStartOffset() {
    String code = ' int vv; ';
    //             012345678
    CompilationUnit unit = parseCompilationUnit(code);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclarationList variableList = declaration.variables;
    Identifier typeName = (variableList.type as NamedType).name;
    SimpleIdentifier varName = variableList.variables[0].name;
    expect(NodeLocator2(0).searchWithin(unit), same(unit));
    expect(NodeLocator2(1).searchWithin(unit), same(typeName));
    expect(NodeLocator2(2).searchWithin(unit), same(typeName));
    expect(NodeLocator2(3).searchWithin(unit), same(typeName));
    expect(NodeLocator2(4).searchWithin(unit), same(variableList));
    expect(NodeLocator2(5).searchWithin(unit), same(varName));
    expect(NodeLocator2(6).searchWithin(unit), same(varName));
    expect(NodeLocator2(7).searchWithin(unit), same(declaration));
    expect(NodeLocator2(8).searchWithin(unit), same(unit));
    expect(NodeLocator2(9).searchWithin(unit), isNull);
    expect(NodeLocator2(100).searchWithin(unit), isNull);
  }

  void test_startEndOffset() {
    String code = ' int vv; ';
    //             012345678
    CompilationUnit unit = parseCompilationUnit(code);
    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclarationList variableList = declaration.variables;
    Identifier typeName = (variableList.type as NamedType).name;
    SimpleIdentifier varName = variableList.variables[0].name;
    expect(NodeLocator2(-1, 2).searchWithin(unit), isNull);
    expect(NodeLocator2(0, 2).searchWithin(unit), same(unit));
    expect(NodeLocator2(1, 2).searchWithin(unit), same(typeName));
    expect(NodeLocator2(1, 3).searchWithin(unit), same(typeName));
    expect(NodeLocator2(1, 4).searchWithin(unit), same(variableList));
    expect(NodeLocator2(5, 6).searchWithin(unit), same(varName));
    expect(NodeLocator2(5, 7).searchWithin(unit), same(declaration));
    expect(NodeLocator2(5, 8).searchWithin(unit), same(unit));
    expect(NodeLocator2(5, 100).searchWithin(unit), isNull);
    expect(NodeLocator2(100, 200).searchWithin(unit), isNull);
  }
}

@reflectiveTest
class NodeLocatorTest extends ParserTestCase {
  void test_range() {
    CompilationUnit unit = parseCompilationUnit("library myLib;");
    var node = _assertLocate(unit, 4, 10);
    expect(node, isLibraryDirective);
  }

  void test_searchWithin_null() {
    NodeLocator locator = NodeLocator(0, 0);
    expect(locator.searchWithin(null), isNull);
  }

  void test_searchWithin_offset() {
    CompilationUnit unit = parseCompilationUnit("library myLib;");
    var node = _assertLocate(unit, 10, 10);
    expect(node, isSimpleIdentifier);
  }

  void test_searchWithin_offsetAfterNode() {
    CompilationUnit unit = parseCompilationUnit(r'''
class A {}
class B {}''');
    NodeLocator locator = NodeLocator(1024, 1024);
    var node = locator.searchWithin(unit.declarations[0]);
    expect(node, isNull);
  }

  void test_searchWithin_offsetBeforeNode() {
    CompilationUnit unit = parseCompilationUnit(r'''
class A {}
class B {}''');
    NodeLocator locator = NodeLocator(0, 0);
    var node = locator.searchWithin(unit.declarations[1]);
    expect(node, isNull);
  }

  AstNode _assertLocate(
    CompilationUnit unit,
    int start,
    int end,
  ) {
    NodeLocator locator = NodeLocator(start, end);
    var node = locator.searchWithin(unit)!;
    expect(locator.foundNode, same(node));
    expect(node.offset <= start, isTrue, reason: "Node starts after range");
    expect(node.offset + node.length > end, isTrue,
        reason: "Node ends before range");
    return node;
  }
}

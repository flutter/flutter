// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorParserTest);
  });
}

@reflectiveTest
class NonErrorParserTest extends ParserTestCase {
  void test_annotationOnEnumConstant_first() {
    createParser("enum E { @override C }");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
  }

  void test_annotationOnEnumConstant_middle() {
    createParser("enum E { C, @override D, E }");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    assertNoErrors();
  }

  void test_staticMethod_notParsingFunctionBodies() {
    ParserTestCase.parseFunctionBodies = false;
    try {
      createParser('class C { static void m() {} }');
      CompilationUnit unit = parser.parseCompilationUnit2();
      expectNotNullIfNoErrors(unit);
      assertNoErrors();
    } finally {
      ParserTestCase.parseFunctionBodies = true;
    }
  }
}

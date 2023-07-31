// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RefutablePatternInIrrefutableContextTest);
  });
}

@reflectiveTest
class RefutablePatternInIrrefutableContextTest
    extends PubPackageResolutionTest {
  test_declaration_constantPattern() async {
    await assertErrorsInCode(r'''
void f() {
  var (0) = 0;
}
''', [
      error(
          CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT, 18, 1),
    ]);

    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
''');
  }

  test_declaration_logicalOrPattern() async {
    await assertErrorsInCode(r'''
void f() {
  var (_ || _) = 0;
}
''', [
      error(
          CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT, 18, 6),
      error(HintCode.DEAD_CODE, 20, 4),
    ]);

    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: LogicalOrPattern
      leftOperand: WildcardPattern
        name: _
        matchedValueType: int
      operator: ||
      rightOperand: WildcardPattern
        name: _
        matchedValueType: int
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
''');
  }

  test_declaration_nullCheckPattern() async {
    await assertErrorsInCode(r'''
void f(int? x) {
  var (_?) = x;
}
''', [
      error(
          CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT, 24, 2),
    ]);

    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: NullCheckPattern
      pattern: WildcardPattern
        name: _
        matchedValueType: int
      operator: ?
      matchedValueType: int?
    rightParenthesis: )
    matchedValueType: int?
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  patternTypeSchema: _
''');
  }

  test_declaration_relationalPattern() async {
    await assertErrorsInCode(r'''
void f() {
  var (> 0) = 0;
}
''', [
      error(
          CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT, 18, 3),
    ]);

    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: RelationalPattern
      operator: >
      operand: IntegerLiteral
        literal: 0
        staticType: int
      element: dart:core::@class::num::@method::>
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: IntegerLiteral
    literal: 0
    staticType: int
  patternTypeSchema: _
''');
  }
}

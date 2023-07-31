// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndPatternResolutionTest);
  });
}

@reflectiveTest
class LogicalAndPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int _ && double _) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: _
    matchedValueType: dynamic
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
    matchedValueType: int
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int _ && double _:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
LogicalAndPattern
  leftOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: _
    matchedValueType: dynamic
  operator: &&
  rightOperand: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: double
        staticElement: dart:core::@class::double
        staticType: null
      type: double
    name: _
    matchedValueType: int
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
void f() {
  var (a && b) = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: LogicalAndPattern
        leftOperand: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@18
            type: int
          matchedValueType: int
        operator: &&
        rightOperand: DeclaredVariablePattern
          name: b
          declaredElement: hasImplicitType b@23
            type: int
          matchedValueType: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: _
  semicolon: ;
''');
  }
}

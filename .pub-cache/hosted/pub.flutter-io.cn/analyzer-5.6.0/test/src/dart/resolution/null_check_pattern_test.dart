// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullCheckPatternResolutionTest);
  });
}

@reflectiveTest
class NullCheckPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertErrorsInCode(r'''
void f(int? x) {
  if (x case var y?) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@34
      type: int
    matchedValueType: int
  operator: ?
  matchedValueType: int?
''');
  }

  test_switchCase() async {
    await assertErrorsInCode(r'''
void f(int? x) {
  switch (x) {
    case var y?:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
NullCheckPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@45
      type: int
    matchedValueType: int
  operator: ?
  matchedValueType: int?
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
void f(int? x) {
  var (a?) = x;
}
''', [
      error(
          CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT, 24, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 24, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: NullCheckPattern
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@24
          type: int
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
}

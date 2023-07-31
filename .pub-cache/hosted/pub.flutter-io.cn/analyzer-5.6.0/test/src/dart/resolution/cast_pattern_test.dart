// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastPatternResolutionTest);
  });
}

@reflectiveTest
class CastPatternResolutionTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertErrorsInCode(r'''
void f(x) {
  if (x case var y as int) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@29
      type: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  matchedValueType: dynamic
''');
  }

  test_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  switch (x) {
    case a as int:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: ConstantPattern
    expression: SimpleIdentifier
      token: a
      staticElement: a@20
      staticType: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
void f(x) {
  var (a as int) = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: CastPattern
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@19
          type: int
        matchedValueType: int
      asToken: as
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      matchedValueType: dynamic
    rightParenthesis: )
    matchedValueType: dynamic
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: dynamic
  patternTypeSchema: Object?
''');
  }
}

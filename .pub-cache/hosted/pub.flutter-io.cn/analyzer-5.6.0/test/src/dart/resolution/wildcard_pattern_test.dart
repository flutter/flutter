// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WildcardPatternResolutionTest);
  });
}

@reflectiveTest
class WildcardPatternResolutionTest extends PubPackageResolutionTest {
  test_assignmentContext_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  (_) = 0;
}
''');
    final node = findNode.singlePatternAssignment.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    name: _
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_declarationContext_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (int _) = 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    type: NamedType
      name: SimpleIdentifier
        token: int
        staticElement: dart:core::@class::int
        staticType: null
      type: int
    name: _
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_declarationContext_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (_) = 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: WildcardPattern
    name: _
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_matchingContext_typed() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case int _) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: _
  matchedValueType: dynamic
''');
  }

  test_matchingContext_typed_final() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case final int _) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  keyword: final
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: _
  matchedValueType: dynamic
''');
  }

  test_matchingContext_untyped() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case _) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  name: _
  matchedValueType: dynamic
''');
  }

  test_matchingContext_untyped_final() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case final _) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
WildcardPattern
  keyword: final
  name: _
  matchedValueType: dynamic
''');
  }
}

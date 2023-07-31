// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaredVariablePatternResolutionTest);
  });
}

@reflectiveTest
class DeclaredVariablePatternResolutionTest extends PubPackageResolutionTest {
  test_final_switchCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final y:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: final
  name: y
  declaredElement: hasImplicitType isFinal y@46
    type: int
  matchedValueType: int
''');
  }

  test_final_typed_switchCase() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case final int y:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: final
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: y
  declaredElement: isFinal y@46
    type: int
  matchedValueType: dynamic
''');
  }

  test_patternVariableDeclaration_final_recordPattern_listPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final [a] = [0];
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      name: a
      declaredElement: hasImplicitType isFinal a@54
        type: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_patternVariableDeclaration_final_recordPattern_listPattern_restPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final [...a] = [0, 1, 2];
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@57
          type: List<int>
        matchedValueType: List<int>
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_patternVariableDeclaration_final_recordPattern_mapPattern_entry() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final {0: a} = {0: 1};
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@57
          type: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Map<int, int>
  requiredType: Map<int, int>
''');
  }

  test_patternVariableDeclaration_final_recordPattern_objectPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final int(sign: a) = 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: sign
        colon: :
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@63
          type: int
        matchedValueType: int
      element: dart:core::@class::int::@getter::sign
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_patternVariableDeclaration_final_recordPattern_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final (a) = 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    name: a
    declaredElement: hasImplicitType isFinal a@54
      type: int
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_patternVariableDeclaration_final_recordPattern_recordPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final (a,) = (0,);
}
''');
    final node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@54
          type: int
        matchedValueType: int
      element: <null>
  rightParenthesis: )
  matchedValueType: (int)
''');
  }

  test_typed_switchCase() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int y:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  name: y
  declaredElement: y@40
    type: int
  matchedValueType: dynamic
''');
  }

  test_var_demoteType() async {
    await assertErrorsInCode(r'''
void f<T>(T x) {
  if (x is int) {
    if (x case var y) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
    ]);

    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@54
    type: T
  matchedValueType: T & int
''');
  }

  test_var_fromLegacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.10
final x = <int>[];
''');
    await assertErrorsInCode(r'''
// ignore:import_of_legacy_library_into_null_safe
import 'a.dart';
void f() {
  if (x case var y) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 95, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@95
    type: List<int>
  matchedValueType: List<int*>*
''');
  }

  test_var_ifCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case var y) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@33
    type: int
  matchedValueType: int
''');
  }

  test_var_nullOrEquivalent_neverQuestion() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  if (x case var y) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@36
    type: dynamic
  matchedValueType: Never?
''');
  }

  test_var_nullOrEquivalent_nullNone() async {
    await assertErrorsInCode(r'''
void f(Null x) {
  if (x case var y) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@34
    type: dynamic
  matchedValueType: Null
''');
  }

  test_var_nullOrEquivalent_nullStar() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.10
Null x = null;
''');
    await assertErrorsInCode(r'''
// ignore:import_of_legacy_library_into_null_safe
import 'a.dart';
void f() {
  if (x case var y) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 95, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@95
    type: dynamic
  matchedValueType: Null*
''');
  }

  test_var_switchCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var y:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@44
    type: int
  matchedValueType: int
''');
  }

  test_var_switchCase_cast() async {
    await assertErrorsInCode(r'''
void f(num x) {
  switch (x) {
    case var y as int:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@44
      type: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  matchedValueType: num
''');
  }
}

// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternAssignmentResolutionTest);
  });
}

@reflectiveTest
class PatternAssignmentResolutionTest extends PubPackageResolutionTest {
  test_assignable_final_definitelyAssigned() async {
    await assertErrorsInCode(r'''
void f() {
  final int a;
  a = 0;
  (a) = 1;
  a;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 38, 1),
    ]);
  }

  test_assignable_final_definitelyUnassigned() async {
    await assertNoErrorsInCode(r'''
void f() {
  final int a;
  (a) = 0;
  a;
}
''');
  }

  test_assignable_final_notDefinitelyUnassigned() async {
    await assertErrorsInCode(r'''
void f(bool flag) {
  final int a;
  if (flag) {
    a = 0;
  }
  (a) = 1;
  a;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 67, 1),
    ]);
  }

  test_assignable_lateFinal_definitelyAssigned() async {
    await assertErrorsInCode(r'''
void f() {
  late final int a;
  a = 0;
  (a) = 1;
  a;
}
''', [
      error(CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED, 43, 1),
    ]);
  }

  test_assignable_lateFinal_definitelyUnassigned() async {
    await assertNoErrorsInCode(r'''
void f() {
  late final int a;
  (a) = 1;
  a;
}
''');
  }

  test_assignable_lateFinal_notDefinitelyAssigned() async {
    await assertNoErrorsInCode(r'''
void f(bool flag) {
  late final int a;
  if (flag) {
    a = 0;
  }
  (a) = 1;
  a;
}
''');
  }

  test_container_listPattern() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x, num a) {
  [a] = x;
}
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ListPattern
    leftBracket: [
    elements
      AssignedVariablePattern
        name: a
        element: self::@function::f::@parameter::a
        matchedValueType: int
    rightBracket: ]
    matchedValueType: List<int>
    requiredType: List<int>
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: List<int>
  patternTypeSchema: List<num>
  staticType: List<int>
''');
  }

  test_container_objectPattern_implicitGetter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(int foo) {
  A(:foo) = A();
}
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ObjectPattern
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          colon: :
        pattern: AssignedVariablePattern
          name: foo
          element: self::@function::f::@parameter::foo
          matchedValueType: int
        element: self::@class::A::@getter::foo
    rightParenthesis: )
    matchedValueType: A
  equals: =
  expression: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: A
          staticElement: self::@class::A
          staticType: null
        type: A
      staticElement: self::@class::A::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  patternTypeSchema: A
  staticType: A
''');
  }

  test_container_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f(int x, num a) {
  (a) = x;
}
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element: self::@function::f::@parameter::a
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int
  patternTypeSchema: num
  staticType: int
''');
  }

  test_container_parenthesizedPattern_schema() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  (a) = g();
}

T g<T>() => throw 0;
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element: self::@function::f::@parameter::a
      matchedValueType: int
    rightParenthesis: )
    matchedValueType: int
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      staticElement: self::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  patternTypeSchema: int
  staticType: int
''');
  }

  test_container_recordPattern_named() async {
    await assertNoErrorsInCode(r'''
void f(({int foo}) x, num a) {
  (foo: a,) = x;
}
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: AssignedVariablePattern
          name: a
          element: self::@function::f::@parameter::a
          matchedValueType: int
        element: <null>
    rightParenthesis: )
    matchedValueType: ({int foo})
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: ({int foo})
  patternTypeSchema: ({num foo})
  staticType: ({int foo})
''');
  }

  test_container_recordPattern_named_implicit() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  (:a) = (a: 0);
}
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          colon: :
        pattern: AssignedVariablePattern
          name: a
          element: self::@function::f::@parameter::a
          matchedValueType: int
        element: <null>
    rightParenthesis: )
    matchedValueType: ({int a})
  equals: =
  expression: RecordLiteral
    leftParenthesis: (
    fields
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            staticElement: <null>
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightParenthesis: )
    staticType: ({int a})
  patternTypeSchema: ({int a})
  staticType: ({int a})
''');
  }

  test_container_recordPattern_positional() async {
    await assertNoErrorsInCode(r'''
void f((int,) x, num a) {
  (a,) = x;
}
''');
    final node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: AssignedVariablePattern
          name: a
          element: self::@function::f::@parameter::a
          matchedValueType: int
        element: <null>
    rightParenthesis: )
    matchedValueType: (int)
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: (int)
  patternTypeSchema: (num)
  staticType: (int)
''');
  }

  test_final_becomesDefinitelyAssigned() async {
    await assertErrorsInCode(r'''
void f() {
  final int a;
  (a) = 0;
  a;
  a = 1;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 44, 1),
    ]);
  }

  test_promotes() async {
    await assertNoErrorsInCode(r'''
void f(num a) {
  if (a is! int) {
    (a) = 0;
  }
  a;
}
''');
    final node = findNode.simple('a;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: a
  staticElement: self::@function::f::@parameter::a
  staticType: int
''');
  }
}

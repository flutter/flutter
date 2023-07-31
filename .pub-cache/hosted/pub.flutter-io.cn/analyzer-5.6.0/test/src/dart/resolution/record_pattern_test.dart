// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternResolutionTest);
  });
}

@reflectiveTest
class RecordPatternResolutionTest extends PubPackageResolutionTest {
  test_dynamicType_empty() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_dynamicType_named_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@46
          type: dynamic
        matchedValueType: dynamic
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_dynamicType_positional_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (var y,):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@41
          type: dynamic
        matchedValueType: dynamic
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_interfaceType_empty() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: 0):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_variable_typed() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: int y):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: y
        declaredElement: y@54
          type: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@54
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (0,):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_variable_typed() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (int y,):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 49, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: y
        declaredElement: y@49
          type: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (var y,):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 49, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@49
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_recordType_differentShape_named_tooFew_hasName() async {
    await assertErrorsInCode(r'''
void f(() x) {
  switch (x) {
    case (a: var b):
      break;
    default:
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: a
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: b
        declaredElement: hasImplicitType b@47
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_named_tooFew_noName() async {
    await assertErrorsInCode(r'''
void f(() x) {
  switch (x) {
    case (: var a):
      break;
    default:
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@46
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_named_tooFew_noName2() async {
    await assertErrorsInCode(r'''
void f(({int b}) x) {
  switch (x) {
    case (: var a):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 53, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@53
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int b})
''');
  }

  test_recordType_differentShape_named_tooMany_noName() async {
    await assertErrorsInCode(r'''
void f(({int a, int b}) x) {
  switch (x) {
    case (: var a):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 60, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@60
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int a, int b})
''');
  }

  test_recordType_differentShape_positional_tooFew() async {
    await assertErrorsInCode(r'''
void f(() x) {
  switch (x) {
    case (var a,):
      break;
    default:
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@44
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_positional_tooMany() async {
    await assertErrorsInCode(r'''
void f((int, String) x) {
  switch (x) {
    case (var a,):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 55, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@55
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: (int, String)
''');
  }

  test_recordType_sameShape_empty() async {
    await assertErrorsInCode(r'''
void f(() x) {
  switch (x) {
    case ():
      break;
    default:
  }
}
''', [
      error(HintCode.DEAD_CODE, 60, 7),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_sameShape_mixed() async {
    await assertErrorsInCode(r'''
void f((int, double, {String foo}) x) {
  switch (x) {
    case (var a, foo: var b, var c):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 69, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 88, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@69
          type: int
        matchedValueType: int
      element: <null>
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: b
        declaredElement: hasImplicitType b@81
          type: String
        matchedValueType: String
      element: <null>
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: c
        declaredElement: hasImplicitType c@88
          type: double
        matchedValueType: double
      element: <null>
  rightParenthesis: )
  matchedValueType: (int, double, {String foo})
''');
  }

  test_recordType_sameShape_named_hasName_unresolved() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (bar: var a):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: bar
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@58
          type: Object?
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_hasName_variable() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@58
          type: int
        matchedValueType: int
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_constant() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (: 0):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_OBJECT_PATTERN_GETTER_NAME, 49, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_variable() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (: var foo):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 55, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@55
          type: int
        matchedValueType: int
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_cast() async {
    await assertErrorsInCode(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo as int):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 56, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: CastPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@56
            type: int
          matchedValueType: int
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        matchedValueType: int?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_nullAssert() async {
    await assertErrorsInCode(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo!):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 56, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullAssertPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@56
            type: int
          matchedValueType: int
        operator: !
        matchedValueType: int?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_nullCheck() async {
    await assertErrorsInCode(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo?):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 56, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullCheckPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@56
            type: int
          matchedValueType: int
        operator: ?
        matchedValueType: int?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_positional_variable() async {
    await assertErrorsInCode(r'''
void f((int,) x) {
  switch (x) {
    case (var a,):
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 48, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@48
          type: int
        matchedValueType: int
      element: <null>
  rightParenthesis: )
  matchedValueType: (int)
''');
  }

  test_variableDeclaration_inferredType() async {
    await assertErrorsInCode(r'''
void f((int, String) x) {
  var (a, b) = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@33
            type: int
          matchedValueType: int
        element: <null>
      PatternField
        pattern: DeclaredVariablePattern
          name: b
          declaredElement: hasImplicitType b@36
            type: String
          matchedValueType: String
        element: <null>
    rightParenthesis: )
    matchedValueType: (int, String)
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: (int, String)
  patternTypeSchema: (_, _)
''');
  }

  test_variableDeclaration_typeSchema() async {
    await assertErrorsInCode(r'''
void f() {
  var (int a, String b) = g();
}

(T, U) g<T, U>() => throw 0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: DeclaredVariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@22
            type: int
          matchedValueType: int
        element: <null>
      PatternField
        pattern: DeclaredVariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: String
              staticElement: dart:core::@class::String
              staticType: null
            type: String
          name: b
          declaredElement: b@32
            type: String
          matchedValueType: String
        element: <null>
    rightParenthesis: )
    matchedValueType: (int, String)
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      staticElement: self::@function::g
      staticType: (T, U) Function<T, U>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: (int, String) Function()
    staticType: (int, String)
    typeArgumentTypes
      int
      String
  patternTypeSchema: (int, String)
''');
  }
}

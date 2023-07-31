// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapPatternResolutionTest);
  });
}

@reflectiveTest
class MapPatternResolutionTest extends PubPackageResolutionTest {
  test_matchDynamic_noTypeArguments_variable_typed() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {0: String a}:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
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
        type: NamedType
          name: SimpleIdentifier
            token: String
            staticElement: dart:core::@class::String
            staticType: null
          type: String
        name: a
        declaredElement: a@47
          type: String
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<dynamic, dynamic>
''');
  }

  test_matchDynamic_noTypeArguments_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case {0: var a}:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
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
        keyword: var
        name: a
        declaredElement: hasImplicitType a@44
          type: dynamic
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<dynamic, dynamic>
''');
  }

  test_matchDynamic_withTypeArguments_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case <int, String>{0: var a}:
      break;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 57, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@57
          type: String
        matchedValueType: String
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_noPattern() async {
    await assertNoErrorsInCode(r'''
void f(Map<int, String> x) {
  if (x case {0: '', ...}) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: ConstantPattern
        expression: SimpleStringLiteral
          literal: ''
        matchedValueType: String
    RestPatternElement
      operator: ...
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_withPattern() async {
    await assertErrorsInCode(r'''
void f(Map<int, String> x) {
  if (x case {0: '', ...var rest}) {}
}
''', [
      error(CompileTimeErrorCode.REST_ELEMENT_WITH_SUBPATTERN_IN_MAP_PATTERN,
          57, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 57, 4),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: ConstantPattern
        expression: SimpleStringLiteral
          literal: ''
        matchedValueType: String
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        keyword: var
        name: rest
        declaredElement: hasImplicitType rest@57
          type: dynamic
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(Map<int, String> x) {
  if (x case {0: var a}) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
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
        keyword: var
        name: a
        declaredElement: hasImplicitType a@50
          type: String
        matchedValueType: String
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_withTypeArguments_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(Map<bool, num> x) {
  if (x case <bool, int>{true: var a}) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: bool
          staticElement: dart:core::@class::bool
          staticType: null
        type: bool
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@62
          type: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Map<bool, num>
  requiredType: Map<bool, int>
''');
  }

  test_matchObject_noTypeArguments_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x case {true: 0}) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_empty() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x case {}) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_typed() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  if (x case {true: int a}) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: a
        declaredElement: a@43
          type: int
        matchedValueType: Object?
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  if (x case {true: var a}) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@43
          type: Object?
        matchedValueType: Object?
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_withTypeArguments_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x case <bool, int>{true: 0}) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: bool
          staticElement: dart:core::@class::bool
          staticType: null
        type: bool
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<bool, int>
''');
  }

  test_matchObject_withTypeArguments_variable_untyped() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  if (x case <bool, int>{true: var a}) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: bool
          staticElement: dart:core::@class::bool
          staticType: null
        type: bool
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@54
          type: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<bool, int>
''');
  }

  test_rewrite_key() async {
    await assertErrorsInCode(r'''
void f(x, bool Function() a) {
  if (x case {a(): 0}) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY, 45, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: a
          staticElement: self::@function::f::@parameter::a
          staticType: bool Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: bool Function()
        staticType: bool
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<dynamic, dynamic>
''');
  }

  test_variableDeclaration_inferredType() async {
    await assertErrorsInCode(r'''
void f(Map<bool, int> x) {
  var {true: a} = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: BooleanLiteral
          literal: true
          staticType: bool
        separator: :
        value: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@40
            type: int
          matchedValueType: int
    rightBracket: }
    matchedValueType: Map<bool, int>
    requiredType: Map<bool, int>
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Map<bool, int>
  patternTypeSchema: Map<_, _>
''');
  }

  test_variableDeclaration_typeSchema_withTypeArguments() async {
    await assertErrorsInCode(r'''
void f() {
  var <bool, int>{true: a} = g();
}

T g<T>() => throw 0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: bool
            staticElement: dart:core::@class::bool
            staticType: null
          type: bool
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    leftBracket: {
    elements
      MapPatternEntry
        key: BooleanLiteral
          literal: true
          staticType: bool
        separator: :
        value: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@35
            type: int
          matchedValueType: int
    rightBracket: }
    matchedValueType: Map<bool, int>
    requiredType: Map<bool, int>
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      staticElement: self::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: Map<bool, int> Function()
    staticType: Map<bool, int>
    typeArgumentTypes
      Map<bool, int>
  patternTypeSchema: Map<bool, int>
''');
  }

  test_variableDeclaration_typeSchema_withVariableType() async {
    await assertErrorsInCode(r'''
void f() {
  var {true: int a} = g();
}

T g<T>() => throw 0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 28, 1),
    ]);
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: BooleanLiteral
          literal: true
          staticType: bool
        separator: :
        value: DeclaredVariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@28
            type: int
          matchedValueType: int
    rightBracket: }
    matchedValueType: Map<Object?, int>
    requiredType: Map<Object?, int>
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      staticElement: self::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: Map<Object?, int> Function()
    staticType: Map<Object?, int>
    typeArgumentTypes
      Map<Object?, int>
  patternTypeSchema: Map<_, int>
''');
  }
}

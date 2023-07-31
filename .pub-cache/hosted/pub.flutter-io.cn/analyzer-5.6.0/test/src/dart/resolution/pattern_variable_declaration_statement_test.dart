// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternVariableDeclarationStatementResolutionTest);
  });
}

@reflectiveTest
class PatternVariableDeclarationStatementResolutionTest
    extends PubPackageResolutionTest {
  test_final_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  final (num a) = 0;
  a;
}
''');
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: num
            staticElement: dart:core::@class::num
            staticType: null
          type: num
        name: a
        declaredElement: isFinal a@24
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: num
  semicolon: ;
''');
  }

  test_final_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  final (a) = 0;
  a;
}
''');
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@20
          type: int
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

  test_rewrite_expression() async {
    await assertErrorsInCode(r'''
void f() {
  var (a) = A();
}

class A {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
    ]);
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@18
          type: A
        matchedValueType: A
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
    patternTypeSchema: _
  semicolon: ;
''');
  }

  test_var_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (num a) = 0;
  a;
}
''');
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: num
            staticElement: dart:core::@class::num
            staticType: null
          type: num
        name: a
        declaredElement: a@22
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    equals: =
    expression: IntegerLiteral
      literal: 0
      staticType: int
    patternTypeSchema: num
  semicolon: ;
''');
  }

  test_var_typed_typeSchema() async {
    await assertErrorsInCode(r'''
void f() {
  var (int a) = g();
}

T g<T>() => throw 0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
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
  semicolon: ;
''');
  }

  test_var_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (a) = 0;
  a;
}
''');
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@18
          type: int
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

  test_var_untyped_multiple() async {
    await assertErrorsInCode(r'''
void f((int, String) x) {
  var (a, b) = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
    final node = findNode.singlePatternVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
PatternVariableDeclarationStatement
  declaration: PatternVariableDeclaration
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
  semicolon: ;
''');
  }

  test_var_withKeyword_final() async {
    await assertErrorsInCode(r'''
void f() {
  var (final a) = 0;
  a;
}
''', [
      error(
          CompileTimeErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT,
          18,
          5),
    ]);
  }

  test_var_withKeyword_var() async {
    await assertErrorsInCode(r'''
void f() {
  var (var a) = 0;
  a;
}
''', [
      error(
          CompileTimeErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT,
          18,
          3),
    ]);
  }
}

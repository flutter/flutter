// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithDeclaration);
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(
        ForElementResolutionTest_ForEachPartsWithPattern_await);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithDeclarations);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithPattern);
  });
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_optIn_fromOptOut() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A implements Iterable<int> {
  Iterator<int> iterator => throw 0;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {
  for (var v in a) {
    v;
  }
}
''');
  }

  test_withDeclaration_scope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i in [1, 2, 3]) i]; // 1
  <double>[for (var i in [1.1, 2.2, 3.3]) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.declaredIdentifier('i in [1, 2').declaredElement!,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.declaredIdentifier('i in [1.1').declaredElement!,
    );
  }

  test_withIdentifier_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
int v = 0;
main() {
  <int>[for (v in [1, 2, 3]) v];
}
''');
    assertElement(
      findNode.simple('v];'),
      findElement.topGet('v'),
    );
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@25
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@25
    staticType: dynamic
''');
  }

  test_iterable_List() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@35
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@35
    staticType: int
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  [for (var (a) in x) a];
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 38, 1),
    ]);
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@32
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@32
    staticType: dynamic
''');
  }

  test_iterableContextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var (int a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
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
        declaredElement: a@28
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@28
    staticType: int
''');
  }

  test_iterableContextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() {
  [for (var (a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@24
          type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<Object?> Function()
      staticType: Iterable<Object?>
      typeArgumentTypes
        Iterable<Object?>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@24
    staticType: Object?
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (final (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@37
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@37
    staticType: int
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (num a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
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
        declaredElement: a@39
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@39
    staticType: num
''');
  }

  test_topLevelVariableInitializer() async {
    await assertNoErrorsInCode(r'''
final x = [0, 1, 2];
final y = [ for (var (a) in x) a ];
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@43
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@getter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@43
    staticType: int
''');
  }

  test_topLevelVariableInitializer_scope() async {
    await assertNoErrorsInCode(r'''
final x = [0, 1, 2];
final y = [ for (var (x) in x) x ];
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: x
        declaredElement: hasImplicitType x@43
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@getter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: x
    staticElement: x@43
    staticType: int
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern_await
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) async {
  [await for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@37
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@37
    staticType: dynamic
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) async {
  [await for (var (a) in x) a];
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 50, 1),
    ]);
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@44
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@44
    staticType: dynamic
''');
  }

  test_iterable_Stream() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@49
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@49
    staticType: int
''');
  }

  test_iterableContextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() async {
  [await for (var (int a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
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
        declaredElement: a@40
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<int> Function()
      staticType: Stream<int>
      typeArgumentTypes
        Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@40
    staticType: int
''');
  }

  test_iterableContextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() async {
  [await for (var (a) in g()) a];
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@36
          type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: self::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<Object?> Function()
      staticType: Stream<Object?>
      typeArgumentTypes
        Stream<Object?>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@36
    staticType: Object?
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (final (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@51
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@51
    staticType: int
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  [await for (var (num a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
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
        declaredElement: a@53
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@53
    staticType: num
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithDeclarations
    extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  <int>[for (; b(); ) 0];
}
''');

    final node = findNode.functionExpressionInvocation('b()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: bool Function()
  staticType: bool
''');
  }

  test_declaredVariableScope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.variableDeclaration('i = 1;').declaredElement!,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.variableDeclaration('i = 1.1;').declaredElement!,
    );
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithPattern
    extends PubPackageResolutionTest {
  test_it() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  [for (var (a, b) = x; b; a--) 0];
}
''');

    final node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredElement: hasImplicitType a@37
                type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredElement: hasImplicitType b@40
                type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        staticElement: self::@function::f::@parameter::x
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      staticElement: b@40
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          staticElement: a@37
          staticType: null
        operator: --
        readElement: a@37
        readType: int
        writeElement: a@37
        writeType: int
        staticElement: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}

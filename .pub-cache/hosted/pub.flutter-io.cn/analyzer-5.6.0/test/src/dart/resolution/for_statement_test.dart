// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        ForStatementResolutionTest_ForEachPartsWithDeclaration);
    defineReflectiveTests(
        ForStatementResolutionTest_ForEachPartsWithIdentifier);
    defineReflectiveTests(ForStatementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(
        ForStatementResolutionTest_ForEachPartsWithPattern_await);
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithExpression);
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithPattern);
  });
}

/// TODO(scheglov) Move other for-in tests here.
@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest {
  test_iterable_contextType() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  for (int v in g()) {}
}

T g<T>() => throw 0;
''');

    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: v
      declaredElement: v@56
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
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_iterable_missing() async {
    await assertErrorsInCode(r'''
void f() {
  for (var v in) {
    v;
  }
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);

    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: v@22
    inKeyword: in
    iterable: SimpleIdentifier
      token: <empty> <synthetic>
      staticElement: <null>
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@22
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_loopVariable_dynamic() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (dynamic v in values) {
    v;
  }
}''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      type: NamedType
        name: SimpleIdentifier
          token: dynamic
          staticElement: dynamic@-1
          staticType: null
        type: dynamic
      name: v
      declaredElement: v@42
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: self::@function::f::@parameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@42
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_loopVariable_var_genericFunction() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  for (var v in g()) {}
}

T g<T>() => throw 0;
''');

    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: v@56
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
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_loopVariable_var_iterable() async {
    await resolveTestCode(r'''
void f(Iterable<int> values) {
  for (var v in values) {
    v;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: v@42
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: self::@function::f::@parameter::values
      staticType: Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@42
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_loopVariable_var_list() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (var v in values) {
    v;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: v@38
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: self::@function::f::@parameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@38
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_loopVariable_var_stream() async {
    await resolveTestCode(r'''
void f(Stream<int> values) async {
  await for (var v in values) {
    v;
  }
}''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: v@52
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: self::@function::f::@parameter::values
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@52
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  /// Test that the parameter `x` is in the scope of the iterable.
  /// But the declared identifier `x` is in the scope of the body.
  test_scope() async {
    await assertNoErrorsInCode('''
void f(List<List<int>> x) {
  for (var x in x.first) {
    x;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: x
      declaredElement: x@39
    inKeyword: in
    iterable: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: x
        staticElement: self::@function::f::@parameter::x
        staticType: List<List<int>>
      period: .
      identifier: SimpleIdentifier
        token: first
        staticElement: PropertyAccessorMember
          base: dart:core::@class::Iterable::@getter::first
          substitution: {E: List<int>, E: List<int>}
        staticType: List<int>
      staticElement: PropertyAccessorMember
        base: dart:core::@class::Iterable::@getter::first
        substitution: {E: List<int>, E: List<int>}
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: x
          staticElement: x@39
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_type_genericFunctionType() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (Null Function<T>(T, Null) e in <dynamic>[]) {
    e;
  }
}
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithIdentifier
    extends PubPackageResolutionTest {
  test_identifier_dynamic() async {
    await resolveTestCode(r'''
void f(var v, List<int> values) {
  for (v in values) {
    v;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      staticElement: self::@function::f::@parameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: self::@function::f::@parameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: self::@function::f::@parameter::v
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@24
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@24
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_List() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@34
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@34
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  for (var (a) in x) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 37, 1),
    ]);
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@31
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@31
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterableContextType_patternVariable_typed() async {
    await assertErrorsInCode(r'''
void f() {
  for (var (int a) in g()) {}
}

T g<T>() => throw 0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
    ]);
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
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
        declaredElement: a@27
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
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_iterableContextType_patternVariable_untyped() async {
    await assertErrorsInCode(r'''
void f() {
  for (var (a) in g()) {}
}

T g<T>() => throw 0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@23
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
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (final (a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@36
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@36
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (num a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
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
        declaredElement: a@38
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@38
          staticType: num
        semicolon: ;
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithPattern_await
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) async {
  await for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@36
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) async {
  await for (var (a) in x) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 49, 1),
    ]);
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@43
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@43
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_Stream() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@48
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@48
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterableContextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() async {
  await for (var (int a) in g()) {
    a;
  }
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
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
        declaredElement: a@39
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@39
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterableContextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() async {
  await for (var (a) in g()) {
    a;
  }
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@35
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@35
          staticType: Object?
        semicolon: ;
    rightBracket: }
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (final (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@50
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@50
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (var (num a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
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
        declaredElement: a@52
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
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@52
          staticType: num
        semicolon: ;
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForPartsWithExpression
    extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
void f(bool Function() b) {
  for (; b(); ) {}
}
''');

    final node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    leftSeparator: ;
    condition: FunctionExpressionInvocation
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
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_initialization_patternAssignment() async {
    await assertNoErrorsInCode(r'''
void f() {
  int a;
  for ((a) = 0;;) {
    a;
  }
}
''');

    final node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    initialization: PatternAssignment
      pattern: ParenthesizedPattern
        leftParenthesis: (
        pattern: AssignedVariablePattern
          name: a
          element: a@17
          matchedValueType: int
        rightParenthesis: )
        matchedValueType: int
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
      patternTypeSchema: int
      staticType: int
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@17
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForPartsWithPattern
    extends PubPackageResolutionTest {
  test_it() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  for (var (a, b) = x; b; a--) {
    a;
    b;
  }
}
''');

    final node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
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
              declaredElement: hasImplicitType a@36
                type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredElement: hasImplicitType b@39
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
      staticElement: b@39
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          staticElement: a@36
          staticType: null
        operator: --
        readElement: a@36
        readType: int
        writeElement: a@36
        writeType: int
        staticElement: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@36
          staticType: int
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: b
          staticElement: b@39
          staticType: bool
        semicolon: ;
    rightBracket: }
''');
  }
}

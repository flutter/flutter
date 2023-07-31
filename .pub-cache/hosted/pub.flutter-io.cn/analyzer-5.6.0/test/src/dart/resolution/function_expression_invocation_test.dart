// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionInvocationTest);
    defineReflectiveTests(FunctionExpressionInvocationWithoutNullSafetyTest);
  });
}

@reflectiveTest
class FunctionExpressionInvocationTest extends PubPackageResolutionTest {
  test_call_infer_fromArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  void call<T>(T t) {}
}

void f(A a) {
  a(0);
}
''');

    final node = findNode.functionExpressionInvocation('a(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::A::@method::call
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
''');
  }

  test_call_infer_fromArguments_listLiteral() async {
    await resolveTestCode(r'''
class A {
  List<T> call<T>(List<T> _)  {
    throw 42;
  }
}

main(A a) {
  a([0]);
}
''');

    final node = findNode.functionExpressionInvocation('a([');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::main::@parameter::a
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 0
            staticType: int
        rightBracket: ]
        parameter: ParameterMember
          base: root::@parameter::_
          substitution: {T: int}
        staticType: List<int>
    rightParenthesis: )
  staticElement: self::@class::A::@method::call
  staticInvokeType: List<int> Function(List<int>)
  staticType: List<int>
  typeArgumentTypes
    int
''');
  }

  test_call_infer_fromContext() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a, int context) {
  context = a();
}
''');

    final node = findNode.functionExpressionInvocation('a()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: self::@class::A::@method::call
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_call_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A {
  T call<T>() {
    throw 42;
  }
}

void f(A a) {
  a<int>();
}
''');

    final node = findNode.functionExpressionInvocation('a<int>()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: self::@class::A::@method::call
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_never() async {
    await assertErrorsInCode(r'''
void f(Never x) {
  x<int>(1 + 2);
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 20, 1),
      error(HintCode.DEAD_CODE, 26, 8),
    ]);

    final node = findNode.functionExpressionInvocation('x<int>(1 + 2)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: dart:core::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: Never
  typeArgumentTypes
    int
''');
  }

  test_neverQ() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  x<int>(1 + 2);
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE, 21, 1),
    ]);

    final node = findNode.functionExpressionInvocation('x<int>(1 + 2)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Never?
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: dart:core::@class::num::@method::+::@parameter::other
          staticType: int
        parameter: <null>
        staticElement: dart:core::@class::num::@method::+
        staticInvokeType: num Function(num)
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
  typeArgumentTypes
    int
''');
  }

  test_nullShorting() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo();
  }
}
''');

    final node = findNode.functionExpressionInvocation('a?.foo()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: a
      staticElement: self::@class::B::@method::bar::@parameter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function()
  staticType: int?
''');
  }

  test_nullShorting_extends() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int Function() get foo;
}

class B {
  void bar(A? a) {
    a?.foo().isEven;
  }
}
''');

    var node = findNode.propertyAccess('isEven');
    assertResolvedNodeText(node, r'''
PropertyAccess
  target: FunctionExpressionInvocation
    function: PropertyAccess
      target: SimpleIdentifier
        token: a
        staticElement: self::@class::B::@method::bar::@parameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: foo
        staticElement: self::@class::A::@getter::foo
        staticType: int Function()
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function()
    staticType: int
  operator: .
  propertyName: SimpleIdentifier
    token: isEven
    staticElement: dart:core::@class::int::@getter::isEven
    staticType: bool
  staticType: bool?
''');
  }

  test_on_switchExpression() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    _ => foo,
  }());
}

void foo() {}
''');

    final node = findNode.functionExpressionInvocation('}()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: SimpleIdentifier
          token: foo
          staticElement: self::@function::foo
          staticType: void Function()
    rightBracket: }
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_record_field_named() async {
    await assertNoErrorsInCode(r'''
void f(({void Function(int) foo}) r) {
  r.foo(0);
}
''');

    final node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({void Function(int) foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: void Function(int)
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_record_field_positional_rewrite() async {
    await assertNoErrorsInCode(r'''
void f((void Function(int),) r) {
  r.$1(0);
}
''');

    final node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (void Function(int))
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      staticType: void Function(int)
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_record_field_positional_withParenthesis() async {
    await assertNoErrorsInCode(r'''
void f((void Function(int),) r) {
  (r.$1)(0);
}
''');

    final node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: PropertyAccess
      target: SimpleIdentifier
        token: r
        staticElement: self::@function::f::@parameter::r
        staticType: (void Function(int))
      operator: .
      propertyName: SimpleIdentifier
        token: $1
        staticElement: <null>
        staticType: void Function(int)
      staticType: void Function(int)
    rightParenthesis: )
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
  }
}

@reflectiveTest
class FunctionExpressionInvocationWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_dynamic_withoutTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)(0);
}
''');

    final node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: AsExpression
      expression: SimpleIdentifier
        token: main
        staticElement: self::@function::main
        staticType: dynamic Function()*
      asOperator: as
      type: NamedType
        name: SimpleIdentifier
          token: dynamic
          staticElement: dynamic@-1
          staticType: null
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_dynamic_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  (main as dynamic)<bool, int>(0);
}
''');

    final node = findNode.functionExpressionInvocation('(0)');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: ParenthesizedExpression
    leftParenthesis: (
    expression: AsExpression
      expression: SimpleIdentifier
        token: main
        staticElement: self::@function::main
        staticType: dynamic Function()*
      asOperator: as
      type: NamedType
        name: SimpleIdentifier
          token: dynamic
          staticElement: dynamic@-1
          staticType: null
        type: dynamic
      staticType: dynamic
    rightParenthesis: )
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: bool
          staticElement: dart:core::@class::bool
          staticType: null
        type: bool*
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int*
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
  typeArgumentTypes
    bool*
    int*
''');
  }
}

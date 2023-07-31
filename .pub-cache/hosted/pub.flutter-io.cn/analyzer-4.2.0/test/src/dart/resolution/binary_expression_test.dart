// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BinaryExpressionResolutionTest);
  });
}

@reflectiveTest
class BinaryExpressionResolutionTest extends PubPackageResolutionTest
    with BinaryExpressionResolutionTestCases {
  test_ifNull_left_nullableContext() async {
    await assertNoErrorsInCode(r'''
T f<T>(T t) => t;

int g() => f(null) ?? 0;
''');

    assertResolvedNodeText(findNode.binary('?? 0'), r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        NullLiteral
          literal: null
          parameter: ParameterMember
            base: root::@parameter::t
            substitution: {T: int?}
          staticType: Null
      rightParenthesis: )
    staticInvokeType: int? Function(int?)
    staticType: int?
    typeArgumentTypes
      int?
  operator: ??
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: int
''');
  }

  test_ifNull_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
void f(int? x, int y) {
  x ?? y;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? y'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: int
''');
  }

  test_ifNull_nullableInt_nullableDouble() async {
    await assertNoErrorsInCode(r'''
void f(int? x, double? y) {
  x ?? y;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? y'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: double?
  staticElement: <null>
  staticInvokeType: null
  staticType: num?
''');
  }

  test_ifNull_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x ?? x;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? x'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: x
    parameter: <null>
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  staticElement: <null>
  staticInvokeType: null
  staticType: int?
''');
  }

  test_plus_int_never() async {
    await assertNoErrorsInCode('''
f(int a, Never b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: Never
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_never_int() async {
    await assertErrorsInCode(r'''
f(Never a, int b) {
  a + b;
}
''', [
      error(HintCode.RECEIVER_OF_TYPE_NEVER, 22, 1),
      error(HintCode.DEAD_CODE, 26, 2),
    ]);

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Never
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: Never
''');
  }
}

mixin BinaryExpressionResolutionTestCases on PubPackageResolutionTest {
  test_bangEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a != b;
}
''');

    assertResolvedNodeText(findNode.binary('a != b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: !=
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::==::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_bangEq_extensionOverride_left() async {
    await assertErrorsInCode(r'''
extension E on int {}

void f(int a) {
  E(a) != 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 46, 2),
    ]);

    assertResolvedNodeText(findNode.binary('!= 0'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int
      rightParenthesis: )
    extendedType: int
    staticType: null
  operator: !=
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_bangEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a !== b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertResolvedNodeText(findNode.binary('a !== b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: !==
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_eqEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a == b;
}
''');

    assertResolvedNodeText(findNode.binary('a == b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: ==
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::==::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_extensionOverride_left() async {
    await assertErrorsInCode(r'''
extension E on int {}

void f(int a) {
  E(a) == 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 46, 2),
    ]);

    assertResolvedNodeText(findNode.binary('== 0'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int
      rightParenthesis: )
    extendedType: int
    staticType: null
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_eqEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a === b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertResolvedNodeText(findNode.binary('a === b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: ===
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_ifNull() async {
    var question = isNullSafetyEnabled ? '?' : '';
    await assertNoErrorsInCode('''
f(int$question a, double b) {
  a ?? b;
}
''');

    assertResolvedNodeText(findNode.binary('a ?? b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: <null>
  staticInvokeType: null
  staticType: num
''');
  }

  test_logicalAnd() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a && b;
}
''');

    assertResolvedNodeText(findNode.binary('a && b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: bool
  operator: &&
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_logicalOr() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a || b;
}
''');

    assertResolvedNodeText(findNode.binary('a || b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: bool
  operator: ||
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_minus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a - f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_minus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a - b;
}
''');

    assertResolvedNodeText(findNode.binary('a - b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: -
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::-::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::-
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_minus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a - b;
}
''');

    assertResolvedNodeText(findNode.binary('a - b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: -
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::-::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::-
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_mod_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a % f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_mod_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a % b;
}
''');

    assertResolvedNodeText(findNode.binary('a % b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: %
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::%::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::%
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_mod_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a % b;
}
''');

    assertResolvedNodeText(findNode.binary('a % b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: %
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::%::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::%
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_double_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
}
h(double x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_double_context_int() async {
    await assertErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 7),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_double_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  a + f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_double_dynamic() async {
    await assertNoErrorsInCode(r'''
f(double a, dynamic b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::double::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: dynamic
  staticElement: dart:core::@class::double::@method::+
  staticInvokeType: double Function(num)
  staticType: double
''');
  }

  test_plus_int_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a + f());
}
h(double x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'double', legacy: 'num')]);
  }

  test_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a + f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_plus_int_context_int_target_rewritten() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a() + f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_plus_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
extension E on int {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a) + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 98, 10),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a + f();
}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_plus_int_dynamic() async {
    await assertNoErrorsInCode(r'''
f(int a, dynamic b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: dynamic
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_int_int_target_rewritten() async {
    await assertNoErrorsInCode('''
f(int Function() a, int b) {
  a() + b;
}
''');

    assertResolvedNodeText(findNode.binary('a() + b'), r'''
BinaryExpression
  leftOperand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function()
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
extension E on int {
  String operator+(int other) => '';
}
f(int a, int b) {
  E(a) + b;
}
''');

    assertResolvedNodeText(findNode.binary('E(a) + b'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int
      rightParenthesis: )
    extendedType: int
    staticType: null
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extension::E::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_plus_int_num() async {
    await assertNoErrorsInCode(r'''
f(int a, num b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: num
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_num_context_int() async {
    await assertErrorsInCode(
        '''
T f<T>() => throw Error();
g(num a) {
  h(a + f());
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 7),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_other_context_int() async {
    await assertErrorsInCode(
        '''
abstract class A {
  num operator+(String x);
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 88, 7),
        ], legacy: []));

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['String']);
  }

  test_plus_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a) + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 10),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 7),
    ]);

    assertTypeArgumentTypes(findNode.methodInvocation('f()'), ['num']);
  }

  test_plus_other_double() async {
    await assertNoErrorsInCode('''
abstract class A {
  String operator+(double other);
}
f(A a, double b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@class::A::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: self::@class::A::@method::+
  staticInvokeType: String Function(double)
  staticType: String
''');
  }

  test_plus_other_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String operator+(int other) => '';
}
f(A a, int b) {
  E(a) + b;
}
''');

    assertResolvedNodeText(findNode.binary('E(a) + b'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    extensionName: SimpleIdentifier
      token: E
      staticElement: self::@extension::E
      staticType: null
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    extendedType: A
    staticType: null
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extension::E::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_plus_other_int_via_extension_implicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String operator+(int other) => '';
}
f(A a, int b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extension::E::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_receiverTypeParameter_bound_dynamic() async {
    await assertNoErrorsInCode(r'''
f<T extends dynamic>(T a) {
  a + 0;
}
''');

    assertResolvedNodeText(findNode.binary('a + 0'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: T
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_receiverTypeParameter_bound_num() async {
    await assertNoErrorsInCode(r'''
f<T extends num>(T a) {
  a + 0;
}
''');

    assertResolvedNodeText(findNode.binary('a + 0'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: T
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_slash() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a / b;
}
''');

    assertResolvedNodeText(findNode.binary('a / b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: /
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::/::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::/
  staticInvokeType: double Function(num)
  staticType: double
''');
  }

  test_star_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a * f());
}
h(int x) {}
''');

    assertTypeArgumentTypes(findNode.methodInvocation('f()'),
        [typeStringByNullability(nullable: 'int', legacy: 'num')]);
  }

  test_star_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a * b;
}
''');

    assertResolvedNodeText(findNode.binary('a * b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::*::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_star_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a * b;
}
''');

    assertResolvedNodeText(findNode.binary('a * b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::*::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: int
''');
  }
}

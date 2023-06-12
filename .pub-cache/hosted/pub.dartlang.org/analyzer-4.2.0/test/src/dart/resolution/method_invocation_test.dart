// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodInvocationResolutionWithoutNullSafetyTest);
    defineReflectiveTests(MethodInvocationResolutionTest);
  });
}

@reflectiveTest
class MethodInvocationResolutionTest extends PubPackageResolutionTest
    with MethodInvocationResolutionTestCases {
  test_hasReceiver_deferredImportPrefix_loadLibrary_optIn_fromOptOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.7
import 'a.dart' deferred as a;

main() {
  a.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 22, 8),
    ]);

    var node = findNode.methodInvocation('loadLibrary()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@prefix::a
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: FunctionMember
      base: loadLibrary@-1
      isLegacy: true
    staticType: Future<dynamic>* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic>* Function()*
  staticType: Future<dynamic>*
''');
  }

  test_hasReceiver_interfaceQ_Function_call_checked() async {
    await assertNoErrorsInCode(r'''
void f(Function? foo) {
  foo?.call();
}
''');

    var node = findNode.methodInvocation('foo?.call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@function::f::@parameter::foo
    staticType: Function?
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_interfaceQ_Function_call_unchecked() async {
    await assertErrorsInCode(r'''
void f(Function? foo) {
  foo.call();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          30, 4),
    ]);

    var node = findNode.methodInvocation('foo.call()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@function::f::@parameter::foo
    staticType: Function?
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_interfaceQ_nullShorting() async {
    await assertNoErrorsInCode(r'''
class C {
  C foo() => throw 0;
  C bar() => throw 0;
}

void testShort(C? c) {
  c?.foo().bar();
}
''');

    var node = findNode.methodInvocation('bar();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: MethodInvocation
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::testShort::@parameter::c
      staticType: C?
    operator: ?.
    methodName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@method::foo
      staticType: C Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: C Function()
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: bar
    staticElement: self::@class::C::@method::bar
    staticType: C Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: C Function()
  staticType: C?
''');
  }

  test_hasReceiver_interfaceQ_nullShorting_getter() async {
    await assertNoErrorsInCode(r'''
abstract class C {
  void Function(C) get foo;
}

void f(C? c) {
  c?.foo(c);
}
''');

    var node = findNode.functionExpressionInvocation('foo(c);');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C?
    operator: ?.
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: void Function(C)
    staticType: void Function(C)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: c
        parameter: root::@parameter::
        staticElement: self::@function::f::@parameter::c
        staticType: C
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(C)
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_enum() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  void foo() {}
}

void f(E e) {
  e.foo();
}
''');

    var node = findNode.methodInvocation('e.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: e
    staticElement: self::@function::f::@parameter::e
    staticType: E
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@enum::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceType_enum_fromMixin() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  void foo() {}
}

enum E with M {
  v;
}

void f(E e) {
  e.foo();
}
''');

    var node = findNode.methodInvocation('e.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: e
    staticElement: self::@function::f::@parameter::e
    staticType: E
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@mixin::M::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceTypeQ_defined() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          48, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceTypeQ_defined_extension() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          86, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_interfaceTypeQ_defined_extensionQ2() async {
    await assertNoErrorsInCode(r'''
extension E<T> on T? {
  T foo() => throw 0;
}

void f(int? a) {
  a.foo();
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: MethodMember
      base: self::@extension::E::@method::foo
      substitution: {T: int}
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined() async {
    await assertErrorsInCode(r'''
class A {}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          31, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extension() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE,
          69, 3),
    ]);

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
  }

  test_hasReceiver_interfaceTypeQ_notDefined_extensionQ() async {
    await assertNoErrorsInCode(r'''
class A {}

extension E on A? {
  void foo() {}
}

void f(A? a) {
  a.foo();
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@extension::E::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_hasReceiver_typeAlias_staticMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

typedef B = A;

void f() {
  B.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_typeAlias_staticMethod_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  static void foo(int _) {}
}

typedef B<T> = A<T>;

void f() {
  B.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: B
    staticElement: self::@typeAlias::B
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
  }

  test_hasReceiver_typeParameter_promotedToNonNullable() async {
    await assertNoErrorsInCode('''
void f<T>(T? t) {
  if (t is int) {
    t.abs();
  }
}
''');

    var node = findNode.methodInvocation('t.abs()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: t
    staticElement: self::@function::f::@parameter::t
    staticType: T & int
  operator: .
  methodName: SimpleIdentifier
    token: abs
    staticElement: dart:core::@class::int::@method::abs
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: int Function()
  staticType: int
''');
  }

  test_hasReceiver_typeParameter_promotedToOtherTypeParameter() async {
    await assertNoErrorsInCode('''
abstract class A {}

abstract class B extends A {
  void foo();
}

void f<T extends A, U extends B>(T a) {
  if (a is U) {
    a.foo();
  }
}
''');

    var node = findNode.methodInvocation('a.foo()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: T & U
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::B::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_namedArgument_anywhere() async {
    await assertNoErrorsInCode('''
class A {}
class B {}
class C {}
class D {}

void foo(A a, B b, {C? c, D? d}) {}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  foo(g1(), c: g3(), g2(), d: g4());
}
''');

    var node = findNode.methodInvocation('foo(g');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(A, B, {C? c, D? d})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          staticElement: self::@function::g1
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: self::@function::foo::@parameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: c
            staticElement: self::@function::foo::@parameter::c
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            staticElement: self::@function::g3
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        parameter: self::@function::foo::@parameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          staticElement: self::@function::g2
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: self::@function::foo::@parameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: d
            staticElement: self::@function::foo::@parameter::d
            staticType: null
          colon: :
        expression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            staticElement: self::@function::g4
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        parameter: self::@function::foo::@parameter::d
    rightParenthesis: )
  staticInvokeType: void Function(A, B, {C? c, D? d})
  staticType: void
''');
  }

  test_nullShorting_cascade_firstMethodInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo()..bar();
}
''');

    var node = findNode.cascade('a?..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  cascadeSections
    MethodInvocation
      operator: ?..
      methodName: SimpleIdentifier
        token: foo
        staticElement: self::@class::A::@method::foo
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: bar
        staticElement: self::@class::A::@method::bar
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
  staticType: A?
''');
  }

  test_nullShorting_cascade_firstPropertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
  int bar() => 0;
}

void f(A? a) {
  a?..foo..bar();
}
''');

    var node = findNode.cascade('a?..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A?
  cascadeSections
    PropertyAccess
      operator: ?..
      propertyName: SimpleIdentifier
        token: foo
        staticElement: self::@class::A::@getter::foo
        staticType: int
      staticType: int
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: bar
        staticElement: self::@class::A::@method::bar
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
  staticType: A?
''');
  }

  test_nullShorting_cascade_nullAwareInside() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() => 0;
}

main() {
  A a = A()..foo()?.abs();
  a;
}
''');

    var node = findNode.cascade('A()..');
    assertResolvedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: A
          staticElement: self::@class::A
          staticType: null
        type: A
      staticElement: self::@class::A::@constructor::•
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A
  cascadeSections
    MethodInvocation
      target: MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: foo
          staticElement: self::@class::A::@method::foo
          staticType: int? Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int? Function()
        staticType: int?
      operator: ?.
      methodName: SimpleIdentifier
        token: abs
        staticElement: dart:core::@class::int::@method::abs
        staticType: int Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
  staticType: A
''');
  }

  test_typeArgumentTypes_generic_inferred_leftTop_dynamic() async {
    await assertNoErrorsInCode('''
void foo<T extends Object>(T? value) {}

void f(dynamic o) {
  foo(o);
}
''');

    var node = findNode.methodInvocation('foo(o)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T extends Object>(T?)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        parameter: ParameterMember
          base: root::@parameter::value
          substitution: {T: Object}
        staticElement: self::@function::f::@parameter::o
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: void Function(Object?)
  staticType: void
  typeArgumentTypes
    Object
''');
  }

  test_typeArgumentTypes_generic_inferred_leftTop_void() async {
    await assertNoErrorsInCode('''
void foo<T extends Object>(List<T?> value) {}

void f(List<void> o) {
  foo(o);
}
''');

    var node = findNode.methodInvocation('foo(o)');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T extends Object>(List<T?>)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: o
        parameter: ParameterMember
          base: root::@parameter::value
          substitution: {T: Object}
        staticElement: self::@function::f::@parameter::o
        staticType: List<void>
    rightParenthesis: )
  staticInvokeType: void Function(List<Object?>)
  staticType: void
  typeArgumentTypes
    Object
''');
  }
}

mixin MethodInvocationResolutionTestCases on PubPackageResolutionTest {
  test_clamp_double_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''');

    var node = findNode.methodInvocation('h(a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(double)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: double
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: double Function()
              staticType: double
              typeArgumentTypes
                double
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: double Function()
              staticType: double
              typeArgumentTypes
                double
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num Function(num, num)
        staticType: double
    rightParenthesis: )
  staticInvokeType: dynamic Function(double)
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(double*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: double*
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: MethodMember
            base: dart:core::@class::num::@method::clamp
            isLegacy: true
          staticType: num* Function(num*, num*)*
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::lowerLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::upperLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num* Function(num*, num*)*
        staticType: num*
    rightParenthesis: )
  staticInvokeType: dynamic Function(double*)*
  staticType: dynamic
''');
    }
  }

  test_clamp_double_context_int() async {
    await assertErrorsInCode(
        '''
T f<T>() => throw Error();
g(double a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 17),
        ], legacy: []));

    var node = findNode.methodInvocation('h(a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: double
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num Function(num, num)
        staticType: num
    rightParenthesis: )
  staticInvokeType: dynamic Function(int)
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: double*
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: MethodMember
            base: dart:core::@class::num::@method::clamp
            isLegacy: true
          staticType: num* Function(num*, num*)*
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::lowerLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::upperLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num* Function(num*, num*)*
        staticType: num*
    rightParenthesis: )
  staticInvokeType: dynamic Function(int*)*
  staticType: dynamic
''');
    }
  }

  test_clamp_double_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  a.clamp(f(), f());
}
''');

    var node = findNode.methodInvocation('a.clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: double*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T* Function<T>()*
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: root::@parameter::lowerLimit
        staticInvokeType: num* Function()*
        staticType: num*
        typeArgumentTypes
          num*
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T* Function<T>()*
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: root::@parameter::upperLimit
        staticInvokeType: num* Function()*
        staticType: num*
        typeArgumentTypes
          num*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_double_double_double() async {
    await assertNoErrorsInCode('''
f(double a, double b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_double_double_int() async {
    await assertNoErrorsInCode('''
f(double a, double b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_double_int_double() async {
    await assertNoErrorsInCode('''
f(double a, int b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_double_int_int() async {
    await assertNoErrorsInCode('''
f(double a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_context_double() async {
    await assertErrorsInCode(
        '''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(double x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 17),
        ], legacy: []));

    var node = findNode.methodInvocation('h(a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(double)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: int
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: num Function()
              staticType: num
              typeArgumentTypes
                num
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num Function(num, num)
        staticType: num
    rightParenthesis: )
  staticInvokeType: dynamic Function(double)
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(double*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: int*
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: MethodMember
            base: dart:core::@class::num::@method::clamp
            isLegacy: true
          staticType: num* Function(num*, num*)*
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::lowerLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::upperLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num* Function(num*, num*)*
        staticType: num*
    rightParenthesis: )
  staticInvokeType: dynamic Function(double*)*
  staticType: dynamic
''');
    }
  }

  test_clamp_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('h(a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: int
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: dart:core::@class::num::@method::clamp
          staticType: num Function(num, num)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
              staticInvokeType: int Function()
              staticType: int
              typeArgumentTypes
                int
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
              staticInvokeType: int Function()
              staticType: int
              typeArgumentTypes
                int
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num Function(num, num)
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic Function(int)
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: int*
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: MethodMember
            base: dart:core::@class::num::@method::clamp
            isLegacy: true
          staticType: num* Function(num*, num*)*
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::lowerLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: root::@parameter::upperLimit
              staticInvokeType: num* Function()*
              staticType: num*
              typeArgumentTypes
                num*
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num* Function(num*, num*)*
        staticType: num*
    rightParenthesis: )
  staticInvokeType: dynamic Function(int*)*
  staticType: dynamic
''');
    }
  }

  test_clamp_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a.clamp(f(), f());
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticInvokeType: num Function()
        staticType: num
        typeArgumentTypes
          num
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T* Function<T>()*
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: root::@parameter::lowerLimit
        staticInvokeType: num* Function()*
        staticType: num*
        typeArgumentTypes
          num*
      MethodInvocation
        methodName: SimpleIdentifier
          token: f
          staticElement: self::@function::f
          staticType: T* Function<T>()*
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: root::@parameter::upperLimit
        staticInvokeType: num* Function()*
        staticType: num*
        typeArgumentTypes
          num*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_double_double() async {
    await assertNoErrorsInCode('''
f(int a, double b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_double_dynamic() async {
    await assertNoErrorsInCode('''
f(int a, double b, dynamic c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_double_int() async {
    await assertNoErrorsInCode('''
f(int a, double b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: double*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_dynamic_double() async {
    await assertNoErrorsInCode('''
f(int a, dynamic b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: dynamic
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: dynamic
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_dynamic_int() async {
    await assertNoErrorsInCode('''
f(int a, dynamic b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: dynamic
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: dynamic
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_int_double() async {
    await assertNoErrorsInCode('''
f(int a, int b, double c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: double*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_int_dynamic() async {
    await assertNoErrorsInCode('''
f(int a, int b, dynamic c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: dynamic
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_int_int() async {
    await assertNoErrorsInCode('''
f(int a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_int_int_from_cascade() async {
    await assertErrorsInCode(
        '''
f(int a, int b, int c) {
  a..clamp(b, c).isEven;
}
''',
        expectedErrorsByNullability(nullable: [], legacy: [
          error(CompileTimeErrorCode.UNDEFINED_GETTER, 42, 6),
        ]));

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
extension E on int {
  String clamp(int x, int y) => '';
}
f(int a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
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
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@extension::E::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@extension::E::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: self::@extension::E::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
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
          staticType: int*
      rightParenthesis: )
    extendedType: int*
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@extension::E::@method::clamp
    staticType: String* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@extension::E::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: self::@extension::E::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: String* Function(int*, int*)*
  staticType: String*
''');
    }
  }

  test_clamp_int_int_never() async {
    await assertNoErrorsInCode('''
f(int a, int b, Never c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: Never
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: Null*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_int_never_int() async {
    await assertErrorsInCode(
        '''
f(int a, Never b, int c) {
  a.clamp(b, c);
}
''',
        expectedErrorsByNullability(nullable: [
          error(HintCode.DEAD_CODE, 40, 3),
        ], legacy: []));

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: dart:core::@class::num::@method::clamp
    staticType: num Function(num, num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::clamp::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: Never
      SimpleIdentifier
        token: c
        parameter: dart:core::@class::num::@method::clamp::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num, num)
  staticType: num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: MethodMember
      base: dart:core::@class::num::@method::clamp
      isLegacy: true
    staticType: num* Function(num*, num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::lowerLimit
        staticElement: self::@function::f::@parameter::b
        staticType: Null*
      SimpleIdentifier
        token: c
        parameter: root::@parameter::upperLimit
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*, num*)*
  staticType: num*
''');
    }
  }

  test_clamp_never_int_int() async {
    await assertErrorsInCode(
        '''
f(Never a, int b, int c) {
  a.clamp(b, c);
}
''',
        expectedErrorsByNullability(nullable: [
          error(HintCode.RECEIVER_OF_TYPE_NEVER, 29, 1),
          error(HintCode.DEAD_CODE, 36, 7),
        ], legacy: [
          error(CompileTimeErrorCode.UNDEFINED_METHOD, 31, 5),
        ]));

    var node = findNode.methodInvocation('clamp');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Never
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <null>
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: <null>
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: Never
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Null*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <null>
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: <null>
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_clamp_other_context_int() async {
    await assertErrorsInCode(
        '''
abstract class A {
  num clamp(String x, String y);
}
T f<T>() => throw Error();
g(A a) {
  h(a.clamp(f(), f()));
}
h(int x) {}
''',
        expectedErrorsByNullability(nullable: [
          error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 94, 17),
        ], legacy: []));

    var node = findNode.methodInvocation('h(a');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: A
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: self::@class::A::@method::clamp
          staticType: num Function(String, String)
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: self::@class::A::@method::clamp::@parameter::x
              staticInvokeType: String Function()
              staticType: String
              typeArgumentTypes
                String
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T Function<T>()
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: self::@class::A::@method::clamp::@parameter::y
              staticInvokeType: String Function()
              staticType: String
              typeArgumentTypes
                String
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num Function(String, String)
        staticType: num
    rightParenthesis: )
  staticInvokeType: dynamic Function(int)
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: h
    staticElement: self::@function::h
    staticType: dynamic Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        target: SimpleIdentifier
          token: a
          staticElement: self::@function::g::@parameter::a
          staticType: A*
        operator: .
        methodName: SimpleIdentifier
          token: clamp
          staticElement: self::@class::A::@method::clamp
          staticType: num* Function(String*, String*)*
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: self::@class::A::@method::clamp::@parameter::x
              staticInvokeType: String* Function()*
              staticType: String*
              typeArgumentTypes
                String*
            MethodInvocation
              methodName: SimpleIdentifier
                token: f
                staticElement: self::@function::f
                staticType: T* Function<T>()*
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
              parameter: self::@class::A::@method::clamp::@parameter::y
              staticInvokeType: String* Function()*
              staticType: String*
              typeArgumentTypes
                String*
          rightParenthesis: )
        parameter: self::@function::h::@parameter::x
        staticInvokeType: num* Function(String*, String*)*
        staticType: num*
    rightParenthesis: )
  staticInvokeType: dynamic Function(int*)*
  staticType: dynamic
''');
    }
  }

  test_clamp_other_int_int() async {
    await assertNoErrorsInCode('''
abstract class A {
  String clamp(int x, int y);
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@class::A::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@class::A::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: self::@class::A::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@class::A::@method::clamp
    staticType: String* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@class::A::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: self::@class::A::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: String* Function(int*, int*)*
  staticType: String*
''');
    }
  }

  test_clamp_other_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  E(a).clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
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
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@extension::E::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@extension::E::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: self::@extension::E::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: ExtensionOverride
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
          staticType: A*
      rightParenthesis: )
    extendedType: A*
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@extension::E::@method::clamp
    staticType: String* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@extension::E::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: self::@extension::E::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: String* Function(int*, int*)*
  staticType: String*
''');
    }
  }

  test_clamp_other_int_int_via_extension_implicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String clamp(int x, int y) => '';
}
f(A a, int b, int c) {
  a.clamp(b, c);
}
''');

    var node = findNode.methodInvocation('clamp(b');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@extension::E::@method::clamp
    staticType: String Function(int, int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@extension::E::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int
      SimpleIdentifier
        token: c
        parameter: self::@extension::E::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int
    rightParenthesis: )
  staticInvokeType: String Function(int, int)
  staticType: String
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A*
  operator: .
  methodName: SimpleIdentifier
    token: clamp
    staticElement: self::@extension::E::@method::clamp
    staticType: String* Function(int*, int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: self::@extension::E::@method::clamp::@parameter::x
        staticElement: self::@function::f::@parameter::b
        staticType: int*
      SimpleIdentifier
        token: c
        parameter: self::@extension::E::@method::clamp::@parameter::y
        staticElement: self::@function::f::@parameter::c
        staticType: int*
    rightParenthesis: )
  staticInvokeType: String* Function(int*, int*)*
  staticType: String*
''');
    }
  }

  test_demoteType() async {
    await assertNoErrorsInCode(r'''
void test<T>(T t) {}

void f<S>(S s) {
  if (s is int) {
    test(s);
  }
}

''');

    var node = findNode.methodInvocation('test(s)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: test
    staticElement: self::@function::test
    staticType: void Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        parameter: ParameterMember
          base: root::@parameter::t
          substitution: {T: S}
        staticElement: self::@function::f::@parameter::s
        staticType: S & int
    rightParenthesis: )
  staticInvokeType: void Function(S)
  staticType: void
  typeArgumentTypes
    S
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: test
    staticElement: self::@function::test
    staticType: void Function<T>(T*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        parameter: ParameterMember
          base: root::@parameter::t
          substitution: {T: S*}
        staticElement: self::@function::f::@parameter::s
        staticType: S* & int*
    rightParenthesis: )
  staticInvokeType: void Function(S*)*
  staticType: void
  typeArgumentTypes
    S*
''');
    }
  }

  test_error_ambiguousImport_topFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(int _) {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
void foo(int _) {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

main() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 46, 3),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@function::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@function::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_error_ambiguousImport_topFunction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo(int _) {}
''');
    newFile('$testPackageLibPath/b.dart', r'''
void foo(int _) {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as p;
import 'b.dart' as p;

main() {
  p.foo(0);
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 58, 3),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@function::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@function::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_error_instanceAccessToStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo(int _) {}
}

void f(A a) {
  a.foo(0);
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 59, 3),
    ]);

    var node = findNode.methodInvocation('a.foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_error_invocationOfNonFunction_interface_hasCall_field() async {
    await assertErrorsInCode(r'''
class C {
  void Function() call = throw Error();
}

void f(C c) {
  c();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 69, 1),
    ]);

    var node = findNode.functionExpressionInvocation('c();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_instance() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;
}

void f(C c) {
  c.foo();
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: dynamic
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: dynamic
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  var foo;
}

class B extends A {
  main() {
    foo();
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_OK_dynamicGetter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  var foo;

  main() {
    foo();
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_OK_Function() async {
    await assertNoErrorsInCode(r'''
f(Function foo) {
  foo(1, 2);
}
''');

    var node = findNode.functionExpressionInvocation('foo(1, 2);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::f::@parameter::foo
    staticType: Function
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int
      IntegerLiteral
        literal: 2
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::f::@parameter::foo
    staticType: Function*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int*
      IntegerLiteral
        literal: 2
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_OK_functionTypeTypeParameter() async {
    await assertNoErrorsInCode(r'''
typedef MyFunction = double Function(int _);

class C<T extends MyFunction> {
  T foo;
  C(this.foo);

  main() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: double Function(int)
      alias: self::@typeAlias::MyFunction
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::_
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
    alias: self::@typeAlias::MyFunction
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: double* Function(int*)*
      alias: self::@typeAlias::MyFunction
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
    alias: self::@typeAlias::MyFunction
  staticType: double*
''');
    }
  }

  test_error_invocationOfNonFunction_parameter() async {
    await assertErrorsInCode(r'''
main(Object foo) {
  foo();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 21, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::main::@parameter::foo
    staticType: Object
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::main::@parameter::foo
    staticType: Object*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_parameter_dynamic() async {
    await assertNoErrorsInCode(r'''
main(var foo) {
  foo();
}
''');

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::main::@parameter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::main::@parameter::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_static_hasTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;
}

main() {
  C.foo();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 46, 5),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: int
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: int*
    staticType: int*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_static_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;

  main() {
    foo();
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 48, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: int*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_invocationOfNonFunction_super_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  main() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 68, 9),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: int
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: int*
    staticType: int*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_prefixIdentifierNotFollowedByDot() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix?.foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 6),
    ]);

    var node = findNode.methodInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@function::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@function::foo
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  test_error_prefixIdentifierNotFollowedByDot_deferred() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math?.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 49, 4),
    ]);

    var node = findNode.methodInvocation('loadLibrary()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: loadLibrary@-1
    staticType: Future<dynamic> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>?
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: ?.
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: FunctionMember
      base: loadLibrary@-1
      isLegacy: true
    staticType: Future<dynamic>* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic>* Function()*
  staticType: Future<dynamic>*
''');
    }
  }

  test_error_prefixIdentifierNotFollowedByDot_invoke() async {
    await assertErrorsInCode(r'''
import 'dart:math' as foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 3),
    ]);

    var node = findNode.methodInvocation('foo()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@prefix::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@prefix::foo
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedFunction() async {
    await assertErrorsInCode(r'''
main() {
  foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 11, 3),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedFunction_hasTarget_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 45, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedIdentifier_target() async {
    await assertErrorsInCode(r'''
main() {
  bar.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 11, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: bar
    staticElement: <null>
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: bar
    staticElement: <null>
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_hasTarget_class() async {
    await assertErrorsInCode(r'''
class C {}
main() {
  C.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_hasTarget_class_arguments() async {
    await assertErrorsInCode(r'''
class C {}

int x = 0;
main() {
  C.foo(x);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 36, 3),
    ]);

    var node = findNode.methodInvocation('foo(x);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
        parameter: <null>
        staticElement: self::@getter::x
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
        parameter: <null>
        staticElement: self::@getter::x
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
    assertTopGetRef('x)', 'x');
  }

  test_error_undefinedMethod_hasTarget_class_inSuperclass() async {
    await assertErrorsInCode(r'''
class S {
  static void foo(int _) {}
}

class C extends S {}

main() {
  C.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 76, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_hasTarget_class_typeArguments() async {
    await assertErrorsInCode(r'''
class C {}

main() {
  C.foo<int>();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);

    var node = findNode.methodInvocation('foo<int>();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
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
  staticInvokeType: dynamic
  staticType: dynamic
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int*
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
  typeArgumentTypes
    int*
''');
    }
  }

  test_error_undefinedMethod_hasTarget_class_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  static main() => C.T();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 34, 1),
    ]);

    var node = findNode.methodInvocation('C.T();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: T
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: T
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_hasTarget_instance() async {
    await assertErrorsInCode(r'''
main() {
  42.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 14, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 42
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: IntegerLiteral
    literal: 42
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_hasTarget_localVariable_function() async {
    await assertErrorsInCode(r'''
main() {
  var v = () {};
  v.foo(0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 30, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: v
    staticElement: v@15
    staticType: Null Function()
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: v
    staticElement: v@15
    staticType: Null* Function()*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_noTarget() async {
    await assertErrorsInCode(r'''
class C {
  main() {
    foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_null() async {
    await assertErrorsInCode(r'''
main() {
  null.foo();
}
''', [
      if (isNullSafetyEnabled)
        error(CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE, 16, 3)
      else
        error(CompileTimeErrorCode.UNDEFINED_METHOD, 16, 3),
    ]);

    var node = findNode.methodInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: NullLiteral
    literal: null
    staticType: Null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: NullLiteral
    literal: null
    staticType: Null*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_object_call() async {
    await assertErrorsInCode(r'''
main(Object o) {
  o.call();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 21, 4),
    ]);
  }

  test_error_undefinedMethod_private() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo(int _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  main() {
    _foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 53, 4),
    ]);

    var node = findNode.methodInvocation('_foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: _foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: _foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_undefinedMethod_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
}

main() {
  C..foo();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 50, 3),
    ]);
  }

  test_error_undefinedMethod_typeLiteral_conditional() async {
    await assertErrorsInCode(
      r'''
class A {}
main() {
  A?.toString();
}
''',
      expectedErrorsByNullability(nullable: [
        error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 23, 2),
        error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 8),
      ], legacy: [
        error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 8),
      ]),
    );
  }

  test_error_undefinedSuperMethod() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 62, 3),
    ]);

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_unqualifiedReferenceToNonLocalStaticMember_method() async {
    await assertErrorsInCode(r'''
class A {
  static void foo() {}
}

class B extends A {
  main() {
    foo(0);
  }
}
''', [
      error(
          CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          71,
          3),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 75, 1),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_prefixed() async {
    await assertErrorsInCode(r'''
import 'missing.dart' as p;

main() {
  p.foo(1);
  p.bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);

    var node = findNode.methodInvocation('foo(1);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: p
    staticElement: self::@prefix::p
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  /// The primary purpose of this test is to ensure that we are only getting a
  /// single error generated when the only problem is that an imported file
  /// does not exist.
  test_error_uriDoesNotExist_show() async {
    await assertErrorsInCode(r'''
import 'missing.dart' show foo, bar;

main() {
  foo(1);
  bar(2);
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);

    var node = findNode.methodInvocation('foo(1);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_useOfVoidResult_name_getter() async {
    await assertErrorsInCode('''
class C<T>{
  T foo;
  C(this.foo);
}

void f(C<void> c) {
  c.foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 61, 5),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C<void>
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: PropertyAccessorMember
        base: self::@class::C::@getter::foo
        substitution: {T: void}
      staticType: void
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C<void>*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: PropertyAccessorMember
        base: self::@class::C::@getter::foo
        substitution: {T: void}
      staticType: void
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_useOfVoidResult_name_localVariable() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_useOfVoidResult_name_topFunction() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo()();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 26, 3),
    ]);

    var node = findNode.methodInvocation('foo()()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
  }

  test_error_useOfVoidResult_name_topVariable() async {
    await assertErrorsInCode(r'''
void foo;

main() {
  foo();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 22, 3),
    ]);

    var node = findNode.functionExpressionInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: void
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_useOfVoidResult_receiver() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo.toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.methodInvocation('toString()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_useOfVoidResult_receiver_cascade() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo..toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.methodInvocation('toString()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  operator: ..
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_useOfVoidResult_receiver_withNull() async {
    await assertErrorsInCode(r'''
main() {
  void foo;
  foo?.toString();
}
''', [
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 23, 3),
    ]);

    var node = findNode.methodInvocation('toString()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void
  operator: ?.
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void
  operator: ?.
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_error_wrongNumberOfTypeArgumentsMethod_01() async {
    await assertErrorsInCode(r'''
void foo() {}

main() {
  foo<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 29, 5),
    ]);

    var node = findNode.methodInvocation('foo<int>()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function()
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
  staticInvokeType: void Function()
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function()*
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int*
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
''');
    }
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_error_wrongNumberOfTypeArgumentsMethod_21() async {
    await assertErrorsInCode(r'''
Map<T, U> foo<T extends num, U>() => throw Error();

main() {
  foo<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 67, 5),
    ]);

    var node = findNode.methodInvocation('foo<int>()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: Map<T, U> Function<T extends num, U>()
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
  staticInvokeType: Map<dynamic, dynamic> Function()
  staticType: Map<dynamic, dynamic>
  typeArgumentTypes
    dynamic
    dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: Map<T*, U*>* Function<T extends num*, U>()*
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int*
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Map<dynamic, dynamic>* Function()*
  staticType: Map<dynamic, dynamic>*
  typeArgumentTypes
    dynamic
    dynamic
''');
    }
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_hasReceiver_class_staticGetter() async {
    await assertNoErrorsInCode(r'''
class C {
  static double Function(int) get foo => throw Error();
}

main() {
  C.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: C
      staticElement: self::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: double* Function(int*)*
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_hasReceiver_class_staticMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  static void foo(int _) {}
}

main() {
  C.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: C
    staticElement: self::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
    assertClassRef(node.target, findElement.class_('C'));
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary();
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
    ]);

    var node = findNode.methodInvocation('loadLibrary()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: loadLibrary@-1
    staticType: Future<dynamic> Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: FunctionMember
      base: loadLibrary@-1
      isLegacy: true
    staticType: Future<dynamic>* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: Future<dynamic>* Function()*
  staticType: Future<dynamic>*
''');
    }
  }

  test_hasReceiver_deferredImportPrefix_loadLibrary_extraArgument() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;

main() {
  math.loadLibrary(1 + 2);
}
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 66, 5),
    ]);

    var node = findNode.methodInvocation('loadLibrary(1 + 2)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: loadLibrary@-1
    staticType: Future<dynamic> Function()
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
  staticInvokeType: Future<dynamic> Function()
  staticType: Future<dynamic>
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: loadLibrary
    staticElement: FunctionMember
      base: loadLibrary@-1
      isLegacy: true
    staticType: Future<dynamic>* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int*
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: root::@parameter::other
          staticType: int*
        parameter: <null>
        staticElement: MethodMember
          base: dart:core::@class::num::@method::+
          isLegacy: true
        staticInvokeType: num* Function(num*)*
        staticType: int*
    rightParenthesis: )
  staticInvokeType: Future<dynamic>* Function()*
  staticType: Future<dynamic>*
''');
    }
  }

  test_hasReceiver_dynamic_hash() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.hash(0, 1);
}
''');

    var node = findNode.methodInvocation('hash(');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: hash
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: hash
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
      IntegerLiteral
        literal: 1
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_hasReceiver_functionTyped() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(int)
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(int*)*
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_hasReceiver_functionTyped_generic() async {
    await assertNoErrorsInCode(r'''
void foo<T>(T _) {}

main() {
  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>(T)
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::_
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>(T*)*
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::_
          substitution: {T: int*}
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
  typeArgumentTypes
    int*
''');
    }
  }

  test_hasReceiver_importPrefix_topFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
T foo<T extends num>(T a, T b) => a;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var node = findNode.methodInvocation('foo(1, 2)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@function::foo
    staticType: T Function<T extends num>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        parameter: ParameterMember
          base: root::@parameter::b
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int, int)
  staticType: int
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: prefix
    staticElement: self::@prefix::prefix
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@function::foo
    staticType: T* Function<T extends num*>(T*, T*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int*}
        staticType: int*
      IntegerLiteral
        literal: 2
        parameter: ParameterMember
          base: root::@parameter::b
          substitution: {T: int*}
        staticType: int*
    rightParenthesis: )
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
  typeArgumentTypes
    int*
''');
    }
  }

  test_hasReceiver_importPrefix_topGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
T Function<T>(T a, T b) get foo => null;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.foo(1, 2);
}
''');

    var node = findNode.functionExpressionInvocation('foo(1, 2);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@getter::foo
      staticType: T Function<T>(T, T)
    staticElement: package:test/a.dart::@getter::foo
    staticType: T Function<T>(T, T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int}
        staticType: int
      IntegerLiteral
        literal: 2
        parameter: ParameterMember
          base: root::@parameter::b
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function(int, int)
  staticType: int
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@getter::foo
      staticType: T* Function<T>(T*, T*)*
    staticElement: package:test/a.dart::@getter::foo
    staticType: T* Function<T>(T*, T*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int*}
        staticType: int*
      IntegerLiteral
        literal: 2
        parameter: ParameterMember
          base: root::@parameter::b
          substitution: {T: int*}
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int* Function(int*, int*)*
  staticType: int*
  typeArgumentTypes
    int*
''');
    }
  }

  test_hasReceiver_instance_Function_call_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(Function getFunction()) {
  Function foo = getFunction();

  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@44
    staticType: Function
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: foo@44
    staticType: Function*
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_hasReceiver_instance_Function_call_topVariable() async {
    await assertNoErrorsInCode(r'''
Function foo = throw Error();

void main() {
  foo.call(0);
}
''');

    var node = findNode.methodInvocation('call(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: Function
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: Function*
  operator: .
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <null>
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_hasReceiver_instance_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => throw Error();
}

void f(C c) {
  c.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: double* Function(int*)*
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  /// It is important to use this expression as an initializer of a top-level
  /// variable, because of the way top-level inference works, at the time of
  /// writing this. We resolve initializers twice - first for dependencies,
  /// then for resolution. This has its issues (for example we miss some
  /// dependencies), but the important thing is that we rewrite `foo(0)` from
  /// being a [MethodInvocation] to [FunctionExpressionInvocation]. So, during
  /// the second pass we see [SimpleIdentifier] `foo` as a `function`. And
  /// we should be aware that it is not a stand-alone identifier, but a
  /// cascade section.
  test_hasReceiver_instance_getter_cascade() async {
    await resolveTestCode(r'''
class C {
  double Function(int) get foo => 0;
}

var v = C()..foo(0) = 0;
''');

    var node = findNode.functionExpressionInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_hasReceiver_instance_getter_switchStatementExpression() async {
    await assertNoErrorsInCode(r'''
class C {
  int Function() get foo => throw Error();
}

void f(C c) {
  switch ( c.foo() ) {
    default:
      break;
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: int Function()
    staticType: int Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int Function()
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::C::@getter::foo
      staticType: int* Function()*
    staticType: int* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: int* Function()*
  staticType: int*
''');
    }
  }

  test_hasReceiver_instance_method() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}
}

void f(C c) {
  c.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_hasReceiver_instance_method_generic() async {
    await assertNoErrorsInCode(r'''
class C {
  T foo<T>(T a) {
    return a;
  }
}

void f(C c) {
  c.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: T Function<T>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticInvokeType: int Function(int)
  staticType: int
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: T* Function<T>(T*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int*}
        staticType: int*
    rightParenthesis: )
  staticInvokeType: int* Function(int*)*
  staticType: int*
  typeArgumentTypes
    int*
''');
    }
  }

  test_hasReceiver_instance_method_issue30552() async {
    await assertNoErrorsInCode(r'''
abstract class I1 {
  void foo(int i);
}

abstract class I2 {
  void foo(Object o);
}

abstract class C implements I1, I2 {}

class D extends C {
  void foo(Object o) {}
}

void f(C c) {
  c.foo('hi');
}
''');

    var node = findNode.methodInvocation("foo('hi')");
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::I2::@method::foo
    staticType: void Function(Object)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: 'hi'
    rightParenthesis: )
  staticInvokeType: void Function(Object)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::I2::@method::foo
    staticType: void Function(Object*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleStringLiteral
        literal: 'hi'
    rightParenthesis: )
  staticInvokeType: void Function(Object*)*
  staticType: void
''');
    }
  }

  test_hasReceiver_instance_typeParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class C<T extends A> {
  T a;
  C(this.a);

  main() {
    a.foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@class::C::@getter::a
    staticType: T
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@class::C::@getter::a
    staticType: T*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_hasReceiver_prefixed_class_staticGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static double Function(int) get foo => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        staticElement: package:test/a.dart::@class::C
        staticType: null
      staticElement: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@class::C::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: prefix
        staticElement: self::@prefix::prefix
        staticType: null
      period: .
      identifier: SimpleIdentifier
        token: C
        staticElement: package:test/a.dart::@class::C
        staticType: null
      staticElement: package:test/a.dart::@class::C
      staticType: null
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::@class::C::@getter::foo
      staticType: double* Function(int*)*
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_hasReceiver_prefixed_class_staticMethod() async {
    newFile('$testPackageLibPath/a.dart', r'''
class C {
  static void foo(int _) => null;
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

main() {
  prefix.C.foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: C
      staticElement: package:test/a.dart::@class::C
      staticType: null
    staticElement: package:test/a.dart::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@class::C::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: C
      staticElement: package:test/a.dart::@class::C
      staticType: null
    staticElement: package:test/a.dart::@class::C
    staticType: null
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::@class::C::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: package:test/a.dart::@class::C::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_hasReceiver_super_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    super.foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: double Function(int)
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B*
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: self::@class::A::@getter::foo
      staticType: double* Function(int*)*
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_hasReceiver_super_method() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void foo(int _) {
    super.foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
    staticType: B*
  operator: .
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode('''
void f({a = b?.foo()}) {}
''');

    var node = findNode.methodInvocation('?.foo()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: dynamic
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: dynamic
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode('''
typedef void F({a = b?.foo()});
''');

    var node = findNode.methodInvocation('?.foo()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: dynamic
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: b
    staticElement: <null>
    staticType: dynamic
  operator: ?.
  methodName: SimpleIdentifier
    token: foo
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_namedArgument() async {
    var question = isNullSafetyEnabled ? '?' : '';
    await assertNoErrorsInCode('''
void foo({int$question a, bool$question b}) {}

main() {
  foo(b: false, a: 0);
}
''');

    var node = findNode.methodInvocation('foo(b:');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function({int? a, bool? b})
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            staticElement: self::@function::foo::@parameter::b
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: false
          staticType: bool
        parameter: self::@function::foo::@parameter::b
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            staticElement: self::@function::foo::@parameter::a
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int
        parameter: self::@function::foo::@parameter::a
    rightParenthesis: )
  staticInvokeType: void Function({int? a, bool? b})
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function({int* a, bool* b})*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
            staticElement: self::@function::foo::@parameter::b
            staticType: null
          colon: :
        expression: BooleanLiteral
          literal: false
          staticType: bool*
        parameter: self::@function::foo::@parameter::b
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
            staticElement: self::@function::foo::@parameter::a
            staticType: null
          colon: :
        expression: IntegerLiteral
          literal: 0
          staticType: int*
        parameter: self::@function::foo::@parameter::a
    rightParenthesis: )
  staticInvokeType: void Function({int* a, bool* b})*
  staticType: void
''');
    }
  }

  test_noReceiver_getter_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  double Function(int) get foo => throw Error();
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@getter::foo
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_noReceiver_getter_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  double Function(int) get foo => throw Error();

  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@getter::foo
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_noReceiver_importPrefix() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  math();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 40, 4),
    ]);

    var node = findNode.methodInvocation('math()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: math
    staticElement: self::@prefix::math
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_noReceiver_localFunction() async {
    await assertNoErrorsInCode(r'''
main() {
  void foo(int _) {}

  foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: foo@16::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: foo@16
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: foo@16::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_localVariable_call() async {
    await assertNoErrorsInCode(r'''
class C {
  void call(int _) {}
}

void f(C c) {
  c(0);
}
''');

    var node = findNode.functionExpressionInvocation('c(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::call::@parameter::_
        staticType: int
    rightParenthesis: )
  staticElement: self::@class::C::@method::call
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: c
    staticElement: self::@function::f::@parameter::c
    staticType: C*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::call::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticElement: self::@class::C::@method::call
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_localVariable_promoted() async {
    await assertNoErrorsInCode(r'''
main() {
  var foo;
  if (foo is void Function(int)) {
    foo(0);
  }
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: foo@15
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: @-1
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: foo@15
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: @-1
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_method_superClass() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(int _) {}
}

class B extends A {
  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::A::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::A::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_method_thisClass() async {
    await assertNoErrorsInCode(r'''
class C {
  void foo(int _) {}

  void bar() {
    foo(0);
  }
}
''');

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@class::C::@method::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@class::C::@method::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_parameter() async {
    await assertNoErrorsInCode(r'''
void f(void Function(int) foo) {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::f::@parameter::foo
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
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@function::f::@parameter::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_parameter_call_nullAware() async {
    var question = isNullSafetyEnabled ? '?' : '';
    await assertNoErrorsInCode('''
double Function(int)$question foo;

main() {
  foo?.call(1);
}
    ''');

    var node = findNode.methodInvocation('call(1)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: double Function(int)?
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticInvokeType: double Function(int)
  staticType: double?
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: double* Function(int*)*
  operator: ?.
  methodName: SimpleIdentifier
    token: call
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 1
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_noReceiver_parameter_functionTyped_typedef() async {
    await assertNoErrorsInCode(r'''
typedef F = void Function();

void f(F a) {
  a();
}
''');

    var node = findNode.functionExpressionInvocation('a();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: void Function()
      alias: self::@typeAlias::F
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()
    alias: self::@typeAlias::F
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: void Function()*
      alias: self::@typeAlias::F
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function()*
    alias: self::@typeAlias::F
  staticType: void
''');
    }
  }

  test_noReceiver_topFunction() async {
    await assertNoErrorsInCode(r'''
void foo(int _) {}

main() {
  foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::_
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::_
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_noReceiver_topGetter() async {
    await assertNoErrorsInCode(r'''
double Function(int) get foo => throw Error();

main() {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: double Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double Function(int)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: double* Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: double* Function(int*)*
  staticType: double*
''');
    }
  }

  test_noReceiver_topVariable() async {
    await assertNoErrorsInCode(r'''
void Function(int) foo = throw Error();

main() {
  foo(0);
}
''');

    var node = findNode.functionExpressionInvocation('foo(0);');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
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
    } else {
      assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: foo
    staticElement: self::@getter::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: root::@parameter::
        staticType: int*
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }

  test_objectMethodOnDynamic_argumentsDontMatch() async {
    await assertNoErrorsInCode(r'''
void f(a, int b) {
  a.toString(b);
}
''');

    var node = findNode.methodInvocation('toString(b)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <null>
        staticElement: self::@function::f::@parameter::b
        staticType: int
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: <null>
        staticElement: self::@function::f::@parameter::b
        staticType: int*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }
  }

  test_objectMethodOnDynamic_argumentsMatch() async {
    await assertNoErrorsInCode(r'''
void f(a) {
  a.toString();
}
''');

    var node = findNode.methodInvocation('toString()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::@class::Object::@method::toString
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: MethodMember
      base: dart:core::@class::Object::@method::toString
      isLegacy: true
    staticType: null
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String* Function()*
  staticType: String*
''');
    }
  }

  test_objectMethodOnFunction() async {
    await assertNoErrorsInCode(r'''
void f() {}

main() {
  f.toString();
}
''');

    var node = findNode.methodInvocation('toString();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: void Function()
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: dart:core::@class::Object::@method::toString
    staticType: String Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String Function()
  staticType: String
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: void Function()*
  operator: .
  methodName: SimpleIdentifier
    token: toString
    staticElement: MethodMember
      base: dart:core::@class::Object::@method::toString
      isLegacy: true
    staticType: String* Function()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: String* Function()*
  staticType: String*
''');
    }
  }

  test_remainder_int_context_cascaded() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a..remainder(f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::remainder::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: root::@parameter::other
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_remainder_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a.remainder(f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::remainder::@parameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: root::@parameter::other
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_remainder_int_context_int_target_rewritten() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a().remainder(f()));
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::remainder::@parameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: root::@parameter::other
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_remainder_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
extension E on int {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 98, 19),
    ]);

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_remainder_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a.remainder(f());
}
''');

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::remainder::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: root::@parameter::other
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_remainder_int_double() async {
    await assertNoErrorsInCode('''
f(int a, double b) {
  a.remainder(b);
}
''');

    var node = findNode.methodInvocation('remainder');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: dart:core::@class::num::@method::remainder
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::remainder::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: double
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: double
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: MethodMember
      base: dart:core::@class::num::@method::remainder
      isLegacy: true
    staticType: num* Function(num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: double*
    rightParenthesis: )
  staticInvokeType: num* Function(num*)*
  staticType: num*
''');
    }
  }

  test_remainder_int_int() async {
    await assertNoErrorsInCode('''
f(int a, int b) {
  a.remainder(b);
}
''');

    var node = findNode.methodInvocation('remainder');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: dart:core::@class::num::@method::remainder
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::remainder::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: MethodMember
      base: dart:core::@class::num::@method::remainder
      isLegacy: true
    staticType: num* Function(num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*)*
  staticType: num*
''');
    }
  }

  test_remainder_int_int_target_rewritten() async {
    await assertNoErrorsInCode('''
f(int Function() a, int b) {
  a().remainder(b);
}
''');

    var node = findNode.methodInvocation('remainder');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: FunctionExpressionInvocation
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
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: dart:core::@class::num::@method::remainder
    staticType: num Function(num)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::remainder::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int
    rightParenthesis: )
  staticInvokeType: num Function(num)
  staticType: int
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  target: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int* Function()*
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int* Function()*
    staticType: int*
  operator: .
  methodName: SimpleIdentifier
    token: remainder
    staticElement: MethodMember
      base: dart:core::@class::num::@method::remainder
      isLegacy: true
    staticType: num* Function(num*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: b
        parameter: root::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int*
    rightParenthesis: )
  staticInvokeType: num* Function(num*)*
  staticType: num*
''');
    }
  }

  test_remainder_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a).remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 19),
    ]);

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_remainder_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String remainder(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a.remainder(f()));
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 16),
    ]);

    var node = findNode.methodInvocation('f()');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T* Function<T>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::remainder::@parameter::x
  staticInvokeType: num* Function()*
  staticType: num*
  typeArgumentTypes
    num*
''');
    }
  }

  test_syntheticName() async {
    // This code is invalid, and the constructor initializer has a method
    // invocation with a synthetic name. But we should still resolve the
    // invocation, and resolve all its arguments.
    await assertErrorsInCode(r'''
class A {
  A() : B(1 + 2, [0]);
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER, 18, 1),
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 13),
    ]);

    var node = findNode.methodInvocation(');');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
    staticType: dynamic
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
      ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 0
            staticType: int
        rightBracket: ]
        parameter: <null>
        staticType: List<int>
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
    staticType: dynamic
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: IntegerLiteral
          literal: 1
          staticType: int*
        operator: +
        rightOperand: IntegerLiteral
          literal: 2
          parameter: root::@parameter::other
          staticType: int*
        parameter: <null>
        staticElement: MethodMember
          base: dart:core::@class::num::@method::+
          isLegacy: true
        staticInvokeType: num* Function(num*)*
        staticType: int*
      ListLiteral
        leftBracket: [
        elements
          IntegerLiteral
            literal: 0
            staticType: int*
        rightBracket: ]
        parameter: <null>
        staticType: List<int*>*
    rightParenthesis: )
  staticInvokeType: dynamic
  staticType: dynamic
''');
    }

    assertType(findNode.binary('1 + 2'), 'int');
    assertType(findNode.listLiteral('[0]'), 'List<int>');
  }

  test_typeArgumentTypes_generic_inferred() async {
    await assertErrorsInCode(r'''
U foo<T, U>(T a) => throw Error();

main() {
  bool v = foo(0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
    ]);

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: U Function<T, U>(T)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int, U: bool}
        staticType: int
    rightParenthesis: )
  staticInvokeType: bool Function(int)
  staticType: bool
  typeArgumentTypes
    int
    bool
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: U* Function<T, U>(T*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: ParameterMember
          base: root::@parameter::a
          substitution: {T: int*, U: bool*}
        staticType: int*
    rightParenthesis: )
  staticInvokeType: bool* Function(int*)*
  staticType: bool*
  typeArgumentTypes
    int*
    bool*
''');
    }
  }

  test_typeArgumentTypes_generic_instantiateToBounds() async {
    await assertNoErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo();
}
''');

    var node = findNode.methodInvocation('foo();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T extends num>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
  typeArgumentTypes
    num
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T extends num*>()*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
  typeArgumentTypes
    num*
''');
    }
  }

  test_typeArgumentTypes_generic_typeArguments_notBounds() async {
    await assertErrorsInCode(r'''
void foo<T extends num>() {}

main() {
  foo<bool>();
}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 45, 4),
    ]);

    var node = findNode.methodInvocation('foo<bool>();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T extends num>()
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: bool
          staticElement: dart:core::@class::bool
          staticType: null
        type: bool
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
  typeArgumentTypes
    bool
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T extends num*>()*
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: bool
          staticElement: dart:core::@class::bool
          staticType: null
        type: bool*
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
  typeArgumentTypes
    bool*
''');
    }
  }

  test_typeArgumentTypes_generic_typeArguments_wrongNumber() async {
    await assertErrorsInCode(r'''
void foo<T>() {}

main() {
  foo<int, double>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 32, 13),
    ]);

    var node = findNode.methodInvocation('foo<int, double>();');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>()
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
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        type: double
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
  typeArgumentTypes
    dynamic
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function<T>()*
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int*
      NamedType
        name: SimpleIdentifier
          token: double
          staticElement: dart:core::@class::double
          staticType: null
        type: double*
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()*
  staticType: void
  typeArgumentTypes
    dynamic
''');
    }
  }

  test_typeArgumentTypes_notGeneric() async {
    await assertNoErrorsInCode(r'''
void foo(int a) {}

main() {
  foo(0);
}
''');

    var node = findNode.methodInvocation('foo(0)');
    if (isNullSafetyEnabled) {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(int)
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::a
        staticType: int
    rightParenthesis: )
  staticInvokeType: void Function(int)
  staticType: void
''');
    } else {
      assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: foo
    staticElement: self::@function::foo
    staticType: void Function(int*)*
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: self::@function::foo::@parameter::a
        staticType: int*
    rightParenthesis: )
  staticInvokeType: void Function(int*)*
  staticType: void
''');
    }
  }
}

@reflectiveTest
class MethodInvocationResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, MethodInvocationResolutionTestCases {}

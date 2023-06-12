// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAssignment_ImplicitCallReferenceTest);
    defineReflectiveTests(InvalidAssignmentTest);
    defineReflectiveTests(
        InvalidAssignmentWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(InvalidAssignmentWithoutNullSafetyTest);
    defineReflectiveTests(InvalidAssignmentWithStrictCastsTest);
  });
}

@reflectiveTest
class InvalidAssignment_ImplicitCallReferenceTest
    extends PubPackageResolutionTest {
  test_invalid_genericBoundedCall_nonGenericContext() async {
    await assertErrorsInCode('''
class C {
  T call<T extends num>(T t) => t;
}

String Function(String) f = C();
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 76, 3),
    ]);
  }

  test_invalid_genericCall_genericEnclosingClass_nonGenericContext() async {
    await assertErrorsInCode('''
class C<T> {
  C(T a);
  void call<U>(T t, U u) {}
}

void Function(bool, String) f = C(7);
''', [
      // The type arguments of the instance of `C` should be accurate and be
      // taken into account when evaluating the assignment of the implicit call
      // reference.
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 86, 4),
    ]);
  }

  test_invalid_genericCall_nonGenericContext() async {
    await assertErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

void Function() f = C();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 56, 3),
    ]);
  }

  test_invalid_genericCall_nonGenericContext_withoutConstructorTearoffs() async {
    await assertErrorsInCode('''
// @dart=2.12
class C {
  T call<T>(T t) => t;
}

int Function(int) f = C();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 72, 3),
    ]);
  }

  test_invalid_noCall_functionContext() async {
    await assertErrorsInCode('''
class C {}

Function f = C();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 25, 3),
    ]);
  }

  test_invalid_noCall_functionTypeContext() async {
    await assertErrorsInCode('''
class C {}

String Function(String) f = C();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 40, 3),
    ]);
  }

  test_invalid_nonGenericCall() async {
    await assertErrorsInCode('''
class C {
  void call(int a) {}
}

void Function(String) f = C();
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 61, 3),
    ]);
  }

  test_invalid_nonGenericCall_typeVariableExtendsFunctionContext() async {
    await assertErrorsInCode('''
class C {
  void call(int a) {}
}
class D<U extends Function> {
  U f = C();
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 72, 3),
    ]);
  }

  test_invalid_nonGenericCall_typeVariableExtendsFunctionTypeContext() async {
    await assertErrorsInCode('''
class C {
  void call(int a) {}
}
class D<U extends void Function(int)> {
  U f = C();
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 82, 3),
    ]);
  }

  test_valid_genericBoundedCall_nonGenericContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T extends num>(T t) => t;
}

int Function(int) f = C();
''');
  }

  test_valid_genericCall_functionContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

Function f = C();
''');
  }

  test_valid_genericCall_futureOrFunctionContext() async {
    await assertNoErrorsInCode('''
import 'dart:async';
class C {
  T call<T>(T t) => t;
}

FutureOr<Function> f = C();
''');
  }

  test_valid_genericCall_futureOrFunctionTypeContext_generic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
class C {
  T call<T>(T t) => t;
}

FutureOr<T Function<T>(T)> f = C();
''');
  }

  test_valid_genericCall_futureOrFunctionTypeContext_nonGeneric() async {
    await assertNoErrorsInCode('''
import 'dart:async';
class C {
  T call<T>(T t) => t;
}

FutureOr<int Function(int)> f = C();
''');
  }

  test_valid_genericCall_genericContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

T Function<T>(T) f = C();
''');
  }

  test_valid_genericCall_genericEnclosingClass_nonGenericContext() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T a);
  void call<U>(T t, U u) {}
}

void Function(int, String) f = C(7);
''');
  }

  test_valid_genericCall_genericTypedefContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}
typedef Fn<T> = T Function(T);
class D<U> {
  Fn<U> f = C();
}

''');
  }

  test_valid_genericCall_nonGenericContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

int Function(int) f = C();
''');
  }

  test_valid_genericCall_nullableFunctionContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

Function? f = C();
''');
  }

  test_valid_genericCall_nullableNonGenericContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

int Function(int)? f = C();
''');
  }

  test_valid_genericCall_typedefOfGenericContext() async {
    await assertNoErrorsInCode('''
class C {
  T call<T>(T t) => t;
}

typedef Fn = T Function<T>(T);

Fn f = C();
''');
  }

  test_valid_nonGenericCall() async {
    await assertNoErrorsInCode('''
class C {
  void call(int a) {}
}

void Function(int) f = C();
''');
  }

  test_valid_nonGenericCall_declaredOnMixin() async {
    await assertNoErrorsInCode('''
mixin M {
  void call(int a) {}
}
class C with M {}

Function f = C();
''');
  }

  test_valid_nonGenericCall_inCascade() async {
    await assertNoErrorsInCode('''
class C {
  void call(int a) {}
}
class D {
  late void Function(int) f;
}

void foo() {
  D()..f = C();
}
''');
  }

  test_valid_nonGenericCall_subTypeViaParameter() async {
    await assertNoErrorsInCode('''
class C {
  void call(num a) {}
}

void Function(int) f = C();
''');
  }

  test_valid_nonGenericCall_subTypeViaReturnType() async {
    await assertNoErrorsInCode('''
class C {
  int call() => 7;
}

num Function() f = C();
''');
  }
}

@reflectiveTest
class InvalidAssignmentTest extends PubPackageResolutionTest
    with InvalidAssignmentTestCases {
  test_constructorTearoff_inferredTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T a);
}

var g = C<int>.new;
''');
  }

  test_constructorTearoff_withExplicitTypeArgs() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T a);
}

C Function(int) g = C<int>.new;
''');
  }

  test_constructorTearoff_withExplicitTypeArgs_invalid() async {
    await assertErrorsInCode('''
class C<T> {
  C(T a);
}

C Function(String) g = C<int>.new;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 49, 10),
    ]);
  }

  test_functionTearoff_genericInstantiation() async {
    await assertNoErrorsInCode('''
int Function() foo(int Function<T extends int>() f) {
  return f;
}
''');

    assertFunctionReference(
      findNode.functionReference('f;'),
      findElement.parameter('f'),
      'int Function()',
    );
  }

  test_functionTearoff_inferredTypeArgs() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}

var g = f<int>;
''');
  }

  test_functionTearoff_withExplicitTypeArgs() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}

void Function(int) g = f<int>;
''');
  }

  test_functionTearoff_withExplicitTypeArgs_invalid() async {
    await assertErrorsInCode('''
void f<T>(T a) {}

void Function(String) g = f<int>;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 45, 6),
    ]);
  }

  test_ifNullAssignment() async {
    await assertErrorsInCode('''
void f(int i) {
  double? d;
  d ??= i;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 37, 1),
    ]);
  }

  test_ifNullAssignment_sameType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  int? j;
  j ??= i;
}
''');
  }

  test_ifNullAssignment_superType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  num? n;
  n ??= i;
}
''');
  }

  test_localLevelVariable_never_null() async {
    await assertErrorsInCode('''
void f(Never x) {
  x = null;
}
''', [
      if (hasAssignmentLeftResolution) error(HintCode.DEAD_CODE, 24, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 24, 4),
    ]);
  }

  test_topLevelVariable_never_null() async {
    await assertErrorsInCode('''
Never x = throw 0;

void f() {
  x = null;
}
''', [
      if (hasAssignmentLeftResolution) error(HintCode.DEAD_CODE, 37, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 37, 4),
    ]);
  }

  test_typeParameter() async {
    // https://github.com/dart-lang/sdk/issues/14221
    await assertErrorsInCode(r'''
class B<T> {
  T? value;
  void test(num n) {
    value = n;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 58, 1),
    ]);
  }
}

mixin InvalidAssignmentTestCases on PubPackageResolutionTest {
  test_assignment_to_dynamic() async {
    await assertErrorsInCode(r'''
f() {
  var g;
  g = () => 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_cascadeExpression() async {
    await assertErrorsInCode(r'''
void f(int a) {
  // ignore:unused_local_variable
  String v = (a)..isEven;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 64, 1),
    ]);
  }

  test_compoundAssignment() async {
    await assertErrorsInCode(r'''
class byte {
  int _value;
  byte(this._value);
  byte operator +(int val) { return this; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}
''', [
      error(HintCode.UNUSED_FIELD, 19, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 116, 1),
    ]);
  }

  test_defaultValue_named() async {
    await assertErrorsInCode(r'''
f({String x: 0}) {
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 13, 1),
    ]);
  }

  test_defaultValue_named_sameType() async {
    await assertNoErrorsInCode(r'''
f({String x: '0'}) {
}''');
  }

  test_defaultValue_optional() async {
    await assertErrorsInCode(r'''
f([String x = 0]) {
}''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 14, 1),
    ]);
  }

  test_defaultValue_optional_sameType() async {
    await assertNoErrorsInCode(r'''
f([String x = '0']) {
}
''');
  }

  test_functionExpressionInvocation() async {
    await assertErrorsInCode('''
class C {
  String x = (() => 5)();
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 11),
    ]);
  }

  test_functionInstantiation_topLevelVariable_genericContext_assignable() async {
    await assertNoErrorsInCode('''
T f<T>(T a) => a;
U Function<U>(U) foo = f;
''');
  }

  test_functionInstantiation_topLevelVariable_genericContext_nonAssignable() async {
    await assertErrorsInCode('''
T f<T>(T a) => a;
U Function<U>(U, int) foo = f;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 46, 1),
    ]);
  }

  test_functionInstantiation_topLevelVariable_nonGenericContext_assignable() async {
    await assertNoErrorsInCode('''
T f<T>(T a) => a;
int Function(int) foo = f;
''');
  }

  test_functionInstantiation_topLevelVariable_nonGenericContext_nonAssignable() async {
    await assertErrorsInCode('''
T f<T>(T a) => a;
int Function(int, int) foo = f;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 47, 1),
    ]);
  }

  test_implicitlyImplementFunctionViaCall_1() async {
    // issue 18341
    //
    // This test and
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()' are
    // closely related: here we see that 'I' checks as a subtype of 'IntToInt'.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new I();
''');
  }

  test_implicitlyImplementFunctionViaCall_2() async {
    // issue 18341
    //
    // Here 'C' checks as a subtype of 'I', but 'C' does not check as a subtype
    // of 'IntToInt'. Together with
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_1()' we see
    // that subtyping is not transitive here.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new C();
''');
  }

  test_implicitlyImplementFunctionViaCall_3() async {
    // issue 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()', but
    // uses type 'Function' instead of more precise type 'IntToInt' for 'f'.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
Function f = new C();
''');
  }

  test_implicitlyImplementFunctionViaCall_4() async {
    // issue 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()', but
    // uses type 'VoidToInt' instead of more precise type 'IntToInt' for 'f'.
    //
    // Here 'C <: IntToInt <: VoidToInt', but the spec gives no transitivity
    // rule for '<:'. However, many of the :/tools/test.py tests assume this
    // transitivity for 'JsBuilder' objects, assigning them to
    // '(String) -> dynamic'. The declared type of 'JsBuilder.call' is
    // '(String, [dynamic]) -> Expression'.
    await assertNoErrorsInCode(r'''
class I {
  int call([int x = 7]) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int VoidToInt();
VoidToInt f = new C();
''');
  }

  test_instanceVariable() async {
    await assertErrorsInCode(r'''
class A {
  int x = 7;
}
f(var y) {
  A a = A();
  if (y is String) {
    a.x = y;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 80, 1),
    ]);
  }

  test_invalidAssignment() async {
    await assertErrorsInCode(r'''
f() {
  var x;
  var y;
  x = y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_localVariable() async {
    await assertErrorsInCode(r'''
f() {
  int x;
  x = '0';
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 21, 3),
    ]);
  }

  test_localVariable_promotion() async {
    await assertErrorsInCode(r'''
f(var y) {
  if (y is String) {
    int x = y;
    print(x);
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 44, 1),
    ]);
  }

  test_parenthesizedExpression() async {
    await assertErrorsInCode(r'''
void f(int a) {
  // ignore:unused_local_variable
  String v = (a);
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 64, 1),
    ]);
  }

  test_postfixExpression_localVariable() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

f(A a) {
  a++;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 65, 3),
    ]);
  }

  test_postfixExpression_localVariable_sameType() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  a++;
}
''');
  }

  test_postfixExpression_property() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

class C {
  A a = A();
}

f(C c) {
  c.a++;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 91, 5),
    ]);
  }

  test_postfixExpression_property_sameType() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a = A();
}

f(C c) {
  c.a++;
}
''');
  }

  test_prefixExpression_localVariable() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

f(A a) {
  ++a;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 65, 3),
    ]);
  }

  test_prefixExpression_localVariable_sameType() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  ++a;
}
''');
  }

  test_prefixExpression_property() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

class C {
  A a = A();
}

f(C c) {
  ++c.a;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 91, 5),
    ]);
  }

  test_prefixExpression_property_sameType() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a = A();
}

f(C c) {
  ++c.a;
}
''');
  }

  test_promotedTypeParameter_regress35306() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends D {}
class D {}

void f<X extends A, Y extends B>(X x) {
  if (x is Y) {
    A a = x;
    B b = x;
    X x2 = x;
    Y y = x;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 127, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 140, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 153, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 167, 1),
    ]);
  }

  test_regressionInIssue18468Fix() async {
    // https://code.google.com/p/dart/issues/detail?id=18628
    await assertErrorsInCode(r'''
class C<T> {
  T t = int;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 21, 3),
    ]);
  }

  test_staticVariable() async {
    await assertErrorsInCode(r'''
class A {
  static int x = 1;
}
f() {
  A.x = '0';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 46, 3),
    ]);
  }

  test_staticVariable_promoted() async {
    await assertErrorsInCode(r'''
class A {
  static int x = 7;
}
f(var y) {
  if (y is String) {
    A.x = y;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 74, 1),
    ]);
  }

  test_topLevelVariableDeclaration() async {
    await assertErrorsInCode('''
int x = 'string';
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 8, 8),
    ]);
  }

  test_typeParameterRecursion_regress35306() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends D {}
class D {}

void f<X extends A, Y extends B>(X x) {
  if (x is Y) {
    D d = x;
    print(d);
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 131, 1),
    ]);
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
class A {
  int x = 'string';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 20, 8),
    ]);
  }

  test_variableDeclaration_overriddenOperator() async {
    // https://github.com/dart-lang/sdk/issues/17971
    await assertErrorsInCode(r'''
class Point {
  final num x, y;
  Point(this.x, this.y);
  Point operator +(Point other) {
    return new Point(x+other.x, y+other.y);
  }
}
main() {
  var p1 = new Point(0, 0);
  var p2 = new Point(10, 10);
  int n = p1 + p2;
  print(n);
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 218, 7),
    ]);
  }
}

@reflectiveTest
class InvalidAssignmentWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_assignment() async {
    await assertErrorsWithNoImplicitCasts('''
void f(num n, int i) {
  i = n;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 1),
    ]);
  }

  test_compoundAssignment() async {
    await assertErrorsWithNoImplicitCasts('''
void f(num n, int i) {
  i += n;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 30, 1),
    ]);
  }

  @failingTest
  test_list_spread_dynamic() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    await assertErrorsWithNoImplicitCasts(r'''
void f(dynamic a) {
  [...a];
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 26, 1),
    ]);
  }

  @failingTest
  test_map_spread_dynamic() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    await assertErrorsWithNoImplicitCasts(r'''
void f(dynamic a) {
  <dynamic, dynamic>{...a};
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 44, 1),
    ]);
  }

  test_numericOps() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26912
    await assertNoErrorsWithNoImplicitCasts('''
void f(int x, int y) {
  x += y;
}
''');
  }

  @failingTest
  test_set_spread_dynamic() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    await assertErrorsWithNoImplicitCasts(r'''
void f(dynamic a) {
  <dynamic>{...a};
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 1),
    ]);
  }
}

@reflectiveTest
class InvalidAssignmentWithoutNullSafetyTest extends PubPackageResolutionTest
    with InvalidAssignmentTestCases, WithoutNullSafetyMixin {
  test_functionTearoff_genericInstantiation() async {
    await assertNoErrorsInCode('''
int Function() foo(int Function<T extends int>() f) {
  return f;
}
''');

    assertSimpleIdentifier(
      findNode.simple('f;'),
      element: findElement.parameter('f'),
      type: 'int Function()',
    );
  }

  test_ifNullAssignment() async {
    await assertErrorsInCode('''
void f(int i) {
  double d;
  d ??= i;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 36, 1),
    ]);
  }

  test_ifNullAssignment_sameType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  int j;
  j ??= i;
}
''');
  }

  test_ifNullAssignment_superType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  num n;
  n ??= i;
}
''');
  }

  test_typeParameter() async {
    // https://github.com/dart-lang/sdk/issues/14221
    await assertErrorsInCode(r'''
class B<T> {
  T value;
  void test(num n) {
    value = n;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 57, 1),
    ]);
  }
}

@reflectiveTest
class InvalidAssignmentWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_assignment() async {
    await assertErrorsWithStrictCasts('''
dynamic a;
int b = a;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }
}

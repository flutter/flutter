// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedMethodTest);
  });
}

@reflectiveTest
class UndefinedMethodTest extends PubPackageResolutionTest {
  test_conditional_expression_condition_context() async {
    await assertErrorsInCode('''
T castObject<T>(Object value) => value as T;

main() {
  (castObject(true)..whatever()) ? 1 : 2;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 76, 8,
          messageContains: ["type 'bool'"]),
    ]);
  }

  test_constructor_defined() async {
    await assertNoErrorsInCode(r'''
class C {
  C.m();
}
C c = C.m();
''');
  }

  test_definedInPrivateExtension() async {
    newFile('$testPackageLibPath/lib.dart', '''
class B {}

extension _ on B {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f(B b) {
  b.a();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 33, 1),
    ]);
  }

  test_definedInUnnamedExtension() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}

extension on C {
  void a() {}
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';

f(C c) {
  c.a();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 33, 1),
    ]);
  }

  test_functionAlias_notInstantiated() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn.foo();
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionAlias_typeInstantiated() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo();
}

extension E on Type {
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE, 58, 3),
    ]);
  }

  test_functionAlias_typeInstantiated_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo();
}

extension E on Type {
  void foo() {}
}
''');
  }

  test_functionExpression_callMethod_defined() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null).call();
}
''');
  }

  test_functionExpression_directCall_defined() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null)();
}
''');
  }

  test_ignoreTypePropagation() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 85, 1),
    ]);
  }

  test_leastUpperBoundWithNull() async {
    await assertErrorsInCode('''
// @dart = 2.9
f(bool b, int i) => (b ? null : i).foo();
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 50, 3),
    ]);
  }

  test_method_undefined() async {
    await assertErrorsInCode(r'''
class C {
  f() {
    abs();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 22, 3),
    ]);
  }

  test_method_undefined_cascade() async {
    await assertErrorsInCode(r'''
class C {}
f(C c) {
  c..abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);
  }

  test_method_undefined_enum() async {
    await assertErrorsInCode(r'''
enum E { A }
f() => E.abs();
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 22, 3),
    ]);
  }

  test_method_undefined_mixin() async {
    await assertErrorsInCode(r'''
mixin M {}
f(M m) {
  m.abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 24, 3),
    ]);
  }

  test_method_undefined_mixin_cascade() async {
    await assertErrorsInCode(r'''
mixin M {}
f(M m) {
  m..abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 25, 3),
    ]);
  }

  test_method_undefined_onNull() async {
    await assertErrorsInCode(r'''
// @dart = 2.9
Null f(int x) => null;
main() {
  f(42).abs();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 55, 3),
    ]);
  }

  test_static_conditionalAccess_defined() async {
    await assertErrorsInCode('''
class A {
  static void m() {}
}
f() { A?.m(); }
''', [
      error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 40, 2),
    ]);
  }

  test_static_mixinApplication_superConstructorIsFactory() async {
    await assertErrorsInCode(r'''
mixin M {}

class A {
  A();
  factory A.named() = A;
}

class B = A with M;

void main() {
  B.named();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 96, 5),
    ]);
  }

  test_typeAlias_functionType() async {
    await assertErrorsInCode(r'''
typedef A = void Function();

void f() {
  A.foo();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 45, 3),
    ]);
  }

  test_typeAlias_interfaceType() async {
    await assertErrorsInCode(r'''
typedef A = List<int>;

void f() {
  A.foo();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 39, 3),
    ]);
  }

  test_withExtension() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {
  void a() {}
}

f(C c) {
  c.c();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 61, 1),
    ]);
  }
}

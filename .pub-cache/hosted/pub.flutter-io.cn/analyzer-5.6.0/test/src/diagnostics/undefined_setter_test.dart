// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSetterTest);
    defineReflectiveTests(UndefinedSetterWithoutNullSafetyTest);
  });
}

@reflectiveTest
class UndefinedSetterTest extends PubPackageResolutionTest
    with UndefinedSetterTestCases {
  test_functionAlias_typeInstantiated() async {
    await assertErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  Fn<int>.foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE, 58, 3),
    ]);
  }

  test_functionAlias_typeInstantiated_parenthesized() async {
    await assertNoErrorsInCode('''
typedef Fn<T> = void Function(T);

void bar() {
  (Fn<int>).foo = 7;
}

extension E on Type {
  set foo(int value) {}
}
''');
  }

  test_new_cascade() async {
    await assertErrorsInCode('''
class C {}

f(C? c) {
  c..new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 3),
    ]);
  }

  test_new_dynamic() async {
    await assertErrorsInCode('''
f(dynamic d) {
  d.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 19, 3),
    ]);
  }

  test_new_instance() async {
    await assertErrorsInCode('''
class C {}

f(C c) {
  c.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 25, 3),
    ]);
  }

  test_new_interfaceType() async {
    await assertErrorsInCode('''
class C {}

f() {
  C.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 22, 3),
    ]);
  }

  test_new_nullAware() async {
    await assertErrorsInCode('''
class C {}

f(C? c) {
  c?.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 3),
    ]);
  }

  test_new_typeVariable() async {
    await assertErrorsInCode('''
f<T>(T t) {
  t.new = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 16, 3),
    ]);
  }

  test_set_abstract_field_valid() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}
void f(A a, int x) {
  a.x = x;
}
''');
  }

  test_set_external_field_valid() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
}
void f(A a, int x) {
  a.x = x;
}
''');
  }

  test_set_external_static_field_valid() async {
    await assertNoErrorsInCode('''
class A {
  external static int x;
}
void f(int x) {
  A.x = x;
}
''');
  }
}

mixin UndefinedSetterTestCases on PubPackageResolutionTest {
  test_importWithPrefix_defined() async {
    newFile('$testPackageLibPath/lib.dart', r'''
library lib;
set y(int value) {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}
''');
  }

  test_instance_undefined() async {
    await assertErrorsInCode(r'''
class T {}
f(T e1) { e1.m = 0; }
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 24, 1,
          messageContains: ["the type 'T'"]),
    ]);
  }

  test_instance_undefined_mixin() async {
    await assertErrorsInCode(r'''
mixin M {
  f() { this.m = 0; }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 23, 1),
    ]);
  }

  test_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(var a) {
  if (a is A) {
    a.b = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 80, 1),
    ]);
  }

  test_inType() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 43, 1),
    ]);
  }

  test_static_conditionalAccess_defined() async {
    await assertErrorsInCode(
      '''
class A {
  static var x;
}
f() { A?.x = 1; }
''',
      expectedErrorsByNullability(nullable: [
        error(StaticWarningCode.INVALID_NULL_AWARE_OPERATOR, 35, 2),
      ], legacy: []),
    );
  }

  test_static_definedInSuperclass() async {
    await assertErrorsInCode('''
class S {
  static set s(int i) {}
}
class C extends S {}
f(var p) {
  f(C.s = 1);
}''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 75, 1,
          messageContains: ["type 'C'"]),
    ]);
  }

  test_static_undefined() async {
    await assertErrorsInCode(r'''
class A {}
f() { A.B = 0;}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 19, 1),
    ]);
  }

  test_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class T {
  static void set foo(_) {}
}
main() {
  T..foo = 42;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 54, 3),
    ]);
  }

  test_withExtension() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {}

f(C c) {
  c.a = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 46, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedSetterWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, UndefinedSetterTestCases {}

// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinApplicationNoConcreteSuperInvokedMemberTest);
  });
}

@reflectiveTest
class MixinApplicationNoConcreteSuperInvokedMemberTest
    extends PubPackageResolutionTest {
  test_class_getter() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}

mixin M on A {
  void bar() {
    super.foo;
  }
}

abstract class X extends A with M {}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          121,
          1),
    ]);
  }

  test_class_inNextMixin() async {
    await assertErrorsInCode('''
abstract class A {
  void foo();
}

mixin M1 on A {
  void foo() {
    super.foo();
  }
}

mixin M2 on A {
  void foo() {}
}

class X extends A with M1, M2 {}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          149,
          2),
    ]);
  }

  test_class_inSameMixin() async {
    await assertErrorsInCode('''
abstract class A {
  void foo();
}

mixin M on A {
  void foo() {
    super.foo();
  }
}

class X extends A with M {}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          113,
          1),
    ]);
  }

  test_class_method() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

abstract class X extends A with M {}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          122,
          1),
    ]);
  }

  test_class_OK_hasNSM() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

class C implements A {
  noSuchMethod(_) {}
}

class X extends C with M {}
''');
  }

  test_class_OK_hasNSM2() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

/// Class `B` has noSuchMethod forwarder for `foo`.
class B implements A {
  noSuchMethod(_) {}
}

/// Class `C` is abstract, but it inherits noSuchMethod forwarders from `B`.
abstract class C extends B {}

class X extends C with M {}
''');
  }

  test_class_OK_inPreviousMixin() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
}

mixin M1 {
  void foo() {}
}

mixin M2 on A {
  void bar() {
    super.foo();
  }
}

class X extends A with M1, M2 {}
''');
  }

  test_class_OK_inSuper_fromMixin() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
}

mixin M1 {
  void foo() {}
}

class B extends A with M1 {}

mixin M2 on A {
  void bar() {
    super.foo();
  }
}

class X extends B with M2 {}
''');
  }

  test_class_OK_notInvoked() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
}

mixin M on A {}

abstract class X extends A with M {}
''');
  }

  test_class_OK_super_covariant() async {
    await assertNoErrorsInCode(r'''
class A {
  bar(num n) {}
}

mixin M on A {
  test() {
    super.bar(3.14);
  }
}

class B implements A {
  bar(covariant int i) {}
}

class C extends B with M {}
''');
  }

  test_class_setter() async {
    await assertErrorsInCode(r'''
abstract class A {
  void set foo(_);
}

mixin M on A {
  void bar() {
    super.foo = 0;
  }
}

abstract class X extends A with M {}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          129,
          1),
    ]);
  }

  test_enum_getter() async {
    await assertErrorsInCode(r'''
mixin M1 {
  int get foo;
}

mixin M2 on M1 {
  void bar() {
    super.foo;
  }
}

enum E with M1, M2 {
  v;
  int get foo => 0;
}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          99,
          2),
    ]);
  }

  test_enum_getter_exists() async {
    await assertNoErrorsInCode(r'''
mixin M1 {
  int get foo => 0;
}

mixin M2 on M1 {
  void bar() {
    super.foo;
  }
}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_getter_index() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  void foo() {
    super.index;
  }
}

enum E with M {
  v
}
''');
  }

  test_enum_method() async {
    await assertErrorsInCode(r'''
mixin M1 {
  void foo();
}

mixin M2 on M1 {
  void bar() {
    super.foo();
  }
}

enum E with M1, M2 {
  v;
  void foo() {}
}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          100,
          2),
    ]);
  }

  test_enum_method_exists() async {
    await assertNoErrorsInCode(r'''
mixin M1 {
  void foo() {}
}

mixin M2 on M1 {
  void bar() {
    super.foo();
  }
}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_OK_getter_inPreviousMixin() async {
    await assertNoErrorsInCode(r'''
mixin M1 {
  int get foo => 0;
}

mixin M2 on M1 {
  void bar() {
    super.foo;
  }
}

enum E with M1, M2 {
  v;
}
''');
  }

  test_enum_setter() async {
    await assertErrorsInCode(r'''
mixin M1 {
  set foo(int _);
}

mixin M2 on M1 {
  void bar() {
    super.foo = 0;
  }
}

enum E with M1, M2 {
  v;
  set foo(int _) {}
}
''', [
      error(
          CompileTimeErrorCode
              .MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER,
          106,
          2),
    ]);
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingStaticAndInstanceClassTest);
    defineReflectiveTests(ConflictingStaticAndInstanceEnumTest);
    defineReflectiveTests(ConflictingStaticAndInstanceMixinTest);
  });
}

@reflectiveTest
class ConflictingStaticAndInstanceClassTest extends PubPackageResolutionTest {
  test_inClass_getter_getter() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inClass_getter_method() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inClass_getter_setter() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inClass_method_getter() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inClass_method_method() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inClass_method_setter() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inClass_setter_getter() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inClass_setter_method() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inClass_setter_setter() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inInterface_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 81, 3),
    ]);
  }

  test_inInterface_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inInterface_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 77, 3),
    ]);
  }

  test_inInterface_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inInterface_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inInterface_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inInterface_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inInterface_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inMixin_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 81, 3),
    ]);
  }

  test_inMixin_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inMixin_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 77, 3),
    ]);
  }

  test_inMixin_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inMixin_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inMixin_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inMixin_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inMixin_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inSuper_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_inSuper_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 66, 3),
    ]);
  }

  test_inSuper_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 3),
    ]);
  }

  test_inSuper_implicitObject_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  static String runtimeType() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 11),
    ]);
  }

  test_inSuper_implicitObject_method_method() async {
    await assertErrorsInCode(r'''
class A {
  static String toString() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 8),
    ]);
  }

  test_inSuper_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 66, 3),
    ]);
  }

  test_inSuper_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 62, 3),
    ]);
  }

  test_inSuper_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 62, 3),
    ]);
  }

  test_inSuper_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }

  test_inSuper_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceEnumTest extends PubPackageResolutionTest {
  test_constant_hashCode() async {
    await assertErrorsInCode(r'''
enum E {
  a, hashCode, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 8),
    ]);
  }

  test_constant_index() async {
    await assertErrorsInCode(r'''
enum E {
  a, index, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 5),
    ]);
  }

  test_constant_noSuchMethod() async {
    await assertErrorsInCode(r'''
enum E {
  a, noSuchMethod, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 12),
    ]);
  }

  test_constant_runtimeType() async {
    await assertErrorsInCode(r'''
enum E {
  a, runtimeType, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 11),
    ]);
  }

  test_constant_this_setter() async {
    await assertErrorsInCode(r'''
enum E {
  foo;
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 11, 3),
    ]);
  }

  test_constant_toString() async {
    await assertErrorsInCode(r'''
enum E {
  a, toString, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 8),
    ]);
  }

  test_field_dartCoreEnum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static final int hashCode = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 33, 8),
    ]);
  }

  test_field_mixin_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  static final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_field_mixin_method() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  static final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_field_mixin_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  static final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_field_this_constant() async {
    await assertErrorsInCode(r'''
enum E {
  foo;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 11, 3),
    ]);
  }

  test_field_this_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static final int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 33, 3),
    ]);
  }

  test_field_this_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static final int foo = 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 33, 3),
    ]);
  }

  test_field_this_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static final int foo = 0;
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 33, 3),
    ]);
  }

  test_getter_this_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 31, 3),
    ]);
  }

  test_method_dartCoreEnum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int hashCode() => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 8),
    ]);
  }

  test_method_mixin_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 3),
    ]);
  }

  test_method_mixin_method() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_method_mixin_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 3),
    ]);
  }

  test_method_this_constant() async {
    await assertErrorsInCode(r'''
enum E {
  foo;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 11, 3),
    ]);
  }

  test_method_this_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 28, 3),
    ]);
  }

  test_method_this_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 28, 3),
    ]);
  }

  test_method_this_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
  set foo(int _) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 28, 3),
    ]);
  }

  test_setter_this_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static set foo(_) {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceMixinTest extends PubPackageResolutionTest {
  test_dartCoreEnum_index_field() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  static int index = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 31, 5),
    ]);
  }

  test_dartCoreEnum_index_getter() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  static int get index => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 35, 5),
    ]);
  }

  test_dartCoreEnum_index_method() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  static int index() => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 31, 5),
    ]);
  }

  test_dartCoreEnum_index_setter() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  static set index(int _) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 31, 5),
    ]);
  }

  test_inConstraint_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_inConstraint_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }

  test_inConstraint_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 60, 3),
    ]);
  }

  test_inConstraint_implicitObject_method_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static String runtimeType() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 11),
    ]);
  }

  test_inConstraint_implicitObject_method_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static String toString() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 8),
    ]);
  }

  test_inConstraint_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }

  test_inConstraint_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 57, 3),
    ]);
  }

  test_inConstraint_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 57, 3),
    ]);
  }

  test_inConstraint_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M on A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 56, 3),
    ]);
  }

  test_inConstraint_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 56, 3),
    ]);
  }

  test_inInterface_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 72, 3),
    ]);
  }

  test_inInterface_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_inInterface_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 3),
    ]);
  }

  test_inInterface_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_inInterface_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 3),
    ]);
  }

  test_inInterface_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 3),
    ]);
  }

  test_inInterface_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_inInterface_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_inMixin_getter_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inMixin_getter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inMixin_getter_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inMixin_method_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inMixin_method_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inMixin_method_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inMixin_setter_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inMixin_setter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inMixin_setter_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }
}

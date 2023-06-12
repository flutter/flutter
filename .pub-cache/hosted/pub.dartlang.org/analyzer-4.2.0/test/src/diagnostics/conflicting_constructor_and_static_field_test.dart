// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingConstructorAndStaticFieldTest);
  });
}

@reflectiveTest
class ConflictingConstructorAndStaticFieldTest
    extends PubPackageResolutionTest {
  test_class_instance_field() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
  int foo = 0;
}
''');
  }

  test_class_static_field() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static int foo = 0;
}
''', [
      error(
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD, 14, 3),
    ]);
  }

  test_class_static_getter() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER, 14,
          3),
    ]);
  }

  test_class_static_notSameClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static int foo = 0;
}
class B extends A {
  B.foo();
}
''');
  }

  test_class_static_setter() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER, 14,
          3),
    ]);
  }

  test_enum_constant() async {
    await assertErrorsInCode(r'''
enum E {
  foo.foo();
  const E.foo();
}
''', [
      error(
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD, 32, 3),
    ]);
  }

  test_enum_instance_field() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  final int foo = 0;
}
''');
  }

  test_enum_static_field() async {
    await assertErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  static int foo = 0;
}
''', [
      error(
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD, 30, 3),
    ]);
  }

  test_enum_static_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER, 30,
          3),
    ]);
  }

  test_enum_static_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER, 30,
          3),
    ]);
  }
}

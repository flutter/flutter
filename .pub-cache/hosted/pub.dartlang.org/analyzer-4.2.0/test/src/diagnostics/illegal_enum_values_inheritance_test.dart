// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalEnumValuesInheritanceTest);
  });
}

@reflectiveTest
class IllegalEnumValuesInheritanceTest extends PubPackageResolutionTest {
  test_class_field_fromExtends() async {
    await assertErrorsInCode(r'''
class A {
  int values = 0;
}

abstract class B extends A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 46, 1),
    ]);
  }

  test_class_field_fromImplements() async {
    await assertErrorsInCode(r'''
class A {
  int values = 0;
}

abstract class B implements A, Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 46, 1),
    ]);
  }

  test_class_field_fromWith() async {
    await assertErrorsInCode(r'''
mixin M {
  int values = 0;
}

abstract class B with M implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 46, 1),
    ]);
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get values => 0;
}

abstract class B extends A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 51, 1),
    ]);
  }

  test_class_method() async {
    await assertErrorsInCode(r'''
class A {
  void values() {}
}

abstract class B extends A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 47, 1),
    ]);
  }

  test_class_setter() async {
    await assertErrorsInCode(r'''
class A {
  set values(int _) {}
}

abstract class B extends A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 51, 1),
    ]);
  }

  test_enum_getter_fromImplements() async {
    await assertErrorsInCode(r'''
class A {
  int get values => 0;
}

enum E implements A {
  v
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 41, 1),
    ]);
  }

  test_enum_method_fromImplements() async {
    await assertErrorsInCode(r'''
class A {
  int values() => 0;
}

enum E implements A {
  v
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 39, 1),
    ]);
  }

  test_enum_method_fromWith() async {
    await assertErrorsInCode(r'''
mixin M {
  int values() => 0;
}

enum E with M {
  v
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 39, 1),
    ]);
  }

  test_enum_setter_fromImplements() async {
    await assertErrorsInCode(r'''
class A {
  set values(int _) {}
}

enum E implements A {
  v
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 41, 1),
    ]);
  }

  test_enum_setter_fromWith() async {
    await assertErrorsInCode(r'''
mixin M {
  set values(int _) {}
}

enum E with M {
  v
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 41, 1),
    ]);
  }

  test_mixin_field() async {
    await assertErrorsInCode(r'''
class A {
  int values = 0;
}

mixin M on A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 37, 1),
    ]);
  }

  test_mixin_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get values => 0;
}

mixin M on A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 42, 1),
    ]);
  }

  test_mixin_method() async {
    await assertErrorsInCode(r'''
class A {
  int values() => 0;
}

mixin M on A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 40, 1),
    ]);
  }

  test_mixin_setter() async {
    await assertErrorsInCode(r'''
class A {
  set values(int _) {}
}

mixin M on A implements Enum {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE, 42, 1),
    ]);
  }
}

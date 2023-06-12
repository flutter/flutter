// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalEnumValuesDeclarationTest);
  });
}

@reflectiveTest
class IllegalEnumValuesDeclarationTest extends PubPackageResolutionTest {
  test_class_field() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int values = 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 41, 6),
    ]);
  }

  test_class_field_static() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  static int values = 0;
}
''');
  }

  test_class_getter() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int get values => 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 45, 6),
    ]);
  }

  test_class_getter_static() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  static int get values => 0;
}
''');
  }

  test_class_method() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  void values() {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 42, 6),
    ]);
  }

  test_class_method_static() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  static void values() {}
}
''');
  }

  test_class_setter() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  set values(int _) {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 41, 6),
    ]);
  }

  test_class_setter_static() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  static set values(int _) {}
}
''');
  }

  test_mixin_field() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  int values = 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 24, 6),
    ]);
  }

  test_mixin_field_static() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  static int values = 0;
}
''');
  }

  test_mixin_getter() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  int get values => 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 28, 6),
    ]);
  }

  test_mixin_getter_static() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  static int get values => 0;
}
''');
  }

  test_mixin_method() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  void values() {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 25, 6),
    ]);
  }

  test_mixin_method_static() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  static void values() {}
}
''');
  }

  test_mixin_setter() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  set values(int _) {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION, 24, 6),
    ]);
  }

  test_mixin_setter_static() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  static set values(int _) {}
}
''');
  }
}

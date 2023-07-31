// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionConflictingStaticAndInstanceTest);
  });
}

@reflectiveTest
class ExtensionConflictingStaticAndInstanceTest
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE;

  test_extendedType_field() async {
    await assertNoErrorsInCode('''
class A {
  static int foo = 0;
  int bar = 0;
}

extension E on A {
  int get foo => 0;
  static int get bar => 0;
}
''');
  }

  test_extendedType_getter() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
  int get bar => 0;
}

extension E on A {
  int get foo => 0;
  static int get bar => 0;
}
''');
  }

  test_extendedType_method() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
  void bar() {}
}

extension E on A {
  void foo() {}
  static void bar() {}
}
''');
  }

  test_extendedType_setter() async {
    await assertNoErrorsInCode('''
class A {
  static set foo(_) {}
  set bar(_) {}
}

extension E on A {
  set foo(_) {}
  static set bar(_) {}
}
''');
  }

  test_field_getter() async {
    await assertErrorsInCode('''
extension E on String {
  static int foo = 0;
  int get foo => 0;
}
''', [
      error(_errorCode, 37, 3),
    ]);
  }

  test_field_getter_unnamed() async {
    await assertErrorsInCode('''
extension on String {
  static int foo = 0;
  int get foo => 0;
}
''', [
      error(HintCode.UNUSED_FIELD, 35, 3),
      error(_errorCode, 35, 3),
      error(HintCode.UNUSED_ELEMENT, 54, 3),
    ]);
  }

  test_field_method() async {
    await assertErrorsInCode('''
extension E on String {
  static int foo = 0;
  void foo() {}
}
''', [
      error(_errorCode, 37, 3),
    ]);
  }

  test_field_setter() async {
    await assertErrorsInCode('''
extension E on String {
  static int foo = 0;
  set foo(_) {}
}
''', [
      error(_errorCode, 37, 3),
    ]);
  }

  test_getter_getter() async {
    await assertErrorsInCode('''
extension E on String {
  static int get foo => 0;
  int get foo => 0;
}
''', [
      error(_errorCode, 41, 3),
    ]);
  }

  test_getter_getter_unnamed() async {
    await assertErrorsInCode('''
extension on String {
  static int get foo => 0;
  int get foo => 0;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 39, 3),
      error(_errorCode, 39, 3),
      error(HintCode.UNUSED_ELEMENT, 59, 3),
    ]);
  }

  test_getter_method() async {
    await assertErrorsInCode('''
extension E on String {
  static int get foo => 0;
  void foo() {}
}
''', [
      error(_errorCode, 41, 3),
    ]);
  }

  test_getter_setter() async {
    await assertErrorsInCode('''
extension E on String {
  static int get foo => 0;
  set foo(_) {}
}
''', [
      error(_errorCode, 41, 3),
    ]);
  }

  test_method_getter() async {
    await assertErrorsInCode('''
extension E on String {
  static void foo() {}
  int get foo => 0;
}
''', [
      error(_errorCode, 38, 3),
    ]);
  }

  test_method_method() async {
    await assertErrorsInCode('''
extension E on String {
  static void foo() {}
  void foo() {}
}
''', [
      error(_errorCode, 38, 3),
    ]);
  }

  test_method_setter() async {
    await assertErrorsInCode('''
extension E on String {
  static void foo() {}
  set foo(_) {}
}
''', [
      error(_errorCode, 38, 3),
    ]);
  }

  test_setter_getter() async {
    await assertErrorsInCode('''
extension E on String {
  static set foo(_) {}
  int get foo => 0;
}
''', [
      error(_errorCode, 37, 3),
    ]);
  }

  test_setter_method() async {
    await assertErrorsInCode('''
extension E on String {
  static set foo(_) {}
  void foo() {}
}
''', [
      error(_errorCode, 37, 3),
    ]);
  }

  test_setter_setter() async {
    await assertErrorsInCode('''
extension E on String {
  static set foo(_) {}
  set foo(_) {}
}
''', [
      error(_errorCode, 37, 3),
    ]);
  }
}

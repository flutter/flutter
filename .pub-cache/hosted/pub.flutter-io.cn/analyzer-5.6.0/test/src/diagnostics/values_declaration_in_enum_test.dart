// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ValuesDeclarationInEnumTest);
  });
}

@reflectiveTest
class ValuesDeclarationInEnumTest extends PubPackageResolutionTest {
  test_constant() async {
    await assertErrorsInCode(r'''
enum E {
  values
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 11, 6),
    ]);
  }

  test_field() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int values = 0;
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 26, 6),
    ]);
  }

  test_field_static() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int values = 0;
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 27, 6),
    ]);
  }

  test_field_withConstructor() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final values = [];
  const E();
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 22, 6),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int get values => 0;
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 24, 6),
    ]);
  }

  test_getter_static() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int get values => 0;
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 31, 6),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void values() {}
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 21, 6),
    ]);
  }

  test_method_static() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void values() {}
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 28, 6),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  set values(_) {}
}
''', [
      error(CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM, 20, 6),
    ]);
  }

  test_setter_static() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static set values(_) {}
}
''');
  }
}

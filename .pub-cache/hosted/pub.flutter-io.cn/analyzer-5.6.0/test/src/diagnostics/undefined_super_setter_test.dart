// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperSetterTest);
  });
}

@reflectiveTest
class UndefinedSuperSetterTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  f() {
    super.m = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_SETTER, 49, 1),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super.foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_SETTER, 37, 3),
    ]);
  }

  test_enum_OK() async {
    await assertNoErrorsInCode(r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  void f() {
    super.foo = 0;
  }
}
''');
  }
}

// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperOperatorTest);
  });
}

@reflectiveTest
class UndefinedSuperOperatorTest extends PubPackageResolutionTest {
  test_class_binaryExpression() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator +(value) {
    return super + value;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 1),
    ]);
  }

  test_class_indexBoth() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index]++;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 7),
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 7),
    ]);
  }

  test_class_indexGetter() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index + 1];
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 11),
    ]);
  }

  test_class_indexSetter() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator []=(index, value) {
    super[index] = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 71, 7),
    ]);
  }

  test_enum_binaryExpression() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super + 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 37, 1),
    ]);
  }

  test_enum_binaryExpression_OK() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int operator +(int a) => 0;
}

enum E with M {
  v;
  void f() {
    super + 0;
  }
}
''');
  }

  test_enum_indexBoth() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super[0]++;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 36, 3),
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 36, 3),
    ]);
  }

  test_enum_indexBoth_OK() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}

enum E with M {
  v;
  void f() {
    super[0]++;
  }
}
''');
  }

  test_enum_indexGetter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super[0];
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 36, 3),
    ]);
  }

  test_enum_indexSetter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super[0] = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 36, 3),
    ]);
  }
}

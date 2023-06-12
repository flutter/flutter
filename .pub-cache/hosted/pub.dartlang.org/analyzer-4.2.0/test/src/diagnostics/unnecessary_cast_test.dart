// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryCastTest);
    defineReflectiveTests(UnnecessaryCastTestWithNullSafety);
  });
}

@reflectiveTest
class UnnecessaryCastTest extends PubPackageResolutionTest
    with UnnecessaryCastTestCases, WithoutNullSafetyMixin {}

mixin UnnecessaryCastTestCases on PubPackageResolutionTest {
  test_conditionalExpression_changesResultType_left() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}

dynamic f(bool c, B x, B y) {
  return c ? x as A : y;
}
''');
  }

  test_conditionalExpression_changesResultType_right() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}

dynamic f(bool c, B x, B y) {
  return c ? x : y as A;
}
''');
  }

  test_conditionalExpression_leftDynamic_rightUnnecessary() async {
    await assertErrorsInCode(r'''
dynamic f(bool c, int a, int b) {
  return c ? a : b as int;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 51, 8),
    ]);
  }

  test_conditionalExpression_leftUnnecessary() async {
    await assertErrorsInCode(r'''
dynamic f(bool c, int a, int b) {
  return c ? a as int : b;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 47, 8),
    ]);
  }

  test_conditionalExpression_leftUnnecessary_rightDynamic() async {
    await assertErrorsInCode(r'''
dynamic f(bool c, int a, dynamic b) {
  return c ? a as int : b;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 51, 8),
    ]);
  }

  test_conditionalExpression_leftUnnecessary_rightUnnecessary() async {
    await assertErrorsInCode(r'''
dynamic f(bool c, int a, int b) {
  return c ? a as int : b as int;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 47, 8),
      error(HintCode.UNNECESSARY_CAST, 58, 8),
    ]);
  }

  test_conditionalExpression_rightUnnecessary() async {
    await assertErrorsInCode(r'''
dynamic f(bool c, int a, int b) {
  return c ? a : b as int;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 51, 8),
    ]);
  }

  test_dynamic_type() async {
    await assertNoErrorsInCode(r'''
void f(a) {
  a as Object;
}
''');
  }

  test_function_toSubtype_viaParameter() async {
    await assertNoErrorsInCode(r'''
void f(void Function(int) a) {
  (a as void Function(num))(3);
}
''');
  }

  test_function_toSubtype_viaReturnType() async {
    await assertNoErrorsInCode(r'''
void f(num Function() a) {
  (a as int Function())();
}
''');
  }

  test_function_toSupertype_viaParameter() async {
    await assertErrorsInCode(r'''
void f(void Function(num) a) {
  (a as void Function(int))(3);
}
''', [
      error(HintCode.UNNECESSARY_CAST, 34, 23),
    ]);
  }

  test_function_toSupertype_viaReturnType() async {
    await assertErrorsInCode(r'''
void f(int Function() a) {
  (a as num Function())();
}
''', [
      error(HintCode.UNNECESSARY_CAST, 30, 19),
    ]);
  }

  test_function_toUnrelated() async {
    await assertNoErrorsInCode(r'''
void f(num Function(num) a) {
  (a as int Function(int))(3);
}
''');
  }

  test_function_toUnrelated_generic() async {
    await assertNoErrorsInCode(r'''
void f<T extends num>(T Function(T) a) {
  (a as int Function(int))(3);
}
''');
  }

  test_type_dynamic() async {
    await assertNoErrorsInCode(r'''
void f() {
  Object as dynamic;
}
''');
  }

  test_type_supertype() async {
    await assertErrorsInCode(r'''
void f(int a) {
  a as Object;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 18, 11),
    ]);
  }

  test_type_type() async {
    await assertErrorsInCode(r'''
void f(num a) {
  a as num;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 18, 8),
    ]);
  }

  test_typeParameter_hasBound_same() async {
    await assertErrorsInCode(r'''
void f<T extends num>(T a) {
  a as num;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 31, 8),
    ]);
  }

  test_typeParameter_hasBound_subtype() async {
    await assertErrorsInCode(r'''
void f<T extends int>(T a) {
  a as num;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 31, 8),
    ]);
  }

  test_typeParameter_hasBound_unrelated() async {
    await assertNoErrorsInCode(r'''
void f<T extends num>(T a) {
  a as String;
}
''');
  }

  test_typeParameter_noBound() async {
    await assertNoErrorsInCode(r'''
void f<T>(T a) {
  a as num;
}
''');
  }
}

@reflectiveTest
class UnnecessaryCastTestWithNullSafety extends PubPackageResolutionTest
    with UnnecessaryCastTestCases {
  test_interfaceType_star_toNone() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
int a = 0;
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f() {
  var b = a as int;
  b;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
      error(HintCode.UNNECESSARY_CAST, 39, 8),
    ]);
  }

  test_interfaceType_star_toQuestion() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.7
int a = 0;
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f() {
  var b = a as int?;
  b;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_type_type_asInterfaceTypeTypedef() async {
    await assertErrorsInCode(r'''
typedef N = num;
void f(num a) {
  a as N;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 35, 6),
    ]);
  }
}

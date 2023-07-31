// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastFromNullAlwaysFailsTest);
  });
}

@reflectiveTest
class CastFromNullAlwaysFailsTest extends PubPackageResolutionTest {
  test_Null_dynamic() async {
    await assertNoErrorsInCode('''
void f(Null n) {
  n as dynamic;
}
''');
  }

  test_Null_Never() async {
    await assertErrorsInCode('''
void f(Null n) {
  n as Never;
}
''', [
      error(WarningCode.CAST_FROM_NULL_ALWAYS_FAILS, 19, 10),
    ]);
  }

  test_Null_nonNullable() async {
    await assertErrorsInCode('''
void f(Null n) {
  n as int;
}
''', [
      error(WarningCode.CAST_FROM_NULL_ALWAYS_FAILS, 19, 8),
    ]);
  }

  test_Null_nonNullableTypeVariable() async {
    await assertErrorsInCode('''
void f<T extends Object>(Null n) {
  n as T;
}
''', [
      error(WarningCode.CAST_FROM_NULL_ALWAYS_FAILS, 37, 6),
    ]);
  }

  test_Null_nullable() async {
    await assertErrorsInCode('''
void f(Null n) {
  n as int?;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 19, 9),
    ]);
  }

  test_Null_nullableTypeVariable() async {
    await assertNoErrorsInCode('''
void f<T>(Null n) {
  n as T;
}
''');
  }

  test_Null_preNullSafety() async {
    noSoundNullSafety = false;
    await assertErrorsInCode('''
// @dart=2.9

void f(Null n) {
  n as int;
}
''', [
      error(HintCode.UNNECESSARY_CAST, 33, 8),
    ]);
  }

  test_nullable_nonNullable() async {
    await assertNoErrorsInCode('''
void f(int? n) {
  n as int;
}
''');
  }
}

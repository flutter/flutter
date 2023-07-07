// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstNotInitializedTest);
    defineReflectiveTests(ConstNotInitializedWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ConstNotInitializedTest extends PubPackageResolutionTest
    with ConstNotInitializedTestCases {
  test_enum_static() async {
    await assertErrorsInCode('''
enum E {
  v;
  static const F;
}
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 29, 1),
    ]);
  }
}

mixin ConstNotInitializedTestCases on PubPackageResolutionTest {
  test_class_static() async {
    await assertErrorsInCode(r'''
class A {
  static const F;
}
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 25, 1),
    ]);
  }

  test_extension_static() async {
    await assertErrorsInCode('''
extension E on String {
  static const F;
}
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 39, 1),
    ]);
  }

  test_local() async {
    await assertErrorsInCode(r'''
f() {
  const int x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_topLevel() async {
    await assertErrorsInCode('''
const F;
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 6, 1),
    ]);
  }
}

@reflectiveTest
class ConstNotInitializedWithoutNullSafetyTest extends PubPackageResolutionTest
    with ConstNotInitializedTestCases, WithoutNullSafetyMixin {}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterSupertypeOfItsBoundTest);
    defineReflectiveTests(
        TypeParameterSupertypeOfItsBoundWithoutNullSafetyTest);
  });
}

@reflectiveTest
class TypeParameterSupertypeOfItsBoundTest extends PubPackageResolutionTest
    with TypeParameterSupertypeOfItsBoundTestCases {}

mixin TypeParameterSupertypeOfItsBoundTestCases on PubPackageResolutionTest {
  test_1of1() async {
    await assertErrorsInCode(r'''
class A<T extends T> {
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 8, 1),
    ]);
  }

  test_1of1_used() async {
    await assertErrorsInCode('''
class A<T extends T> {
  void foo(x) {
    x is T;
  }
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 8, 1),
    ]);
  }

  test_2of3() async {
    await assertErrorsInCode(r'''
class A<T1 extends T3, T2, T3 extends T1> {
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 8, 2),
      error(CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 27, 2),
    ]);
  }
}

@reflectiveTest
class TypeParameterSupertypeOfItsBoundWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with TypeParameterSupertypeOfItsBoundTestCases, WithoutNullSafetyMixin {}

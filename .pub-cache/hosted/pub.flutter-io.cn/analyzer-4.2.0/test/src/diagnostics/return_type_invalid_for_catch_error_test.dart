// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnTypeInvalidForCatchErrorTest);
    defineReflectiveTests(ReturnTypeInvalidForCatchErrorWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ReturnTypeInvalidForCatchErrorTest extends PubPackageResolutionTest
    with ReturnTypeInvalidForCatchErrorTestCases {
  test_nullableReturnType() async {
    await assertErrorsInCode('''
void f(Future<int> future, String? Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''', [
      error(HintCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR, 91, 2),
    ]);
  }
}

mixin ReturnTypeInvalidForCatchErrorTestCases on PubPackageResolutionTest {
  test_dynamic_returnTypeIsUnrelatedFuture() async {
    await assertNoErrorsInCode('''
void f(
    Future<dynamic> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_dynamic_unrelatedReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<dynamic> future, String Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_invalidReturnType() async {
    await assertErrorsInCode('''
void f(Future<int> future, String Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''', [
      error(HintCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR, 90, 2),
    ]);
  }

  test_returnTypeIsFuture() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_returnTypeIsFutureOr() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(Future<int> future, FutureOr<int> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_sameReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, int Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_void_returnTypeIsUnrelatedFuture() async {
    await assertNoErrorsInCode('''
void f(Future<void> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_void_unrelatedReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<void> future, String Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }
}

@reflectiveTest
class ReturnTypeInvalidForCatchErrorWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with ReturnTypeInvalidForCatchErrorTestCases, WithoutNullSafetyMixin {}

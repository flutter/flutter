// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMayCompleteNormallyCatchErrorTest);
  });
}

@reflectiveTest
class BodyMayCompleteNormallyCatchErrorTest extends PubPackageResolutionTest {
  test_alwaysReturn() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) {
    return 7;
  });
}
''');
  }

  test_noReturn_futureOrVoidReturnType() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(Future<FutureOr<void>> future) {
  future.catchError((e, st) {});
}
''');
  }

  test_noReturn_namedBeforePositional() async {
    await assertErrorsInCode('''
void f(Future<int> future) {
  future.catchError(test: (_) => false, (e, st) {});
}
''', [
      error(WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR, 77, 1),
    ]);
  }

  test_noReturn_nonNullableReturnType() async {
    await assertErrorsInCode('''
void f(Future<int> future) {
  future.catchError((e, st) {});
}
''', [
      error(WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR, 57, 1),
    ]);
  }

  test_noReturn_nullableReturnType() async {
    await assertErrorsInCode('''
void f(Future<int?> future) {
  future.catchError((e, st) {});
}
''', [
      error(WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR, 58, 1),
    ]);
  }

  test_noReturn_nullReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<Null> future) {
  future.catchError((e, st) {});
}
''');
  }

  test_noReturn_voidReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((e, st) {});
}
''');
  }
}

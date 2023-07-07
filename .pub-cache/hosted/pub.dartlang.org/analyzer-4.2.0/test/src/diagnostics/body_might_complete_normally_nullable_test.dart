// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMightCompleteNormallyNullableTest);
  });
}

@reflectiveTest
class BodyMightCompleteNormallyNullableTest extends PubPackageResolutionTest {
  test_function_async_block_futureOrIntQuestion() async {
    await assertErrorsInCode('''
import 'dart:async';
FutureOr<int?> f(Future f) async {}
''', [
      error(HintCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE, 36, 1),
    ]);
  }

  test_function_async_block_futureOrVoid() async {
    await assertNoErrorsInCode('''
import 'dart:async';
FutureOr<void> f(Future f) async {}
''');
  }

  test_function_async_block_void() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(Future f) async {}
''');
  }

  test_function_sync_block_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f() {}
''');
  }

  test_function_sync_block_intQuestion() async {
    await assertErrorsInCode('''
int? f() {}
''', [
      error(HintCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE, 5, 1),
    ]);
  }

  test_function_sync_block_intQuestion_definiteReturn() async {
    await assertNoErrorsInCode('''
int? f() {
  return null;
}
''');
  }

  test_function_sync_block_Null() async {
    await assertNoErrorsInCode('''
Null f() {}
''');
  }

  test_function_sync_block_void() async {
    await assertNoErrorsInCode('''
void f() {}
''');
  }
}

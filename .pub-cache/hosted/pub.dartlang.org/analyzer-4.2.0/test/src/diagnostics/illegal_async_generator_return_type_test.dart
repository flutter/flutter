// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalAsyncGeneratorReturnTypeTest);
  });
}

@reflectiveTest
class IllegalAsyncGeneratorReturnTypeTest extends PubPackageResolutionTest {
  test_function_nonStream() async {
    await assertErrorsInCode('''
int f() async* {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 3),
    ]);
  }

  test_function_stream() async {
    await assertNoErrorsInCode('''
Stream<void> f() async* {}
''');
  }

  test_function_subtypeOfStream() async {
    await assertErrorsInCode('''
abstract class SubStream<T> implements Stream<T> {}
SubStream<int> f() async* {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 52, 14),
    ]);
  }

  test_function_void() async {
    await assertErrorsInCode('''
void f() async* {}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 4),
    ]);
  }

  test_method_nonStream() async {
    await assertErrorsInCode('''
class C {
  int f() async* {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 12, 3),
    ]);
  }

  test_method_subtypeOfStream() async {
    await assertErrorsInCode('''
abstract class SubStream<T> implements Stream<T> {}
class C {
  SubStream<int> f() async* {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 64, 14),
    ]);
  }

  test_method_void() async {
    await assertErrorsInCode('''
class C {
  void f() async* {}
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 12, 4),
    ]);
  }
}

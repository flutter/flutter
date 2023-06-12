// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalAsyncReturnTypeTest);
  });
}

@reflectiveTest
class IllegalAsyncReturnTypeTest extends PubPackageResolutionTest {
  test_function_nonFuture() async {
    await assertErrorsInCode('''
int f() async {
  return 1;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
    ]);
  }

  test_function_nonFuture_void() async {
    await assertNoErrorsInCode('''
void f() async {}
''');
  }

  test_function_nonFuture_withReturn() async {
    await assertErrorsInCode('''
int f() async {
  return 2;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
    ]);
  }

  test_function_subtypeOfFuture() async {
    await assertErrorsInCode('''
abstract class SubFuture<T> implements Future<T> {}
SubFuture<int> f() async {
  return 0;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE, 52, 14),
    ]);
  }

  test_method_nonFuture() async {
    await assertErrorsInCode('''
class C {
  int m() async {
    return 1;
  }
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE, 12, 3),
    ]);
  }

  test_method_nonFuture_void() async {
    await assertNoErrorsInCode('''
class C {
  void m() async {}
}
''');
  }

  test_method_subtypeOfFuture() async {
    await assertErrorsInCode('''
abstract class SubFuture<T> implements Future<T> {}
class C {
  SubFuture<int> m() async {
    return 0;
  }
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE, 64, 14),
    ]);
  }
}

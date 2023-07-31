// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvocationOfNonFunctionExpressionTest);
  });
}

@reflectiveTest
class InvocationOfNonFunctionExpressionTest extends PubPackageResolutionTest {
  test_literal_int() async {
    await assertErrorsInCode(r'''
void f() {
  3(5);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 13, 1),
    ]);
  }

  test_literal_null() async {
    await assertErrorsInCode(r'''
// @dart = 2.9
void f() {
  null();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 28, 4),
    ]);
  }

  test_type_Null() async {
    await assertErrorsInCode(r'''
// @dart = 2.9
void f(Null a) {
  a();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 34, 1),
    ]);
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolExpressionTest);
    defineReflectiveTests(NonBoolExpressionWithStrictCastsTest);
  });
}

@reflectiveTest
class NonBoolExpressionTest extends PubPackageResolutionTest {
  test_functionType_bool() async {
    await assertErrorsInCode(r'''
bool makeAssertion() => true;
f() {
  assert(makeAssertion);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_EXPRESSION, 45, 13),
    ]);
  }

  test_functionType_int() async {
    await assertErrorsInCode(r'''
int makeAssertion() => 1;
f() {
  assert(makeAssertion);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_EXPRESSION, 41, 13),
    ]);
  }

  test_interfaceType() async {
    await assertErrorsInCode(r'''
f() {
  assert(0);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_EXPRESSION, 15, 1),
    ]);
  }
}

@reflectiveTest
class NonBoolExpressionWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_assert() async {
    await assertErrorsWithStrictCasts('''
void f(dynamic a) {
  assert(a);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_EXPRESSION, 29, 1),
    ]);
  }
}

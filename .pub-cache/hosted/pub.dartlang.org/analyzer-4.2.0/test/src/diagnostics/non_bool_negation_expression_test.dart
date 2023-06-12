// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolNegationExpressionTest);
    defineReflectiveTests(NonBoolNegationExpressionWithoutNullSafetyTest);
    defineReflectiveTests(NonBoolNegationExpressionWithStrictCastsTest);
  });
}

@reflectiveTest
class NonBoolNegationExpressionTest extends PubPackageResolutionTest {
  test_null() async {
    await assertErrorsInCode('''
void m(Null x) {
  !x;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 20, 1),
    ]);
  }
}

@reflectiveTest
class NonBoolNegationExpressionWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_nonBool() async {
    await assertErrorsInCode(r'''
f() {
  !42;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 9, 2),
    ]);
  }

  test_nonBool_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
f() {
  ![1, 2, 3];
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 9, 9),
    ]);
  }

  test_nonBool_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
f(Object o) {
  !o;
}
''');
  }
}

@reflectiveTest
class NonBoolNegationExpressionWithStrictCastsTest
    extends PubPackageResolutionTest with WithStrictCastsMixin {
  test_negation() async {
    await assertErrorsWithStrictCasts(r'''
void f(dynamic a) {
  !a;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 23, 1),
    ]);
  }
}

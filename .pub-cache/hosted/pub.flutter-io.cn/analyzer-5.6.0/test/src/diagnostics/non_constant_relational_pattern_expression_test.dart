// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantRelationalPatternExpressionTest);
  });
}

@reflectiveTest
class NonConstantRelationalPatternExpressionTest
    extends PubPackageResolutionTest {
  test_const_integerLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case > 0) {}
}
''');
  }

  test_const_localVariable() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  const a = 0;
  if (x case > a) {}
}
''');
  }

  test_const_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
const a = 0;

void f(x) {
  if (x case > a) {}
}
''');
  }

  test_notConst_formalParameter() async {
    await assertErrorsInCode(r'''
void f(x, int a) {
  if (x case > a) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION, 34,
          1),
    ]);
  }

  test_notConst_topLevelVariable() async {
    await assertErrorsInCode(r'''
final a = 0;

void f(x) {
  if (x case > a) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION, 41,
          1),
    ]);
  }
}

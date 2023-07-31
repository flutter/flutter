// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolTest extends PubPackageResolutionTest {
  test_binary_and() async {
    await assertErrorsInCode('''
const c = true && '';
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 10),
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 18, 2),
    ]);
  }

  test_binary_leftTrue() async {
    await assertErrorsInCode('''
const c = (true || 0);
''', [
      error(HintCode.DEAD_CODE, 16, 4),
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 19, 1),
    ]);
  }

  test_binary_or() async {
    await assertErrorsInCode(r'''
const c = false || '';
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 11),
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 19, 2),
    ]);
  }

  test_lengthOfErroneousConstant() async {
    // Attempting to compute the length of constant that couldn't be evaluated
    // (due to an error) should not crash the analyzer (see dartbug.com/23383)
    await assertErrorsInCode('''
const int i = (1 ? 'alpha' : 'beta').length;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 14,
          29),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 15, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 15, 1),
    ]);
  }

  test_logicalOr_trueLeftOperand() async {
    await assertNoErrorsInCode(r'''
class C {
  final int? x;
  const C({this.x}) : assert(x == null || x >= 0);
}
const c = const C();
''');
  }
}

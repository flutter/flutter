// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolIntTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolIntTest extends PubPackageResolutionTest {
  test_binary() async {
    await _check_constEvalTypeBoolOrInt_binary("a ^ ''");
    await _check_constEvalTypeBoolOrInt_binary("a & ''");
    await _check_constEvalTypeBoolOrInt_binary("a | ''");
    await _check_constEvalTypeBoolOrInt_binary("a >> ''");
    await _check_constEvalTypeBoolOrInt_binary("a << ''");
  }

  Future<void> _check_constEvalTypeBoolOrInt_binary(String expr) async {
    await assertErrorsInCode('''
const int a = 0;
const b = $expr;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT, 27, 6),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 2),
    ]);
  }
}

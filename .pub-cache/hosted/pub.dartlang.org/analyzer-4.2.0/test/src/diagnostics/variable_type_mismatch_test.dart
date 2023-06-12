// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableTypeMismatchTest);
    defineReflectiveTests(VariableTypeMismatchWithoutNullSafetyTest);
  });
}

@reflectiveTest
class VariableTypeMismatchTest extends PubPackageResolutionTest {
  test_assignNullToInt() async {
    await assertNoErrorsInCode('''
const int? x = null;
''');
  }

  test_assignNullToUndefined() async {
    await assertErrorsInCode('''
const Unresolved x = null;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 6, 10),
    ]);
  }

  test_assignUnrelatedTypes() async {
    await assertErrorsInCode('''
const int x = 'foo';
''', [
      error(CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 14, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 14, 5),
    ]);
  }

  test_assignValueToUndefined() async {
    await assertErrorsInCode('''
const Unresolved x = 'foo';
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 6, 10),
    ]);
  }
}

@reflectiveTest
class VariableTypeMismatchWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_int_to_double_variable_reference_is_not_promoted() async {
    // Note: in the following code, the declaration of `y` should produce an
    // error because we should only promote literal ints to doubles; we
    // shouldn't promote the reference to the variable `x`.
    await assertErrorsInCode('''
const Object x = 0;
const double y = x;
''', [
      error(CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 37, 1),
    ]);
  }

  test_listLiteral_inferredElementType() async {
    await assertErrorsInCode('''
const Object x = [1];
const List<String> y = x;
''', [
      error(CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 45, 1),
    ]);
  }

  test_mapLiteral_inferredKeyType() async {
    await assertErrorsInCode('''
const Object x = {1: 1};
const Map<String, dynamic> y = x;
''', [
      error(CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 56, 1),
    ]);
  }

  test_mapLiteral_inferredValueType() async {
    await assertErrorsInCode('''
const Object x = {1: 1};
const Map<dynamic, String> y = x;
''', [
      error(CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 56, 1),
    ]);
  }
}

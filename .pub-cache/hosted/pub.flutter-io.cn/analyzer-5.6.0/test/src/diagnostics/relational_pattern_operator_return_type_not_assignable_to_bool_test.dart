// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        RelationalPatternOperatorReturnTypeNotAssignableToBoolTest);
  });
}

@reflectiveTest
class RelationalPatternOperatorReturnTypeNotAssignableToBoolTest
    extends PubPackageResolutionTest {
  test_dynamic() async {
    await assertNoErrorsInCode(r'''
class A {
  dynamic operator >(_) => 42;
}

void f(A x) {
  if (x case > 0) {}
}
''');
  }

  test_int() async {
    await assertErrorsInCode(r'''
class A {
  int operator >(_) => 42;
}

void f(A x) {
  if (x case > 0) {}
}
''', [
      error(
          CompileTimeErrorCode
              .RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL,
          67,
          1),
    ]);
  }

  test_Object() async {
    await assertErrorsInCode(r'''
class A {
  Object operator >(_) => 42;
}

void f(A x) {
  if (x case > 0) {}
}
''', [
      error(
          CompileTimeErrorCode
              .RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL,
          70,
          1),
    ]);
  }
}

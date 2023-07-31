// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternAssignmentNotLocalVariableTest);
  });
}

@reflectiveTest
class PatternAssignmentNotLocalVariableTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode('''
void f() {
  (int) = 0;
}
''', [
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 14, 3),
    ]);
  }

  test_class_field() async {
    await assertErrorsInCode('''
class A {
  var x = 0;

  void f() {
    (x) = 0;
  }
}
''', [
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 42, 1),
    ]);
  }

  test_class_typeParameter() async {
    await assertErrorsInCode('''
class A<T> {
  void f() {
    (T) = 0;
  }
}
''', [
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 31, 1),
    ]);
  }

  test_dynamic() async {
    await assertErrorsInCode('''
void f() {
  (dynamic) = 0;
}
''', [
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 14, 7),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
void f() {
  (f) = 0;
}
''', [
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 14, 1),
    ]);
  }

  test_topLevelVariable() async {
    await assertErrorsInCode('''
var x = 0;

void f() {
  (x) = 0;
}
''', [
      error(CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE, 26, 1),
    ]);
  }
}

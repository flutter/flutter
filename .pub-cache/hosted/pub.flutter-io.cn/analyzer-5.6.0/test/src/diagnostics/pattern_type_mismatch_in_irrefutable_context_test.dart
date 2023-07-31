// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PatternTypeMismatchInIrrefutableContextTest);
  });
}

@reflectiveTest
class PatternTypeMismatchInIrrefutableContextTest
    extends PubPackageResolutionTest {
  test_listPattern_differentList() async {
    await assertErrorsInCode(r'''
void f(List<Object> x) {
  var <int>[a] = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          31, 8),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
  }

  test_listPattern_notList() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  var [a] = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          25, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_mapPattern_notMap() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  var <int, String>{0: a} = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          25, 19),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 42, 1),
    ]);
  }

  test_objectPattern_differentClass() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  var String(length: a) = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          25, 17),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
    ]);
  }

  test_patternAssignment_assignedVariablePattern() async {
    await assertErrorsInCode(r'''
void f(int a) {
  (a) = 1.2;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          19, 1),
    ]);
  }

  test_recordPattern_notRecord() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  var (a,) = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          25, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_recordPattern_record_differentShape() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  var (a,) = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          30, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 31, 1),
    ]);
  }

  test_variablePattern_assignable_fromDynamic() async {
    await assertErrorsInCode(r'''
void f(dynamic x) {
  var (int a) = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 31, 1),
    ]);
  }

  test_variablePattern_assignable_fromSubtype() async {
    await assertErrorsInCode(r'''
void f(int x) {
  var (num a) = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
    ]);
  }

  test_variablePattern_notAssignable_fromSupertype() async {
    await assertErrorsInCode(r'''
void f(num x) {
  var (int a) = x;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          23, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
    ]);
  }
}

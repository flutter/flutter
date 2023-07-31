// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToConstTest);
  });
}

@reflectiveTest
class AssignmentToConstTest extends PubPackageResolutionTest {
  test_instanceVariable() async {
    await assertErrorsInCode('''
class A {
  static const v = 0;
}
f() {
  A.v = 1;
}''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 44, 1),
    ]);
  }

  test_instanceVariable_plusEq() async {
    await assertErrorsInCode('''
class A {
  static const v = 0;
}
f() {
  A.v += 1;
}''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 44, 1),
    ]);
  }

  test_localVariable() async {
    await assertErrorsInCode('''
f() {
  const x = 0;
  x = 1;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 23, 1),
    ]);
  }

  test_localVariable_inForEach() async {
    await assertErrorsInCode('''
f() {
  const x = 0;
  for (x in <int>[1, 2]) {
    print(x);
  }
}''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 28, 1),
    ]);
  }

  test_localVariable_plusEq() async {
    await assertErrorsInCode('''
f() {
  const x = 0;
  x += 1;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 23, 1),
    ]);
  }
}

// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePatternAssignmentVariableTest);
  });
}

@reflectiveTest
class DuplicatePatternAssignmentVariableTest extends PubPackageResolutionTest {
  test_nested() async {
    await assertErrorsInCode(r'''
void f() {
  int a;
  (a && int(sign: a)) = 0;
  a;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE, 38, 1,
          contextMessages: [message('/home/test/lib/test.dart', 23, 1)]),
    ]);
  }

  test_record_2() async {
    await assertErrorsInCode(r'''
void f() {
  int a;
  (a, a) = (1, 2);
  a;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE, 26, 1,
          contextMessages: [message('/home/test/lib/test.dart', 23, 1)]),
    ]);
  }

  test_record_3() async {
    await assertErrorsInCode(r'''
void f() {
  int a;
  (a, a, a) = (1, 2, 3);
  a;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE, 26, 1,
          contextMessages: [message('/home/test/lib/test.dart', 23, 1)]),
      error(CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE, 29, 1,
          contextMessages: [message('/home/test/lib/test.dart', 23, 1)]),
    ]);
  }

  test_separate() async {
    await assertNoErrorsInCode(r'''
void f() {
  int a;
  (a) = 1;
  (a) = 2;
  a;
}
''');
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseBlockNotTerminatedTest);
    defineReflectiveTests(CaseBlockNotTerminatedWithoutNullSafetyTest);
  });
}

@reflectiveTest
class CaseBlockNotTerminatedTest extends PubPackageResolutionTest {
  test_lastCase() async {
    await assertNoErrorsInCode(r'''
f(int a) {
  switch (a) {
    case 0:
      print(0);
  }
}
''');
  }

  test_terminated_break() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      break;
    default:
      return;
  }
}
''');
  }

  test_terminated_continue_loop() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  while (true) {
    switch (a) {
      case 0:
        continue;
      default:
        return;
    }
  }
}
''');
  }

  test_terminated_return() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      return;
    default:
      return;
  }
}
''');
  }

  test_terminated_return2() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
    case 1:
      return;
    default:
      return;
  }
}
''');
  }

  test_terminated_throw() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      throw 42;
    default:
      return;
  }
}
''');
  }
}

@reflectiveTest
class CaseBlockNotTerminatedWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_notTerminated() async {
    await assertErrorsInCode('''
void f(int a) {
  switch (a) {
    case 0:
      print(0);
    default:
      return;
  }
}''', [
      error(CompileTimeErrorCode.CASE_BLOCK_NOT_TERMINATED, 35, 4),
    ]);
  }
}

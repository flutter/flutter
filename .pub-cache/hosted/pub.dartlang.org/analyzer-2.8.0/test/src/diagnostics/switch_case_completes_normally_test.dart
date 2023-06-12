// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchCaseCompletesNormallyTest);
  });
}

@reflectiveTest
class SwitchCaseCompletesNormallyTest extends PubPackageResolutionTest {
  test_break() async {
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

  test_completes() async {
    await assertErrorsInCode('''
void f(int a) {
  switch (a) {
    case 0:
      print(0);
    default:
      return;
  }
}''', [
      error(CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY, 35, 4),
    ]);
  }

  test_continue_loop() async {
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

  test_for_whatever() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      for (;;) {
        print(0);
      }
    default:
      return;
  }
}
''');
  }

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

  test_methodInvocation_never() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      neverCompletes();
    default:
      return;
  }
}

Never neverCompletes() {
  throw 0;
}
''');
  }

  test_return() async {
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

  test_return2() async {
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

  test_throw() async {
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

  test_while_true() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      while (true) {
        print(0);
      }
    default:
      return;
  }
}
''');
  }
}

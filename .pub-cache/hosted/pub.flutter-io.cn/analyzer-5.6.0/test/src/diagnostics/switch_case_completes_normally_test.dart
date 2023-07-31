// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchCaseCompletesNormallyTest);
    defineReflectiveTests(SwitchCaseCompletesNormallyTest_Language218);
  });
}

@reflectiveTest
class SwitchCaseCompletesNormallyTest extends PubPackageResolutionTest
    with SwitchCaseCompletesNormallyTestCases {
  @override
  bool get _patternsEnabled => true;
}

@reflectiveTest
class SwitchCaseCompletesNormallyTest_Language218
    extends PubPackageResolutionTest
    with WithLanguage218Mixin, SwitchCaseCompletesNormallyTestCases {
  @override
  bool get _patternsEnabled => false;
}

mixin SwitchCaseCompletesNormallyTestCases on PubPackageResolutionTest {
  bool get _patternsEnabled;

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
      if (!_patternsEnabled)
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

  test_multiple_cases_sharing_a_body() async {
    await assertErrorsInCode('''
void f(int a) {
  switch (a) {
    case 0:
    case 1:
      print(0);
    default:
      return;
  }
}''', [
      if (!_patternsEnabled)
        error(CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY, 35, 4),
    ]);
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

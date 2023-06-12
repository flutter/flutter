// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LateFinalLocalAlreadyAssignedTest);
  });
}

@reflectiveTest
class LateFinalLocalAlreadyAssignedTest extends PubPackageResolutionTest {
  test_assignmentExpression_compound() async {
    await assertErrorsInCode('''
main() {
  late final int v;
  v = 0;
  v += 1;
  v;
}
''', [
      error(CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED, 40, 1),
    ]);
  }

  test_assignmentExpression_simple() async {
    await assertErrorsInCode('''
main() {
  late final int v;
  v = 0;
  v = 1;
  v;
}
''', [
      error(CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED, 40, 1),
    ]);
  }

  test_assignmentExpression_simple_initialized() async {
    await assertErrorsInCode('''
main() {
  late final int v = 0;
  v = 1;
  v;
}
''', [
      error(CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED, 35, 1),
    ]);
  }

  test_postfixExpression_inc() async {
    await assertErrorsInCode('''
main() {
  late final int v = 0;
  v++;
  v;
}
''', [
      error(CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED, 35, 1),
    ]);
  }

  test_postfixExpression_nullCheck() async {
    await assertErrorsInCode('''
main() {
  late final int v = 0;
  v!;
  v;
}
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 36, 1),
    ]);
  }

  test_prefixExpression_inc() async {
    await assertErrorsInCode('''
main() {
  late final int v = 0;
  ++v;
  v;
}
''', [
      error(CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED, 37, 1),
    ]);
  }

  test_prefixExpression_negation() async {
    await assertNoErrorsInCode('''
main() {
  late final bool v = true;
  !v;
  v;
}
''');
  }
}

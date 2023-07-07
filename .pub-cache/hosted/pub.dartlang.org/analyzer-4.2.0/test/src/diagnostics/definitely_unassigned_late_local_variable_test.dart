// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinitelyUnassignedLateLocalVariableTest);
  });
}

@reflectiveTest
class DefinitelyUnassignedLateLocalVariableTest
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode {
    return CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE;
  }

  test_definitelyAssigned_after_compoundAssignment() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  v += 1;
  v;
}
''', [
      error(_errorCode, 27, 1),
    ]);
  }

  test_definitelyAssigned_after_postfixExpression_increment() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  v++;
  v;
}
''', [
      error(_errorCode, 27, 1),
    ]);
  }

  test_mightBeAssigned_if_else() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  late int v;
  if (c) {
    print(0);
  } else {
    v = 0;
  }
  v;
}
''');
  }

  test_mightBeAssigned_if_then() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  late int v;
  if (c) {
    v = 0;
  }
  v;
}
''');
  }

  test_mightBeAssigned_while() async {
    await assertNoErrorsInCode(r'''
void f(bool c) {
  late int v;
  while (c) {
    v = 0;
  }
  v;
}
''');
  }

  test_neverAssigned_assignment_compound() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  v += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
      error(_errorCode, 27, 1),
    ]);
  }

  test_neverAssigned_assignment_pure() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  v = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);
  }

  test_neverAssigned_nullable() async {
    await assertErrorsInCode(r'''
void f() {
  late int? v;
  v;
}
''', [
      error(_errorCode, 28, 1),
    ]);
  }

  test_neverAssigned_prefixExpression() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  ++v;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
      error(_errorCode, 29, 1),
    ]);
  }

  test_neverAssigned_read() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  v;
}
''', [
      error(_errorCode, 27, 1),
    ]);
  }

  test_neverAssigned_suffixExpression() async {
    await assertErrorsInCode(r'''
void f() {
  late int v;
  v++;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
      error(_errorCode, 27, 1),
    ]);
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeIsNotSwitchExpressionSubtype);
  });
}

@reflectiveTest
class CaseExpressionTypeIsNotSwitchExpressionSubtype
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode {
    return CompileTimeErrorCode
        .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE;
  }

  test_notSubtype() async {
    await assertErrorsInCode('''
class A {
  const A();
}

class B {
  final int value;
  const B(this.value);
}

const dynamic B0 = B(0);

void f(A e) {
  switch (e) {
    case B0:
      break;
    case B(1):
      break;
  }
}
''', [
      error(_errorCode, 145, 2),
      error(_errorCode, 171, 4),
    ]);
  }

  test_subtype() async {
    await assertNoErrorsInCode('''
class A {
  final int value;
  const A(this.value);
}

class B extends A {
  const B(int value) : super(value);
}

class C extends A {
  const C(int value) : super(value);
}

void f(A e) {
  switch (e) {
    case B(0):
      break;
    case C(0):
      break;
  }
}
''');
  }
}

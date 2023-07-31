// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionEqEqOperatorTest);
  });
}

@reflectiveTest
class SdkVersionEqEqOperatorTest extends SdkConstraintVerifierTest {
  test_left_equals() async {
    await verifyVersion('2.5.0', '''
class A {
  const A();
}
const A? a = A();
const c = a == null;
''');
  }

  test_left_lessThan() async {
    await verifyVersion('2.2.0', '''
class A {
  const A();
}
const A? a = A();
const c = a == null;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT, 55, 2),
    ]);
  }

  test_right_equals() async {
    await verifyVersion('2.5.0', '''
class A {
  const A();
}
const A a = A();
const c = 0 == a;
''');
  }

  test_right_lessThan() async {
    await verifyVersion('2.2.0', '''
class A {
  const A();
}
const A a = A();
const c = 0 == a;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_EQ_EQ_OPERATOR_IN_CONST_CONTEXT, 54, 2),
    ]);
  }
}

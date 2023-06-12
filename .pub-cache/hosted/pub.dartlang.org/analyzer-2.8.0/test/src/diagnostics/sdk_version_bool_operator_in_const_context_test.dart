// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionBoolOperatorInConstContextTest);
  });
}

@reflectiveTest
class SdkVersionBoolOperatorInConstContextTest
    extends SdkConstraintVerifierTest {
  test_and_const_equals() async {
    await verifyVersion('2.5.0', '''
const c = true & false;
''');
  }

  test_and_const_lessThan() async {
    await verifyVersion('2.2.0', '''
const c = true & false;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT, 15, 1),
    ]);
  }

  test_and_nonConst_equals() async {
    await verifyVersion('2.5.0', '''
var c = true & false;
''');
  }

  test_and_nonConst_lessThan() async {
    await verifyVersion('2.2.0', '''
var c = true & false;
''');
  }

  test_or_const_equals() async {
    await verifyVersion('2.5.0', '''
const c = true | false;
''');
  }

  test_or_const_lessThan() async {
    await verifyVersion('2.2.0', '''
const c = true | false;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT, 15, 1),
    ]);
  }

  test_or_nonConst_equals() async {
    await verifyVersion('2.5.0', '''
var c = true | false;
''');
  }

  test_or_nonConst_lessThan() async {
    await verifyVersion('2.2.0', '''
var c = true | false;
''');
  }

  test_xor_const_equals() async {
    await verifyVersion('2.5.0', '''
const c = true ^ false;
''');
  }

  test_xor_const_lessThan() async {
    await verifyVersion('2.2.0', '''
const c = true ^ false;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_BOOL_OPERATOR_IN_CONST_CONTEXT, 15, 1),
    ]);
  }

  test_xor_nonConst_equals() async {
    await verifyVersion('2.5.0', '''
var c = true ^ false;
''');
  }

  test_xor_nonConst_lessThan() async {
    await verifyVersion('2.2.0', '''
var c = true ^ false;
''');
  }
}

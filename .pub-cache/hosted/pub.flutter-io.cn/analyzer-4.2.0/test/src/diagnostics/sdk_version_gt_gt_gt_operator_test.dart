// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionGtGtGtOperatorTest);
  });
}

@reflectiveTest
class SdkVersionGtGtGtOperatorTest extends SdkConstraintVerifierTest {
  @override
  String get testPackageLanguageVersion =>
      '${ExperimentStatus.currentVersion.major}.'
      '${ExperimentStatus.currentVersion.minor}';

  test_const_equals() async {
    await verifyVersion('2.15.0', '''
const a = 42 >>> 3;
''');
  }

  test_const_lessThan() async {
    await verifyVersion('2.13.0', '''
const a = 42 >>> 3;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_GT_GT_GT_OPERATOR, 13, 3),
    ]);
  }

  test_declaration_equals() async {
    await verifyVersion('2.15.0', '''
class A {
  A operator >>>(A a) => this;
}
''');
  }

  test_declaration_lessThan() async {
    await verifyVersion('2.13.0', '''
class A {
  A operator >>>(A a) => this;
}
''', expectedErrors: [
      error(HintCode.SDK_VERSION_GT_GT_GT_OPERATOR, 23, 3),
    ]);
  }

  test_nonConst_equals() async {
    await verifyVersion('2.15.0', '''
var a = 42 >>> 3;
''');
  }

  test_nonConst_lessThan() async {
    await verifyVersion('2.13.0', '''
var a = 42 >>> 3;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_GT_GT_GT_OPERATOR, 11, 3),
    ]);
  }
}

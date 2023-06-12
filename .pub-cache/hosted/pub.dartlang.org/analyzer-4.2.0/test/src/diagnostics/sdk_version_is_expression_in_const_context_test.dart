// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionIsExpressionInConstContextTest);
  });
}

@reflectiveTest
class SdkVersionIsExpressionInConstContextTest
    extends SdkConstraintVerifierTest {
  test_equals() async {
    await verifyVersion('2.5.0', '''
const dynamic a = 2;
const c = a is int;
''');
  }

  test_lessThan() async {
    await verifyVersion('2.2.0', '''
const dynamic a = 2;
const c = a is int;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_IS_EXPRESSION_IN_CONST_CONTEXT, 31, 8),
    ]);
  }
}

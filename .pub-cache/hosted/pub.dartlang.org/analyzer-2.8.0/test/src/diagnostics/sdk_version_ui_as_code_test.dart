// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionUiAsCodeTest);
  });
}

@reflectiveTest
class SdkVersionUiAsCodeTest extends SdkConstraintVerifierTest {
  test_equals() async {
    await verifyVersion('2.2.2', '''
List<int> zero() => [for (var e in [0]) e];
''');
  }

  test_greaterThan() async {
    await verifyVersion('2.3.0', '''
List<int> zero() => [...[0]];
''');
  }

  test_lessThan() async {
    await verifyVersion('2.2.1', '''
List<int> zero() => [if (0 < 1) 0];
''', expectedErrors: [
      error(HintCode.SDK_VERSION_UI_AS_CODE, 21, 12),
    ]);
  }
}

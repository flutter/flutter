// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementResolutionTest);
  });
}

@reflectiveTest
class IfStatementResolutionTest extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  if ( b() ) {
    print(0);
  }
}
''');

    assertFunctionExpressionInvocation(
      findNode.functionExpressionInvocation('b()'),
      element: null,
      typeArgumentTypes: [],
      invokeType: 'bool Function()',
      type: 'bool',
    );
  }
}

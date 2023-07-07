// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitExpressionResolutionTest);
    defineReflectiveTests(AwaitExpressionResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class AwaitExpressionResolutionTest extends PubPackageResolutionTest {
  test_futureOrQ() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(FutureOr<int>? a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int?');
  }

  test_futureQ() async {
    await assertNoErrorsInCode(r'''
f(Future<int>? a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int?');
  }
}

@reflectiveTest
class AwaitExpressionResolutionWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_future() async {
    await assertNoErrorsInCode(r'''
f(Future<int> a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int');
  }

  test_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

f(FutureOr<int> a) async {
  await a;
}
''');

    assertType(findNode.awaitExpression('await a'), 'int');
  }
}

// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedOneListPatternTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedOneListPatternTypeArgumentsTest extends PubPackageResolutionTest {
  test_1() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case <int>[0]) {}
}
''');
  }

  test_2() async {
    await assertErrorsInCode(r'''
void f(x) {
  if (x case <int, int>[0]) {}
}
''', [
      error(CompileTimeErrorCode.EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS, 25,
          10),
    ]);
  }
}

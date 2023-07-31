// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedTwoMapPatternTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedTwoMapPatternTypeArgumentsTest extends PubPackageResolutionTest {
  test_0() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case {}) {}
}
''');
  }

  test_1() async {
    await assertErrorsInCode(r'''
void f(x) {
  if (x case <int>{}) {}
}
''', [
      error(
          CompileTimeErrorCode.EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS, 25, 5),
    ]);
  }

  test_2() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case <bool, int>{}) {}
}
''');
  }

  test_3() async {
    await assertErrorsInCode(r'''
void f(x) {
  if (x case <bool, int, String>{}) {}
}
''', [
      error(
          CompileTimeErrorCode.EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS, 25, 19),
    ]);
  }
}

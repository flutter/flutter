// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedTwoMapTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedTwoMapTypeArgumentsTest extends PubPackageResolutionTest {
  test_three_type_arguments_ambiguous() async {
    // TODO(brianwilkerson) We probably need a new error code for "expected
    //  either one or two type arguments" to handle the ambiguous case.
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{};
}''', [
      error(CompileTimeErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_three_type_arguments_map() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{1: 2};
}''', [
      error(CompileTimeErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_two_type_arguments() async {
    await assertNoErrorsInCode(r'''
main() {
  <int, int> {};
}
''');
  }
}

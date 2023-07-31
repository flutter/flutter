// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedOneListTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedOneListTypeArgumentsTest extends PubPackageResolutionTest {
  test_one_type_argument() async {
    await assertNoErrorsInCode(r'''
main() {
  <int> [];
}
''');
  }

  test_two_type_arguments() async {
    await assertErrorsInCode(r'''
main() {
  <int, int>[];
}''', [
      error(CompileTimeErrorCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS, 11, 10),
    ]);
  }
}

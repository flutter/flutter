// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedOneSetTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedOneSetTypeArgumentsTest extends PubPackageResolutionTest {
  test_multiple_type_arguments() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{2, 3};
}''', [
      error(CompileTimeErrorCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS, 11, 15),
    ]);
  }
}

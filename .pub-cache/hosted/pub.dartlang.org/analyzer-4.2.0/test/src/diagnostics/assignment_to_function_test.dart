// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFunctionTest);
  });
}

@reflectiveTest
class AssignmentToFunctionTest extends PubPackageResolutionTest {
  test_function() async {
    await assertErrorsInCode('''
f() {}
main() {
  f = null;
}''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION, 18, 1),
    ]);
  }
}

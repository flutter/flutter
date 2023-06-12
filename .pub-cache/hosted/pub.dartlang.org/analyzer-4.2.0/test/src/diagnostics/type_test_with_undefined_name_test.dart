// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeTestWithUndefinedNameTest);
  });
}

@reflectiveTest
class TypeTestWithUndefinedNameTest extends PubPackageResolutionTest {
  test_undefined() async {
    await assertErrorsInCode('''
f(var p) {
  if (p is A) {
  }
}''', [
      error(CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME, 22, 1),
    ]);
  }
}

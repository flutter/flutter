// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToInvalidReturnTypeTest);
  });
}

@reflectiveTest
class RedirectToInvalidReturnTypeTest extends PubPackageResolutionTest {
  test_redirectToInvalidReturnType() async {
    await assertErrorsInCode('''
class A {
  A() {}
}
class B {
  factory B() = A;
}''', [
      error(CompileTimeErrorCode.REDIRECT_TO_INVALID_RETURN_TYPE, 47, 1),
    ]);
  }
}

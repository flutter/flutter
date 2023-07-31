// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToNonClassTest);
  });
}

@reflectiveTest
class RedirectToNonClassTest extends PubPackageResolutionTest {
  test_notAType() async {
    await assertErrorsInCode('''
class B {
  int A = 0;
  factory B() = A;
}''', [
      error(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, 39, 1),
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 39, 1),
    ]);
  }

  test_undefinedIdentifier() async {
    await assertErrorsInCode('''
class B {
  factory B() = A;
}''', [
      error(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, 26, 1),
    ]);
  }
}

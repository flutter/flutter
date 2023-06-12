// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToInvalidFunctionTypeTest);
  });
}

@reflectiveTest
class RedirectToInvalidFunctionTypeTest extends PubPackageResolutionTest {
  test_redirectToInvalidFunctionType() async {
    await assertErrorsInCode('''
class A implements B {
  A(int p) {}
}
class B {
  factory B() = A;
}''', [
      error(CompileTimeErrorCode.REDIRECT_TO_INVALID_FUNCTION_TYPE, 65, 1),
    ]);
  }

  test_valid_redirect() async {
    await assertNoErrorsInCode(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B(int p) = A;
}
''');
  }
}

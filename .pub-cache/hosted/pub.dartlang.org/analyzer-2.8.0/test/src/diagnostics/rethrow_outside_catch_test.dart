// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RethrowOutsideCatchTest);
  });
}

@reflectiveTest
class RethrowOutsideCatchTest extends PubPackageResolutionTest {
  test_insideCatch() async {
    await assertNoErrorsInCode(r'''
class A {
  void m() {
    try {} catch (e) {rethrow;}
  }
}
''');
  }

  test_withoutCatch() async {
    await assertErrorsInCode(r'''
f() {
  rethrow;
}
''', [
      error(CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, 8, 7),
    ]);
  }
}

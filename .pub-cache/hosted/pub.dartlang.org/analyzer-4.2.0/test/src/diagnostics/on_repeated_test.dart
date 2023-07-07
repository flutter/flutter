// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OnRepeatedTest);
  });
}

@reflectiveTest
class OnRepeatedTest extends PubPackageResolutionTest {
  test_2times() async {
    await assertErrorsInCode(r'''
class A {}
mixin M on A, A {}
''', [
      error(CompileTimeErrorCode.ON_REPEATED, 25, 1),
    ]);
  }

  test_2times_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
typedef B = A;
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.ON_REPEATED, 40, 1),
    ]);
  }
}

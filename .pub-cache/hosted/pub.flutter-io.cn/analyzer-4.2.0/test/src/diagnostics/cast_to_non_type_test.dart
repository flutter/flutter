// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastToNonTypeTest);
  });
}

@reflectiveTest
class CastToNonTypeTest extends PubPackageResolutionTest {
  test_variable() async {
    await assertErrorsInCode('''
var A = 0;
f(String s) { var x = s as A; }''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(CompileTimeErrorCode.CAST_TO_NON_TYPE, 38, 1),
    ]);
  }
}

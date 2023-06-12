// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapValueTest);
  });
}

@reflectiveTest
class NonConstantMapValueTest extends PubPackageResolutionTest
    with NonConstantMapValueTestCases {}

mixin NonConstantMapValueTestCases on PubPackageResolutionTest {
  test_const_ifTrue_elseFinal() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a': 'b', 'c' : a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 81, 1),
    ]);
  }

  test_const_ifTrue_thenFinal() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a' : a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 71, 1),
    ]);
  }

  test_const_topLevel() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const {'a' : a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 42, 1),
    ]);
  }
}

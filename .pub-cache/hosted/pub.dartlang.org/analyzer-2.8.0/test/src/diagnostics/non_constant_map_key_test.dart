// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapKeyTest);
  });
}

@reflectiveTest
class NonConstantMapKeyTest extends PubPackageResolutionTest
    with NonConstantMapKeyTestCases {}

mixin NonConstantMapKeyTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenTrue_elseFinal() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 0: 1 else a : 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 75, 1),
    ]);
  }

  test_const_ifElement_thenTrue_thenFinal() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) a : 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 65, 1),
    ]);
  }

  test_const_topLevel() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const {a : 0};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 36, 1),
    ]);
  }
}

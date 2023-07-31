// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelCycleTest);
  });
}

@reflectiveTest
class TopLevelCycleTest extends PubPackageResolutionTest {
  test_cycle() async {
    await assertErrorsInCode(r'''
var x = y + 1;
var y = x + 1;
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 1),
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 19, 1),
    ]);
  }

  test_singleVariable() async {
    await assertErrorsInCode(r'''
var x = x;
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 1),
    ]);
  }

  test_singleVariable_fromList() async {
    await assertErrorsInCode(r'''
var elems = [
  [
    1, elems, 3,
  ],
];
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 5),
    ]);
  }
}

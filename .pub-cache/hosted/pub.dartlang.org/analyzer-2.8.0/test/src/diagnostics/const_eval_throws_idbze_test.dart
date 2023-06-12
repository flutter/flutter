// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalThrowsIdbzeTest);
  });
}

@reflectiveTest
class ConstEvalThrowsIdbzeTest extends PubPackageResolutionTest {
  test_divisionByZero() async {
    await assertErrorsInCode('''
const C = 1 ~/ 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE, 10, 6),
    ]);
  }
}

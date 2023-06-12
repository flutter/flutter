// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalTypeBoolNumStringTest);
  });
}

@reflectiveTest
class ConstEvalTypeBoolNumStringTest extends PubPackageResolutionTest {
  test_equal() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

const num a = 0;
const b = a == const A();
''');
  }

  test_notEqual() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

const num a = 0;
const _ = a != const A();
''', [
      error(HintCode.UNUSED_ELEMENT, 49, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 53, 14),
    ]);
  }
}

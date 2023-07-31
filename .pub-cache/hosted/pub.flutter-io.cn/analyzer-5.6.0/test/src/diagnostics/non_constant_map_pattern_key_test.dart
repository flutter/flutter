// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapPatternKeyTest);
  });
}

@reflectiveTest
class NonConstantMapPatternKeyTest extends PubPackageResolutionTest {
  test_formalParameter() async {
    await assertErrorsInCode(r'''
void f(x, int a) {
  if (x case {a: 0}) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY, 33, 1),
    ]);
  }

  test_instanceCreation_noConst() async {
    await assertErrorsInCode(r'''
void f(x) {
  if (x case {A(): 0}) {}
}

class A {
  const A();
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY, 26, 3),
    ]);
  }

  test_integerLiteral() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case {0: 1}) {}
}
''');
  }
}

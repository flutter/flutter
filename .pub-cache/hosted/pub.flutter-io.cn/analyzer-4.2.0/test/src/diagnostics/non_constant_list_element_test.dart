// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantListElementTest);
  });
}

@reflectiveTest
class NonConstantListElementTest extends PubPackageResolutionTest
    with NonConstantListElementTestCases {}

mixin NonConstantListElementTestCases on PubPackageResolutionTest {
  test_const_forElement() async {
    await assertErrorsInCode(r'''
const Set set = {};
var v = const [for(final x in set) x];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 35, 21),
    ]);
  }

  test_const_ifElement_thenElseFalse_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [if (1 < 0) 0 else a];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 54, 1),
    ]);
  }

  test_const_ifElement_thenElseFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [if (1 < 0) a else 0];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
    ]);
  }

  test_const_ifElement_thenElseTrue_finalElse() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [if (1 > 0) 0 else a];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 54, 1),
    ]);
  }

  test_const_ifElement_thenElseTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [if (1 > 0) a else 0];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
    ]);
  }

  test_const_ifElement_thenFalse_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const [if (1 < 0) a];
''');
  }

  test_const_ifElement_thenFalse_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [if (1 < 0) a];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
    ]);
  }

  test_const_ifElement_thenTrue_constThen() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const [if (1 > 0) a];
''');
  }

  test_const_ifElement_thenTrue_finalThen() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [if (1 > 0) a];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 47, 1),
    ]);
  }

  test_const_topVar() async {
    await assertErrorsInCode('''
final dynamic a = 0;
var v = const [a];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 1),
    ]);
  }

  test_const_topVar_nested() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const [a + 1];
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT, 36, 1),
    ]);
  }

  test_nonConst_topVar() async {
    await assertNoErrorsInCode('''
final dynamic a = 0;
var v = [a];
''');
  }
}

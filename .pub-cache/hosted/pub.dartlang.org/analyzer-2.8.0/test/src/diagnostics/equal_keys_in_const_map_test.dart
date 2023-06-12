// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EqualKeysInConstMapTest);
  });
}

@reflectiveTest
class EqualKeysInConstMapTest extends PubPackageResolutionTest
    with EqualKeysInConstMapTestCases {}

mixin EqualKeysInConstMapTestCases on PubPackageResolutionTest {
  test_const_entry() async {
    await assertErrorsInCode('''
var c = const {1: null, 2: null, 1: null};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 33, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_const_ifElement_thenElseFalse() async {
    await assertErrorsInCode('''
var c = const {1: null, if (1 < 0) 2: null else 1: null};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 48, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_const_ifElement_thenElseFalse_onlyElse() async {
    await assertNoErrorsInCode('''
var c = const {if (0 < 1) 1: null else 1: null};
''');
  }

  test_const_ifElement_thenElseTrue() async {
    await assertNoErrorsInCode('''
var c = const {1: null, if (0 < 1) 2: null else 1: null};
''');
  }

  test_const_ifElement_thenElseTrue_onlyThen() async {
    await assertNoErrorsInCode('''
var c = const {if (0 < 1) 1: null else 1: null};
''');
  }

  test_const_ifElement_thenFalse() async {
    await assertNoErrorsInCode('''
var c = const {2: null, if (1 < 0) 2: 2};
''');
  }

  test_const_ifElement_thenTrue() async {
    await assertErrorsInCode('''
var c = const {1: null, if (0 < 1) 1: null};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 35, 1,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_const_instanceCreation_equalTypeArgs() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(): null, const A<int>(): null};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 66, 14,
          contextMessages: [message('$testPackageLibPath/test.dart', 44, 14)]),
    ]);
  }

  test_const_instanceCreation_notEqualTypeArgs() async {
    // No error because A<int> and A<num> are different types.
    await assertNoErrorsInCode(r'''
class A<T> {
  const A();
}

var c = const {const A<int>(): null, const A<num>(): null};
''');
  }

  test_const_spread__noDuplicate() async {
    await assertNoErrorsInCode('''
var c = const {1: null, ...{2: null}};
''');
  }

  test_const_spread_hasDuplicate() async {
    await assertErrorsInCode('''
var c = const {1: null, ...{1: null}};
''', [
      error(CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, 27, 9,
          contextMessages: [message('$testPackageLibPath/test.dart', 15, 1)]),
    ]);
  }

  test_nonConst_entry() async {
    // No error, but there is a hint.
    await assertErrorsInCode('''
var c = {1: null, 2: null, 1: null};
''', [
      error(HintCode.EQUAL_KEYS_IN_MAP, 27, 1),
    ]);
  }
}

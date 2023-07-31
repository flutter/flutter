// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapKeyTypeNotAssignableTest);
    defineReflectiveTests(
        MapKeyTypeNotAssignableWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(MapKeyTypeNotAssignableWithoutNullSafetyTest);
    defineReflectiveTests(MapKeyTypeNotAssignableWithStrictCastsTest);
  });
}

@reflectiveTest
class MapKeyTypeNotAssignableTest extends PubPackageResolutionTest
    with MapKeyTypeNotAssignableTestCases {
  test_const_intQuestion_null_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = null;
var v = const <int?, bool>{a : true};
''');
  }

  test_const_intQuestion_null_value() async {
    await assertNoErrorsInCode('''
var v = const <int?, bool>{null : true};
''');
  }
}

mixin MapKeyTypeNotAssignableTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_const_ifElement_thenElseFalse_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int, bool>{if (1 < 0) a: true else b: false};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 94, 1),
    ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = const <int, bool>{if (1 < 0) a: true};
''');
  }

  test_const_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode('''
var v = const <int, bool>{if (1 < 0) 'a': true};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 37, 3),
    ]);
  }

  test_const_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, bool>{if (true) a: true};
''');
  }

  test_const_ifElement_thenTrue_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int, bool>{if (true) a: true};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 59, 1),
    ]);
  }

  test_const_ifElement_thenTrue_notConst() async {
    await assertErrorsInCode('''
final a = 0;
var v = const <int, bool>{if (1 < 2) a: true};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_KEY, 50, 1),
    ]);
  }

  test_const_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int, bool>{a : true};
''');
  }

  test_const_intNull_dynamic() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 50, 1),
    ], legacy: []);
    await assertErrorsInCode('''
const dynamic a = null;
var v = const <int, bool>{a : true};
''', errors);
  }

  test_const_intNull_value() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 26, 4),
    ], legacy: []);
    await assertErrorsInCode('''
var v = const <int, bool>{null : true};
''', errors);
  }

  test_const_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int, bool>{a : true};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 49, 1),
    ]);
  }

  test_const_intString_value() async {
    await assertErrorsInCode('''
var v = const <int, bool>{'a' : true};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 26, 3),
    ]);
  }

  test_const_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = const <int, String>{...{1: 'a'}};
''');
  }

  test_const_spread_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int, String>{...{a: 'a'}};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 55, 1),
    ]);
  }

  test_key_type_is_assignable() async {
    await assertNoErrorsInCode('''
var v = <String, int > {'a' : 1};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = <int, bool>{if (1 < 0) a: true else b: false};
''');
  }

  test_nonConst_ifElement_thenFalse_intString_value() async {
    await assertErrorsInCode('''
var v = <int, bool>{if (1 < 0) 'a': true};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 31, 3),
    ]);
  }

  test_nonConst_ifElement_thenTrue_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int, bool>{if (true) a: true};
''');
  }

  test_nonConst_ifElement_thenTrue_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int, bool>{if (true) a: true};
''');
  }

  test_nonConst_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int, bool>{a : true};
''');
  }

  test_nonConst_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int, bool>{a : true};
''');
  }

  test_nonConst_intString_value() async {
    await assertErrorsInCode('''
var v = <int, bool>{'a' : true};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 20, 3),
    ]);
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int, String>{...{1: 'a'}};
''');
  }

  test_nonConst_spread_intString() async {
    await assertErrorsInCode('''
var v = <int, String>{...{'a': 'a'}};
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 26, 3),
    ]);
  }

  test_nonConst_spread_intString_dynamic() async {
    await assertNoErrorsInCode('''
dynamic a = 'a';
var v = <int, String>{...{a: 'a'}};
''');
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_ifElement_falseBranch_key_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: 0 else a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 58, 1),
    ]);
  }

  test_ifElement_falseBranch_key_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, num a) {
  <int, int>{if (c) 0: 0 else a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 54, 1),
    ]);
  }

  test_ifElement_trueBranch_key_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int, int>{if (c) a: 0 };
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 48, 1),
    ]);
  }

  test_ifElement_trueBranch_key_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, num a) {
  <int, int>{if (c) a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 44, 1),
    ]);
  }

  test_spread_key_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(Map<num, dynamic> a) {
  <int, dynamic>{...a};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, MapKeyTypeNotAssignableTestCases {
  test_nonConst_spread_intNum() async {
    await assertNoErrorsInCode('''
var v = <int, int>{...<num, num>{1: 1}};
''');
  }
}

@reflectiveTest
class MapKeyTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertErrorsWithStrictCasts('''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: 0 else a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 58, 1),
    ]);
  }

  test_ifElement_trueBranch() async {
    await assertErrorsWithStrictCasts('''
void f(bool c, dynamic a) {
  <int, int>{if (c) a: 0 };
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 48, 1),
    ]);
  }

  test_spread() async {
    await assertErrorsWithStrictCasts('''
void f(Map<dynamic, int> a) {
  <int, int>{...a};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 46, 1),
    ]);
  }
}

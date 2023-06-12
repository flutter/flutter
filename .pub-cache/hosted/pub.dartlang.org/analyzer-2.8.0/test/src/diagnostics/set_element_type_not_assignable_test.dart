// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetElementTypeNotAssignableTest);
    defineReflectiveTests(
        SetElementTypeNotAssignableWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(SetElementTypeNotAssignableWithoutNullSafetyTest);
    defineReflectiveTests(SetElementTypeNotAssignableWithStrictCastsTest);
  });
}

@reflectiveTest
class SetElementTypeNotAssignableTest extends PubPackageResolutionTest
    with SetElementTypeNotAssignableTestCases {
  test_const_stringQuestion_null_dynamic() async {
    await assertNoErrorsInCode('''
const a = null;
var v = const <String?>{a};
''');
  }

  test_const_stringQuestion_null_value() async {
    await assertNoErrorsInCode('''
var v = const <String?>{null};
''');
  }
}

mixin SetElementTypeNotAssignableTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>{if (1 < 0) a else b};
''');
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await assertErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>{if (1 < 0) a else b};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 82, 1),
    ]);
  }

  test_const_ifElement_thenFalse_intString() async {
    await assertErrorsInCode('''
var v = const <int>{if (1 < 0) 'a'};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 31, 3),
    ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = const <int>{if (1 < 0) a};
''');
  }

  test_const_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>{if (true) a};
''');
  }

  test_const_ifElement_thenTrue_intString() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int>{if (true) a};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 53, 1),
    ]);
  }

  test_const_intInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 42;
var v = const <int>{a};
''');
  }

  test_const_intInt_value() async {
    await assertNoErrorsInCode('''
var v = const <int>{42};
''');
  }

  test_const_intNull_dynamic() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 36, 1),
    ], legacy: []);
    await assertErrorsInCode('''
const a = null;
var v = const <int>{a};
''', errors);
  }

  test_const_intNull_value() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 20, 4),
    ], legacy: []);
    await assertErrorsInCode('''
var v = const <int>{null};
''', errors);
  }

  test_const_intString_dynamic() async {
    await assertErrorsInCode('''
const dynamic x = 'abc';
var v = const <int>{x};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 45, 1),
    ]);
  }

  test_const_intString_value() async {
    await assertErrorsInCode('''
var v = const <int>{'abc'};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 20, 5),
    ]);
  }

  test_const_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = const <int>{...[0, 1]};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>{if (1 < 0) a else b};
''');
  }

  test_nonConst_ifElement_thenFalse_intString() async {
    await assertErrorsInCode('''
var v = <int>[if (1 < 0) 'a'];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 25, 3),
    ]);
  }

  test_nonConst_ifElement_thenTrue_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = <int>{if (true) a};
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int>{if (true) a};
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int>{...[0, 1]};
''');
  }

  test_notConst_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic x = 'abc';
var v = <int>{x};
''');
  }

  test_notConst_intString_value() async {
    await assertErrorsInCode('''
var v = <int>{'abc'};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 14, 5),
    ]);
  }
}

@reflectiveTest
class SetElementTypeNotAssignableWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_ifElement_falseBranch_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>{if (c) 0 else a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_ifElement_falseBranch_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, num a) {
  <int>{if (c) 0 else a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 46, 1),
    ]);
  }

  test_ifElement_trueBranch_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>{if (c) a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 43, 1),
    ]);
  }

  test_ifElement_trueBranch_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, num a) {
  <int>{if (c) a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 39, 1),
    ]);
  }

  test_spread_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(Iterable<num> a) {
  <int>{...a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 37, 1),
    ]);
  }
}

@reflectiveTest
class SetElementTypeNotAssignableWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, SetElementTypeNotAssignableTestCases {}

@reflectiveTest
class SetElementTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertErrorsWithStrictCasts('''
void f(bool c, dynamic a) {
  <int>{if (c) 0 else a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_ifElement_trueBranch() async {
    await assertErrorsWithStrictCasts('''
void f(bool c, dynamic a) {
  <int>{if (c) a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 43, 1),
    ]);
  }

  test_spread() async {
    await assertErrorsWithStrictCasts('''
void f(Iterable<dynamic> a) {
  <int>{...a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 41, 1),
    ]);
  }
}

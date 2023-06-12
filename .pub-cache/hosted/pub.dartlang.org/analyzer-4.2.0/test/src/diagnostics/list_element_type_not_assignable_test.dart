// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListElementTypeNotAssignableTest);
    defineReflectiveTests(
        ListElementTypeNotAssignableWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(ListElementTypeNotAssignableWithoutNullSafetyTest);
    defineReflectiveTests(ListElementTypeNotAssignableWithStrictCastsTest);
  });
}

@reflectiveTest
class ListElementTypeNotAssignableTest extends PubPackageResolutionTest
    with ListElementTypeNotAssignableTestCases {
  test_const_stringQuestion_null_value() async {
    await assertNoErrorsInCode('''
var v = const <String?>[null];
''');
  }

  test_nonConst_genericFunction_genericContext() async {
    await assertNoErrorsInCode('''
List<U Function<U>(U)> foo(T Function<T>(T a) f) {
  return [f];
}
''');
  }

  test_nonConst_genericFunction_genericContext_nonAssignable() async {
    await assertErrorsInCode('''
List<U Function<U>(U, int)> foo(T Function<T>(T a) f) {
  return [f];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 66, 1),
    ]);
  }

  test_nonConst_genericFunction_nonGenericContext() async {
    await assertNoErrorsInCode('''
List<int Function(int)> foo(T Function<T>(T a) f) {
  return [f];
}
''');
  }

  test_nonConst_genericFunction_nonGenericContext_nonAssignable() async {
    await assertErrorsInCode('''
List<int Function(int, int)> foo(T Function<T>(T a) f) {
  return [f];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 67, 1),
    ]);
  }
}

mixin ListElementTypeNotAssignableTestCases on PubPackageResolutionTest {
  test_const_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = const <int>[if (1 < 0) a else b];
''');
  }

  test_const_ifElement_thenElseFalse_intString() async {
    await assertErrorsInCode('''
const dynamic a = 0;
const dynamic b = 'b';
var v = const <int>[if (1 < 0) a else b];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 82, 1),
    ]);
  }

  test_const_ifElement_thenFalse_intString() async {
    await assertErrorsInCode('''
var v = const <int>[if (1 < 0) 'a'];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 31, 3),
    ]);
  }

  test_const_ifElement_thenFalse_intString_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
var v = const <int>[if (1 < 0) a];
''');
  }

  test_const_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = const <int>[if (true) a];
''');
  }

  test_const_ifElement_thenTrue_intString() async {
    await assertErrorsInCode('''
const dynamic a = 'a';
var v = const <int>[if (true) a];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 53, 1),
    ]);
  }

  test_const_intInt() async {
    await assertNoErrorsInCode(r'''
var v1 = <int> [42];
var v2 = const <int> [42];
''');
  }

  test_const_intNull_dynamic() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 36, 1),
    ], legacy: []);
    await assertErrorsInCode('''
const a = null;
var v = const <int>[a];
''', errors);
  }

  test_const_intNull_value() async {
    var errors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 20, 4),
    ], legacy: []);
    await assertErrorsInCode('''
var v = const <int>[null];
''', errors);
  }

  test_const_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = const <int>[...[0, 1]];
''');
  }

  test_const_stringInt() async {
    await assertErrorsInCode('''
var v = const <String>[42];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 23, 2),
    ]);
  }

  test_const_stringInt_dynamic() async {
    await assertErrorsInCode('''
const dynamic x = 42;
var v = const <String>[x];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 45, 1),
    ]);
  }

  test_const_voidInt() async {
    await assertNoErrorsInCode('''
var v = const <void>[42];
''');
  }

  test_nonConst_ifElement_thenElseFalse_intDynamic() async {
    await assertNoErrorsInCode('''
const dynamic a = 'a';
const dynamic b = 'b';
var v = <int>[if (1 < 0) a else b];
''');
  }

  test_nonConst_ifElement_thenElseFalse_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
const dynamic b = 0;
var v = <int>[if (1 < 0) a else b];
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
var v = <int>[if (true) a];
''');
  }

  test_nonConst_ifElement_thenTrue_intInt() async {
    await assertNoErrorsInCode('''
const dynamic a = 0;
var v = <int>[if (true) a];
''');
  }

  test_nonConst_spread_intInt() async {
    await assertNoErrorsInCode('''
var v = <int>[...[0, 1]];
''');
  }

  test_nonConst_stringInt() async {
    await assertErrorsInCode('''
var v = <String>[42];
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 17, 2),
    ]);
  }

  test_nonConst_stringInt_dynamic() async {
    await assertNoErrorsInCode('''
const dynamic x = 42;
var v = <String>[x];
''');
  }

  test_nonConst_voidInt() async {
    await assertNoErrorsInCode('''
var v = <void>[42];
''');
  }
}

@reflectiveTest
class ListElementTypeNotAssignableWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_ifElement_falseBranch_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>[if (c) 0 else a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_ifElement_falseBranch_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, num a) {
  <int>[if (c) 0 else a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 46, 1),
    ]);
  }

  test_ifElement_trueBranch_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>[if (c) a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 43, 1),
    ]);
  }

  test_ifElement_trueBranch_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(bool c, num a) {
  <int>[if (c) a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 39, 1),
    ]);
  }

  test_spread_supertype() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(Iterable<num> a) {
  <int>[...a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 37, 1),
    ]);
  }
}

@reflectiveTest
class ListElementTypeNotAssignableWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, ListElementTypeNotAssignableTestCases {}

@reflectiveTest
class ListElementTypeNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest with WithStrictCastsMixin {
  test_ifElement_falseBranch() async {
    await assertErrorsWithStrictCasts('''
void f(bool c, dynamic a) {
  <int>[if (c) 0 else a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_ifElement_trueBranch() async {
    await assertErrorsWithStrictCasts('''
void f(bool c, dynamic a) {
  <int>[if (c) a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 43, 1),
    ]);
  }

  test_spread() async {
    await assertErrorsWithStrictCasts('''
void f(Iterable<dynamic> a) {
  <int>[...a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 41, 1),
    ]);
  }
}

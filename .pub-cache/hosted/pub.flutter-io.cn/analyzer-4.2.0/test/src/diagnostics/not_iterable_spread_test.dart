// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotIterableSpreadTest);
    defineReflectiveTests(NotIterableSpreadWithoutNullSafetyTest);
    defineReflectiveTests(NotIterableSpreadWithStrictCastsTest);
  });
}

@reflectiveTest
class NotIterableSpreadTest extends PubPackageResolutionTest
    with NotIterableSpreadTestCases {
  test_iterable_interfaceTypeTypedef() async {
    await assertNoErrorsInCode('''
typedef A = List<int>;
f(A a) {
  var v = [...a];
  v;
}
''');
  }

  test_iterable_typeParameter_bound_listQuestion() async {
    await assertNoErrorsInCode('''
void f<T extends List<int>?>(T a) {
  var v = [...?a];
  v;
}
''');
  }
}

mixin NotIterableSpreadTestCases on PubPackageResolutionTest {
  test_iterable_list() async {
    await assertNoErrorsInCode('''
var a = [0];
var v = [...a];
''');
  }

  test_iterable_null() async {
    await assertNoErrorsInCode('''
var v = [...?null];
''');
  }

  test_iterable_typeParameter_bound_list() async {
    await assertNoErrorsInCode('''
void f<T extends List<int>>(T a) {
  var v = [...a];
  v;
}
''');
  }

  test_notIterable_direct() async {
    await assertErrorsInCode('''
var a = 0;
var v = [...a];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 23, 1),
    ]);
  }

  test_notIterable_forElement() async {
    await assertErrorsInCode('''
var a = 0;
var v = [for (var i in []) ...a];
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 41, 1),
    ]);
  }

  test_notIterable_ifElement_else() async {
    await assertErrorsInCode('''
var a = 0;
var v = [if (1 > 0) ...[] else ...a];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 45, 1),
    ]);
  }

  test_notIterable_ifElement_then() async {
    await assertErrorsInCode('''
var a = 0;
var v = [if (1 > 0) ...a];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 34, 1),
    ]);
  }

  test_notIterable_typeParameter_bound() async {
    await assertErrorsInCode('''
void f<T extends num>(T a) {
  var v = [...a];
  v;
}
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 43, 1),
    ]);
  }

  test_spread_map_in_iterable_context() async {
    await assertErrorsInCode('''
List<int> f() => [...{1: 2, 3: 4}];
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 21, 12),
    ]);
  }
}

@reflectiveTest
class NotIterableSpreadWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, NotIterableSpreadTestCases {}

@reflectiveTest
class NotIterableSpreadWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_list() async {
    await assertErrorsWithStrictCasts('''
void f(dynamic a) {
  [...a];
}
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 26, 1),
    ]);
  }

  test_set() async {
    await assertErrorsWithStrictCasts('''
void f(dynamic a) {
  <int>{...a};
}
''', [
      error(CompileTimeErrorCode.NOT_ITERABLE_SPREAD, 31, 1),
    ]);
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolConditionWithoutNullSafetyTest);
    defineReflectiveTests(
        NonBoolConditionWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(NonBoolConditionTest);
    defineReflectiveTests(NonBoolConditionWithStrictCastsTest);
  });
}

@reflectiveTest
class NonBoolConditionTest extends PubPackageResolutionTest {
  test_if_null() async {
    await assertErrorsInCode(r'''
void f(Null a) {
  if (a) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 23, 1),
    ]);
  }

  test_ternary_condition_null() async {
    await assertErrorsInCode(r'''
void f(Null a) {
  a ? 0 : 1;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 19, 1),
    ]);
  }
}

@reflectiveTest
class NonBoolConditionWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_map_ifElement_condition_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(dynamic c) {
  <int, int>{if (c) 0: 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 37, 1),
    ]);
  }

  test_map_ifElement_condition_object() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(Object c) {
  <int, int>{if (c) 0: 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 36, 1),
    ]);
  }

  test_set_ifElement_condition_dynamic() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(dynamic c) {
  <int>{if (c) 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 32, 1),
    ]);
  }

  test_set_ifElement_condition_object() async {
    await assertErrorsWithNoImplicitCasts(r'''
void f(Object c) {
  <int>{if (c) 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 31, 1),
    ]);
  }
}

@reflectiveTest
class NonBoolConditionWithoutNullSafetyTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_conditional() async {
    await assertErrorsInCode('''
f() { return 3 ? 2 : 1; }
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_conditional_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
f() { return [1, 2, 3] ? 2 : 1; }
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 13, 9),
    ]);
  }

  test_conditional_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
Object o;
f() { return o ? 2 : 1; }
''');
  }

  test_do() async {
    await assertErrorsInCode(r'''
f() {
  do {} while (3);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 21, 1),
    ]);
  }

  test_do_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
Object o;
f() {
  do {} while ([1, 2, 3]);
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 31, 9),
    ]);
  }

  test_do_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
Object o;
f() {
  do {} while (o);
}
''');
  }

  test_for() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (;3;) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 14, 1),
    ]);
  }

  test_for_declaration() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (int i = 0; 3;) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 24, 1),
    ]);
  }

  test_for_expression() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  int i;
  for (i = 0; 3;) {}
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 29, 1),
    ]);
  }

  test_for_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
f() {
  for (;[1, 2, 3];) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 14, 9),
    ]);
  }

  test_for_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
Object o;
f() {
  for (;o;) {}
}
''');
  }

  test_forElement() async {
    await assertErrorsInCode('''
var v = [for (; 0;) 1];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 16, 1),
    ]);
  }

  test_if() async {
    await assertErrorsInCode(r'''
f() {
  if (3) return 2; else return 1;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 12, 1),
    ]);
  }

  test_if_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
f() {
  if ([1, 2, 3]) return 2; else return 1;
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 12, 9),
    ]);
  }

  test_if_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
f(Object o) {
  if (o) return 2; else return 1;
}
''');
  }

  test_ifElement() async {
    await assertErrorsInCode('''
var v = [if (3) 1];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_ifElement_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
var v = [if ([1, 2, 3]) 'x'];
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 13, 9),
    ]);
  }

  test_ifElement_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
Object o;
var v = [if (o) 'x'];
''');
  }

  test_while() async {
    await assertErrorsInCode(r'''
f() {
  while (3) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 15, 1),
    ]);
  }

  test_while_implicitCast_fromLiteral() async {
    await assertErrorsInCode('''
f() {
  while ([1, 2, 3]) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 15, 9),
    ]);
  }

  test_while_implicitCast_fromSupertype() async {
    await assertNoErrorsInCode('''
f(Object o) {
  while (o) {}
}
''');
  }
}

@reflectiveTest
class NonBoolConditionWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_map_ifElement_condition() async {
    await assertErrorsWithStrictCasts('''
void f(dynamic c) {
  <int, int>{if (c) 0: 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 37, 1),
    ]);
  }

  test_set_ifElement_condition() async {
    await assertErrorsWithStrictCasts('''
void f(dynamic c) {
  <int>{if (c) 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 32, 1),
    ]);
  }
}

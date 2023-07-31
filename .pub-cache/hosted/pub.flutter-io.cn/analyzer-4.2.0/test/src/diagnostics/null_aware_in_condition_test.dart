// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareInConditionTest);
  });
}

@reflectiveTest
class NullAwareInConditionTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_assert() async {
    await assertErrorsInCode(r'''
m(x) {
  assert (x?.a);
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 17, 4),
    ]);
  }

  test_conditionalExpression() async {
    await assertErrorsInCode(r'''
m(x) {
  return x?.a ? 0 : 1;
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 16, 4),
    ]);
  }

  test_do() async {
    await assertErrorsInCode(r'''
m(x) {
  do {} while (x?.a);
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 22, 4),
    ]);
  }

  test_for() async {
    await assertErrorsInCode(r'''
m(x) {
  for (var v = x; v?.a; v = v.next) {}
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 25, 4),
    ]);
  }

  test_if() async {
    await assertErrorsInCode(r'''
m(x) {
  if (x?.a) {}
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 13, 4),
    ]);
  }

  test_if_parenthesized() async {
    await assertErrorsInCode(r'''
m(x) {
  if ((x?.a)) {}
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 13, 6),
    ]);
  }

  test_while() async {
    await assertErrorsInCode(r'''
m(x) {
  while (x?.a) {}
}
''', [
      error(HintCode.NULL_AWARE_IN_CONDITION, 16, 4),
    ]);
  }
}

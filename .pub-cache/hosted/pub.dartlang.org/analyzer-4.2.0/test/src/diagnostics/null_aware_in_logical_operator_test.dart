// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareInLogicalOperatorTest);
  });
}

@reflectiveTest
class NullAwareInLogicalOperatorTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_conditionalAnd_first() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a && x.b;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 9, 4),
    ]);
  }

  test_conditionalAnd_second() async {
    await assertErrorsInCode(r'''
m(x) {
  x.a && x?.b;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 16, 4),
    ]);
  }

  test_conditionalAnd_third() async {
    await assertErrorsInCode(r'''
m(x) {
  x.a && x.b && x?.c;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 23, 4),
    ]);
  }

  test_conditionalOr_first() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a || x.b;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 9, 4),
    ]);
  }

  test_conditionalOr_second() async {
    await assertErrorsInCode(r'''
m(x) {
  x.a || x?.b;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 16, 4),
    ]);
  }

  test_conditionalOr_third() async {
    await assertErrorsInCode(r'''
m(x) {
  x.a || x.b || x?.c;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 23, 4),
    ]);
  }

  test_for_noCondition() async {
    await assertNoErrorsInCode(r'''
m(x) {
  for (var v = x; ; v++) {}
}
''');
  }

  test_if_notTopLevel() async {
    await assertNoErrorsInCode(r'''
m(x) {
  if (x?.y == null) {}
}
''');
  }

  test_not() async {
    await assertErrorsInCode(r'''
m(x) {
  !x?.a;
}
''', [
      error(HintCode.NULL_AWARE_IN_LOGICAL_OPERATOR, 10, 4),
    ]);
  }
}

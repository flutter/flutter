// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullAwareBeforeOperatorTest);
  });
}

/// This diagnostic is only reported in pre-null safe code.
@reflectiveTest
class NullAwareBeforeOperatorTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_assignment() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a = '';
}
''');
  }

  test_equal_equal() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a == '';
}
''');
  }

  test_is() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a is String;
}
''');
  }

  test_is_not() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a is! String;
}
''');
  }

  test_minus() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a - '';
}
''', [
      error(HintCode.NULL_AWARE_BEFORE_OPERATOR, 9, 4),
    ]);
  }

  test_not_equal() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a != '';
}
''');
  }

  test_question_question() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a ?? true;
}
''');
  }
}

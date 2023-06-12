// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CanBeNullAfterNullAwareTest);
    defineReflectiveTests(CanBeNullAfterNullAwareWithoutNullSafetyTest);
  });
}

@reflectiveTest
class CanBeNullAfterNullAwareTest extends PubPackageResolutionTest {
  test_definedForNull() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a.hashCode;
  x?.a.runtimeType;
  x?.a.toString();
  x?.b().hashCode;
  x?.b().runtimeType;
  x?.b().toString();
}
''');
  }

  test_guarded_methodInvocation() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a()?.b();
}
''');
  }

  test_guarded_propertyAccess() async {
    await assertNoErrorsInCode(r'''
m(x) {
  x?.a?.b;
}
''');
  }
}

@reflectiveTest
class CanBeNullAfterNullAwareWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_afterCascade() async {
    await assertErrorsInCode(r'''
m(x) {
  x..a?.b.c;
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 10, 6),
    ]);
  }

  test_beforeCascade() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a..m();
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 9, 4),
    ]);
  }

  test_cascadeWithParenthesis() async {
    await assertErrorsInCode(r'''
m(x) {
  (x?.a)..m();
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 9, 6),
    ]);
  }

  test_methodInvocation() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a.b();
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 9, 4),
    ]);
  }

  test_multipleInvocations() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a
    ..m()
    ..m();
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 9, 4),
    ]);
  }

  test_parenthesized() async {
    await assertErrorsInCode(r'''
m(x) {
  (x?.a).b;
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 9, 6),
    ]);
  }

  test_propertyAccess() async {
    await assertErrorsInCode(r'''
m(x) {
  x?.a.b;
}
''', [
      error(HintCode.CAN_BE_NULL_AFTER_NULL_AWARE, 9, 4),
    ]);
  }
}

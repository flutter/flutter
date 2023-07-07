// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEnumConstantInSwitchTest);
    defineReflectiveTests(MissingEnumConstantInSwitchWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MissingEnumConstantInSwitchTest extends PubPackageResolutionTest
    with MissingEnumConstantInSwitchTestCases {
  test_all_enhanced() async {
    await assertNoErrorsInCode('''
enum E {
  one, two;

  static const x = 0;
}

void f(E e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
  }
}
''');
  }

  test_nullable() async {
    await assertErrorsInCode('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
    case E.two:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 38, 10),
    ]);
  }

  test_nullable_default() async {
    await assertNoErrorsInCode('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_nullable_null() async {
    await assertNoErrorsInCode('''
enum E { one, two }

void f(E? e) {
  switch (e) {
    case E.one:
      break;
    case E.two:
      break;
    case null:
      break;
  }
}
''');
  }
}

mixin MissingEnumConstantInSwitchTestCases on PubPackageResolutionTest {
  test_default() async {
    await assertNoErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
      break;
    default:
      break;
  }
}
''');
  }

  test_first() async {
    await assertErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.two:
    case E.three:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10),
    ]);
  }

  test_last() async {
    await assertErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
    case E.two:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10),
    ]);
  }

  test_middle() async {
    await assertErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case E.one:
    case E.three:
      break;
  }
}
''', [
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10),
    ]);
  }

  test_parenthesized() async {
    await assertNoErrorsInCode('''
enum E { one, two, three }

void f(E e) {
  switch (e) {
    case (E.one):
      break;
    case (E.two):
      break;
    case (E.three):
      break;
  }
}
''');
  }
}

@reflectiveTest
class MissingEnumConstantInSwitchWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with MissingEnumConstantInSwitchTestCases, WithoutNullSafetyMixin {}

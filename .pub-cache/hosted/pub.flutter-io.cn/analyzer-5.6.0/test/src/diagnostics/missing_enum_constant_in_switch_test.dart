// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingEnumConstantInSwitchTest);
    defineReflectiveTests(MissingEnumConstantInSwitchTest_Language218);
    defineReflectiveTests(MissingEnumConstantInSwitchWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MissingEnumConstantInSwitchTest extends PubPackageResolutionTest
    with
        MissingEnumConstantInSwitchTestCases,
        MissingEnumConstantInSwitchTestCases_Language212 {
  @override
  bool get _arePatternsEnabled => true;
}

@reflectiveTest
class MissingEnumConstantInSwitchTest_Language218
    extends PubPackageResolutionTest
    with
        WithLanguage218Mixin,
        MissingEnumConstantInSwitchTestCases,
        MissingEnumConstantInSwitchTestCases_Language212 {
  @override
  bool get _arePatternsEnabled => false;
}

mixin MissingEnumConstantInSwitchTestCases on PubPackageResolutionTest {
  bool get _arePatternsEnabled;

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
      if (!_arePatternsEnabled)
        error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10)
      else
        error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 44, 6),
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
      if (!_arePatternsEnabled)
        error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10)
      else
        error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 44, 6),
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
      if (!_arePatternsEnabled)
        error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 44, 10)
      else
        error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 44, 6),
    ]);
  }

  test_parenthesized() async {
    // TODO(johnniwinther): Re-enable this test for the patterns feature.
    if (_arePatternsEnabled) return;
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

mixin MissingEnumConstantInSwitchTestCases_Language212
    on PubPackageResolutionTest, MissingEnumConstantInSwitchTestCases {
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
      if (!_arePatternsEnabled)
        error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 38, 10)
      else
        error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 38, 6),
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

@reflectiveTest
class MissingEnumConstantInSwitchWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with MissingEnumConstantInSwitchTestCases, WithoutNullSafetyMixin {
  @override
  bool get _arePatternsEnabled => false;
}

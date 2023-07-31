// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeIsNotSwitchExpressionSubtypeTest);
    defineReflectiveTests(
        CaseExpressionTypeIsNotSwitchExpressionSubtypeTest_Language218);
  });
}

@reflectiveTest
class CaseExpressionTypeIsNotSwitchExpressionSubtypeTest
    extends PubPackageResolutionTest
    with CaseExpressionTypeIsNotSwitchExpressionSubtypeTestCases {
  @override
  _Variant get _variant => _Variant.patterns;
}

@reflectiveTest
class CaseExpressionTypeIsNotSwitchExpressionSubtypeTest_Language218
    extends PubPackageResolutionTest
    with
        WithLanguage218Mixin,
        CaseExpressionTypeIsNotSwitchExpressionSubtypeTestCases {
  @override
  _Variant get _variant => _Variant.nullSafe;
}

mixin CaseExpressionTypeIsNotSwitchExpressionSubtypeTestCases
    on PubPackageResolutionTest {
  _Variant get _variant;

  test_notSubtype_hasEqEq() async {
    final List<ExpectedError> expectedErrors;
    switch (_variant) {
      case _Variant.nullSafe:
        expectedErrors = [
          error(
              CompileTimeErrorCode
                  .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
              180,
              2),
          error(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
              180, 2),
          error(
              CompileTimeErrorCode
                  .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
              206,
              10),
          error(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
              206, 10),
        ];
        break;
      case _Variant.patterns:
        expectedErrors = [];
        break;
    }

    await assertErrorsInCode('''
class A {
  const A();
}

class B {
  final int value;
  const B(this.value);
  bool operator ==(other) => true;
}

const dynamic B0 = B(0);

void f(A e) {
  switch (e) {
    case B0:
      break;
    case const B(1):
      break;
  }
}
''', expectedErrors);
  }

  test_notSubtype_primitiveEquality() async {
    final List<ExpectedError> expectedErrors;
    switch (_variant) {
      case _Variant.nullSafe:
        expectedErrors = [
          error(
              CompileTimeErrorCode
                  .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
              145,
              2),
          error(
              CompileTimeErrorCode
                  .CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE,
              171,
              10),
        ];
        break;
      case _Variant.patterns:
        expectedErrors = [
          error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 145, 2),
          error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 177, 4),
        ];
        break;
    }

    await assertErrorsInCode('''
class A {
  const A();
}

class B {
  final int value;
  const B(this.value);
}

const dynamic B0 = B(0);

void f(A e) {
  switch (e) {
    case B0:
      break;
    case const B(1):
      break;
  }
}
''', expectedErrors);
  }

  test_subtype() async {
    await assertNoErrorsInCode('''
class A {
  final int value;
  const A(this.value);
}

class B extends A {
  const B(int value) : super(value);
}

class C extends A {
  const C(int value) : super(value);
}

void f(A e) {
  switch (e) {
    case const B(0):
      break;
    case const C(0):
      break;
  }
}
''');
  }
}

enum _Variant { nullSafe, patterns }

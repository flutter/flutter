// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest);
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest_Language218);
    defineReflectiveTests(
      CaseExpressionTypeImplementsEqualsWithoutNullSafetyTest,
    );
  });
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest extends PubPackageResolutionTest
    with CaseExpressionTypeImplementsEqualsTestCases {
  @override
  _Variants get _variant => _Variants.patterns;
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest_Language218
    extends PubPackageResolutionTest
    with WithLanguage218Mixin, CaseExpressionTypeImplementsEqualsTestCases {
  @override
  _Variants get _variant => _Variants.nullSafe;
}

mixin CaseExpressionTypeImplementsEqualsTestCases on PubPackageResolutionTest {
  _Variants get _variant;

  test_classInstance_declares() async {
    await assertNoErrorsInCode(r'''
class A {
  final int value;

  const A(this.value);

  bool operator==(Object other);
}

void f(e) {
  switch (e) {
    case const A(0):
      break;
    case const A(1):
      break;
  }
}
''');
  }

  test_classInstance_fromObject() async {
    await assertNoErrorsInCode(r'''
class A {
  final int value;
  const A(this.value);
}

void f(e) {
  switch (e) {
    case const A(0):
      break;
  }
}
''');
  }

  test_classInstance_implements() async {
    final List<ExpectedError> expectedErrors;
    switch (_variant) {
      case _Variants.legacy:
        expectedErrors = [
          error(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
              128, 6),
        ];
        break;
      case _Variants.nullSafe:
        expectedErrors = [
          error(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS,
              150, 10),
        ];
        break;
      case _Variants.patterns:
        expectedErrors = [];
        break;
    }

    await assertErrorsInCode(r'''
class A {
  final int value;

  const A(this.value);

  bool operator ==(Object other) {
    return false;
  }
}

void f(e) {
  switch (e) {
    case const A(0):
      break;
  }
}
''', expectedErrors);
  }

  test_int() async {
    await assertNoErrorsInCode(r'''
void f(e) {
  switch (e) {
    case 0:
      break;
  }
}
''');
  }

  test_String() async {
    await assertNoErrorsInCode(r'''
void f(e) {
  switch (e) {
    case '0':
      break;
  }
}
''');
  }
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, CaseExpressionTypeImplementsEqualsTestCases {
  @override
  _Variants get _variant => _Variants.legacy;
}

enum _Variants { legacy, nullSafe, patterns }

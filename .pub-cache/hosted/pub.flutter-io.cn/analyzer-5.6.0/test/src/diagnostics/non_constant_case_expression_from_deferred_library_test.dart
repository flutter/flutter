// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantCaseExpressionFromDeferredLibraryTest);
    defineReflectiveTests(
        NonConstantCaseExpressionFromDeferredLibraryTest_Language218);
  });
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest
    extends PubPackageResolutionTest
    with NonConstantCaseExpressionFromDeferredLibraryTestCases {
  @override
  _Variant get _variant => _Variant.patterns;

  test_nested() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case const (a.c + 1):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY, 81, 1),
    ]);
  }
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest_Language218
    extends PubPackageResolutionTest
    with
        WithLanguage218Mixin,
        NonConstantCaseExpressionFromDeferredLibraryTestCases {
  @override
  _Variant get _variant => _Variant.nullSafe;

  test_nested() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c + 1:
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
          74,
          1),
    ]);
  }
}

mixin NonConstantCaseExpressionFromDeferredLibraryTestCases
    on PubPackageResolutionTest {
  _Variant get _variant;

  test_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    final ErrorCode expectedErrorCode;
    switch (_variant) {
      case _Variant.nullSafe:
        expectedErrorCode = CompileTimeErrorCode
            .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY;
        break;
      case _Variant.patterns:
        expectedErrorCode =
            CompileTimeErrorCode.PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY;
        break;
    }

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c:
      break;
  }
}
''', [
      error(expectedErrorCode, 74, 1),
    ]);
  }
}

enum _Variant { nullSafe, patterns }

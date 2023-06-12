// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantCaseExpressionFromDeferredLibraryTest);
  });
}

@reflectiveTest
class NonConstantCaseExpressionFromDeferredLibraryTest
    extends PubPackageResolutionTest {
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
          72,
          7),
    ]);
  }

  test_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
const int c = 0;
''');

    await assertErrorsInCode('''
import 'a.dart' deferred as a;

void f(int e) {
  switch (e) {
    case a.c:
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
          72,
          3),
    ]);
  }
}

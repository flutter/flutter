// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNonNullAssertionTest);
  });
}

@reflectiveTest
class UnnecessaryNonNullAssertionTest extends PubPackageResolutionTest {
  test_legacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.5
var x = 0;
''');

    await assertErrorsInCode('''
import 'a.dart';

f() {
  x!;
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_nonNull_function() async {
    await assertErrorsInCode('''
void g() {}

void f() {
  g!();
}
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 27, 1),
    ]);
  }

  test_nonNull_method() async {
    await assertErrorsInCode('''
class A {
  static void foo() {}
}

void f() {
  A.foo!();
}
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 54, 1),
    ]);
  }

  test_nonNull_parameter() async {
    await assertErrorsInCode('''
f(int x) {
  x!;
}
''', [
      error(StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION, 14, 1),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x!;
}
''');
  }
}

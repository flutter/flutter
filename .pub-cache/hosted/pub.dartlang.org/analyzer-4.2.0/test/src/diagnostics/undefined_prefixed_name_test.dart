// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedPrefixedNameTest);
  });
}

@reflectiveTest
class UndefinedPrefixedNameTest extends PubPackageResolutionTest {
  test_getterContext() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() => p.c;
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 33, 1),
    ]);
  }

  test_new() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
void f() {
  p.new;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 39, 3),
    ]);
  }

  test_setterContext() async {
    newFile('$testPackageLibPath/lib.dart', '');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p.c = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME, 34, 1),
    ]);
  }
}

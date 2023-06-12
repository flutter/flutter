// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithNonTypeTest);
  });
}

@reflectiveTest
class ConstWithNonTypeTest extends PubPackageResolutionTest {
  test_fromLibrary() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await assertErrorsInCode('''
import 'lib1.dart' as lib;
void f() {
  const lib.A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_TYPE, 50, 1),
    ]);
  }

  test_variable() async {
    await assertErrorsInCode(r'''
int A = 0;
f() {
  return const A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_TYPE, 32, 1),
    ]);
  }
}

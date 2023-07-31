// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapValueFromDeferredLibraryTest);
  });
}

@reflectiveTest
class NonConstantMapValueFromDeferredLibraryTest
    extends PubPackageResolutionTest
    with NonConstantMapValueFromDeferredLibraryTestCases {}

mixin NonConstantMapValueFromDeferredLibraryTestCases
    on PubPackageResolutionTest {
  @failingTest
  test_const_ifElement_thenTrue_elseDeferred() async {
    // reports wrong error code
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const { if (cond) 'a': 'b' else 'c' : a.c};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          99, 3),
    ]);
  }

  test_const_ifElement_thenTrue_thenDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const { if (cond) 'a' : a.c};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          85, 3),
    ]);
  }

  test_const_topLevel_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {'a' : a.c};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          55, 3),
    ]);
  }

  test_const_topLevel_deferred_nested() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {'a' : a.c + 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          55, 7),
    ]);
  }
}

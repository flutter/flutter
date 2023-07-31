// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetElementFromDeferredLibraryTest);
  });
}

@reflectiveTest
class SetElementFromDeferredLibraryTest extends PubPackageResolutionTest
    with SetElementFromDeferredLibraryTestCases {}

mixin SetElementFromDeferredLibraryTestCases on PubPackageResolutionTest {
  @failingTest
  test_const_ifElement_thenTrue_elseDeferred() async {
    // reports wrong error code
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const {if (cond) null else a.c};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 88, 3),
    ]);
  }

  test_const_ifElement_thenTrue_thenDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const {if (cond) a.c};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 78, 3),
    ]);
  }

  test_const_topLevel_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {a.c};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_const_topLevel_deferred_nested() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {a.c + 1};
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY, 49, 7),
    ]);
  }
}

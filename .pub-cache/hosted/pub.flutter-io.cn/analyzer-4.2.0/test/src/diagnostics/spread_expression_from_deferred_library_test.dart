// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SpreadExpressionFromDeferredLibraryTest);
  });
}

@reflectiveTest
class SpreadExpressionFromDeferredLibraryTest extends PubPackageResolutionTest
    with SpreadExpressionFromDeferredLibraryTestCases {}

mixin SpreadExpressionFromDeferredLibraryTestCases on PubPackageResolutionTest {
  test_inList_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const List c = [];''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
f() {
  return const [...a.c];
}''', [
      error(
          CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY, 59, 3),
    ]);
  }

  test_inList_deferred_notConst() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const List c = [];''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' deferred as a;
f() {
  return [...a.c];
}''');
  }

  test_inList_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const List c = [];''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as a;
f() {
  return const [...a.c];
}''');
  }

  test_inMap_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const Map c = <int, int>{};''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
f() {
  return const {...a.c};
}''', [
      error(
          CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY, 59, 3),
    ]);
  }

  test_inMap_notConst() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const Map c = <int, int>{};''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' deferred as a;
f() {
  return {...a.c};
}''');
  }

  test_inMap_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const Map c = <int, int>{};''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as a;
f() {
  return const {...a.c};
}''');
  }

  test_inSet_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const Set c = <int>{};''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
f() {
  return const {...a.c};
}''', [
      error(
          CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY, 59, 3),
    ]);
  }

  test_inSet_notConst() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const Set c = <int>{};''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' deferred as a;
f() {
  return {...a.c};
}''');
  }

  test_inSet_notDeferred() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
const Set c = <int>{};''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as a;
f() {
  return const {...a.c};
}''');
  }
}

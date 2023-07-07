// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantDefaultValueFromDeferredLibraryTest);
  });
}

@reflectiveTest
class NonConstantDefaultValueFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_deferred() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V}) {}
''', [
      error(
          CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY,
          55,
          3),
    ]);
  }

  test_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V + 1}) {}
''', [
      error(
          CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY,
          55,
          7),
    ]);
  }
}

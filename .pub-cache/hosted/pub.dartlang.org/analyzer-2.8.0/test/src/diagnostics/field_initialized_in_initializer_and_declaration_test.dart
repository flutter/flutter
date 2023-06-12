// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializedInInitializerAndDeclarationTest);
  });
}

@reflectiveTest
class FieldInitializedInInitializerAndDeclarationTest
    extends PubPackageResolutionTest {
  test_both() async {
    await assertErrorsInCode('''
class A {
  final int x = 0;
  A() : x = 1;
}
''', [
      error(
          CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          37,
          1),
    ]);
  }
}

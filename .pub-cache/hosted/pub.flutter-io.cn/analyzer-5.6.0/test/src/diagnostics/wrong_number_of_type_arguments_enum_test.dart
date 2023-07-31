// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsEnumTest);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsEnumTest extends PubPackageResolutionTest {
  test_tooFew() async {
    await assertErrorsInCode(r'''
enum E<T, U> {
  v<int>()
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM, 18, 5),
    ]);
  }

  test_tooMany() async {
    await assertErrorsInCode(r'''
enum E<T> {
  v<int, int>()
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM, 15, 10),
    ]);
  }
}

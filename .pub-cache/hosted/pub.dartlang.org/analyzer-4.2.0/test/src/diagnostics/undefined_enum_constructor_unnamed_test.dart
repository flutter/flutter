// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedEnumConstructorUnnamedTest);
  });
}

@reflectiveTest
class UndefinedEnumConstructorUnnamedTest extends PubPackageResolutionTest {
  test_withArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  const E.named();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED, 11, 1),
    ]);
  }

  test_withoutArguments() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E.named();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED, 11, 1),
    ]);
  }
}

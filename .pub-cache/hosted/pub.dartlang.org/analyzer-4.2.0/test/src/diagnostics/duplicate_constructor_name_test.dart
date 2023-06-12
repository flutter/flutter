// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateConstructorNameTest);
  });
}

@reflectiveTest
class DuplicateConstructorNameTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  C.foo();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 23, 5),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  const E.foo();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 45, 5),
    ]);
  }
}

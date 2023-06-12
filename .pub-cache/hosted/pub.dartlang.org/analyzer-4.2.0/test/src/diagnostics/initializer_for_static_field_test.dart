// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializerForStaticFieldTest);
  });
}

@reflectiveTest
class InitializerForStaticFieldTest extends PubPackageResolutionTest {
  test_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  static int? x;
  A([this.x = 0]) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, 32, 6),
    ]);
  }

  test_initializer() async {
    await assertErrorsInCode(r'''
class A {
  static int x = 1;
  A() : x = 0 {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, 38, 5,
          messageContains: ["'x'"]),
    ]);
  }
}

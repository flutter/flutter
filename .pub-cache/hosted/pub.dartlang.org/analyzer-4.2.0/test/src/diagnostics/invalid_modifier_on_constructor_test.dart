// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidModifierOnConstructorTest);
  });
}

@reflectiveTest
class InvalidModifierOnConstructorTest extends PubPackageResolutionTest {
  test_async() async {
    await assertErrorsInCode(r'''
class A {
  A() async {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, 16, 5),
    ]);
  }

  test_asyncStar() async {
    await assertErrorsInCode(r'''
class A {
  A() async* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, 16, 5),
    ]);
  }

  test_syncStar() async {
    await assertErrorsInCode(r'''
class A {
  A() sync* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, 16, 4),
    ]);
  }
}

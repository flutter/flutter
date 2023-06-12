// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializingFormalForNonExistentFieldTest);
  });
}

@reflectiveTest
class InitializingFormalForNonExistentFieldTest
    extends PubPackageResolutionTest {
  test_nonExistent() async {
    await assertErrorsInCode(r'''
class A {
  A(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 14,
          6),
    ]);
  }

  test_notInEnclosingClass() async {
    await assertErrorsInCode(r'''
class A {
  int x = 1;
}
class B extends A {
  B(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 49,
          6),
    ]);
  }

  test_optional() async {
    await assertErrorsInCode(r'''
class A {
  A([this.x]) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 15,
          6),
    ]);
  }

  test_synthetic() async {
    await assertErrorsInCode(r'''
class A {
  int get x => 1;
  A(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 32,
          6),
    ]);
  }
}

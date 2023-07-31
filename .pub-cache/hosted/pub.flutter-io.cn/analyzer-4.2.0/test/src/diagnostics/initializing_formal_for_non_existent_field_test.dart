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
  test_class_nonExistent() async {
    await assertErrorsInCode(r'''
class A {
  A(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 14,
          6),
    ]);
  }

  test_class_notInEnclosingClass() async {
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

  test_class_optional() async {
    await assertErrorsInCode(r'''
class A {
  A([this.x]) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 15,
          6),
    ]);
  }

  test_class_synthetic() async {
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

  test_enum_existing() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  final int x;
  const E(this.x);
}
''');
  }

  test_enum_optional() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E([this.x]);
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 25,
          6),
      error(HintCode.UNUSED_ELEMENT_PARAMETER, 30, 1),
    ]);
  }

  test_enum_required() async {
    await assertErrorsInCode(r'''
enum E {
  v(0);
  const E(this.x);
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 27,
          6),
    ]);
  }

  test_enum_synthetic() async {
    await assertErrorsInCode(r'''
enum E {
  v(0);
  const E(this.x);
  int get x => 1;
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 27,
          6),
    ]);
  }
}

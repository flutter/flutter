// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsSuperClassTest);
  });
}

@reflectiveTest
class ImplementsSuperClassTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A implements A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 40, 1),
    ]);
  }

  test_class_Object() async {
    await assertErrorsInCode('''
class A implements Object {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 19, 6),
    ]);
  }

  test_class_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
typedef B = A;
class C extends A implements B {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 55, 1),
    ]);
  }

  test_classAlias() async {
    await assertErrorsInCode(r'''
class A {}
mixin M {}
class B = A with M implements A;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 52, 1),
    ]);
  }

  test_classAlias_Object() async {
    await assertErrorsInCode(r'''
class M {}
class A = Object with M implements Object;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 46, 6),
    ]);
  }

  test_classAlias_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
mixin M {}
typedef B = A;
class C = A with M implements B;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 67, 1),
    ]);
  }
}

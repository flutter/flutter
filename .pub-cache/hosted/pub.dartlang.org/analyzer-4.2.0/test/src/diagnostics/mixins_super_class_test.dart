// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinsSuperClassTest);
  });
}

@reflectiveTest
class MixinsSuperClassTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A with A {}
''', [
      error(CompileTimeErrorCode.MIXINS_SUPER_CLASS, 34, 1),
    ]);
  }

  test_class_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
typedef B = A;
class C extends A with B {}
''', [
      error(CompileTimeErrorCode.MIXINS_SUPER_CLASS, 49, 1),
    ]);
  }

  test_classAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B = A with A;
''', [
      error(CompileTimeErrorCode.MIXINS_SUPER_CLASS, 28, 1),
    ]);
  }

  test_classAlias_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
typedef B = A;
class C = A with B;
''', [
      error(CompileTimeErrorCode.MIXINS_SUPER_CLASS, 43, 1),
    ]);
  }
}

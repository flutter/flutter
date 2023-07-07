// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinWithNonClassSuperclassTest);
  });
}

@reflectiveTest
class MixinWithNonClassSuperclassTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
int A = 0;
class B {}
class C extends A with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS, 38, 1),
    ]);
  }

  test_mixinApplication() async {
    await assertErrorsInCode(r'''
int A = 0;
class B {}
class C = A with B;
''', [
      error(CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS, 32, 1),
    ]);
  }
}

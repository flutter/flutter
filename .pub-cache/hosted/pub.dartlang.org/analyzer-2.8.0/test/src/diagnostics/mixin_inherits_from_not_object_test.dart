// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinInheritsFromNotObjectTest);
  });
}

@reflectiveTest
class MixinInheritsFromNotObjectTest extends PubPackageResolutionTest {
  test_classAlias_class_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 54, 1),
    ]);
  }

  test_classAlias_class_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 66, 1),
    ]);
  }

  test_classAlias_classAlias_with() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C = Object with B;
''');
  }

  test_classAlias_classAlias_with2() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C = Object with A, B;
class D = Object with C;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 72, 1),
    ]);
  }

  test_classAlias_mixin() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C = A with B;
''');
  }

  test_classDeclaration_class_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 60, 1),
    ]);
  }

  test_classDeclaration_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends Object {}
class C extends Object with B {}
''');
  }

  test_classDeclaration_class_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 72, 1),
    ]);
  }

  test_classDeclaration_classAlias_with() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C extends Object with B {}
''');
  }

  test_classDeclaration_classAlias_with2() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C = Object with A, B;
class D extends Object with C {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 78, 1),
    ]);
  }

  test_classDeclaration_mixin() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C extends A with B {}
''');
  }
}

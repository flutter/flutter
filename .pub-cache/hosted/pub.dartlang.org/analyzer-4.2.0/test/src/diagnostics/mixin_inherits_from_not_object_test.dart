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
  test_class_class_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 60, 1),
    ]);
  }

  test_class_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends Object {}
class C extends Object with B {}
''');
  }

  test_class_class_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 72, 1),
    ]);
  }

  test_class_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C extends Object with B {}
''');
  }

  test_class_classTypeAlias_with2() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C = Object with A, B;
class D extends Object with C {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 78, 1),
    ]);
  }

  test_class_mixin() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C extends A with B {}
''');
  }

  test_classTypeAlias_class_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 54, 1),
    ]);
  }

  test_classTypeAlias_class_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 66, 1),
    ]);
  }

  test_classTypeAlias_classAlias_with() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C = Object with B;
''');
  }

  test_classTypeAlias_classAlias_with2() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C = Object with A, B;
class D = Object with C;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 72, 1),
    ]);
  }

  test_classTypeAlias_mixin() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C = A with B;
''');
  }

  test_enum_class_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
enum E with B {
  v
}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 44, 1),
    ]);
  }

  test_enum_class_extends_Object() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends Object {}
enum E with B {
  v
}
''');
  }

  test_enum_class_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
enum E with B {
  v
}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 56, 1),
    ]);
  }

  test_enum_classTypeAlias_with() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
enum E with B {
  v
}
''');
  }

  test_enum_classTypeAlias_with2() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C = Object with A, B;
enum E with C {
  v
}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 62, 1),
    ]);
  }
}

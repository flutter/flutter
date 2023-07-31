// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateCollisionInMixinApplicationTest);
  });
}

@reflectiveTest
class PrivateCollisionInMixinApplicationTest extends PubPackageResolutionTest {
  test_class_interfaceAndMixin_same() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C implements A {}
class D extends C with A {}
''');
  }

  test_class_interfaceAndMixin_same_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C implements A {}
class D extends C with A {}
''');
  }

  test_class_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 49, 1),
    ]);
  }

  test_class_mixinAndMixin_indirect() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends Object with A {}
class D extends C with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 74, 1),
    ]);
  }

  test_class_mixinAndMixin_indirect_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends Object with A {}
class D extends C with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 74, 1),
    ]);
  }

  test_class_mixinAndMixin_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 49, 1),
    ]);
  }

  test_class_mixinAndMixin_withoutExtends() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C with A, B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 34, 1),
    ]);
  }

  test_class_mixinAndMixin_withoutExtends_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C with A, B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 34, 1),
    ]);
  }

  test_class_staticAndInstanceElement() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  static void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_staticAndInstanceElement_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  static void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_staticElements() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  static void _foo() {}
}

mixin B {
  static void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_staticElements_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  static void _foo() {}
}

mixin class B {
  static void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''');
  }

  test_class_superclassAndMixin_getter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}

mixin B {
  int get _foo => 0;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_getter2_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}

mixin class B {
  int get _foo => 0;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_method2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_method2_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_sameLibrary() async {
    await assertErrorsInCode('''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}

class C extends Object with A, B {}
''', [
      error(HintCode.UNUSED_ELEMENT, 17, 4),
      error(HintCode.UNUSED_ELEMENT, 47, 4),
    ]);
  }

  test_class_superclassAndMixin_sameLibrary_mixinClass() async {
    await assertErrorsInCode('''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}

class C extends Object with A, B {}
''', [
      error(HintCode.UNUSED_ELEMENT, 23, 4),
      error(HintCode.UNUSED_ELEMENT, 59, 4),
    ]);
  }

  test_class_superclassAndMixin_setter2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}

mixin B {
  set _foo(int _) {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1,
          messageContains: ["'_foo'"]),
    ]);
  }

  test_class_superclassAndMixin_setter2_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(int _) {}
}

mixin class B {
  set _foo(int _) {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1,
          messageContains: ["'_foo'"]),
    ]);
  }

  test_classTypeAlias_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = Object with A, B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 43, 1),
    ]);
  }

  test_classTypeAlias_mixinAndMixin_indirect() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = Object with A;
class D = C with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 60, 1),
    ]);
  }

  test_classTypeAlias_mixinAndMixin_indirect_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = Object with A;
class D = C with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 60, 1),
    ]);
  }

  test_classTypeAlias_mixinAndMixin_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = Object with A, B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 43, 1),
    ]);
  }

  test_classTypeAlias_superclassAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = A with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 35, 1),
    ]);
  }

  test_classTypeAlias_superclassAndMixin_mixinClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  void _foo() {}
}

mixin class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = A with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 35, 1),
    ]);
  }

  test_enum_getter_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  int get _foo => 0;
}

mixin B {
  int get _foo => 0;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

enum E with A, B {
  v
}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 33, 1),
    ]);
  }

  test_enum_method_interfaceAndMixin_same() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

mixin B implements A {}
enum E with B, A {
  v
}
''');
  }

  test_enum_method_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

enum E with A, B {
  v
}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 33, 1),
    ]);
  }

  test_enum_method_staticAndInstanceElement() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  static void _foo() {}
}

mixin B {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

enum E with A, B {
  v
}
''');
  }

  test_enum_setter_mixinAndMixin() async {
    newFile('$testPackageLibPath/a.dart', r'''
mixin A {
  set _foo(int _) {}
}

mixin B {
  set _foo(int _) {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

enum E with A, B {
  v
}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 33, 1,
          messageContains: ["'_foo'"]),
    ]);
  }
}

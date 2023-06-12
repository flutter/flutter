// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritanceGetterAndMethodTest);
  });
}

@reflectiveTest
class InconsistentInheritanceGetterAndMethodTest
    extends PubPackageResolutionTest {
  test_class_getter_method() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 85,
          1),
    ]);
  }

  test_class_method_getter() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
abstract class C implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 85,
          1),
    ]);
  }

  test_class_mixinApp() async {
    await assertErrorsInCode('''
class S {
  int get foo => 0;
}

class M {
  int foo() => 0;
}

class C = S with M;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 70,
          1),
    ]);
  }

  test_class_mixinApp2() async {
    await assertErrorsInCode('''
class S {
  int get foo => 0;
}

class M1 {
  int foo() => 0;
}

class M2 {
  int get foo => 0;
}

class C = S with M1, M2;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
          105, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD,
          105, 1),
    ]);
  }

  test_mixin_implements_getter_method() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 76,
          1),
    ]);
  }

  test_mixin_implements_method_getter() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
mixin M implements A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 76,
          1),
    ]);
  }

  test_mixin_on_getter_method() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 76,
          1),
    ]);
  }

  test_mixin_on_method_getter() async {
    await assertErrorsInCode(r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
mixin M on A, B {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD, 76,
          1),
    ]);
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceTest);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceTest extends PubPackageResolutionTest {
  test_class_extends() async {
    await assertErrorsInCode(r'''
class A extends B {}
class B extends A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
    ]);
  }

  test_class_extends_implements() async {
    await assertErrorsInCode(r'''
class A extends B {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
    ]);
  }

  test_class_implements() async {
    await assertErrorsInCode('''
class A implements B {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 30, 1),
    ]);
  }

  test_class_implements_generic() async {
    await assertErrorsInCode('''
class A<T> implements B<T> {}
class B<T> implements A<T> {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 36, 1),
    ]);
  }

  test_class_implements_generic_typeArgument() async {
    await assertErrorsInCode('''
class A<T> implements B<List<T>> {}
class B<T> implements A<List<T>> {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 42, 1),
    ]);
  }

  test_class_implements_tail2() async {
    await assertErrorsInCode(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 48, 1),
    ]);
  }

  test_class_implements_tail3() async {
    await assertErrorsInCode(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 48, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 81, 1),
    ]);
  }

  test_classTypeAlias_mixin() async {
    await assertErrorsInCode(r'''
class M1 = Object with M2;
class M2 = Object with M1;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 2),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 33, 2),
    ]);
  }

  test_classTypeAlias_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    await assertErrorsInCode('''
class C = D with M;
class D = C with M;
class M {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 26, 1),
    ]);
  }
}

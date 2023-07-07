// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstantiateAbstractClassTest);
  });
}

@reflectiveTest
class InstantiateAbstractClassTest extends PubPackageResolutionTest {
  test_const_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {
  const A();
}
void f() {
  var a = const A<int>();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 64, 6),
    ]);

    assertType(findNode.instanceCreation('const A<int>'), 'A<int>');
  }

  test_const_simple() async {
    await assertErrorsInCode('''
abstract class A {
  const A();
}
void f() {
  A a = const A();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 49, 1),
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 59, 1),
    ]);
  }

  test_new_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {}
void f() {
  new A<int>();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 40, 6),
    ]);

    assertType(findNode.instanceCreation('new A<int>'), 'A<int>');
  }

  test_new_interfaceTypeTypedef() async {
    await assertErrorsInCode('''
abstract class A {}
typedef B = A;
void f() {
  new B();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 52, 1),
    ]);
  }

  test_new_nonGeneric() async {
    await assertErrorsInCode('''
abstract class A {}
void f() {
  new A();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 37, 1),
    ]);
  }

  test_noKeyword_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {}
void f() {
  A<int>();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 36, 6),
    ]);

    assertType(findNode.instanceCreation('A<int>'), 'A<int>');
  }

  test_noKeyword_interfaceTypeTypedef() async {
    await assertErrorsInCode('''
abstract class A {}
typedef B = A;
void f() {
  B();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 48, 1),
    ]);
  }

  test_noKeyword_nonGeneric() async {
    await assertErrorsInCode('''
abstract class A {}
void f() {
  A();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS, 33, 1),
    ]);
  }
}

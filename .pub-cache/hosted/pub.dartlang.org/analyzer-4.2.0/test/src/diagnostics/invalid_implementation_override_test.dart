// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidImplementationOverrideTest);
    defineReflectiveTests(InvalidImplementationOverrideWithoutNullSafetyTest);
  });
}

@reflectiveTest
class InvalidImplementationOverrideTest extends PubPackageResolutionTest
    with InvalidImplementationOverrideTestCases {
  test_enum_getter_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
mixin M {
  num get foo => 0;
}
enum E with M {
  v;
  int get foo;
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 37, 1),
    ]);
  }

  test_enum_method_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
mixin M {
  num foo() => 0;
}
enum E with M {
  v;
  int foo();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 35, 1),
    ]);
  }

  test_enum_method_mixin_toString() async {
    await assertErrorsInCode('''
abstract class I {
  String toString([int? value]);
}

enum E1 implements I {
  v
}

enum E2 implements I {
  v;
  String toString([int? value]) => '';
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 60, 2),
    ]);
  }
}

mixin InvalidImplementationOverrideTestCases on PubPackageResolutionTest {
  test_class_generic_method_generic_hasCovariantParameter() async {
    await assertNoErrorsInCode('''
class A<T> {
  void foo<U>(covariant Object a, U b) {}
}
class B extends A<int> {}
''');
  }

  test_class_getter_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
class A {
  num get g => 7;
}
class B	extends A {
  int get g;
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 36, 1),
    ]);
  }

  test_class_method_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
class A	{
  int add(int a, int b) => a + b;
}
class B	extends A {
  int add();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 72, 3,
          contextMessages: [message('/home/test/lib/test.dart', 16, 3)]),
    ]);
  }

  test_class_method_abstractOverridesConcrete_expandedParameterType() async {
    await assertErrorsInCode('''
class A {
  int add(int a) => a;
}
class B	extends A {
  int add(num a);
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 41, 1),
    ]);
  }

  test_class_method_abstractOverridesConcrete_expandedParameterType_covariant() async {
    await assertNoErrorsInCode('''
class A {
  int add(covariant int a) => a;
}
class B	extends A {
  int add(num a);
}
''');
  }

  test_class_method_abstractOverridesConcrete_withOptional() async {
    await assertErrorsInCode('''
class A {
  int add() => 7;
}
class B	extends A {
  int add([int a = 0, int b = 0]);
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 36, 1),
    ]);
  }

  test_class_method_abstractOverridesConcreteInMixin() async {
    await assertErrorsInCode('''
mixin M {
  int add(int a, int b) => a + b;
}
class A with M {
  int add();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 69, 3,
          contextMessages: [message('/home/test/lib/test.dart', 16, 3)]),
    ]);
  }

  test_class_method_abstractOverridesConcreteViaMixin() async {
    await assertErrorsInCode('''
class A {
  int add(int a, int b) => a + b;
}
mixin M {
  int add();
}
class B	extends A with M {}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 77, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 94, 1,
          contextMessages: [message('/home/test/lib/test.dart', 16, 3)]),
    ]);
  }

  test_class_method_covariant_inheritance_merge() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}

class C {
  /// Not covariant-by-declaration here.
  void foo(B b) {}
}

abstract class I {
  /// Is covariant-by-declaration here.
  void foo(covariant A a);
}

/// Is covariant-by-declaration here.
class D extends C implements I {}
''');
  }
}

@reflectiveTest
class InvalidImplementationOverrideWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with InvalidImplementationOverrideTestCases, WithoutNullSafetyMixin {}

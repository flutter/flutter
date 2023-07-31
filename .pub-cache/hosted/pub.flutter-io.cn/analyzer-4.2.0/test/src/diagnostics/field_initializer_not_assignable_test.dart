// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerNotAssignableTest);
    defineReflectiveTests(
        FieldInitializerNotAssignableWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(FieldInitializerNotAssignableWithStrictCastsTest);
  });
}

@reflectiveTest
class FieldInitializerNotAssignableTest extends PubPackageResolutionTest {
  test_class_implicitCallReference() async {
    await assertNoErrorsInCode('''
class C {
  void call(int p) {}
}
class A {
  void Function(int) x;
  A() : x = C();
}
''');
  }

  test_class_implicitCallReference_genericFunctionInstantiation() async {
    await assertNoErrorsInCode('''
class C {
  void call<T>(T p) {}
}
class A {
  void Function(int) x;
  A() : x = C();
}
''');
  }

  test_class_unrelated() async {
    await assertErrorsInCode('''
class A {
  int x;
  A() : x = '';
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 31, 2),
    ]);
  }

  test_enum_unrelated() async {
    await assertErrorsInCode('''
enum E {
  v;
  final int x;
  const E() : x = '';
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH, 11, 1),
      error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 47, 2),
      error(CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE, 47, 2),
    ]);
  }
}

@reflectiveTest
class FieldInitializerNotAssignableWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_constructorInitializer() async {
    await assertErrorsWithNoImplicitCasts('''
class A {
  int i;
  A(num n) : i = n;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 36, 1),
    ]);
  }
}

@reflectiveTest
class FieldInitializerNotAssignableWithStrictCastsTest
    extends PubPackageResolutionTest with WithStrictCastsMixin {
  test_constructorInitializer() async {
    await assertErrorsWithStrictCasts(
      '''
class A {
  int i;
  A(dynamic a) : i = a;
}
''',
      [
        error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 40, 1),
      ],
    );
  }
}

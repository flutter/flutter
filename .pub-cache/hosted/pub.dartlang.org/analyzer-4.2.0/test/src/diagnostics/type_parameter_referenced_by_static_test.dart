// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterReferencedByStaticTest);
  });
}

@reflectiveTest
class TypeParameterReferencedByStaticTest extends PubPackageResolutionTest {
  test_expression_method() async {
    await assertErrorsInCode('''
class A<T> {
  static foo() {
    T;
  }
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 34, 1),
    ]);
  }

  test_type_field() async {
    await assertErrorsInCode('''
class A<T> {
  static T? foo;
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_type_getter() async {
    await assertErrorsInCode('''
class A<T> {
  static T? get foo => null;
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_type_method_bodyReference() async {
    await assertErrorsInCode('''
class A<T> {
  static foo() {
    // ignore:unused_local_variable
    T v;
  }
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 70, 1),
    ]);
  }

  test_type_method_closure() async {
    await assertErrorsInCode('''
class A<T> {
  static Object foo() {
    return (T a) {};
  }
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 49, 1),
    ]);
  }

  test_type_method_parameter() async {
    await assertErrorsInCode('''
class A<T> {
  static foo(T a) {}
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 26, 1),
    ]);
  }

  test_type_method_return() async {
    await assertErrorsInCode('''
class A<T> {
  static T foo() {
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 22, 1),
    ]);
  }

  test_type_setter() async {
    await assertErrorsInCode('''
class A<T> {
  static set foo(T _) {}
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 30, 1),
    ]);
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericFunctionTypeResolutionTest);
  });
}

@reflectiveTest
class GenericFunctionTypeResolutionTest extends PubPackageResolutionTest {
  /// Test that when [GenericFunctionType] is used in a constant variable
  /// initializer, analysis does not throw an exception; and that the next
  /// [GenericFunctionType] is also handled correctly.
  test_constInitializer_field_static_const() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}

class B {
  static const x = const A<bool Function()>();
}

int Function(int a)? y;
''');
  }

  /// Test that when [GenericFunctionType] is used in a constant variable
  /// initializer, analysis does not throw an exception; and that the next
  /// [GenericFunctionType] is also handled correctly.
  test_constInitializer_topLevel() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
}

const x = const A<bool Function()>();

int Function(int a)? y;
''');
  }

  test_metadata_typeParameter() async {
    await assertNoErrorsInCode(r'''
const a = 42;

Function<@a T>()? x;
''');
    var T = findNode.typeParameter('T');
    var annotation = T.declaredElement!.metadata[0];
    expect(annotation.element, findElement.topGet('a'));
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [FunctionDeclaration], all of them are resolved correctly.
  test_typeAnnotation_function() async {
    await assertNoErrorsInCode('''
void Function()? f<T extends bool Function()>(int Function() a) {
  return null;
}

double Function()? x;
''');
    assertType(
      findNode.genericFunctionType('void Function()?'),
      'void Function()?',
    );
    assertType(
      findNode.genericFunctionType('bool Function()'),
      'bool Function()',
    );
    assertType(
      findNode.genericFunctionType('int Function()'),
      'int Function()',
    );
    assertType(
      findNode.genericFunctionType('double Function()?'),
      'double Function()?',
    );
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [FunctionDeclaration], the one in the return type is consumed before the
  /// one in the parameter type. This is necessary because matching of
  /// [GenericFunctionType] nodes to their elements is based on the sequential
  /// identifier of a node in the unit.
  test_typeAnnotation_function_returnType_parameterType() async {
    await assertNoErrorsInCode(r'''
void Function(E a) f<E>(void Function() b) {
  return (_) {};
}
''');
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [GenericFunctionType], all of them are resolved correctly.
  test_typeAnnotation_genericFunctionType() async {
    await assertNoErrorsInCode('''
void f(
  void Function() a,
  bool Function() Function(int Function()) b,
) {}
''');
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [FunctionDeclaration], all of them are resolved correctly.
  test_typeAnnotation_method() async {
    await assertNoErrorsInCode('''
class C {
  void Function()? m<T extends bool Function()>(int Function() a) {
    return null;
  }
}

double Function()? x;
''');
    assertType(
      findNode.genericFunctionType('void Function()?'),
      'void Function()?',
    );
    assertType(
      findNode.genericFunctionType('bool Function()'),
      'bool Function()',
    );
    assertType(
      findNode.genericFunctionType('int Function()'),
      'int Function()',
    );
    assertType(
      findNode.genericFunctionType('double Function()?'),
      'double Function()?',
    );
  }

  /// Test that when multiple [GenericFunctionType]s are used in a
  /// [MethodDeclaration], the one in the return type is consumed before the
  /// one in the parameter type. This is necessary because matching of
  /// [GenericFunctionType] nodes to their elements is based on the sequential
  /// identifier of a node in the unit.
  test_typeAnnotation_method_returnType_parameterType() async {
    await assertNoErrorsInCode(r'''
class C {
  void Function(E a) f<E>(void Function() b) {
    return (_) {};
  }
}
''');
  }
}

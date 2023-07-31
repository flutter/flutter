// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithFieldInitializedByNonConstTest);
  });
}

@reflectiveTest
class ConstConstructorWithFieldInitializedByNonConstTest
    extends PubPackageResolutionTest {
  test_class_factoryConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final List<int> list = f();
  const factory A() = B;
}
class B implements A {
  final List<int> list = const [];
  const B();
}
List<int> f() {
  return [3];
}
''');
  }

  test_class_instanceField() async {
    await assertErrorsInCode(r'''
class A {
  final int i = f();
  const A();
}
int f() {
  return 3;
}
''', [
      error(
          CompileTimeErrorCode
              .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
          33,
          5),
    ]);
  }

  test_class_staticField() async {
    await assertNoErrorsInCode(r'''
class A {
  static final int i = f();
  const A();
}
int f() {
  return 3;
}
''');
  }

  test_enum_instanceField() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int i = f();
  const E();
}
int f() => 0;
''', [
      error(
          CompileTimeErrorCode
              .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
          37,
          5),
    ]);
  }

  test_enum_staticField() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static final int i = f();
  const E();
}
int f() => 0;
''');
  }
}

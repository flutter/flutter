// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetterNotSubtypeSetterTypesTest);
  });
}

@reflectiveTest
class GetterNotSubtypeSetterTypesTest extends PubPackageResolutionTest {
  test_class_instance() async {
    await assertErrorsInCode('''
class C {
  num get foo => 0;
  set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 20, 3),
    ]);
  }

  test_class_instance_dynamicGetter() async {
    await assertErrorsInCode(r'''
class C {
  get foo => 0;
  set foo(String v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 16, 3),
    ]);
  }

  test_class_instance_dynamicSetter() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(v) {}
}
''');
  }

  test_class_instance_field() async {
    await assertErrorsInCode('''
class C {
  final num foo = 0;
  set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 22, 3),
    ]);
  }

  test_class_instance_interfaces() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B {
  set foo(String _) {}
}

abstract class X implements A, B {}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 84, 1),
    ]);
  }

  test_class_instance_private_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  set _foo(String _) {}
}
''', [
      error(HintCode.UNUSED_ELEMENT, 44, 4),
    ]);
  }

  test_class_instance_private_interfaces() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
class B {
  set _foo(String _) {}
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';
import 'b.dart';

class X implements A, B {}
''');
  }

  test_class_instance_private_interfaces2() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int get _foo => 0;
}

class B {
  set _foo(String _) {}
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

class X implements A, B {}
''');
  }

  test_class_instance_private_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  set _foo(String _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  int get _foo => 0;
}
''', [
      error(HintCode.UNUSED_ELEMENT, 48, 4),
    ]);
  }

  test_class_instance_sameClass() async {
    await assertErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(String _) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 20, 3),
    ]);
  }

  test_class_instance_sameTypes() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(int v) {}
}
''');
  }

  test_class_instance_setterParameter_0() async {
    await assertErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo() {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 36, 3),
    ]);
  }

  test_class_instance_setterParameter_2() async {
    await assertErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(String p1, String p2) {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 36, 3),
    ]);
  }

  test_class_instance_superGetter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

class B extends A {
  set foo(String _) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 59, 3),
    ]);
  }

  test_class_instance_superSetter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(String _) {}
}

class B extends A {
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 66, 3),
    ]);
  }

  test_class_static() async {
    await assertErrorsInCode('''
class C {
  static num get foo => 0;
  static set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 27, 3),
    ]);
  }

  test_class_static_field() async {
    await assertErrorsInCode('''
class C {
  static final num foo = 0;
  static set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 29, 3),
    ]);
  }

  test_enum_instance_mixinGetter_mixinSetter() async {
    await assertErrorsInCode('''
mixin M1 {
  num get foo => 0;
}

mixin M2 {
  set foo(int v) {}
}

enum E with M1, M2 {
  v
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 73, 1),
    ]);
  }

  test_enum_instance_mixinGetter_thisSetter() async {
    await assertErrorsInCode('''
mixin M {
  num get foo => 0;
}

enum E with M {
  v;
  set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 60, 3),
    ]);
  }

  test_enum_instance_superGetter_thisSetter_index() async {
    await assertErrorsInCode('''
enum E {
  v;
  set index(String _) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 20, 5),
    ]);
  }

  test_enum_instance_thisField_thisSetter() async {
    await assertErrorsInCode('''
enum E {
  v;
  final num foo = 0;
  set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 26, 3),
    ]);
  }

  test_enum_instance_thisGetter_thisSetter() async {
    await assertErrorsInCode('''
enum E {
  v;
  num get foo => 0;
  set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 24, 3),
    ]);
  }

  test_enum_static() async {
    await assertErrorsInCode('''
enum E {
  v;
  static num get foo => 0;
  static set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 31, 3),
    ]);
  }

  test_enum_static_field() async {
    await assertErrorsInCode('''
enum E {
  foo;
  static set foo(int v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 11, 3),
    ]);
  }

  test_enum_static_generatedGetter_thisSetter_index() async {
    await assertErrorsInCode('''
enum E {
  v;
  static set values(int _) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 5, 1),
    ]);
  }

  test_extension_instance() async {
    await assertErrorsInCode('''
extension E on Object {
  int get foo => 0;
  set foo(String v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 34, 3),
    ]);
  }

  test_extension_static() async {
    await assertErrorsInCode('''
extension E on Object {
  static int get foo => 0;
  static set foo(String v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 41, 3),
    ]);
  }

  test_extension_static_field() async {
    await assertErrorsInCode('''
extension E on Object {
  static final int foo = 0;
  static set foo(String v) {}
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 43, 3),
    ]);
  }

  test_topLevel() async {
    await assertErrorsInCode('''
int get foo => 0;
set foo(String v) {}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 8, 3),
    ]);
  }

  test_topLevel_dynamicGetter() async {
    await assertErrorsInCode(r'''
get foo => 0;
set foo(int v) {}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 4, 3),
    ]);
  }

  test_topLevel_dynamicSetter() async {
    await assertNoErrorsInCode(r'''
int get foo => 0;
set foo(v) {}
''');
  }

  test_topLevel_sameTypes() async {
    await assertNoErrorsInCode(r'''
int get foo => 0;
set foo(int v) {}
''');
  }

  test_topLevel_variable() async {
    await assertErrorsInCode('''
final int foo = 0;
set foo(String v) {}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES, 10, 3),
    ]);
  }
}

// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalConcreteEnumMemberDeclarationClassTest);
    defineReflectiveTests(IllegalConcreteEnumMemberDeclarationEnumTest);
    defineReflectiveTests(IllegalConcreteEnumMemberDeclarationMixinTest);
  });
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationClassTest
    extends PubPackageResolutionTest {
  test_hashCode_field() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int hashCode = 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 41, 8),
    ]);
  }

  test_hashCode_getter() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int get hashCode => 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 45, 8),
    ]);
  }

  test_hashCode_getter_abstract() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  int get hashCode;
}
''');
  }

  test_hashCode_setter() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  set hashCode(int _) {}
}
''');
  }

  test_index_field() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int index = 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 41, 5),
    ]);
  }

  test_index_getter() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  int get index => 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 45, 5),
    ]);
  }

  test_index_getter_abstract() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  int get index;
}
''');
  }

  test_index_setter() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Enum {
  set index(int _) {}
}
''');
  }

  test_operatorEqEq() async {
    await assertErrorsInCode(r'''
abstract class A implements Enum {
  bool operator ==(Object other) => false;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 51, 2),
    ]);
  }
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationEnumTest
    extends PubPackageResolutionTest {
  test_index_field() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int index = 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 26, 5),
    ]);
  }

  test_index_field_notInitializer() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int index;
  const E();
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 26, 5),
    ]);
  }

  test_index_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int get index => 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 24, 5),
    ]);
  }

  test_index_getter_abstract() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  int get index;
}
''');
  }

  test_index_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  set index(int _) {}
}
''');
  }

  test_operatorEqEq() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  bool operator ==(Object other) => false;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 30, 2),
    ]);
  }
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationMixinTest
    extends PubPackageResolutionTest {
  test_index_field() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  int index = 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 24, 5),
    ]);
  }

  test_index_getter() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  int get index => 0;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 28, 5),
    ]);
  }

  test_index_getter_abstract() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  int get index;
}
''');
  }

  test_index_setter() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {
  set index(int _) {}
}
''');
  }

  test_operatorEqEq() async {
    await assertErrorsInCode(r'''
mixin M on Enum {
  bool operator ==(Object other) => false;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 34, 2),
    ]);
  }
}

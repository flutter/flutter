// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsDisallowedClassTest);
  });
}

@reflectiveTest
class ImplementsDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await assertErrorsInCode('''
class A implements bool {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 4),
    ]);
  }

  test_class_dartCoreEnum_abstract() async {
    await assertNoErrorsInCode('''
abstract class A implements Enum {}
''');
  }

  test_class_dartCoreEnum_language216_abstract() async {
    await assertErrorsInCode('''
// @dart = 2.16
abstract class A implements Enum {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 44, 4),
    ]);
  }

  test_class_dartCoreEnum_language216_concrete() async {
    await assertErrorsInCode('''
// @dart = 2.16
class A implements Enum {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 35, 4),
    ]);
  }

  test_class_double() async {
    await assertErrorsInCode('''
class A implements double {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
    ]);
  }

  test_class_FutureOr() async {
    await assertErrorsInCode('''
import 'dart:async';
class A implements FutureOr {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 40, 8),
    ]);
  }

  test_class_FutureOr_typeArgument() async {
    await assertErrorsInCode('''
import 'dart:async';
class A implements FutureOr<int> {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 40, 13),
    ]);
  }

  test_class_FutureOr_typedef() async {
    await assertErrorsInCode('''
import 'dart:async';
typedef F = FutureOr<void>;
class A implements F {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 68, 1),
    ]);
  }

  test_class_FutureOr_typeVariable() async {
    await assertErrorsInCode('''
import 'dart:async';
class A<T> implements FutureOr<T> {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 43, 11),
    ]);
  }

  test_class_int() async {
    await assertErrorsInCode('''
class A implements int {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 3),
    ]);
  }

  test_class_Null() async {
    await assertErrorsInCode('''
class A implements Null {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 4),
    ]);
  }

  test_class_num() async {
    await assertErrorsInCode('''
class A implements num {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 3),
    ]);
  }

  test_class_Record() async {
    await assertErrorsInCode('''
class A implements Record {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
    ]);
  }

  test_class_String() async {
    await assertErrorsInCode('''
class A implements String {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
    ]);
  }

  test_class_String_num() async {
    await assertErrorsInCode('''
class A implements String, num {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 27, 3),
    ]);
  }

  test_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements bool;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 4),
    ]);
  }

  test_classTypeAlias_dartCoreEnum_abstract() async {
    await assertNoErrorsInCode('''
class M {}
abstract class A = Object with M implements Enum;
''');
  }

  test_classTypeAlias_dartCoreEnum_language216_abstract() async {
    await assertErrorsInCode('''
// @dart = 2.16
mixin M {}
abstract class A = Object with M implements Enum;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 71, 4),
    ]);
  }

  test_classTypeAlias_dartCoreEnum_language216_concrete() async {
    await assertErrorsInCode('''
// @dart = 2.16
mixin M {}
class A = Object with M implements Enum;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 62, 4),
    ]);
  }

  test_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements double;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 6),
    ]);
  }

  test_classTypeAlias_FutureOr() async {
    await assertErrorsInCode(r'''
import 'dart:async';
class A {}
class M {}
class C = A with M implements FutureOr;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 73, 8),
    ]);
  }

  test_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements int;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 3),
    ]);
  }

  test_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements Null;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 4),
    ]);
  }

  test_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements num;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 3),
    ]);
  }

  test_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements String;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 6),
    ]);
  }

  test_classTypeAlias_String_num() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements String, num;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 6),
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 60, 3),
    ]);
  }

  test_enum_int() async {
    await assertErrorsInCode('''
enum E implements int {
  v
}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 18, 3),
    ]);
  }

  test_mixin_dartCoreEnum() async {
    await assertNoErrorsInCode('''
mixin M implements Enum {}
''');
  }

  test_mixin_dartCoreEnum_language216() async {
    await assertErrorsInCode('''
// @dart = 2.16
mixin M implements Enum {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 35, 4),
    ]);
  }

  test_mixin_int() async {
    await assertErrorsInCode(r'''
mixin M implements int {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 3),
    ]);

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, ['int']);

    var typeRef = findNode.namedType('int {}');
    assertNamedType(typeRef, intElement, 'int');
  }
}

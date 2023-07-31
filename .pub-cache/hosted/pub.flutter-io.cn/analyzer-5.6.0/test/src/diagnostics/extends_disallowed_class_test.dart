// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsDisallowedClassTest);
  });
}

@reflectiveTest
class ExtendsDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await assertErrorsInCode('''
class A extends bool {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 4),
    ]);
  }

  test_class_double() async {
    await assertErrorsInCode('''
class A extends double {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 6),
    ]);
  }

  test_class_FutureOr() async {
    await assertErrorsInCode('''
import 'dart:async';
class A extends FutureOr {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 37, 8),
    ]);
  }

  test_class_FutureOr_typeArgument() async {
    await assertErrorsInCode('''
import 'dart:async';
class A extends FutureOr<int> {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 37, 13),
    ]);
  }

  test_class_FutureOr_typedef() async {
    await assertErrorsInCode('''
import 'dart:async';
typedef F = FutureOr<void>;
class A extends F {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 65, 1),
    ]);
  }

  test_class_FutureOr_typeVariable() async {
    await assertErrorsInCode('''
import 'dart:async';
class A<T> extends FutureOr<T> {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 40, 11),
    ]);
  }

  test_class_int() async {
    await assertErrorsInCode('''
class A extends int {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 3),
    ]);
  }

  test_class_Null() async {
    await assertErrorsInCode('''
class A extends Null {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 4),
    ]);
  }

  test_class_num() async {
    await assertErrorsInCode('''
class A extends num {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 3),
    ]);
  }

  test_class_Record() async {
    await assertErrorsInCode('''
class A extends Record {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 6),
    ]);
  }

  test_class_String() async {
    await assertErrorsInCode('''
class A extends String {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 6),
    ]);
  }

  test_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class M {}
class C = bool with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 4),
    ]);
  }

  test_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class M {}
class C = double with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 6),
    ]);
  }

  test_classTypeAlias_FutureOr() async {
    await assertErrorsInCode(r'''
import 'dart:async';
class M {}
class C = FutureOr with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 42, 8),
    ]);
  }

  test_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class M {}
class C = int with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 3),
    ]);
  }

  test_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class M {}
class C = Null with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 4),
    ]);
  }

  test_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class M {}
class C = num with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 3),
    ]);
  }

  test_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class M {}
class C = String with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 6),
    ]);
  }
}

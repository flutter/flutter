// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFieldName_RecordLiteralTest);
    defineReflectiveTests(InvalidFieldName_RecordTypeAnnotationTest);
  });
}

@reflectiveTest
class InvalidFieldName_RecordLiteralTest extends PubPackageResolutionTest {
  void test_fromObject() async {
    await assertErrorsInCode(r'''
var r = (hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 9, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 22, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 39, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 55, 8),
    ]);
  }

  void test_fromObject_withPositional() async {
    await assertErrorsInCode(r'''
var r = (0, hashCode: 1, noSuchMethod: 2, runtimeType: 3, toString: 4);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 12, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 25, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 42, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 58, 8),
    ]);
  }

  void test_positional_named_conflict() async {
    await assertErrorsInCode(r'''
var r = (0, $1: 2);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 12, 2),
    ]);
  }

  void test_positional_named_conflict_namedBeforePositional() async {
    await assertErrorsInCode(r'''
var r = ($1: 2, 1);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 9, 2),
    ]);
  }

  void test_positional_named_leadingZero() async {
    await assertNoErrorsInCode(r'''
var r = (0, 1, $02: 2);
''');
  }

  void test_positional_named_noConflict() async {
    await assertNoErrorsInCode(r'''
var r = (0, $2: 2);
''');
  }

  void test_private() async {
    await assertErrorsInCode(r'''
var r = (_a: 1, b: 2);
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 9, 2),
    ]);
  }
}

@reflectiveTest
class InvalidFieldName_RecordTypeAnnotationTest
    extends PubPackageResolutionTest {
  void test_fromObject_named() async {
    await assertErrorsInCode(r'''
void f(({int hashCode, int noSuchMethod, int runtimeType, int toString}) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 13, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 27, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 45, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 62, 8),
    ]);
  }

  void test_fromObject_positional() async {
    await assertErrorsInCode(r'''
void f((int hashCode, int noSuchMethod, int runtimeType, int toString) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 12, 8),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 26, 12),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 44, 11),
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT, 61, 8),
    ]);
  }

  void test_positional_named_conflict() async {
    await assertErrorsInCode(r'''
void f((int, String, {int $2}) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 26, 2),
    ]);
  }

  void test_positional_named_leadingZero() async {
    await assertNoErrorsInCode(r'''
void f((int, String, {int $02}) r) {}
''');
  }

  void test_positional_named_noConflict() async {
    await assertNoErrorsInCode(r'''
void f(({int $22}) r) {}
''');
  }

  void test_positional_positional_conflict() async {
    await assertErrorsInCode(r'''
void f((int $2, int b) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL, 12, 2),
    ]);
  }

  void test_positional_positional_noConflict_same() async {
    await assertNoErrorsInCode(r'''
void f((int $1, int b) r) {}
''');
  }

  void test_positional_positional_noConflict_unused() async {
    await assertNoErrorsInCode(r'''
void f((int $4, int b) r) {}
''');
  }

  void test_private_named() async {
    await assertErrorsInCode(r'''
void f(({int _a}) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 13, 2),
    ]);
  }

  void test_private_positional() async {
    await assertErrorsInCode(r'''
void f((int _a, int b) r) {}
''', [
      error(CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE, 12, 2),
    ]);
  }
}

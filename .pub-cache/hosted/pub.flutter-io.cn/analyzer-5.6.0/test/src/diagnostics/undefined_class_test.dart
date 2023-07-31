// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedClassTest);
  });
}

@reflectiveTest
class UndefinedClassTest extends PubPackageResolutionTest {
  test_augmentation_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
library augment 'test.dart';
''');

    await assertErrorsInCode(r'''
import augment 'a.g.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 28, 3),
    ]);
  }

  test_augmentation_notExist_uriGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
import augment 'a.g.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 15, 10),
    ]);
  }

  test_augmentation_notExist_uriGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
import augment 'a.g.dart';

A a;
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 15, 10),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 28, 1),
    ]);
  }

  test_augmentation_notExist_uriNotGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
import augment 'a.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 15, 8),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 26, 3),
    ]);
  }

  test_augmentation_notExist_uriNotGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
import augment 'a.dart';

A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 15, 8),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 26, 1),
    ]);
  }

  test_const() async {
    await assertErrorsInCode(r'''
f() {
  return const A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_TYPE, 21, 1),
    ]);
  }

  test_dynamic_coreWithPrefix() async {
    await assertErrorsInCode('''
import 'dart:core' as core;

dynamic x;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 29, 7),
    ]);
  }

  test_ignore_libraryImport_prefix() async {
    await assertErrorsInCode(r'''
import 'a.dart' as p;

p.A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_ignore_libraryImport_show_it() async {
    await assertErrorsInCode(r'''
import 'a.dart' show A;

A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_ignore_libraryImport_show_other() async {
    await assertErrorsInCode(r'''
import 'a.dart' show B;

A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 25, 1),
    ]);
  }

  test_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(r'''
part 'a.g.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 18, 3),
    ]);
  }

  test_ignore_part_notExist_uriGenerated2_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.template.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 17),
    ]);
  }

  test_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
    ]);
  }

  test_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

A a;
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 18, 1),
    ]);
  }

  test_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

_$A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 16, 3),
    ]);
  }

  test_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

A a;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 16, 1),
    ]);
  }

  test_import_exists_prefixed() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

p.A a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 26, 3),
    ]);
  }

  test_instanceCreation() async {
    await assertErrorsInCode('''
f() { new C(); }
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 10, 1),
    ]);
  }

  test_Record() async {
    await assertNoErrorsInCode('''
void f(Record r) {}
''');
  }

  test_Record_language218() async {
    await assertErrorsInCode('''
// @dart = 2.18
void f(Record r) {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 23, 6),
    ]);
  }

  test_Record_language218_exported() async {
    newFile('$testPackageLibPath/a.dart', r'''
export 'dart:core' show Record;
''');

    await assertNoErrorsInCode('''
// @dart = 2.18
import 'a.dart';
void f(Record r) {}
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode('''
f() { C c; }
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 6, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 8, 1),
    ]);
  }
}

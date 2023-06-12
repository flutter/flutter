// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOfNonClassTest);
    defineReflectiveTests(MixinOfNonClassWithoutNullSafetyTest);
  });
}

@reflectiveTest
class MixinOfNonClassTest extends PubPackageResolutionTest
    with MixinOfNonClassTestCases {
  test_enum_enum() async {
    await assertErrorsInCode(r'''
enum E1 { v }
enum E2 with E1 { v }
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 27, 2),
    ]);
  }

  test_enum_topLevelVariable() async {
    await assertErrorsInCode(r'''
int A = 7;
enum E with A {
  v
}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 23, 1),
    ]);
  }

  test_enum_undefined() async {
    await assertErrorsInCode(r'''
enum E with M {
  v
}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 12, 1),
    ]);
  }

  test_Never() async {
    await assertErrorsInCode('''
class A with Never {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 13, 5),
    ]);
  }
}

mixin MixinOfNonClassTestCases on PubPackageResolutionTest {
  test_class_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends Object with E {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 43, 1),
    ]);
  }

  test_class_topLevelVariable() async {
    await assertErrorsInCode(r'''
int A = 7;
class B extends Object with A {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 39, 1),
    ]);
  }

  test_class_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
int B = 7;
class C = A with B;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 39, 1),
    ]);
  }

  test_class_undefined() async {
    await assertErrorsInCode(r'''
class C with M {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 13, 1),
    ]);
  }

  test_undefined_ignore_import_prefix() async {
    await assertErrorsInCode(r'''
import 'a.dart' as p;

class C with p.M {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_undefined_ignore_import_show_it() async {
    await assertErrorsInCode(r'''
import 'a.dart' show M;

class C with M {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_undefined_ignore_import_show_other() async {
    await assertErrorsInCode(r'''
import 'a.dart' show N;

class C with M {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 38, 1),
    ]);
  }

  test_undefined_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(r'''
part 'a.g.dart';

class C with _$M {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 31, 3),
    ]);
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

class C with _$M {}
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
    ]);
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

class C with M {}
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 31, 1),
    ]);
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

class C with _$M {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 29, 3),
    ]);
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

class C with M {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 29, 1),
    ]);
  }

  test_undefined_import_exists_prefixed() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

class C with p.M {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 39, 3),
    ]);
  }
}

@reflectiveTest
class MixinOfNonClassWithoutNullSafetyTest extends PubPackageResolutionTest
    with MixinOfNonClassTestCases, WithoutNullSafetyMixin {}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends PubPackageResolutionTest {
  test_class_dynamic() async {
    await assertErrorsInCode(r'''
class A extends dynamic {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 7),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_class_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends E {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 31, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');

    var eRef = findNode.namedType('E {}');
    assertNamedType(eRef, findElement.enum_('E'), 'E');
  }

  test_class_mixin() async {
    await assertErrorsInCode(r'''
mixin M {}
class A extends M {} // ref
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');

    var mRef = findNode.namedType('M {} // ref');
    assertNamedType(mRef, findElement.mixin('M'), 'M');
  }

  test_class_variable() async {
    await assertErrorsInCode(r'''
int v = 0;
class A extends v {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_class_variable_generic() async {
    await assertErrorsInCode(r'''
int v = 0;
class A extends v<int> {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_Never() async {
    await assertErrorsInCode('''
class A extends Never {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 5),
    ]);
  }

  test_undefined() async {
    await assertErrorsInCode(r'''
class C extends A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 1),
    ]);
  }

  test_undefined_ignore_import_prefix() async {
    await assertErrorsInCode(r'''
import 'a.dart' as p;

class C extends p.A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_undefined_ignore_import_show_it() async {
    await assertErrorsInCode(r'''
import 'a.dart' show A;

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
    ]);
  }

  test_undefined_ignore_import_show_other() async {
    await assertErrorsInCode(r'''
import 'a.dart' show B;

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 8),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 41, 1),
    ]);
  }

  test_undefined_ignore_part_exists_uriGenerated_nameIgnorable() async {
    newFile('$testPackageLibPath/a.g.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(r'''
part 'a.g.dart';

class C extends _$A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 34, 3),
    ]);
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

class C extends _$A {}
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
    ]);
  }

  test_undefined_ignore_part_notExist_uriGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.g.dart';

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED, 5, 10),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 34, 1),
    ]);
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

class C extends _$A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 32, 3),
    ]);
  }

  test_undefined_ignore_part_notExist_uriNotGenerated_nameNotIgnorable() async {
    await assertErrorsInCode(r'''
part 'a.dart';

class C extends A {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 8),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 32, 1),
    ]);
  }

  test_undefined_import_exists_prefixed() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;

class C extends p.A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 42, 3),
    ]);
  }
}

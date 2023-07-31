// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalMixinImplementedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalMixinImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await assertNoErrorsInCode(r'''
final mixin Foo {}
class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          3),
    ]);
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          10),
    ]);
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 66,
          10),
    ]);
  }

  test_class_subtypeOfFinal_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
class Bar implements Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 implements Bar {}
''');
  }

  test_enum_inside() async {
    await assertNoErrorsInCode(r'''
final mixin Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          3),
    ]);
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          10),
    ]);
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 65,
          10),
    ]);
  }

  test_enum_subtypeOfFinal_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
class Bar implements Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
enum Bar2 implements Bar { bar }
''');
  }

  test_mixin_inside() async {
    await assertNoErrorsInCode(r'''
final mixin Foo {}
mixin Bar implements Foo {}
''');
  }

  test_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
mixin Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          3),
    ]);
  }

  test_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
mixin Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          10),
    ]);
  }

  test_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
mixin Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.FINAL_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 66,
          10),
    ]);
  }

  test_mixin_subtypeOfFinal_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
class Bar implements Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
mixin Bar2 implements Bar {}
''');
  }
}

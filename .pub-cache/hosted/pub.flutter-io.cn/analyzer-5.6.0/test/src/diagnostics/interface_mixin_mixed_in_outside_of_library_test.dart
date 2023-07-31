// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InterfaceMixinMixedInOutsideOfLibraryTest);
  });
}

@reflectiveTest
class InterfaceMixinMixedInOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await assertNoErrorsInCode(r'''
interface mixin Foo {}
class Bar with Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''', [
      error(CompileTimeErrorCode.INTERFACE_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY,
          34, 3),
    ]);
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''', [
      error(CompileTimeErrorCode.INTERFACE_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY,
          34, 10),
    ]);
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''', [
      error(CompileTimeErrorCode.INTERFACE_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY,
          60, 10),
    ]);
  }

  test_class_subtypeOfBase_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
class Bar with Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 extends Bar {}
''');
  }

  test_enum_inside() async {
    await assertNoErrorsInCode(r'''
interface mixin Foo {}
enum Bar with Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar with Foo { bar }
''', [
      error(CompileTimeErrorCode.INTERFACE_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY,
          33, 3),
    ]);
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar with FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.INTERFACE_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY,
          33, 10),
    ]);
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
interface mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar with FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.INTERFACE_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY,
          59, 10),
    ]);
  }
}

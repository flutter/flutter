// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassUsedAsMixinTest);
  });
}

@reflectiveTest
class ClassUsedAsMixinTest extends PubPackageResolutionTest {
  test_inside() async {
    await assertNoErrorsInCode(r'''
class Foo {}
class Bar with Foo {}
''');
  }

  test_inside_language219() async {
    await assertNoErrorsInCode(r'''
// @dart = 2.19
class Foo {}
class Bar with Foo {}
''');
  }

  test_inside_mixinClass() async {
    await assertNoErrorsInCode(r'''
mixin class Foo {}
class Bar with Foo {}
''');
  }

  test_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 34, 3),
    ]);
  }

  test_outside_language219() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.19
class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''');
  }

  test_outside_language219_mixedIn() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.19
import 'foo.dart';
class Bar with Foo {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 50, 3),
    ]);
  }

  test_outside_mixinClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''');
  }

  test_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 34, 10),
    ]);
  }

  test_outside_viaTypedef_inside_language219() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.19
class Foo {}
typedef FooTypedef = Foo;
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''');
  }

  test_outside_viaTypedef_inside_mixinClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
typedef FooTypedef = Foo;
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''');
  }

  test_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 60, 10),
    ]);
  }

  test_outside_viaTypedef_outside_language219() async {
    newFile('$testPackageLibPath/foo.dart', r'''
// @dart = 2.19
class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''');
  }

  test_outside_viaTypedef_outside_mixinClass() async {
    newFile('$testPackageLibPath/foo.dart', r'''
mixin class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''');
  }
}

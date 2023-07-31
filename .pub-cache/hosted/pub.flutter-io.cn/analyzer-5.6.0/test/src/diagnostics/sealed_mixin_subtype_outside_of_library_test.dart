// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SealedMixinSubtypeOutsideOfLibraryTest);
  });
}

@reflectiveTest
class SealedMixinSubtypeOutsideOfLibraryTest extends PubPackageResolutionTest {
  test_class_typeAlias_with_sealed_mixin_inside() async {
    await assertNoErrorsInCode(r'''
sealed mixin Foo {}
class Bar = Object with Foo;
''');
  }

  test_class_typeAlias_with_sealed_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar = Object with Foo;
''', [
      error(
          CompileTimeErrorCode.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY, 43, 3),
    ]);
  }

  test_class_typeAlias_with_sealed_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar = Object with FooTypedef;
''', [
      error(
          CompileTimeErrorCode.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY, 43, 10),
    ]);
  }

  test_class_typeAlias_with_sealed_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar = Object with FooTypedef;
''', [
      error(
          CompileTimeErrorCode.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY, 69, 10),
    ]);
  }

  test_class_with_sealed_mixin_inside() async {
    await assertNoErrorsInCode(r'''
sealed mixin Foo {}
class Bar with Foo {}
''');
  }

  test_class_with_sealed_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''', [
      error(
          CompileTimeErrorCode.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY, 34, 3),
    ]);
  }

  test_class_with_sealed_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY, 34, 10),
    ]);
  }

  test_class_with_sealed_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY, 60, 10),
    ]);
  }

  test_mixin_on_sealed_class_inside() async {
    await assertNoErrorsInCode(r'''
sealed class Foo {}
mixin Bar on Foo {}
''');
  }

  test_mixin_on_sealed_class_inside_multiple() async {
    await assertNoErrorsInCode(r'''
sealed class Foo {}
sealed class Foo2 {}
mixin Bar on Foo, Foo2 {}
''');
  }

  test_mixin_on_sealed_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
mixin Bar on Foo {}
''');
  }

  test_mixin_on_sealed_class_outside_multiple() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
sealed class Foo2 {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
mixin Bar on Foo, Foo2 {}
''');
  }

  test_mixin_on_sealed_classAndMixin_inside_multiple() async {
    await assertNoErrorsInCode(r'''
sealed class Foo {}
sealed mixin Foo2 {}
mixin Bar on Foo, Foo2 {}
''');
  }

  test_mixin_on_sealed_classAndMixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
sealed mixin Foo2 {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
mixin Bar on Foo, Foo2 {}
''');
  }
}

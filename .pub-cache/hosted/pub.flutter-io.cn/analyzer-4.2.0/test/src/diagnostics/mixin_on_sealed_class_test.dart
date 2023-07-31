// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOnSealedClassTest);
  });
}

@reflectiveTest
class MixinOnSealedClassTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_mixinOnSealedClass() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'foo', rootPath: '$workspaceRootPath/foo'),
      meta: true,
    );

    newFile('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'package:foo/foo.dart';
mixin Bar on Foo {}
''', [
      error(HintCode.MIXIN_ON_SEALED_CLASS, 31, 19),
    ]);
  }

  test_withinLibrary_OK() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
mixin Bar on Foo {}
''');
  }

  test_withinPackageLibDirectory_OK() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    newFile('$testPackageLibPath/src/lib2.dart', r'''
import '../lib1.dart';
mixin Bar on Foo {}
''');

    await resolveFile2('$testPackageLibPath/lib1.dart');
    assertNoErrorsInResult();

    await resolveFile2('$testPackageLibPath/src/lib2.dart');
    assertNoErrorsInResult();
  }

  test_withinPackageTestDirectory_OK() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@sealed class Foo {}
''');

    newFile('$testPackageRootPath/test/lib2.dart', r'''
import 'package:test/lib1.dart';
mixin Bar on Foo {}
''');

    await resolveFile2('$testPackageLibPath/lib1.dart');
    assertNoErrorsInResult();

    await resolveFile2('$testPackageRootPath/test/lib2.dart');
    assertNoErrorsInResult();
  }

  test_withinPart_OK() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:meta/meta.dart';
part 'part1.dart';
@sealed class Foo {}
''');

    newFile('$testPackageLibPath/part1.dart', r'''
part of 'lib1.dart';
mixin Bar on Foo {}
''');

    await resolveFile2('$testPackageLibPath/lib1.dart');
    assertNoErrorsInResult();

    await resolveFile2('$testPackageLibPath/part1.dart');
    assertNoErrorsInResult();
  }
}

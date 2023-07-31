// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportOfNotAugmentationTest);
  });
}

@reflectiveTest
class ImportOfNotAugmentationTest extends PubPackageResolutionTest {
  test_inLibrary_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await assertNoErrorsInCode('''
import augment 'a.dart';
''');
  }

  test_inLibrary_library_explicit() async {
    newFile('$testPackageLibPath/a.dart', r'''
library my.lib;
''');

    await assertErrorsInCode('''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);
  }

  test_inLibrary_library_implicit() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode('''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);
  }

  test_inLibrary_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    await assertErrorsInCode('''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);
  }

  test_inLibrary_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode('''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);
  }
}

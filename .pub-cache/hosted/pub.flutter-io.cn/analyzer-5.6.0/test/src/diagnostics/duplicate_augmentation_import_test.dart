// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateAugmentationImportTest);
  });
}

@reflectiveTest
class DuplicateAugmentationImportTest extends PubPackageResolutionTest {
  test_duplicate() async {
    newFile('$testPackageLibPath/a.dart', '''
library augment 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/b.dart', '''
library augment 'test.dart';
class B {}
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
import augment 'b.dart';
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_AUGMENTATION_IMPORT, 65, 8),
    ]);
  }

  test_ok() async {
    newFile('$testPackageLibPath/a.dart', '''
library augment 'test.dart';
class A {}
''');

    newFile('$testPackageLibPath/b.dart', '''
library augment 'test.dart';
class B {}
''');

    await assertNoErrorsInCode(r'''
import augment 'a.dart';
import augment 'b.dart';
''');
  }
}

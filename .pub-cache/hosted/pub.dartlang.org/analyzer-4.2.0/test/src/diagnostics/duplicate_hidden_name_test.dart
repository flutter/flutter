// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateHiddenNameTest);
  });
}

@reflectiveTest
class DuplicateHiddenNameTest extends PubPackageResolutionTest {
  test_hidden() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertErrorsInCode('''
export 'lib1.dart' hide A, B, A;
''', [
      error(HintCode.DUPLICATE_HIDDEN_NAME, 30, 1),
    ]);
  }
}

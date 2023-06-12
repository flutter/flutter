// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportResolutionTest);
  });
}

@reflectiveTest
class ImportResolutionTest extends PubPackageResolutionTest {
  test_overrideCoreType_Never() async {
    newFile('$testPackageLibPath/declares_never.dart', '''
class Never {}
''');
    await assertNoErrorsInCode(r'''
import 'declares_never.dart';

Never f() => throw 'foo';
''');
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousExportTest);
  });
}

@reflectiveTest
class AmbiguousExportTest extends PubPackageResolutionTest {
  test_class() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class N {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class N {}
''');
    await assertErrorsInCode(r'''
export 'lib1.dart';
export 'lib2.dart';
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXPORT, 27, 11),
    ]);
  }

  test_extensions_bothExported() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
extension E on String {}
''');
    await assertErrorsInCode(r'''
export 'lib1.dart';
export 'lib2.dart';
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_EXPORT, 27, 11),
    ]);
  }

  test_extensions_localAndExported() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
extension E on String {}
''');
    await assertNoErrorsInCode(r'''
export 'lib1.dart';

extension E on String {}
''');
  }
}

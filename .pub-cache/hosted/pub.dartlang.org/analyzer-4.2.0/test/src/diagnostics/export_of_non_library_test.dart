// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportOfNonLibraryTest);
  });
}

@reflectiveTest
class ExportOfNonLibraryTest extends PubPackageResolutionTest {
  test_export_of_non_library() async {
    newFile('$testPackageLibPath/lib1.dart', '''
part of lib;
''');
    await assertErrorsInCode(r'''
library L;
export 'lib1.dart';
''', [
      error(CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY, 18, 11,
          messageContains: ["library 'lib1.dart' "]),
    ]);
  }

  test_libraryDeclared() async {
    newFile('$testPackageLibPath/lib1.dart', "library lib1;");
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
''');
  }

  test_libraryNotDeclared() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
''');
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateImportTest);
  });
}

@reflectiveTest
class DuplicateImportTest extends PubPackageResolutionTest {
  test_duplicateImport() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
class A {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
A a = A();''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.DUPLICATE_IMPORT, 38, 11),
    ]);
  }

  test_importsHaveIdenticalShowHide() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
class A {}
class B {}
''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a = M.A();
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.DUPLICATE_IMPORT, 57, 11),
    ]);
  }

  test_oneImportHasHide() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
class A {}
class B {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
B b = B();
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_oneImportHasShow() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
class A {}
class B {}
''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart' show A; // ignore: unnecessary_import
A a = A();
B b = B();
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_oneImportUsesAs() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
class A {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
A a = A();
one.A a2 = one.A();
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_twoDuplicateImports() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
library lib1;
class A {}''');

    newFile('$testPackageLibPath/lib2.dart', content: r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a = A();
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.DUPLICATE_IMPORT, 38, 11),
      error(HintCode.DUPLICATE_IMPORT, 58, 11),
    ]);
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}

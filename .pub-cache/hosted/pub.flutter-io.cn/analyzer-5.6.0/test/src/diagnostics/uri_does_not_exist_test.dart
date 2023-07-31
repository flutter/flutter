// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UriDoesNotExistTest);
  });
}

@reflectiveTest
class UriDoesNotExistTest extends PubPackageResolutionTest {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/51407')
  test_doubleSlash() async {
    newFolder('$testPackageLibPath/c');
    newFile('$testPackageLibPath/c/d.dart', '''''
class D {}
''');
    newFile('$testPackageLibPath/b.dart', '''
import 'c/d.dart';
void g(D d) {}
''');
    await assertErrorsInCode(r'''
import 'b.dart';
import 'c//d.dart';

void f() {
  g(D());
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 24, 11),
    ]);
  }

  test_libraryExport() async {
    await assertErrorsInCode('''
export 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_libraryExport_cannotResolve() async {
    await assertErrorsInCode(r'''
export 'dart:foo';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 10),
    ]);
  }

  test_libraryExport_dart() async {
    await assertErrorsInCode('''
export 'dart:math/bar.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 20),
    ]);
  }

  test_libraryImport() async {
    await assertErrorsInCode('''
import 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_libraryImport_appears_after_deleting_target() async {
    String filePath = newFile('$testPackageLibPath/target.dart', '').path;

    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 13),
    ]);

    // Remove the overlay in the same way as AnalysisServer.
    deleteFile(filePath);

    var analysisDriver = driverFor(testFile);
    analysisDriver.removeFile(filePath);
    await analysisDriver.applyPendingFileChanges();

    await resolveTestFile();
    assertErrorsInResult([
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);
  }

  test_libraryImport_cannotResolve() async {
    await assertErrorsInCode(r'''
import 'dart:foo';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 10),
    ]);
  }

  test_libraryImport_dart() async {
    await assertErrorsInCode('''
import 'dart:math/bar.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 20),
    ]);
  }

  test_libraryImport_deferredWithInvalidUri() async {
    await assertErrorsInCode(r'''
import '[invalid uri]' deferred as p;
main() {
  p.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 15),
    ]);
  }

  @failingTest
  test_libraryImport_disappears_when_fixed() async {
    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);

    newFile('$testPackageLibPath/target.dart', '');

    // Make sure the error goes away.
    // TODO(brianwilkerson) The error does not go away, possibly because the
    //  file is not being reanalyzed.
    await resolveTestFile();
    assertErrorsInResult([
      error(HintCode.UNUSED_IMPORT, 0, 0),
    ]);
  }

  test_part() async {
    await assertErrorsInCode(r'''
library lib;
part 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 18, 14),
    ]);
  }

  test_part_cannotResolve() async {
    await assertErrorsInCode(r'''
part 'dart:foo';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 5, 10),
    ]);
  }
}

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
  test_deferredImportWithInvalidUri() async {
    await assertErrorsInCode(r'''
import '[invalid uri]' deferred as p;
main() {
  p.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 15),
    ]);
  }

  test_export() async {
    await assertErrorsInCode('''
export 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_import() async {
    await assertErrorsInCode('''
import 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_import_appears_after_deleting_target() async {
    String filePath = newFile('$testPackageLibPath/target.dart').path;

    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 13),
    ]);

    // Remove the overlay in the same way as AnalysisServer.
    deleteFile(filePath);
    driverFor(testFilePath).removeFile(filePath);

    await resolveTestFile();
    assertErrorsInResult([
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);
  }

  @failingTest
  test_import_disappears_when_fixed() async {
    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);

    newFile('$testPackageLibPath/target.dart');

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
}

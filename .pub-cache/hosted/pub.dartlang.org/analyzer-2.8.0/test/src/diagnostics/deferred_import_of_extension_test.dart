// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeferredImportOfExtensionTest);
  });
}

@reflectiveTest
class DeferredImportOfExtensionTest extends PubPackageResolutionTest {
  test_deferredImport_withExtensions() {
    newFile('$testPackageLibPath/foo.dart', content: '''
extension E on C {}
class C {}
''');
    assertErrorsInCode('''
import 'foo.dart' deferred as foo;

void f() {
  foo.C();
}
''', [
      error(CompileTimeErrorCode.DEFERRED_IMPORT_OF_EXTENSION, 7, 10),
    ]);
  }

  test_deferredImport_withHiddenExtensions() {
    newFile('$testPackageLibPath/foo.dart', content: '''
extension E on C {}
class C {}
''');
    assertNoErrorsInCode('''
import 'foo.dart' deferred as foo hide E;

void f() {
  foo.C();
}
''');
  }

  test_deferredImport_withoutExtensions() {
    newFile('$testPackageLibPath/foo.dart', content: '''
class C {}
''');
    assertNoErrorsInCode('''
import 'foo.dart' deferred as foo;

void f() {
  foo.C();
}
''');
  }

  test_deferredImport_withShownNonExtensions() {
    newFile('$testPackageLibPath/foo.dart', content: '''
extension E on C {}
class C {}
''');
    assertNoErrorsInCode('''
import 'foo.dart' deferred as foo show C;

void f() {
  foo.C();
}
''');
  }

  test_invalidUri() {
    assertErrorsInCode('''
import 'ht:' deferred as foo;
''', [
      error(CompileTimeErrorCode.INVALID_URI, 7, 5),
    ]);
  }
}

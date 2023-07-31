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
  Future<void> test_deferredImport_withExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on C {}
class C {}
''');
    await assertErrorsInCode('''
import 'foo.dart' deferred as foo;

void f() {
  foo.C();
}
''', [
      error(CompileTimeErrorCode.DEFERRED_IMPORT_OF_EXTENSION, 7, 10),
    ]);
  }

  Future<void> test_deferredImport_withHiddenExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on C {}
class C {}
''');
    await assertNoErrorsInCode('''
import 'foo.dart' deferred as foo hide E;

void f() {
  foo.C();
}
''');
  }

  Future<void> test_deferredImport_withoutExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
class C {}
''');
    await assertNoErrorsInCode('''
import 'foo.dart' deferred as foo;

void f() {
  foo.C();
}
''');
  }

  Future<void> test_deferredImport_withShownNonExtensions() async {
    newFile('$testPackageLibPath/foo.dart', '''
extension E on C {}
class C {}
''');
    await assertNoErrorsInCode('''
import 'foo.dart' deferred as foo show C;

void f() {
  foo.C();
}
''');
  }
}

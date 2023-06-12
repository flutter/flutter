// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDeferredLibraryWithLoadFunctionTest);
  });
}

@reflectiveTest
class ImportDeferredLibraryWithLoadFunctionTest
    extends PubPackageResolutionTest {
  test_deferredImport_withLoadLibraryFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void loadLibrary() {}
void f() {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' deferred as p;
void main() {
  p.f();
}
''', [
      error(HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION, 0, 30),
    ]);
  }

  test_deferredImport_withLoadLibraryFunction_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
void loadLibrary() {}
void f() {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' deferred as p hide loadLibrary;
void main() {
  p.f();
}
''');
  }

  test_deferredImport_withLoadLibraryFunction_hide2() async {
    newFile('$testPackageLibPath/a.dart', r'''
void loadLibrary() {}
void f() {}
void f2() {}
''');

    await assertErrorsInCode(r'''
import 'a.dart' deferred as p hide f2;
void main() {
  p.f();
}
''', [
      error(HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION, 0, 38),
    ]);
  }

  test_deferredImport_withLoadLibraryFunction_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
void loadLibrary() {}
void f() {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' deferred as p show f;
void main() {
  p.f();
}
''');
  }

  test_deferredImport_withoutLoadLibraryFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void f() {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' deferred as p;
void main() {
  p.f();
}
''');
  }

  test_nonDeferredImport_withLoadLibraryFunction() async {
    newFile('$testPackageLibPath/a.dart', r'''
void loadLibrary() {}
void f() {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as p;
void main() {
  p.f();
}
''');
  }
}

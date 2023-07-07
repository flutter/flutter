// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsDeferredClassTest);
  });
}

@reflectiveTest
class ExtendsDeferredClassTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class M {}
class C = a.A with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, 69, 3),
    ]);
  }

  test_extends_deferred_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B extends a.A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, 64, 3),
    ]);
  }

  test_extends_deferred_interfaceTypeTypedef() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
class B {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B extends a.B {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, 64, 3),
    ]);
  }
}

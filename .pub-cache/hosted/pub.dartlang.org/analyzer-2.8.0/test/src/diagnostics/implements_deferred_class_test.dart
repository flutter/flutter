// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsDeferredClassTest);
  });
}

@reflectiveTest
class ImplementsDeferredClassTest extends PubPackageResolutionTest {
  test_implements() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B implements a.A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, 67, 3),
    ]);
  }

  test_implements_interfaceTypeTypedef() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
library lib1;
class A {}
typedef B = A;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C implements a.B {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, 67, 3),
    ]);
  }

  test_mixinApplication() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B {}
class M {}
class C = B with M implements a.A;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, 100, 3),
    ]);
  }
}

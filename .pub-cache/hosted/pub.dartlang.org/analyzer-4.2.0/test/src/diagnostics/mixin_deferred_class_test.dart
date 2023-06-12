// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeferredClassTest);
  });
}

@reflectiveTest
class MixinDeferredClassTest extends PubPackageResolutionTest {
  test_classTypeAlias() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B {}
class C = B with a.A;
''', [
      error(CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, 76, 3),
    ]);
  }

  test_enum() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');
    await assertErrorsInCode('''
import 'a.dart' deferred as a;
enum E with a.A {
  v;
}
''', [
      error(CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, 43, 3),
    ]);
  }

  test_mixin_deferred_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B extends Object with a.A {}
''', [
      error(CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, 76, 3),
    ]);
  }
}

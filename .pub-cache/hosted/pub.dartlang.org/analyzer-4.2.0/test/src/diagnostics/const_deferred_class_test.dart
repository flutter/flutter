// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstDeferredClassTest);
  });
}

@reflectiveTest
class ConstDeferredClassTest extends PubPackageResolutionTest {
  test_namedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {
  const A.b();
}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A.b();
}''', [
      error(CompileTimeErrorCode.CONST_DEFERRED_CLASS, 65, 5),
    ]);
  }

  test_nonFunctionTypedef() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {
  const A();
}
typedef B = A;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.B();
}
''', [
      error(CompileTimeErrorCode.CONST_DEFERRED_CLASS, 65, 3),
    ]);
  }

  test_unnamed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {
  const A();
}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A();
}
''', [
      error(CompileTimeErrorCode.CONST_DEFERRED_CLASS, 65, 3),
    ]);
  }
}

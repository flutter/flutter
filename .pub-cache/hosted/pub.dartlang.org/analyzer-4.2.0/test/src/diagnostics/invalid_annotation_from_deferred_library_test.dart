// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationFromDeferredLibraryTest);
  });
}

@reflectiveTest
class InvalidAnnotationFromDeferredLibraryTest
    extends PubPackageResolutionTest {
  test_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class C { const C(); }
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
@a.C() main () {}
''', [
      error(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_constructor_argument() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const x = 0;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C { const C(int i); }
@C(a.x) main () {}
''', [
      error(
          CompileTimeErrorCode
              .INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY,
          79,
          3),
    ]);
  }

  test_from_deferred_library() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class V { const V(); }
const v = const V();
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
@a.v main () {}
''', [
      error(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_namedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class C { const C.name(); }
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
@a.C.name() main () {}
''', [
      error(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }
}

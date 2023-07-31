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
  test_class_implements() async {
    newFile('$testPackageLibPath/lib1.dart', '''
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

  test_class_implements_interfaceTypeTypedef() async {
    newFile('$testPackageLibPath/lib1.dart', '''
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

  test_classTypeAlias() async {
    newFile('$testPackageLibPath/lib1.dart', '''
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

  test_mixin() async {
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;
mixin M implements math.Random {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, 56, 11),
    ]);
    var mathImport = findElement.import('dart:math');
    var randomElement = mathImport.importedLibrary!.getClass('Random')!;

    var element = findElement.mixin('M');
    assertElementTypes(element.interfaces, ['Random']);

    var typeRef = findNode.namedType('Random {}');
    assertNamedType(typeRef, randomElement, 'Random',
        expectedPrefix: mathImport.prefix?.element);
  }
}

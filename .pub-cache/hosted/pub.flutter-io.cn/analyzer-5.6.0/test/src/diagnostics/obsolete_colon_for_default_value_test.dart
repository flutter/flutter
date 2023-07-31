// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ObsoleteColonForDefaultValueTest);
  });
}

@reflectiveTest
class ObsoleteColonForDefaultValueTest extends PubPackageResolutionTest {
  test_noDefault() async {
    await assertNoErrorsInCode('''
void f({int? x}) {}
''');
  }

  test_superFormalParameter() async {
    await assertErrorsInCode('''
class A {
  String? a;
  A({this.a});
}

class B extends A {
  B({super.a : ''});
}
''', [error(CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE, 74, 1)]);
  }

  test_usesColon() async {
    await assertErrorsInCode('''
void f({int x : 0}) {}
''', [error(CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE, 14, 1)]);
  }

  test_usesEqual() async {
    await assertNoErrorsInCode('''
void f({int x = 0}) {}
''');
  }
}

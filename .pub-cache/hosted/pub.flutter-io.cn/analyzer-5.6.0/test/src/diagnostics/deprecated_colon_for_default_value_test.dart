// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedColonForDefaultValueTest);
  });
}

@reflectiveTest
class DeprecatedColonForDefaultValueTest extends PubPackageResolutionTest {
  @override
  String get testPackageLanguageVersion => '2.19';

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
''', [error(HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE, 74, 1)]);
  }

  test_usesColon() async {
    await assertErrorsInCode('''
void f({int x : 0}) {}
''', [error(HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE, 14, 1)]);
  }

  test_usesEqual() async {
    await assertNoErrorsInCode('''
void f({int x = 0}) {}
''');
  }
}

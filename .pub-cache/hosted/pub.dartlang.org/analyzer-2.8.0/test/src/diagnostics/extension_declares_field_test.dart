// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresFieldTest);
  });
}

@reflectiveTest
class ExtensionDeclaresFieldTest extends PubPackageResolutionTest {
  test_multiple() async {
    await assertErrorsInCode('''
extension E on String {
  String? one, two, three;
}
''', [error(ParserErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 34, 3)]);
  }

  test_none() async {
    await assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_one() async {
    await assertErrorsInCode('''
extension E on String {
  String? s;
}
''', [error(ParserErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 34, 1)]);
  }

  test_static() async {
    await assertNoErrorsInCode('''
extension E on String {
  static String EMPTY = '';
}
''');
  }
}

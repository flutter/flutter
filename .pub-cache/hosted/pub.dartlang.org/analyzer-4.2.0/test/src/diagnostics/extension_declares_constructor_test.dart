// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresConstructorTest);
  });
}

@reflectiveTest
class ExtensionDeclaresConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await assertErrorsInCode('''
extension E on String {
  E.named() : super();
}
''', [error(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 26, 1)]);
  }

  test_none() async {
    await assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_unnamed() async {
    await assertErrorsInCode('''
extension E on String {
  E() : super();
}
''', [error(ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR, 26, 1)]);
  }
}

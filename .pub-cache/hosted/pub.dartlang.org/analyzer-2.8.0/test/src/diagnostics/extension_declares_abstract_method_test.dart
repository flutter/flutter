// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresAbstractMethodTest);
  });
}

@reflectiveTest
class ExtensionDeclaresAbstractMethodTest extends PubPackageResolutionTest {
  test_getter() async {
    await assertErrorsInCode('''
extension E on String {
  bool get isPalindrome;
}
''', [
      error(ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER, 35, 12),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
extension E on String {
  String reversed();
}
''', [
      error(ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER, 33, 8),
    ]);
  }

  test_none() async {
    await assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_operator() async {
    await assertErrorsInCode('''
extension E on String {
  String operator -(String otherString);
}
''', [
      error(ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER, 42, 1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode('''
extension E on String {
  set length(int newLength);
}
''', [
      error(ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER, 30, 6),
    ]);
  }
}

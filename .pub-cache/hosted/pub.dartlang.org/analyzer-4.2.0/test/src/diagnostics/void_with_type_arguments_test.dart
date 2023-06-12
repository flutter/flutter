// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VoidWithTypeArgumentsTest);
  });
}

@reflectiveTest
class VoidWithTypeArgumentsTest extends PubPackageResolutionTest {
  test_noArguments() async {
    await assertNoErrorsInCode('''
void f() {}
''');
  }

  test_withArguments() async {
    await assertErrorsInCode('''
void<int> f() {}
''', [
      error(ParserErrorCode.VOID_WITH_TYPE_ARGUMENTS, 4, 1),
    ]);
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }
}

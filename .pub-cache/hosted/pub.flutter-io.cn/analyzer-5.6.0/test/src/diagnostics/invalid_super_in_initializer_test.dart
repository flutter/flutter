// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidSuperInInitializerTest);
  });
}

@reflectiveTest
class InvalidSuperInInitializerTest extends PubPackageResolutionTest {
  test_constructor_name_is_keyword() async {
    await assertErrorsInCode('''
class C {
  C() : super.const();
}
''', [
      error(ParserErrorCode.INVALID_SUPER_IN_INITIALIZER, 18, 5),
      error(ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD, 24, 5),
      error(ParserErrorCode.MISSING_IDENTIFIER, 24, 5),
    ]);
  }
}

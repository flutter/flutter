// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NativeFunctionBodyInNonSdkCodeTest);
  });
}

@reflectiveTest
class NativeFunctionBodyInNonSdkCodeTest extends PubPackageResolutionTest {
  test_function() async {
    await assertErrorsInCode('''
int m(a) native 'string';
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 9, 16),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  static int m(a) native 'string';
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 28, 16),
    ]);
  }

  test_mixinMethod() async {
    await assertErrorsInCode(r'''
mixin A {
  static int m(a) native 'string';
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 28, 16),
    ]);
  }
}

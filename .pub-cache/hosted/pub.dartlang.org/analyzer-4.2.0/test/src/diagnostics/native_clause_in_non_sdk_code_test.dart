// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NativeClauseInNonSdkCodeTest);
  });
}

@reflectiveTest
class NativeClauseInNonSdkCodeTest extends PubPackageResolutionTest {
  test_nativeClauseInNonSDKCode() async {
    await assertErrorsInCode('''
class A native 'string' {}
''', [
      error(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, 8, 15),
    ]);
  }
}

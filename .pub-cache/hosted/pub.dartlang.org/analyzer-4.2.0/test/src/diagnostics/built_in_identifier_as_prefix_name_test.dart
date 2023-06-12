// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsPrefixNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsPrefixNameTest extends PubPackageResolutionTest {
  test_abstract() async {
    await assertErrorsInCode('''
import 'dart:async' as abstract;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME, 23, 8),
    ]);
  }

  test_Function() async {
    await assertErrorsInCode('''
import 'dart:async' as Function;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME, 23, 8),
    ]);
  }
}

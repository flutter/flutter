// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionAsExpressionTest);
  });
}

@reflectiveTest
class ExtensionAsExpressionTest extends PubPackageResolutionTest {
  test_prefixedIdentifier() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on int {}
''');
    await assertErrorsInCode('''
import 'a.dart' as p;
var v = p.E;
''', [
      error(CompileTimeErrorCode.EXTENSION_AS_EXPRESSION, 30, 3),
    ]);
    assertTypeDynamic(findNode.simple('E;'));
    assertTypeDynamic(findNode.prefixed('p.E;'));
  }

  test_simpleIdentifier() async {
    await assertErrorsInCode('''
extension E on int {}
var v = E;
''', [
      error(CompileTimeErrorCode.EXTENSION_AS_EXPRESSION, 30, 1),
    ]);
    assertTypeDynamic(findNode.simple('E;'));
  }
}

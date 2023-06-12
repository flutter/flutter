// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExtensionArgumentCountTest);
  });
}

@reflectiveTest
class InvalidExtensionArgumentCountTest extends PubPackageResolutionTest {
  test_many() async {
    await assertErrorsInCode('''
extension E on String {
  void m() {}
}
f() {
  E('a', 'b', 'c').m();
}
''', [
      error(CompileTimeErrorCode.INVALID_EXTENSION_ARGUMENT_COUNT, 49, 15),
    ]);
    assertTypeDynamic(findNode.extensionOverride('E(').extendedType);
  }

  test_one() async {
    await assertNoErrorsInCode('''
extension E on String {
  void m() {}
}
f() {
  E('a').m();
}
''');
  }

  test_zero() async {
    await assertErrorsInCode('''
extension E on String {
  void m() {}
}
f() {
  E().m();
}
''', [
      error(CompileTimeErrorCode.INVALID_EXTENSION_ARGUMENT_COUNT, 49, 2),
    ]);
    assertTypeDynamic(findNode.extensionOverride('E(').extendedType);
  }
}

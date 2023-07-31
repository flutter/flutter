// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideWithCascadeTest);
  });
}

@reflectiveTest
class ExtensionOverrideWithCascadeTest extends PubPackageResolutionTest {
  test_getter() async {
    await assertErrorsInCode('''
extension E on int {
  int get g => 0;
}
f() {
  E(3)..g..g;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, 49, 1),
    ]);
    assertTypeDynamic(findNode.extensionOverride('E('));
  }

  test_method() async {
    await assertErrorsInCode('''
extension E on int {
  void m() {}
}
f() {
  E(3)..m()..m();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, 45, 1),
    ]);
    assertTypeDynamic(findNode.extensionOverride('E('));
  }

  test_setter() async {
    await assertErrorsInCode('''
extension E on int {
  set s(int i) {}
}
f() {
  E(3)..s = 1..s = 2;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE, 49, 1),
    ]);
    assertTypeDynamic(findNode.extensionOverride('E('));
  }
}

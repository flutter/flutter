// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionExtensionMethodsTest);
  });
}

@reflectiveTest
class SdkVersionExtensionMethodsTest extends SdkConstraintVerifierTest {
  test_extension_equals() async {
    await verifyVersion('2.6.0', '''
extension E on int {}
''');
  }

  test_extension_lessThan() async {
    await verifyVersion('2.2.0', '''
extension E on int {}
''', expectedErrors: [
      error(HintCode.SDK_VERSION_EXTENSION_METHODS, 0, 9),
    ]);
  }

  test_extensionOverride_equals() async {
    await verifyVersion('2.6.0', '''
extension E on int {
  int get a => 0;
}
void f() {
  E(0).a;
}
''');
  }

  test_extensionOverride_lessThan() async {
    await verifyVersion('2.2.0', '''
extension E on int {
  int get a => 0;
}
void f() {
  E(0).a;
}
''', expectedErrors: [
      error(HintCode.SDK_VERSION_EXTENSION_METHODS, 0, 9),
      error(HintCode.SDK_VERSION_EXTENSION_METHODS, 54, 1),
    ]);
  }
}

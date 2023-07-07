// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionGetterTest);
  });
}

@reflectiveTest
class UndefinedExtensionGetterTest extends PubPackageResolutionTest {
  test_override_defined() async {
    await assertNoErrorsInCode('''
extension E on String {
  int get g => 0;
}
f() {
  E('a').g;
}
''');
  }

  test_override_undefined() async {
    await assertErrorsInCode('''
extension E on String {}
f() {
  E('a').g;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 40, 1),
    ]);
  }

  test_override_undefined_hasSetter() async {
    await assertErrorsInCode('''
extension E on int {
  set foo(int _) {}
}
f() {
  E(0).foo;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 56, 3),
    ]);
  }

  test_override_undefined_hasSetter_plusEq() async {
    await assertErrorsInCode('''
extension E on int {
  set foo(int _) {}
}
f() {
  E(0).foo += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 56, 3),
    ]);
  }

  test_static_withInference() async {
    await assertErrorsInCode('''
extension E on Object {}
var a = E.v;
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 35, 1),
    ]);
  }

  test_static_withoutInference() async {
    await assertErrorsInCode('''
extension E on Object {}
void f() {
  E.v;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER, 40, 1),
    ]);
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedExtensionSetterTest);
  });
}

@reflectiveTest
class UndefinedExtensionSetterTest extends PubPackageResolutionTest {
  test_override_defined() async {
    await assertNoErrorsInCode('''
extension E on int {
  void set foo(int _) {}
}
f() {
  E(0).foo = 1;
}
''');
  }

  test_override_undefined() async {
    await assertErrorsInCode('''
extension E on int {}
f() {
  E(0).foo = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 35, 3),
    ]);
  }

  test_override_undefined_hasGetter_eq() async {
    await assertErrorsInCode('''
extension E on int {
  int get foo => 0;
}
f() {
  E(0).foo = 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 56, 3),
    ]);
  }

  test_override_undefined_hasGetter_plusEq() async {
    await assertErrorsInCode('''
extension E on int {
  int get foo => 0;
}
f() {
  E(0).foo += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 56, 3),
    ]);
  }

  test_override_undefined_hasGetterAndNonExtensionSetter() async {
    await assertErrorsInCode('''
class C {
  int get id => 0;
  void set id(int v) {}
}

extension Ext on C {
  int get id => 1;
}

f(C c) {
  Ext(c).id++;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 117, 2),
    ]);
  }

  test_static_undefined() async {
    await assertErrorsInCode('''
extension E on int {}
void f() {
  E.foo = 3;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER, 37, 3),
    ]);
  }
}

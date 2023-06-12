// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInExtensionTest);
  });
}

@reflectiveTest
class SuperInExtensionTest extends PubPackageResolutionTest {
  test_binaryOperator_inMethod() async {
    await assertErrorsInCode('''
extension E on int {
  int plusOne() => super + 1;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION, 40, 5),
    ]);
  }

  test_binaryOperator_withGenericExtendedType() async {
    await assertErrorsInCode('''
extension <T> on T {
  f() {
    super + 1;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 23, 1),
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION, 33, 5),
    ]);
  }

  test_getter_inSetter() async {
    await assertErrorsInCode('''
class C {
  int get value => 0;
  set value(int newValue) {}
}
extension E on C {
  set sign(int sign) {
    value = super.value * sign;
  }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION, 117, 5),
    ]);
  }

  test_indexOperator_inMethod() async {
    await assertErrorsInCode('''
class C {
  int operator[](int i) => 0;
}
extension E on C {
  int at(int i) => super[i];
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION, 80, 5),
    ]);
  }

  test_method_inGetter() async {
    await assertErrorsInCode('''
extension E on int {
  String get displayText => super.toString();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION, 49, 5),
    ]);
  }

  test_prefixOperator_inGetter() async {
    await assertErrorsInCode('''
class C {
  C operator-() => this;
}
extension E on C {
  C get negated => -super;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_EXTENSION, 76, 5),
    ]);
  }
}

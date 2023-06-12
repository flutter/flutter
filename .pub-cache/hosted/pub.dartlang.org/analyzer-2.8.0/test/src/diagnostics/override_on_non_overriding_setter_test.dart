// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingSetterTest);
  });
}

@reflectiveTest
class OverrideOnNonOverridingSetterTest extends PubPackageResolutionTest {
  test_inInterface() async {
    await assertNoErrorsInCode(r'''
class A {
  set m(int x) {}
}
class B implements A {
  @override
  set m(int x) {}
}''');
  }

  test_inSupertype() async {
    await assertNoErrorsInCode(r'''
class A {
  set m(int x) {}
}
class B extends A {
  @override
  set m(int x) {}
}''');
  }

  test_invalid_class() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  @override
  set foo(int _) {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER, 50, 3),
    ]);
  }

  test_invalid_extension() async {
    await assertErrorsInCode(r'''
extension E on int {
  @override
  set foo(int _) {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER, 39, 3),
    ]);
  }

  test_invalid_mixin() async {
    await assertErrorsInCode(r'''
class A {}

mixin M on A {
  @override
  set foo(int _) {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER, 45, 3),
    ]);
  }
}

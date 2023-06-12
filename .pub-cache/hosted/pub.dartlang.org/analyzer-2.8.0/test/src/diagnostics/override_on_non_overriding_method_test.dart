// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingMethodTest);
  });
}

@reflectiveTest
class OverrideOnNonOverridingMethodTest extends PubPackageResolutionTest {
  test_inInterface() async {
    await assertNoErrorsInCode(r'''
class A {
  int m() => 1;
}
class B implements A {
  @override
  int m() => 1;
}''');
  }

  test_inInterfaces() async {
    await assertNoErrorsInCode(r'''
abstract class I {
  void foo(int _);
}

abstract class J {
  void foo(String _);
}

class C implements I, J {
  @override
  void foo(Object _) {}
}''');
  }

  test_inSuperclass() async {
    await assertNoErrorsInCode(r'''
class A {
  int m() => 1;
}
class B extends A {
  @override
  int m() => 1;
}''');
  }

  test_inSuperclass_abstract() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int m();
}
class B extends A {
  @override
  int m() => 1;
}''');
  }

  test_invalid_class() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  @override
  void foo() {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, 51, 3),
    ]);
  }

  test_invalid_extension() async {
    await assertErrorsInCode(r'''
extension E on int {
  @override
  void foo() {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, 40, 3),
    ]);
  }

  test_invalid_mixin() async {
    await assertErrorsInCode(r'''
class A {}

mixin M on A {
  @override
  void foo() {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, 46, 3),
    ]);
  }
}

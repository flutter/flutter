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
  test_class() async {
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

  test_class_extends() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

class B extends A {
  @override
  void foo() {}
}''');
  }

  test_class_extends_abstract() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo();
}

class B extends A {
  @override
  void foo() {}
}''');
  }

  test_class_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

class B implements A {
  @override
  void foo() {}
}''');
  }

  test_class_implements2() async {
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

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  @override
  void foo() {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, 33, 3),
    ]);
  }

  test_extension() async {
    await assertErrorsInCode(r'''
extension E on int {
  @override
  void foo() {}
}
''', [
      error(HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD, 40, 3),
    ]);
  }

  test_mixin() async {
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

  test_mixin_implements() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

mixin M implements A {
  @override
  void foo() {}
}
''');
  }

  test_mixin_on() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

mixin M on A {
  @override
  void foo() {}
}
''');
  }
}

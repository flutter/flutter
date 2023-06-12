// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedSuperMethodTest);
  });
}

@reflectiveTest
class UndefinedSuperMethodTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  void bar() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 57, 3),
    ]);

    var invocation = findNode.methodInvocation('foo()');
    assertElementNull(invocation.methodName);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void f() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 37, 3),
    ]);
  }

  test_enum_OK() async {
    await assertNoErrorsInCode(r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  void f() {
    super.foo();
  }
}
''');
  }

  test_mixin() async {
    await assertErrorsInCode(r'''
class A {}

mixin M on A {
  void bar() {
    super.foo();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 52, 3),
    ]);

    var invocation = findNode.methodInvocation('foo()');
    assertElementNull(invocation.methodName);
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberAccessFromFactoryTest);
  });
}

@reflectiveTest
class InstanceMemberAccessFromFactoryTest extends PubPackageResolutionTest {
  test_named_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;

  factory A.make() {
    foo;
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 56, 3),
    ]);
  }

  test_named_getter_localFunction() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;

  factory A.make() {
    void f() {
      foo;
    }
    f();
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 73, 3),
    ]);
  }

  test_named_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}

  factory A.make() {
    foo();
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 52, 3),
    ]);
  }

  test_named_method_functionExpression() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}

  factory A.make() {
    () => foo();
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 58, 3),
    ]);
  }

  test_named_method_functionExpression_localVariable() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}

  factory A.make() {
    // ignore:unused_local_variable
    var x = () => foo();
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 102, 3),
    ]);
  }

  test_unnamed_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}

  factory A() {
    foo();
    throw 0;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 47, 3),
    ]);
  }
}

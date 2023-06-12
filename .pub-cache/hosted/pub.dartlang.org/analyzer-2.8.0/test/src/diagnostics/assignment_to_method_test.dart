// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToMethodTest);
  });
}

@reflectiveTest
class AssignmentToMethodTest extends PubPackageResolutionTest {
  test_instance_extendedHasMethod_extensionHasSetter() async {
    await assertErrorsInCode('''
class C {
  void foo() {}
}

extension E on C {
  void set foo(int _) {}
}

void f(C c) {
  c.foo = 0;
  c.foo += 1;
  c.foo++;
  --c.foo;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 94, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 107, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 121, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 134, 3),
    ]);
  }

  test_prefixedIdentifier_instanceMethod() async {
    await assertErrorsInCode('''
class A {
  void foo() {}
}

void f(A a) {
  a.foo = 0;
  a.foo += 1;
  a.foo++;
  ++a.foo;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 47, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 60, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 74, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 87, 3),
    ]);
  }

  test_propertyAccess_instanceMethod() async {
    await assertErrorsInCode('''
class A {
  void foo() {}
}

void f(A a) {
  (a).foo = 0;
  (a).foo += 1;
  (a).foo++;
  ++(a).foo;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 49, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 64, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 80, 3),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 95, 3),
    ]);
  }

  test_this_extendedHasMethod_extensionHasSetter() async {
    await assertErrorsInCode('''
class C {
  void foo() {}
}

extension E on C {
  void set foo(int _) {}

  f() {
    this.foo = 0;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 91, 3),
    ]);
  }
}

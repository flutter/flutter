// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidSuperFormalParameterLocationTest);
  });
}

@reflectiveTest
class InvalidSuperFormalParameterLocationTest extends PubPackageResolutionTest {
  test_class_constructor_external() async {
    await assertErrorsInCode(r'''
class A {
  external A(super.a);
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 23, 5),
    ]);
  }

  test_class_constructor_factory() async {
    await assertErrorsInCode(r'''
class A {
  factory A(super.a) {
    return A._();
  }
  A._();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 22, 5),
    ]);
  }

  test_class_constructor_redirecting() async {
    await assertErrorsInCode(r'''
class A {
  A(super.a) : this._();
  A._();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 14, 5),
    ]);
  }

  test_class_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo(super.a) {}
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 21, 5),
    ]);
  }

  test_extension_method() async {
    await assertErrorsInCode(r'''
extension E on int {
  void foo(super.a) {}
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 32, 5),
    ]);
  }

  test_local_function() async {
    await assertErrorsInCode(r'''
void f() {
  // ignore:unused_element
  void g(super.a) {}
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 47, 5),
    ]);
  }

  test_mixin_method() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo(super.a) {}
}
''', [
      error(
          CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 21, 5),
    ]);
  }

  test_unit_function() async {
    await assertErrorsInCode(r'''
void f(super.a) {}
''', [
      error(CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION, 7, 5),
    ]);
  }

  test_valid_optionalNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}

class B extends A {
  B({super.a});
}
''');
  }

  test_valid_optionalPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}

class B extends A {
  B([super.a]);
}
''');
  }

  test_valid_requiredNamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a});
}
''');
  }

  test_valid_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a);
}
''');
  }
}

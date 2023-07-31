// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
  });
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends PubPackageResolutionTest {
  test_const() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
main() {
  const A();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 41, 9),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 48, 2),
    ]);
  }

  test_const_namedArgument_insteadOfRequiredPositional() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
main() {
  const A(p: 0);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 41, 13),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 48, 6),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 49, 1),
    ]);
  }

  test_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 69, 2),
    ]);
  }

  test_enumConstant_withArgumentList() async {
    await assertErrorsInCode(r'''
enum E {
  v();
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 11, 3),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 12, 2),
    ]);
  }

  test_enumConstant_withoutArgumentList() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  const E(int a);
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH, 11, 1),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 11, 1),
    ]);
  }

  test_functionExpression() async {
    await assertErrorsInCode('''
main() {
  (int x) {} ();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 22, 2),
    ]);
  }

  test_functionInvocation() async {
    await assertErrorsInCode('''
f(int a, String b) {}
main() {
  f();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 34, 2),
    ]);
  }

  test_getterReturningFunction() async {
    await assertErrorsInCode('''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 65, 2),
    ]);
  }

  test_superParameter_optional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}

class B extends A {
  B([super.a]) : super();
}
''');
  }

  test_superParameter_required() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a) : super();
}
''');
  }
}

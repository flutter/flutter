// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidConstantTest);
    defineReflectiveTests(InvalidConstantWithoutNullSafetyTest);
  });
}

@reflectiveTest
class InvalidConstantTest extends PubPackageResolutionTest
    with InvalidConstantTestCases {
  test_in_initializer_field_as() async {
    await assertNoErrorsInCode('''
class C<T> {
  final l;
  const C.test(dynamic x) : l = x as List<T>;
}
''');
  }
}

mixin InvalidConstantTestCases on PubPackageResolutionTest {
  test_in_initializer_assert_condition() async {
    await assertErrorsInCode('''
class A {
  const A(int i) : assert(i.isNegative);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 36, 12),
    ]);
  }

  test_in_initializer_assert_message() async {
    await assertErrorsInCode(r'''
class A {
  const A(int i) : assert(i < 0, 'isNegative = ${i.isNegative}');
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 59, 12),
    ]);
  }

  test_in_initializer_field() async {
    await assertErrorsInCode(r'''
class A {
  static int C = 0;
  final int a;
  const A() : a = C;
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 63, 1),
    ]);
  }

  test_in_initializer_from_deferred_library_field() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c;
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 91, 3),
    ]);
  }

  test_in_initializer_from_deferred_library_field_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 91, 3),
    ]);
  }

  test_in_initializer_from_deferred_library_redirecting() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 103, 3),
    ]);
  }

  test_in_initializer_from_deferred_library_super() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 114, 3),
    ]);
  }

  test_in_initializer_instanceCreation() async {
    // TODO(scheglov): the error CONST_EVAL_THROWS_EXCEPTION is redundant and
    // ought to be suppressed. Or not?
    await assertErrorsInCode(r'''
class A {
  A();
}
class B {
  const B() : a = new A();
  final a;
}
var b = const B();
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 47, 7),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 77, 9),
    ]);
  }

  test_in_initializer_redirecting() async {
    await assertErrorsInCode(r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 71, 1),
    ]);
  }

  test_in_initializer_super() async {
    await assertErrorsInCode(r'''
class A {
  const A(p);
}
class B extends A {
  static var C;
  const B() : super(C);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 82, 1),
    ]);
  }
}

@reflectiveTest
class InvalidConstantWithoutNullSafetyTest extends PubPackageResolutionTest
    with InvalidConstantTestCases, WithoutNullSafetyMixin {}

// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantPatternNeverMatchesValueTypeTest);
  });
}

@reflectiveTest
class ConstantPatternNeverMatchesValueTypeTest
    extends PubPackageResolutionTest {
  test_bool_bool() async {
    await assertNoErrorsInCode('''
void f(bool x) {
  if (x case (true)) {}
}
''');
  }

  test_bool_int() async {
    await assertErrorsInCode('''
void f(int x) {
  if (x case (true)) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 4),
    ]);
  }

  test_bool_ListOfBool() async {
    await assertErrorsInCode('''
void f(List<bool> x) {
  if (x case (true)) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 37, 4),
    ]);
  }

  test_bool_typeParameter_bound_bool() async {
    await assertNoErrorsInCode('''
void f<T extends bool>(T x) {
  if (x case (true)) {}
}
''');
  }

  test_bool_typeParameter_bound_bool_nested() async {
    await assertNoErrorsInCode('''
void f<T extends bool>(List<T> x) {
  if (x case [true]) {}
}
''');
  }

  test_bool_typeParameter_bound_num() async {
    await assertErrorsInCode('''
void f<T extends num>(T x) {
  if (x case (true)) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 43, 4),
    ]);
  }

  test_bool_typeParameter_bound_num_nested() async {
    await assertErrorsInCode('''
void f<T extends num>(List<T> x) {
  if (x case [true]) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 49, 4),
    ]);
  }

  test_bool_typeParameter_promoted_bool() async {
    await assertNoErrorsInCode('''
void f<T>(T x) {
  if (x is bool) {
    if (x case (true)) {}
  }
}
''');
  }

  test_bool_typeParameter_promoted_int() async {
    await assertErrorsInCode('''
void f<T>(T x) {
  if (x is int) {
    if (x case (true)) {}
  }
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 51, 4),
    ]);
  }

  test_custom_notPrimitiveEquality_constantIsSubtypeOfValue() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case const B()) {}
}

class A {
  const A();
}

class B extends A {
  const B();
  bool operator ==(other) => true;
}
''');
  }

  test_custom_notPrimitiveEquality_constantIsSupertypeOfValue() async {
    await assertNoErrorsInCode('''
void f(B x) {
  if (x case const A()) {}
}

class A {
  const A();
  bool operator ==(other) => true;
}

class B extends A {
  const B();
}
''');
  }

  test_custom_primitiveEquality_constantIsSameTypeAsValue() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case const A()) {}
}

class A {
  const A();
}
''');
  }

  test_custom_primitiveEquality_constantIsSubtypeOfValue() async {
    await assertNoErrorsInCode('''
void f(A x) {
  if (x case const B()) {}
}

class A {
  const A();
}

class B extends A {
  const B();
}
''');
  }

  test_custom_primitiveEquality_constantIsSupertypeOfValue() async {
    await assertErrorsInCode('''
void f(B x) {
  if (x case const A()) {}
}

class A {
  const A();
}

class B extends A {
  const B();
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 33, 3),
    ]);
  }

  test_int_bool() async {
    await assertErrorsInCode('''
void f(bool x) {
  if (x case (0)) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 31, 1),
    ]);
  }

  test_int_double() async {
    await assertErrorsInCode('''
void f(double x) {
  if (x case (zero)) {}
}

const zero = 0;
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 33, 4),
    ]);
  }

  test_int_int() async {
    await assertNoErrorsInCode('''
void f(int x) {
  if (x case (0)) {}
}
''');
  }

  test_int_intQuestion() async {
    await assertNoErrorsInCode('''
void f(int? x) {
  if (x case (0)) {}
}
''');
  }

  test_int_num() async {
    await assertNoErrorsInCode('''
void f(num x) {
  if (x case (0)) {}
}
''');
  }

  test_int_otherClass() async {
    await assertErrorsInCode('''
void f(A x) {
  if (x case (0)) {}
}

class A {}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 28, 1),
    ]);
  }

  test_int_String() async {
    await assertErrorsInCode('''
void f(String x) {
  if (x case (0)) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 33, 1),
    ]);
  }

  test_Null_int() async {
    await assertErrorsInCode('''
void f(int x) {
  if (x case (null)) {}
}
''', [
      error(WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE, 30, 4),
    ]);
  }

  test_Null_intQuestion() async {
    await assertNoErrorsInCode('''
void f(int? x) {
  if (x case (null)) {}
}
''');
  }
}

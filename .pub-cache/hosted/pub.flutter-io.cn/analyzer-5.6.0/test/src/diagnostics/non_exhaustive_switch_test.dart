// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonExhaustiveSwitchExpressionTest);
    defineReflectiveTests(NonExhaustiveSwitchStatementTest);
  });
}

@reflectiveTest
class NonExhaustiveSwitchExpressionTest extends PubPackageResolutionTest {
  test_bool_true() async {
    await assertErrorsInCode(r'''
Object f(bool x) {
  return switch (x) {
    true => 0,
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 28, 6),
    ]);
  }

  test_bool_true_false() async {
    await assertNoErrorsInCode(r'''
Object f(bool x) {
  return switch (x) {
    true => 1,
    false => 0,
  };
}
''');
  }

  test_class_int_wildcard() async {
    await assertNoErrorsInCode(r'''
Object f(int x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
  }

  test_class_withField_wildcard() async {
    await assertNoErrorsInCode(r'''
Object f(int x) {
  return switch (x) {
    int(isEven: true) => 0,
    _ => 1,
  };
}
''');
  }

  test_enum_2at2_hasWhen() async {
    await assertErrorsInCode(r'''
enum E {
  a, b
}

Object f(E x) {
  return switch (x) {
    E.a when 1 == 0 => 0,
    E.b => 1,
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 44, 6,
          correctionContains: 'E.a'),
    ]);
  }
}

@reflectiveTest
class NonExhaustiveSwitchStatementTest extends PubPackageResolutionTest {
  test_alwaysExhaustive_bool_true() async {
    await assertErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case true:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 19, 6),
    ]);
  }

  test_alwaysExhaustive_bool_true_false() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_typed_bool() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case bool _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_typed_int() async {
    await assertErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case int _:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 19, 6),
    ]);
  }

  test_alwaysExhaustive_bool_wildcard_untyped() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_boolNullable_true_false() async {
    await assertErrorsInCode(r'''
void f(bool? x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 20, 6),
    ]);
  }

  /// TODO(scheglov) Fix it.
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/51275')
  test_alwaysExhaustive_boolNullable_true_false_null() async {
    await assertNoErrorsInCode(r'''
void f(bool? x) {
  switch (x) {
    case true:
    case false:
    case Null:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at1() async {
    await assertErrorsInCode(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 35, 6),
    ]);
  }

  test_alwaysExhaustive_enum_2at2_cases() async {
    await assertNoErrorsInCode(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a:
    case E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at2_hasWhen() async {
    await assertErrorsInCode(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a when 1 == 0:
    case E.b:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 35, 6,
          correctionContains: 'E.a'),
    ]);
  }

  /// TODO(scheglov) Fix it.
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/51275')
  test_alwaysExhaustive_enum_2at2_logicalOr() async {
    await assertNoErrorsInCode(
      r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a || E.b:
      break;
  }
}
''',
    );
  }

  test_alwaysExhaustive_Null_hasError() async {
    await assertErrorsInCode(r'''
void f(Null x) {
  switch (x) {}
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 19, 6),
    ]);
  }

  test_alwaysExhaustive_Null_noError() async {
    await assertNoErrorsInCode(r'''
void f(Null x) {
  switch (x) {
    case null:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_recordType_bool_bool_4at4() async {
    await assertNoErrorsInCode(r'''
void f((bool, bool) x) {
  switch (x) {
    case (false, false):
    case (false, true):
    case (true, false):
    case (true, true):
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at1() async {
    await assertErrorsInCode(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 77, 6),
    ]);
  }

  test_alwaysExhaustive_sealedClass_2at2() async {
    await assertNoErrorsInCode(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
    case C():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at2_wildcard() async {
    await assertNoErrorsInCode(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
    case _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedMixin_2at1() async {
    await assertErrorsInCode(r'''
sealed mixin M {}
class A with M {}
class B with M {}

void f(M x) {
  switch (x) {
    case A():
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 71, 6),
    ]);
  }

  /// TODO(scheglov) Fix it.
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/51275')
  test_alwaysExhaustive_sealedMixin_2at2() async {
    await assertNoErrorsInCode(r'''
sealed mixin M {}
class A with M {}
class B with M {}

void f(M x) {
  switch (x) {
    case A():
    case B():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_typeVariable_bound_bool_true() async {
    await assertErrorsInCode(r'''
void f<T extends bool>(T x) {
  switch (x) {
    case true:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 32, 6),
    ]);
  }

  test_alwaysExhaustive_typeVariable_bound_bool_true_false() async {
    await assertErrorsInCode(r'''
void f<T extends bool>(T x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 32, 6),
    ]);
  }

  test_alwaysExhaustive_typeVariable_promoted_bool_true() async {
    await assertErrorsInCode(r'''
void f<T>(T x) {
  if (x is bool) {
    switch (x) {
      case true:
        break;
    }
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH, 40, 6),
    ]);
  }

  /// TODO(scheglov) Fix it.
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/51275')
  test_alwaysExhaustive_typeVariable_promoted_bool_true_false() async {
    await assertNoErrorsInCode(r'''
void f<T>(T x) {
  if (x is bool) {
    switch (x) {
      case true:
      case false:
        break;
    }
  }
}
''');
  }

  test_notAlwaysExhaustive_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMayCompleteNormallyTest);
  });
}

@reflectiveTest
class BodyMayCompleteNormallyTest extends PubPackageResolutionTest {
  test_enum_method_nonNullable_blockBody_switchStatement_notNullable_exhaustive() async {
    await assertNoErrorsInCode(r'''
enum E {
  a;

  static const b = 0;
  static final c = 0;

  int get value {
    switch (this) {
      case a:
        return 0;
    }
  }
}
''');
  }

  test_enum_method_nonNullable_blockBody_switchStatement_notNullable_notExhaustive() async {
    await assertErrorsInCode(r'''
enum E {
  a, b;

  int get value {
    switch (this) {
      case a:
        return 0;
    }
  }
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 28, 5),
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 40, 13),
    ]);
  }

  test_factoryConstructor_named_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  factory A.named() {}
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 20, 7),
    ]);
  }

  test_factoryConstructor_unnamed_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  factory A() {}
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 20, 1),
    ]);
  }

  test_function_future_int_blockBody_async() async {
    await assertErrorsInCode(r'''
Future<int> foo() async {}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 12, 3),
    ]);
  }

  test_function_future_void_blockBody() async {
    await assertErrorsInCode(r'''
Future<void> foo() {}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 13, 3),
    ]);
  }

  test_function_future_void_blockBody_async() async {
    await assertNoErrorsInCode(r'''
Future<void> foo() async {}
''');
  }

  test_function_nonNullable_blockBody() async {
    await assertErrorsInCode(r'''
int foo() {}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 4, 3),
    ]);
  }

  test_function_nonNullable_blockBody_generator_async() async {
    await assertNoErrorsInCode(r'''
Stream<int> foo() async* {}
''');
  }

  test_function_nonNullable_blockBody_generator_sync() async {
    await assertNoErrorsInCode(r'''
Iterable<int> foo() sync* {}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_exhaustive() async {
    await assertNoErrorsInCode(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_exhaustive_enhanced() async {
    await assertNoErrorsInCode(r'''
enum E {
  a;

  static const b = 0;
  static final c = 0;
}

int f(E e) {
  switch (e) {
    case E.a:
      return 0;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_exhaustive_parenthesis() async {
    await assertNoErrorsInCode(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case (Foo.a):
      return 0;
    case (Foo.b):
      return 1;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_notExhaustive() async {
    await assertErrorsInCode(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case Foo.a:
      return 0;
  }
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 23, 1),
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 38, 12),
    ]);
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_notExhaustive_enhanced() async {
    await assertErrorsInCode(r'''
enum E {
  a, b;

  static const c = 0;
}

int f(E e) {
  switch (e) {
    case E.a:
      return 0;
  }
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 47, 1),
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 58, 10),
    ]);
  }

  test_function_nonNullable_blockBody_switchStatement_nullable_exhaustive_default() async {
    await assertNoErrorsInCode(r'''
enum Foo { a, b }

int f(Foo? foo) {
  switch (foo) {
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
    default:
      return 2;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_nullable_exhaustive_null() async {
    await assertNoErrorsInCode(r'''
enum Foo { a, b }

int f(Foo? foo) {
  switch (foo) {
    case null:
      return 0;
    case Foo.a:
      return 1;
    case Foo.b:
      return 2;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_nullable_notExhaustive_null() async {
    await assertErrorsInCode(r'''
enum Foo { a, b }

int f(Foo? foo) {
  switch (foo) {
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
  }
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 23, 1),
      error(StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH, 39, 12),
    ]);
  }

  test_function_nullable_blockBody() async {
    await assertNoErrorsInCode(r'''
int foo() {
  return 0;
}
''');
  }

  test_functionExpression_future_int_blockBody_async() async {
    await assertErrorsInCode(r'''
void f() {
  Future<int> Function() foo = () async {};
  foo;
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 51, 1),
    ]);
  }

  test_functionExpression_future_void_blockBody() async {
    await assertErrorsInCode(r'''
void f() {
  Future<void> Function() foo = () {};
  foo;
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 46, 1),
    ]);
  }

  test_functionExpression_future_void_blockBody_async() async {
    await assertNoErrorsInCode(r'''
main() {
  Future<void> Function() foo = () async {};
  foo;
}
''');
  }

  test_functionExpression_notNullable_blockBody() async {
    await assertErrorsInCode(r'''
void f() {
  int Function() foo = () {
  };
  foo;
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 37, 1),
    ]);
  }

  test_functionExpression_notNullable_blockBody_return() async {
    await assertNoErrorsInCode(r'''
main() {
  int Function() foo = () {
    return 0;
  };
  foo;
}
''');
  }

  test_generativeConstructor_blockBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
''');
  }

  test_generativeConstructor_emptyBody() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
''');
  }

  test_method_future_int_blockBody_async() async {
    await assertErrorsInCode(r'''
class A {
  Future<int> foo() async {}
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 24, 3),
    ]);
  }

  test_method_future_void_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  Future<void> foo() {}
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 25, 3),
    ]);
  }

  test_method_future_void_blockBody_async() async {
    await assertNoErrorsInCode(r'''
class A {
  Future<void> foo() async {}
}
''');
  }

  test_method_nonNullable_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  int foo() {}
}
''', [
      error(CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY, 16, 3),
    ]);
  }

  test_method_nonNullable_blockBody_generator_async() async {
    await assertNoErrorsInCode(r'''
class A {
  Stream<int> foo() async* {
    yield 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_generator_sync() async {
    await assertNoErrorsInCode(r'''
class A {
  Iterable<int> foo() sync* {
    yield 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_return() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() {
    return 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_throw() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() {
    throw 0;
  }
}
''');
  }

  test_method_nonNullable_emptyBody() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int foo();
}
''');
  }

  test_method_nonNullable_expressionBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
}
''');
  }

  test_method_nonNullable_expressionBody_throw() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => throw 0;
}
''');
  }

  test_method_nullable_blockBody_return() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() {
    return 0;
  }
}
''');
  }

  test_setter() async {
    // Even though this code has an illegal return type for a setter, do not
    // use the invalid return type to report BODY_MIGHT_COMPLETE_NORMALLY for
    // setters.
    await assertErrorsInCode(r'''
bool set s(int value) {}
''', [
      error(CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER, 0, 4),
    ]);
  }
}

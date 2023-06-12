// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeTest);
    defineReflectiveTests(
        ReturnOfInvalidTypeWithoutNullSafetyAndNoImplicitCastsTest);
    defineReflectiveTests(ReturnOfInvalidTypeWithoutNullSafetyTest);
    defineReflectiveTests(ReturnOfInvalidTypeWithStrictCastsTest);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeTest extends PubPackageResolutionTest
    with ReturnOfInvalidTypeTestCases {
  test_function_async_block_int__to_Future_void() async {
    await assertErrorsInCode(r'''
Future<void> f() async {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 34, 1),
    ]);
  }

  test_function_async_block_void__to_Future_Null() async {
    await assertErrorsInCode(r'''
Future<Null> f(void a) async {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 40, 1),
    ]);
  }

  test_function_async_block_void__to_FutureOr_ObjectQ() async {
    await assertErrorsInCode(r'''
import 'dart:async';

FutureOr<Object?> f(void a) async {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 67, 1),
    ]);
  }

  test_function_async_expression_dynamic__to_Future_int() async {
    await assertNoErrorsInCode(r'''
Future<int> f(dynamic a) async => a;
''');
  }

  test_functionExpression_async_futureOr_void__to_Object() async {
    await assertNoErrorsInCode(r'''
void a = null;

Object Function() f = () async {
  return a;
};
''');
  }

  test_functionExpression_async_futureQ_void__to_Object() async {
    await assertNoErrorsInCode(r'''
Future<void>? a = (throw 0);

Object Function() f = () async {
  return a;
};
''');
  }

  test_functionExpression_async_void__to_FutureOr_ObjectQ() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

void a = (throw 0);

FutureOr<Object?> Function() f = () async {
  return a;
};
''');
  }
}

mixin ReturnOfInvalidTypeTestCases on PubPackageResolutionTest {
  test_closure() async {
    await assertErrorsInCode('''
typedef Td = int Function();
Td f() {
  return () => "hello";
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 53, 7),
    ]);
  }

  test_factoryConstructor_named() async {
    await assertErrorsInCode('''
class C {
  factory C.named() => 7;
}
''', [
      error(
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR, 33, 1),
    ]);
  }

  test_factoryConstructor_unnamed() async {
    await assertErrorsInCode('''
class C {
  factory C() => 7;
}
''', [
      error(
          CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR, 27, 1),
    ]);
  }

  test_function_async_block__to_Future_void() async {
    await assertNoErrorsInCode(r'''
Future<void> f1() async {}
Future<void> f2() async { return; }
Future<void> f3() async { return null; }
Future<void> f4() async { return g1(); }
Future<void> f5() async { return g2(); }
g1() {}
void g2() {}
''');
  }

  test_function_async_block_Future_Future_int__to_Future_int() async {
    await assertErrorsInCode('''
Future<int> f(Future<Future<int>> a) async {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 54, 1),
    ]);
  }

  test_function_async_block_Future_String__to_Future_int() async {
    await assertErrorsInCode('''
Future<int> f(Future<String> a) async {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 49, 1),
    ]);
  }

  test_function_async_block_Future_void() async {
    await assertNoErrorsInCode('''
void f1(Future<void> a) async { return a; }
dynamic f2(Future<void> a) async { return a; }
''');
  }

  test_function_async_block_illegalReturnType() async {
    await assertErrorsInCode('''
int f() async {
  return 5;
}
''', [
      error(CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
    ]);
  }

  test_function_async_block_int__to_Future_int() async {
    await assertNoErrorsInCode(r'''
Future<int> f() async {
  return 0;
}
''');
  }

  test_function_async_block_int__to_Future_num() async {
    await assertNoErrorsInCode(r'''
Future<num> f() async {
  return 0;
}
''');
  }

  test_function_async_block_int__to_Future_String() async {
    await assertErrorsInCode('''
Future<String> f() async {
  return 5;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 36, 1),
    ]);
  }

  test_function_async_block_int__to_void() async {
    await assertErrorsInCode('''
void f() async {
  return 5;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 26, 1),
    ]);
  }

  test_function_async_block_void__to_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f(void a) async {
  return a;
}
''');
  }

  test_function_async_block_void__to_Future_int() async {
    await assertErrorsInCode('''
Future<int> f(void a) async {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 39, 1),
    ]);
  }

  test_function_async_block_void__to_void() async {
    await assertNoErrorsInCode('''
void f(void a) async {
  return a;
}
''');
  }

  test_function_asyncStar() async {
    await assertErrorsInCode('''
Stream<int> f() async* => 3;
''', [
      // RETURN_OF_INVALID_TYPE shouldn't be reported in addition to this error.
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 23, 2),
    ]);
  }

  test_function_sync_block__to_dynamic() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
    return 0;
  } on ArgumentError {
    return 'abc';
  }
}
''');
  }

  test_function_sync_block__to_void() async {
    await assertNoErrorsInCode(r'''
void f1() {}
void f2() { return; }
void f3() { return null; }
void f4() { return g1(); }
void f5() { return g2(); }
g1() {}
void g2() {}
''');
  }

  test_function_sync_block_genericFunction__to_genericFunction() async {
    await assertNoErrorsInCode('''
U Function<U>(U) foo(T Function<T>(T a) f) {
  return f;
}
''');
  }

  test_function_sync_block_genericFunction__to_genericFunction_notAssignable() async {
    await assertErrorsInCode('''
U Function<U>(U, int) foo(T Function<T>(T a) f) {
  return f;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 59, 1),
    ]);
  }

  test_function_sync_block_genericFunction__to_nonGenericFunction() async {
    await assertNoErrorsInCode('''
int Function(int) foo(T Function<T>(T a) f) {
  return f;
}
''');
  }

  test_function_sync_block_genericFunction__to_nonGenericFunction_notAssignable() async {
    await assertErrorsInCode('''
int Function(int, int) foo(T Function<T>(T a) f) {
  return f;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 60, 1),
    ]);
  }

  test_function_sync_block_int__to_num() async {
    await assertNoErrorsInCode(r'''
num f(int a) {
  return a;
}
''');
  }

  test_function_sync_block_int__to_void() async {
    await assertErrorsInCode('''
void f() {
  return 42;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 20, 2),
    ]);
  }

  test_function_sync_block_num__to_int() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 24, 1),
    ], legacy: []);
    await assertErrorsInCode(r'''
int f(num a) {
  return a;
}
''', expectedErrors);
  }

  test_function_sync_block_String__to_int() async {
    await assertErrorsInCode('''
int f() {
  return '0';
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 19, 3),
    ]);
  }

  test_function_sync_block_typeParameter__to_Type() async {
    // https://code.google.com/p/dart/issues/detail?id=18468
    //
    // This test verifies that the type of T is more specific than Type, where T
    // is a type parameter and Type is the type Type from core, this particular
    // test case comes from issue 18468.
    //
    // A test cannot be added to TypeParameterTypeImplTest since the types
    // returned out of the TestTypeProvider don't have a mock 'dart.core'
    // enclosing library element.
    // See TypeParameterTypeImpl.isMoreSpecificThan().
    await assertNoErrorsInCode(r'''
class Foo<T> {
  Type get t => T;
}
''');
  }

  test_function_sync_block_void__to_dynamic() async {
    await assertNoErrorsInCode('''
dynamic f(void a) {
  return a;
}
''');
  }

  test_function_sync_block_void__to_int() async {
    await assertErrorsInCode('''
int f(void a) {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 25, 1),
    ]);
  }

  test_function_sync_block_void__to_Null() async {
    var expectedErrors = expectedErrorsByNullability(nullable: [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 26, 1),
    ], legacy: []);
    await assertErrorsInCode('''
Null f(void a) {
  return a;
}
''', expectedErrors);
  }

  test_function_sync_block_void__to_void() async {
    await assertNoErrorsInCode('''
void f(void a) {
  return a;
}
''');
  }

  test_function_sync_expression_genericFunction__to_genericFunction() async {
    await assertNoErrorsInCode('''
U Function<U>(U) foo(T Function<T>(T a) f) => f;
''');
  }

  test_function_sync_expression_genericFunction__to_genericFunction_notAssignable() async {
    await assertErrorsInCode('''
U Function<U>(U, int) foo(T Function<T>(T a) f) => f;
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 51, 1),
    ]);
  }

  test_function_sync_expression_genericFunction__to_nonGenericFunction() async {
    await assertNoErrorsInCode('''
int Function(int) foo(T Function<T>(T a) f) => f;
''');
  }

  test_function_sync_expression_genericFunction__to_nonGenericFunction_notAssignable() async {
    await assertErrorsInCode('''
int Function(int, int) foo(T Function<T>(T a) f) => f;
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 52, 1),
    ]);
  }

  test_function_sync_expression_int__to_void() async {
    await assertNoErrorsInCode('''
void f() => 42;
''');
  }

  test_function_sync_expression_String__to_int() async {
    await assertErrorsInCode('''
int f() => '0';
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 11, 3),
    ]);
  }

  test_function_syncStar() async {
    await assertErrorsInCode('''
Iterable<int> f() sync* => 3;
''', [
      // RETURN_OF_INVALID_TYPE shouldn't be reported in addition to this error.
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 24, 2),
    ]);
  }

  test_getter_sync_block_String__to_int() async {
    await assertErrorsInCode('''
int get g {
  return '0';
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 21, 3),
    ]);
  }

  test_getter_sync_expression_String__to_int() async {
    await assertErrorsInCode('''
int get g => '0';
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 13, 3),
    ]);
  }

  test_localFunction_sync_block_String__to_int() async {
    await assertErrorsInCode(r'''
void f() {
  int g() {
    return '0';
  }
  g();
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 34, 3),
    ]);
  }

  test_localFunction_sync_expression_String__to_int() async {
    await assertErrorsInCode(r'''
class A {
  void m() {
    int f() => '0';
    f();
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 38, 3),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/38162')
  test_method_async_block_callable_class() async {
    if (isLegacyLibrary) {
      throw 'Make it fail for Null Safety as well, for now.';
    }

    await assertNoErrorsInCode(r'''
typedef Fn = void Function(String s);

class CanFn {
  void call(String s) => print(s);
}

Future<Fn> f() async {
  return CanFn();
}
''');
  }

  test_method_sync_block_String__to_int() async {
    await assertErrorsInCode(r'''
class A {
  int m() {
    return '0';
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 33, 3),
    ]);
  }

  test_method_sync_expression_generic() async {
    await assertNoErrorsInCode(r'''
abstract class F<T>  {
  T get value;
}

abstract class G<U> {
  U test(F<U> arg) => arg.value;
}
''');
  }

  test_method_sync_expression_String__to_int() async {
    await assertErrorsInCode(r'''
class A {
  int f() => '0';
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 23, 3),
    ]);
  }

  test_spread_iterable_in_map_context() async {
    await assertErrorsInCode('''
Map<int, int> f() => {...[1, 2, 3, 4]};
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 21, 17),
    ]);
  }
}

@reflectiveTest
class ReturnOfInvalidTypeWithoutNullSafetyAndNoImplicitCastsTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, WithNoImplicitCastsMixin {
  test_return() async {
    await assertErrorsWithNoImplicitCasts('int f(num n) => n;', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 16, 1),
    ]);
  }

  test_return_async() async {
    await assertErrorsWithNoImplicitCasts(r'''
Future<List<String>> f() async {
  List<Object> x = <Object>['hello', 'world'];
  return x;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 89, 1),
    ]);
  }
}

@reflectiveTest
class ReturnOfInvalidTypeWithoutNullSafetyTest extends PubPackageResolutionTest
    with ReturnOfInvalidTypeTestCases, WithoutNullSafetyMixin {}

@reflectiveTest
class ReturnOfInvalidTypeWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_return() async {
    await assertErrorsWithStrictCasts('''
int f(dynamic a) => a;
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 20, 1),
    ]);
  }

  test_return_async() async {
    await assertErrorsWithStrictCasts('''
Future<int> f(dynamic a) async {
  return a;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 42, 1),
    ]);
  }
}

// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorWithoutNullSafetyTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_FutureThenTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_FutureThenWithoutNullSafetyTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorWithoutNullSafetyTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_StreamListenTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_StreamListenWithoutNullSafetyTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTest
    extends PubPackageResolutionTest
    with ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTestCases {
  void test_functionExpression_firstParameterIsNullableObject() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object? a) {});
}
''');
  }

  @override
  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, {required StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 38),
    ]);
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, StackTrace? b) {});
}
''');
  }
}

mixin ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTestCases
    on PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(dynamic a) callback) {
  future.catchError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function({Object a}) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 92, 8),
    ]);
  }

  void test_firstParameterIsOptional() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function([Object a]) callback) {
  future.catchError(callback);
}
''');
  }

  void test_functionExpression_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((dynamic a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsImplicit() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError(({Object a = 1}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 19),
    ]);
  }

  void test_functionExpression_firstParameterIsOptional() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError(([Object a = 1]) {});
}
''');
  }

  void test_functionExpression_firstParameterIsVar() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((var a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError(() {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 5),
    ]);
  }

  void test_functionExpression_secondParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, dynamic b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsImplicit() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, {StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 29),
    ]);
  }

  void test_functionExpression_secondParameterIsVar() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, var b) {});
}
''');
  }

  void test_functionExpression_tooManyParameters() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((a, b, c) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 12),
    ]);
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((String a) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 13),
    ]);
  }

  void test_functionExpression_wrongSecondParameterType() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, String b) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 50, 23),
    ]);
  }

  void test_noParameters() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function() callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 82, 8),
    ]);
  }

  void test_okType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object, StackTrace) callback) {
  future.catchError(callback);
}
''');
  }

  void test_secondParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object a, dynamic b) callback) {
  future.catchError(callback);
}
''');
  }

  void test_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object a, {StackTrace b}) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 106, 8),
    ]);
  }

  void test_tooManyParameters() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(int, int, int) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 95, 8),
    ]);
  }

  void test_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(String) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 88, 8),
    ]);
  }

  void test_wrongSecondParameterType() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object, String) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 96, 8),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTestCases,
        WithoutNullSafetyMixin {}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_FutureThenTest
    extends PubPackageResolutionTest
    with ArgumentTypeNotAssignableToErrorHandler_FutureThenTestCases {
  void test_functionExpression_firstParameterIsNullableObject() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object? a) {});
}
''');
  }

  @override
  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object a, {StackTrace? b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 52, 39),
    ]);
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object a, StackTrace? b) {});
}
''');
  }
}

mixin ArgumentTypeNotAssignableToErrorHandler_FutureThenTestCases
    on PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<void> future, void Function(dynamic a) callback) {
  future.then((_) {}, onError: callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future, Future<int> Function({Object a}) callback) {
  future.then((_) {}, onError: callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 95, 17),
    ]);
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: ({Object a = 1}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 52, 28),
    ]);
  }

  void test_functionExpression_noParameters() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: () {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 52, 14),
    ]);
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object a, {StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 52, 38),
    ]);
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.then((_) {}, onError: (String a) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 52, 22),
    ]);
  }

  void test_functionType() async {
    await assertNoErrorsInCode('''
void f(Future<void> future, Function callback) {
  future.then((_) {}, onError: callback);
}
''');
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_FutureThenWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        ArgumentTypeNotAssignableToErrorHandler_FutureThenTestCases,
        WithoutNullSafetyMixin {}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTest
    extends PubPackageResolutionTest
    with ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTestCases {
  void test_functionExpression_firstParameterIsNullableObject() async {
    await assertNoErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError((Object? a) {});
}
''');
  }

  @override
  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError((Object a, {StackTrace? b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 51, 30),
    ]);
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await assertNoErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError((Object a, StackTrace? b) {});
}
''');
  }
}

mixin ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTestCases
    on PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Stream<void> stream, void Function(dynamic a) callback) {
  stream.handleError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream, Future<int> Function({Object a}) callback) {
  stream.handleError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 94, 8),
    ]);
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError(({Object a = 1}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 51, 19),
    ]);
  }

  void test_functionExpression_noParameters() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError(() {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 51, 5),
    ]);
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError((Object a, {StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 51, 29),
    ]);
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.handleError((String a) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 51, 13),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTestCases,
        WithoutNullSafetyMixin {}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamListenTest
    extends PubPackageResolutionTest
    with ArgumentTypeNotAssignableToErrorHandler_StreamListenTestCases {
  void test_functionExpression_firstParameterIsNullableObject() async {
    await assertNoErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object? a) {});
}
''');
  }

  @override
  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object a, {StackTrace? b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 54, 39),
    ]);
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await assertNoErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object a, StackTrace? b) {});
}
''');
  }
}

mixin ArgumentTypeNotAssignableToErrorHandler_StreamListenTestCases
    on PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Stream<void> stream, void Function(dynamic a) callback) {
  stream.listen((_) {}, onError: callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream, Future<int> Function({Object a}) callback) {
  stream.listen((_) {}, onError: callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 97, 17),
    ]);
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: ({Object a = 1}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 54, 28),
    ]);
  }

  void test_functionExpression_noParameters() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: () {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 54, 14),
    ]);
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object a, {StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 54, 38),
    ]);
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (String a) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 54, 22),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamListenWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        ArgumentTypeNotAssignableToErrorHandler_StreamListenTestCases,
        WithoutNullSafetyMixin {}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTest
    extends PubPackageResolutionTest
    with
        ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTestCases {
  void test_functionExpression_firstParameterIsNullableObject() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object? a) {});
}
''');
  }

  @override
  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object a, {StackTrace? b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 92, 30),
    ]);
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object a, StackTrace? b) {});
}
''');
  }
}

mixin ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTestCases
    on PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(
    StreamSubscription<void> subscription, void Function(dynamic a) callback) {
  subscription.onError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(
    StreamSubscription<void> subscription,
    Future<int> Function({Object a}) callback) {
  subscription.onError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 144, 8),
    ]);
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError(({Object a = 1}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 92, 19),
    ]);
  }

  void test_functionExpression_noParameters() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError(() {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 92, 5),
    ]);
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object a, {StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 92, 29),
    ]);
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await assertErrorsInCode('''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((String a) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER, 92, 13),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTestCases,
        WithoutNullSafetyMixin {}

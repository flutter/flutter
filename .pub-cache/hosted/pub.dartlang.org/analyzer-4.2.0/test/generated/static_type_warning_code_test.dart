// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest);
    defineReflectiveTests(StaticTypeWarningCodeWithoutNullSafetyTest);
  });
}

/// TODO(srawlins) Figure out what to do with the rest of these tests.
///  The names do not correspond to diagnostic codes, so it isn't clear what
///  they're testing.
@reflectiveTest
class StaticTypeWarningCodeTest extends PubPackageResolutionTest {
  test_await_simple() async {
    await assertErrorsInCode('''
Future<int> fi() => Future.value(0);
f() async {
  String a = await fi(); // Warning: int not assignable to String
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 62, 10),
    ]);
  }

  test_awaitForIn_declaredVariableRightType() async {
    await assertErrorsInCode('''
f(Stream<int> stream) async {
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);
  }

  test_awaitForIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f(Stream<String> stream) async {
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 55, 6),
    ]);
  }

  test_awaitForIn_downcast() async {
    await assertErrorsInCode('''
f(Stream<num> stream) async {
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 52, 6),
    ]);
  }

  test_awaitForIn_dynamicVariable() async {
    await assertErrorsInCode('''
f(Stream<int> stream) async {
  await for (var i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);
  }

  test_awaitForIn_existingVariableRightType() async {
    await assertErrorsInCode('''
f(Stream<int> stream) async {
  late int i;
  await for (i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
    ]);
  }

  test_awaitForIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
f(Stream<String> stream) async {
  late int i;
  await for (i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 65, 6),
    ]);
  }

  test_awaitForIn_streamOfDynamic() async {
    await assertErrorsInCode('''
f(Stream stream) async {
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 42, 1),
    ]);
  }

  test_awaitForIn_upcast() async {
    await assertErrorsInCode('''
f(Stream<int> stream) async {
  await for (num i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);
  }

  test_forIn_declaredVariableRightType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <int>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_forIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 22, 10),
    ]);
  }

  test_forIn_dynamic() async {
    await assertErrorsInCode('''
f() {
  dynamic d; // Could be [].
  for (var i in d) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
  }

  test_forIn_dynamicIterable() async {
    await assertErrorsInCode('''
f() {
  dynamic iterable;
  for (int i in iterable) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
  }

  test_forIn_dynamicVariable() async {
    await assertErrorsInCode('''
f() {
  for (var i in <int>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_forIn_existingVariableRightType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <int>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_forIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 27, 10),
    ]);
  }

  test_forIn_iterableOfDynamic() async {
    await assertErrorsInCode('''
f() {
  for (int i in []) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_forIn_object() async {
    await assertErrorsInCode('''
f(List o) { // Could be [].
  for (var i in o) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 39, 1),
    ]);
  }

  test_forIn_typeBoundBad() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 86, 8),
    ]);
  }

  test_forIn_typeBoundGood() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (var i in iterable) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 78, 1),
    ]);
  }

  test_forIn_upcast() async {
    await assertErrorsInCode('''
f() {
  for (num i in <int>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_mutated() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
f(Object p) {
  (p is String) && callMe(() { p.length; });
  p = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 68, 6),
    ]);
  }

  test_typePromotion_booleanAnd_useInRight_mutatedInLeft() async {
    await assertErrorsInCode(r'''
f(Object p) {
  ((p is String) && ((p = 42) == 42)) && p.length != 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 57, 6),
    ]);
  }

  test_typePromotion_booleanAnd_useInRight_mutatedInRight() async {
    await assertErrorsInCode(r'''
f(Object p) {
  (p is String) && (((p = 42) == 42) && p.length != 0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 56, 6),
    ]);
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_after() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
g(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
  p = 42;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 65, 6),
    ]);
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_before() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
g(Object p) {
  p = 42;
  p is String ? callMe(() { p.length; }) : 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 75, 6),
    ]);
  }

  test_typePromotion_if_accessedInClosure_hasAssignment() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
f(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
  p = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 80, 6),
    ]);
  }

  test_typePromotion_if_extends_notMoreSpecific_dynamic() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

f(A<V> p) {
  if (p is B) {
    p.b;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 97, 1),
    ]);
  }

  test_typePromotion_if_extends_notMoreSpecific_notMoreSpecificTypeArg() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

f(A<V> p) {
  if (p is B<int>) {
    p.b;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 102, 1),
    ]);
  }

  test_typePromotion_if_hasAssignment_before() async {
    await assertErrorsInCode(r'''
f(Object p) {
  if (p is String) {
    p = 0;
    p.length;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 52, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_anonymous_before() async {
    await assertErrorsInCode(r'''
f(Object p) {
  () {p = 0;};
  if (p is String) {
    p.length;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 56, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_function_before() async {
    await assertErrorsInCode(r'''
g(Object p) {
  f() {p = 0;};
  if (p is String) {
    p.length;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 16, 1),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 57, 6),
    ]);
  }

  test_typePromotion_if_implements_notMoreSpecific_dynamic() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

f(A<V> p) {
  if (p is B) {
    p.b;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 100, 1),
    ]);
  }

  test_typePromotion_if_with_notMoreSpecific_dynamic() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> extends Object with A<S> {
  var b;
}

f(A<V> p) {
  if (p is B) {
    p.b;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 109, 1),
    ]);
  }

  test_wrongNumberOfTypeArguments() async {
    await assertErrorsInCode(r'''
class A<E> {
  late E element;
}
g(A<NoSuchType> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT, 37, 10),
    ]);
  }
}

@reflectiveTest
class StaticTypeWarningCodeWithoutNullSafetyTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_assert_message_suppresses_type_promotion() async {
    // If a variable is assigned to inside the expression for an assert
    // message, type promotion should be suppressed, just as it would be if the
    // assignment occurred outside an assert statement.  (Note that it is a
    // dubious practice for the computation of an assert message to have side
    // effects, since it is only evaluated if the assert fails).
    await assertErrorsInCode('''
class C {
  void foo() {}
}

f(Object x) {
  if (x is C) {
    x.foo();
    assert(true, () { x = new C(); return 'msg'; }());
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 65, 3),
    ]);
  }

  test_await_flattened() async {
    await assertErrorsInCode('''
Future<Future<int>> ffi() => null;
f() async {
  Future<int> b = await ffi();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 61, 1),
    ]);
  }

  test_bug21912() async {
    await assertErrorsInCode('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);
typedef B AToB(A x);
typedef A BToA(B x);

void main() {
  {
    Function2<Function2<A, B>, Function2<B, A>> t1;
    Function2<AToB, BToA> t2;

    Function2<Function2<int, double>, Function2<int, double>> left;

    left = t1;
    left = t2;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 271, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 289, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 304, 2),
    ]);
  }

  test_forIn_downcast() async {
    await assertErrorsInCode('''
f() {
  for (int i in <num>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);
  }

  test_typePromotion_conditional_useInThen_hasAssignment() async {
    await assertErrorsInCode(r'''
f(Object p) {
  p is String ? (p.length + (p = 42)) : 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 33, 6),
    ]);
  }

  test_typePromotion_if_and_right_hasAssignment() async {
    await assertErrorsInCode(r'''
f(Object p) {
  if (p is String && (p = null) == null) {
    p.length;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 63, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_after() async {
    await assertErrorsInCode(r'''
f(Object p) {
  if (p is String) {
    p.length;
    p = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_anonymous_after() async {
    await assertErrorsInCode(r'''
f(Object p) {
  if (p is String) {
    p.length;
  }
  () {p = 0;};
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_function_after() async {
    await assertErrorsInCode(r'''
g(Object p) {
  if (p is String) {
    p.length;
  }
  f() {p = 0;};
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 41, 6),
      error(HintCode.UNUSED_ELEMENT, 55, 1),
    ]);
  }
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest extends PubPackageResolutionTest {
  test_legalAsyncGeneratorReturnType_function_supertypeOfStream() async {
    await assertNoErrorsInCode('''
f() async* { yield 42; }
dynamic f2() async* { yield 42; }
Object f3() async* { yield 42; }
Stream f4() async* { yield 42; }
Stream<dynamic> f5() async* { yield 42; }
Stream<Object> f6() async* { yield 42; }
Stream<num> f7() async* { yield 42; }
Stream<int> f8() async* { yield 42; }
''');
  }

  test_legalAsyncReturnType_function_supertypeOfFuture() async {
    await assertNoErrorsInCode('''
f() async { return 42; }
dynamic f2() async { return 42; }
Object f3() async { return 42; }
Future f4() async { return 42; }
Future<dynamic> f5() async { return 42; }
Future<Object> f6() async { return 42; }
Future<num> f7() async { return 42; }
Future<int> f8() async { return 42; }
''');
  }

  test_legalSyncGeneratorReturnType_function_supertypeOfIterable() async {
    await assertNoErrorsInCode('''
f() sync* { yield 42; }
dynamic f2() sync* { yield 42; }
Object f3() sync* { yield 42; }
Iterable f4() sync* { yield 42; }
Iterable<dynamic> f5() sync* { yield 42; }
Iterable<Object> f6() sync* { yield 42; }
Iterable<num> f7() sync* { yield 42; }
Iterable<int> f8() sync* { yield 42; }
''');
  }
}

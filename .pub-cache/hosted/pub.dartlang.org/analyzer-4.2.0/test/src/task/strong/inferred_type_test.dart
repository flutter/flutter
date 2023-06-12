// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferredTypeTest);
  });
}

@reflectiveTest
class InferredTypeTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  // TODO(https://github.com/dart-lang/sdk/issues/44666): Use null safety in
  //  test cases.
  CompilationUnitElement get _resultUnitElement {
    return result.unit.declaredElement!;
  }

  test_asyncClosureReturnType_flatten() async {
    await assertNoErrorsInCode('''
Future<int> futureInt = null;
var f = () => futureInt;
var g = () async => futureInt;
''');
    var futureInt = _resultUnitElement.topLevelVariables[0];
    expect(futureInt.name, 'futureInt');
    _assertTypeStr(futureInt.type, 'Future<int>');
    var f = _resultUnitElement.topLevelVariables[1];
    expect(f.name, 'f');
    _assertTypeStr(f.type, 'Future<int> Function()');
    var g = _resultUnitElement.topLevelVariables[2];
    expect(g.name, 'g');
    _assertTypeStr(g.type, 'Future<int> Function()');
  }

  test_asyncClosureReturnType_future() async {
    await assertNoErrorsInCode('''
var f = () async => 0;
''');
    var f = _resultUnitElement.topLevelVariables[0];
    expect(f.name, 'f');
    _assertTypeStr(f.type, 'Future<int> Function()');
  }

  test_asyncClosureReturnType_futureOr() async {
    await assertNoErrorsInCode('''
import 'dart:async';
FutureOr<int> futureOrInt = null;
var f = () => futureOrInt;
var g = () async => futureOrInt;
''');
    var futureOrInt = _resultUnitElement.topLevelVariables[0];
    expect(futureOrInt.name, 'futureOrInt');
    _assertTypeStr(futureOrInt.type, 'FutureOr<int>');
    var f = _resultUnitElement.topLevelVariables[1];
    expect(f.name, 'f');
    _assertTypeStr(f.type, 'FutureOr<int> Function()');
    var g = _resultUnitElement.topLevelVariables[2];
    expect(g.name, 'g');
    _assertTypeStr(g.type, 'Future<int> Function()');
  }

  test_blockBodiedLambdas_async_allReturnsAreFutures() async {
    await assertErrorsInCode(r'''
import 'dart:math' show Random;
main() {
  var f = () async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return new Future<double>.value(2.0);
    }
  };
  Future<num> g = f();
  Future<int> h = f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 218, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 241, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<num> Function()');
  }

  test_blockBodiedLambdas_async_allReturnsAreValues() async {
    await assertErrorsInCode(r'''
import 'dart:math' show Random;
main() {
  var f = () async {
    if (new Random().nextBool()) {
      return 1;
    } else {
      return 2.0;
    }
  };
  Future<num> g = f();
  Future<int> h = f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 169, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 192, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<num> Function()');
  }

  test_blockBodiedLambdas_async_mixOfValuesAndFutures() async {
    await assertErrorsInCode(r'''
import 'dart:math' show Random;
main() {
  var f = () async {
    if (new Random().nextBool()) {
      return new Future<int>.value(1);
    } else {
      return 2.0;
    }
  };
  Future<num> g = f();
  Future<int> h = f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 192, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 215, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<num> Function()');
  }

  test_blockBodiedLambdas_asyncStar() async {
    await assertErrorsInCode(r'''
main() {
  var f = () async* {
    yield 1;
    Stream<double> s;
    yield* s;
  };
  Stream<num> g = f();
  Stream<int> h = f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 99, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 122, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Stream<num> Function()');
  }

  test_blockBodiedLambdas_basic() async {
    await assertErrorsInCode(r'''
test1() {
  List<int> o;
  var y = o.map((x) { return x + 1; });
  Iterable<int> z = y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
    ]);
  }

  test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference() async {
    await assertErrorsInCode(r'''
main() {
  String f() => null;
  var g = f;
  g = () { return 1; };
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 37, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 62, 1),
    ]);

    var g = findElement.localVar('g');
    _assertTypeStr(g.type, 'String Function()');
  }

  test_blockBodiedLambdas_downwardsIncompatibleWithUpwardsInference_topLevel() async {
    await assertNoErrorsInCode(r'''
String f() => null;
var g = f;
''');
    var g = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(g.type, 'String Function()');
  }

  test_blockBodiedLambdas_inferBottom_async() async {
    await assertErrorsInCode(r'''
main() async {
  var f = () async { return null; };
  Future y = f();
  Future<String> z = f();
  String s = await f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 61, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 87, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 105, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Future<Null> Function()');
  }

  test_blockBodiedLambdas_inferBottom_asyncStar() async {
    await assertErrorsInCode(r'''
main() async {
  var f = () async* { yield null; };
  Stream y = f();
  Stream<String> z = f();
  String s = await f().first;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 61, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 87, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 105, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Stream<Null> Function()');
  }

  test_blockBodiedLambdas_inferBottom_sync() async {
    await assertErrorsInCode(r'''
var h = null;
void foo(int g(Object _)) {}

main() {
  var f = (Object x) { return null; };
  String y = f(42);

  f = (x) => 'hello';

  foo((x) { return null; });
  foo((x) { throw "not implemented"; });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 101, 1),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL, 126, 7),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Null Function(Object)');
  }

  test_blockBodiedLambdas_inferBottom_syncStar() async {
    await assertErrorsInCode(r'''
main() {
  var f = () sync* { yield null; };
  Iterable y = f();
  Iterable<String> z = f();
  String s = f().first;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 56, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 84, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 102, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Iterable<Null> Function()');
  }

  test_blockBodiedLambdas_LUB() async {
    await assertErrorsInCode(r'''
import 'dart:math' show Random;
test2() {
  List<num> o;
  var y = o.map((x) {
    if (new Random().nextBool()) {
      return x.toInt() + 1;
    } else {
      return x.toDouble();
    }
  });
  Iterable<num> w = y;
  Iterable<int> z = y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 210, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 233, 1),
    ]);
  }

  test_blockBodiedLambdas_nestedLambdas() async {
    // Original feature request: https://github.com/dart-lang/sdk/issues/25487
    await assertErrorsInCode(r'''
main() {
  var f = () {
    return (int x) { return 2.0 * x; };
  };
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'double Function(int) Function()');
  }

  test_blockBodiedLambdas_noReturn() async {
    await assertErrorsInCode(r'''
test1() {
  List<int> o;
  var y = o.map((x) { });
  Iterable<int> z = y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 67, 1),
    ]);

    var y = findElement.localVar('y');
    _assertTypeStr(y.type, 'Iterable<Null>');
  }

  test_blockBodiedLambdas_syncStar() async {
    await assertErrorsInCode(r'''
main() {
  var f = () sync* {
    yield 1;
    yield* [3, 4.0];
  };
  Iterable<num> g = f();
  Iterable<int> h = f();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 85, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 110, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Iterable<num> Function()');
  }

  test_bottom() async {
    await assertNoErrorsInCode('''
var v = null;
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'dynamic');
  }

  test_bottom_inClosure() async {
    await assertNoErrorsInCode('''
var v = () => null;
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'Null Function()');
  }

  test_circularReference_viaClosures() async {
    await assertErrorsInCode('''
var x = () => y;
var y = () => x;
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 1),
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 21, 1),
    ]);

    var x = _resultUnitElement.topLevelVariables[0];
    var y = _resultUnitElement.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    _assertTypeStr(x.type, 'dynamic');
    _assertTypeStr(y.type, 'dynamic');
  }

  test_circularReference_viaClosures_initializerTypes() async {
    await assertErrorsInCode('''
var x = () => y;
var y = () => x;
''', [
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 4, 1),
      error(CompileTimeErrorCode.TOP_LEVEL_CYCLE, 21, 1),
    ]);

    var x = _resultUnitElement.topLevelVariables[0];
    var y = _resultUnitElement.topLevelVariables[1];
    expect(x.name, 'x');
    expect(y.name, 'y');
    _assertTypeStr(x.type, 'dynamic');
    _assertTypeStr(y.type, 'dynamic');
  }

  test_conflictsCanHappen2() async {
    await assertErrorsInCode('''
class I1 {
  int x;
}
class I2 {
  int y;
}

class I3 implements I1, I2 {
  int x;
  int y;
}

class A {
  final I1 a = null;
}

class B {
  final I2 a = null;
}

class C1 implements A, B {
  I3 get a => null;
}

class C2 implements A, B {
  get a => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 246, 1,
          contextMessages: [message('/home/test/lib/test.dart', 150, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 246, 1,
          contextMessages: [message('/home/test/lib/test.dart', 116, 1)]),
    ]);
  }

  test_constructors_downwardsWithConstraint() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26431
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class Foo<T extends A> {}
void main() {
  Foo<B> foo = new Foo();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 3),
    ]);
  }

  test_constructors_inferFromArguments() async {
    await assertErrorsInCode('''
class C<T> {
  T t;
  C(this.t);
}

main() {
  var x = new C(42);

  num y;
  C<int> c_int = new C(y);

  // These hints are not reported because we resolve with a null error listener.
  C<num> c_num = new C(123);
  C<num> c_num2 = (new C(456))
      ..t = 1.0;

  // Don't infer from explicit dynamic.
  var c_dynamic = new C<dynamic>(42);
  x.t = 'hello';
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 85, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 194, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 223, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 309, 9),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 349, 7),
    ]);

    _assertTypeStr(findElement.localVar('x').type, 'C<int>');
    _assertTypeStr(findElement.localVar('c_int').type, 'C<int>');
    _assertTypeStr(findElement.localVar('c_num').type, 'C<num>');
    _assertTypeStr(findElement.localVar('c_dynamic').type, 'C<dynamic>');
  }

  test_constructors_inferFromArguments_const() async {
    await assertErrorsInCode('''
class C<T> {
  final T t;
  const C(this.t);
}

main() {
  var x = const C(42);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 63, 1),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_constWithUpperBound() async {
    // Regression for https://github.com/dart-lang/sdk/issues/26993
    await assertErrorsInCode('''
class C<T extends num> {
  final T x;
  const C(this.x);
}
class D<T extends num> {
  const D();
}
void f() {
  const c = const C(0);
  C<int> c2 = c;
  const D<int> d = const D();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 143, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 166, 1),
    ]);
  }

  test_constructors_inferFromArguments_downwardsFromConstructor() {
    return assertErrorsInCode(r'''
class C<T> { C(List<T> list); }

main() {
  var x = new C([123]);
  C<int> y = x;

  var a = new C<dynamic>([123]);
  // This one however works.
  var b = new C<Object>([123]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 75, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 151, 1),
    ]);
  }

  test_constructors_inferFromArguments_factory() async {
    await assertErrorsInCode('''
class C<T> {
  T t;

  C._();

  factory C(T t) {
    var c = new C<T>._();
    c.t = t;
    return c;
  }
}


main() {
  var x = new C(42);
  x.t = 'hello';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 149, 7),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_factory_callsConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A<T> f = new A();
  A();
  factory A.factory() => new A();
  A<T> m() => new A();
}
''');
  }

  test_constructors_inferFromArguments_named() async {
    await assertErrorsInCode('''
class C<T> {
  T t;
  C.named(List<T> t);
}


main() {
  var x = new C.named(<int>[]);
  x.t = 'hello';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 95, 7),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_namedFactory() async {
    await assertErrorsInCode('''
class C<T> {
  T t;
  C();

  factory C.named(T t) {
    var c = new C<T>();
    c.t = t;
    return c;
  }
}


main() {
  var x = new C.named(42);
  x.t = 'hello';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 156, 7),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_redirecting() async {
    await assertErrorsInCode('''
class C<T> {
  T t;
  C(this.t);
  C.named(List<T> t) : this(t[0]);
}


main() {
  var x = new C.named(<int>[42]);
  x.t = 'hello';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 123, 7),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_inferFromArguments_redirectingFactory() async {
    await assertErrorsInCode('''
abstract class C<T> {
  T get t;
  void set t(T t);

  factory C(T t) = CImpl<T>;
}

class CImpl<T> implements C<T> {
  T t;
  CImpl(this.t);
}

main() {
  var x = new C(42);
  x.t = 'hello';
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 183, 7),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'C<int>');
  }

  test_constructors_reverseTypeParameters() async {
    // Regression for https://github.com/dart-lang/sdk/issues/26990
    await assertNoErrorsInCode('''
class Pair<T, U> {
  T t;
  U u;
  Pair(this.t, this.u);
  Pair<U, T> get reversed => new Pair(u, t);
}
''');
  }

  test_constructors_tooManyPositionalArguments() async {
    await assertErrorsInCode(r'''
class A<T> {}
main() {
  var a = new A(42);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 39, 2),
    ]);

    var a = findElement.localVar('a');
    _assertTypeStr(a.type, 'A<dynamic>');
  }

  test_doNotInferOverriddenFieldsThatExplicitlySayDynamic_infer() async {
    await assertErrorsInCode('''
class A {
  final int x = 2;
}

class B implements A {
  dynamic get x => 3;
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 69, 1,
          contextMessages: [message('/home/test/lib/test.dart', 22, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 97, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 118, 1),
    ]);
  }

  test_dontInferFieldTypeWhenInitializerIsNull() async {
    await assertErrorsInCode('''
var x = null;
var y = 3;
class A {
  static var x = null;
  static var y = 3;

  var x2 = null;
  var y2 = 3;
}

test() {
  x = "hi";
  y = "hi";
  A.x = "hi";
  A.y = "hi";
  new A().x2 = "hi";
  new A().y2 = "hi";
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 140, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 168, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 210, 4),
    ]);
  }

  test_dontInferTypeOnDynamic() async {
    await assertErrorsInCode('''
test() {
  dynamic x = 3;
  x = "hi";
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
  }

  test_dontInferTypeWhenInitializerIsNull() async {
    await assertErrorsInCode('''
test() {
  var x = null;
  x = "hi";
  x = 3;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
  }

  test_downwardInference_miscellaneous() async {
    await assertErrorsInCode('''
typedef T Function2<S, T>(S x);
class A<T> {
  Function2<T, T> x;
  A(this.x);
}
void main() {
  {  // Variables, nested literals
    var x = "hello";
    var y = 3;
    void f(List<Map<int, String>> l) {};
    f([{y: x}]);
  }
  {
    int f(int x) => 0;
    A<int> a = new A(f);
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 266, 1),
    ]);
  }

  test_downwardsInference_insideTopLevel() async {
    await assertNoErrorsInCode('''
class A {
  B<int> b;
}

class B<T> {
  B(T x);
}

var t1 = new A()..b = new B(1);
var t2 = <B<int>>[new B(2)];
var t3 = [
            new B(3)
         ];
''');
  }

  test_downwardsInferenceAnnotations() async {
    await assertNoErrorsInCode('''
class Foo {
  const Foo(List<String> l);
  const Foo.named(List<String> l);
}
@Foo(const [])
class Bar {}
@Foo.named(const [])
class Baz {}
''');
  }

  test_downwardsInferenceAssignmentStatements() async {
    await assertErrorsInCode('''
void main() {
  List<int> l;
  l = ["hello"];
  l = (l = [1]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 36, 7),
    ]);
  }

  test_downwardsInferenceAsyncAwait() async {
    await assertErrorsInCode('''
Future test() async {
  dynamic d;
  List<int> l0 = await [d];
  List<int> l1 = await new Future.value([d]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 75, 2),
    ]);
  }

  test_downwardsInferenceForEach() async {
    await assertErrorsInCode('''
abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw 0;
}

Future main() async {
  for(int x in [1, 2, 3]) {}
  await for(int x in new MyStream()) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 115, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 150, 1),
    ]);
  }

  test_downwardsInferenceInitializingFormalDefaultFormal() async {
    await assertNoErrorsInCode('''
typedef T Function2<S, T>([S x]);
class Foo {
  List<int> x;
  Foo([this.x = const [1]]);
  Foo.named([List<int> x = const [1]]);
}
void f([List<int> l = const [1]]) {}
// We do this inference in an early task but don't preserve the infos.
Function2<List<int>, String> g = ([llll = const [1]]) => "hello";
''');
  }

  test_downwardsInferenceOnConstructorArguments_inferDownwards() async {
    await assertErrorsInCode('''
class F0 {
  F0(List<int> a) {}
}
class F1 {
  F1({List<int> a}) {}
}
class F2 {
  F2(Iterable<int> a) {}
}
class F3 {
  F3(Iterable<Iterable<int>> a) {}
}
class F4 {
  F4({Iterable<Iterable<int>> a}) {}
}
void main() {
  new F0([]);
  new F0([3]);
  new F0(["hello"]);
  new F0(["hello", 3]);

  new F1(a: []);
  new F1(a: [3]);
  new F1(a: ["hello"]);
  new F1(a: ["hello", 3]);

  new F2([]);
  new F2([3]);
  new F2(["hello"]);
  new F2(["hello", 3]);

  new F3([]);
  new F3([[3]]);
  new F3([["hello"]]);
  new F3([["hello"], [3]]);

  new F4(a: []);
  new F4(a: [[3]]);
  new F4(a: [["hello"]]);
  new F4(a: [["hello"], [3]]);
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 259, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 280, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 343, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 367, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 421, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 442, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 499, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 522, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 591, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 617, 7),
    ]);
  }

  test_downwardsInferenceOnFunctionArguments_inferDownwards() async {
    await assertErrorsInCode('''
void f0(List<int> a) {}
void f1({List<int> a}) {}
void f2(Iterable<int> a) {}
void f3(Iterable<Iterable<int>> a) {}
void f4({Iterable<Iterable<int>> a}) {}
void main() {
  f0([]);
  f0([3]);
  f0(["hello"]);
  f0(["hello", 3]);

  f1(a: []);
  f1(a: [3]);
  f1(a: ["hello"]);
  f1(a: ["hello", 3]);

  f2([]);
  f2([3]);
  f2(["hello"]);
  f2(["hello", 3]);

  f3([]);
  f3([[3]]);
  f3([["hello"]]);
  f3([["hello"], [3]]);

  f4(a: []);
  f4(a: [[3]]);
  f4(a: [["hello"]]);
  f4(a: [["hello"], [3]]);
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 197, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 214, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 265, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 285, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 327, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 344, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 389, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 408, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 465, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 487, 7),
    ]);
  }

  test_downwardsInferenceOnFunctionExpressions() async {
    await assertErrorsInCode('''
typedef T Function2<S, T>(S x);

void main () {
  {
    Function2<int, String> l0 = (int x) => null;
    Function2<int, String> l1 = (int x) => "hello";
    Function2<int, String> l2 = (String x) => "hello";
    Function2<int, String> l3 = (int x) => 3;
    Function2<int, String> l4 = (int x) {return 3;};
  }
  {
    Function2<int, String> l0 = (x) => null;
    Function2<int, String> l1 = (x) => "hello";
    Function2<int, String> l2 = (x) => 3;
    Function2<int, String> l3 = (x) {return 3;};
    Function2<int, String> l4 = (x) {return x;};
  }
  {
    Function2<int, List<String>> l0 = (int x) => null;
    Function2<int, List<String>> l1 = (int x) => ["hello"];
    Function2<int, List<String>> l2 = (String x) => ["hello"];
    Function2<int, List<String>> l3 = (int x) => [3];
    Function2<int, List<String>> l4 = (int x) {return [3];};
  }
  {
    Function2<int, int> l0 = (x) => x;
    Function2<int, int> l1 = (x) => x+1;
    Function2<int, String> l2 = (x) => x;
    Function2<int, String> l3 = (x) => x.substring(3);
    Function2<String, String> l4 = (x) => x.substring(3);
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 79, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 128, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 180, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 185, 21),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 235, 2),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 251, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 281, 2),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 302, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 342, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 387, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 435, 2),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 447, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 477, 2),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 494, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 526, 2),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 543, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 589, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 644, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 704, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 709, 23),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 767, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 784, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 821, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 843, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 881, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 920, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 964, 2),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 976, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1006, 2),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 1020, 9),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1064, 2),
    ]);
  }

  test_downwardsInferenceOnFunctionOfTUsingTheT() async {
    await assertErrorsInCode('''
void main () {
  {
    T f<T>(T x) => null;
    var v1 = f;
    v1 = <S>(x) => x;
  }
  {
    List<T> f<T>(T x) => null;
    var v2 = f;
    v2 = <S>(x) => [x];
    Iterable<int> r = v2(42);
    Iterable<String> s = v2('hello');
    Iterable<List<int>> t = v2(<int>[]);
    Iterable<num> u = v2(42);
    Iterable<num> v = v2<num>(42);
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 179, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 212, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 253, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 288, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 318, 1),
    ]);
  }

  test_downwardsInferenceOnGenericConstructorArguments_emptyList() async {
    await assertNoErrorsInCode('''
class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}
class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
}
void main() {
  new F3([]);
  new F4(a: []);
}
''');
  }

  test_downwardsInferenceOnGenericConstructorArguments_inferDownwards() async {
    await assertErrorsInCode('''
class F0<T> {
  F0(List<T> a) {}
}
class F1<T> {
  F1({List<T> a}) {}
}
class F2<T> {
  F2(Iterable<T> a) {}
}
class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}
class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
}
class F5<T> {
  F5(Iterable<Iterable<Iterable<T>>> a) {}
}
void main() {
  new F0<int>([]);
  new F0<int>([3]);
  new F0<int>(["hello"]);
  new F0<int>(["hello", 3]);

  new F1<int>(a: []);
  new F1<int>(a: [3]);
  new F1<int>(a: ["hello"]);
  new F1<int>(a: ["hello", 3]);

  new F2<int>([]);
  new F2<int>([3]);
  new F2<int>(["hello"]);
  new F2<int>(["hello", 3]);

  new F3<int>([]);
  new F3<int>([[3]]);
  new F3<int>([["hello"]]);
  new F3<int>([["hello"], [3]]);

  new F4<int>(a: []);
  new F4<int>(a: [[3]]);
  new F4<int>(a: [["hello"]]);
  new F4<int>(a: [["hello"], [3]]);

  new F3([]);
  var f31 = new F3([[3]]);
  var f32 = new F3([["hello"]]);
  var f33 = new F3([["hello"], [3]]);

  new F4(a: []);
  new F4(a: [[3]]);
  new F4(a: [["hello"]]);
  new F4(a: [["hello"], [3]]);

  new F5([[[3]]]);
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 338, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 364, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 442, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 471, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 540, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 566, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 638, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 666, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 750, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 781, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 819, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 846, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 879, 3),
    ]);
  }

  test_downwardsInferenceOnGenericFunctionExpressions() async {
    await assertErrorsInCode('''
void main () {
  {
    String f<S>(int x) => null;
    var v = f;
    v = <T>(int x) => null;
    v = <T>(int x) => "hello";
    v = <T>(String x) => "hello";
    v = <T>(int x) => 3;
    v = <T>(int x) {return 3;};
  }
  {
    String f<S>(int x) => null;
    var v = f;
    v = <T>(x) => null;
    v = <T>(x) => "hello";
    v = <T>(x) => 3;
    v = <T>(x) {return 3;};
    v = <T>(x) {return x;};
  }
  {
    List<String> f<S>(int x) => null;
    var v = f;
    v = <T>(int x) => null;
    v = <T>(int x) => ["hello"];
    v = <T>(String x) => ["hello"];
    v = <T>(int x) => [3];
    v = <T>(int x) {return [3];};
  }
  {
    int int2int<S>(int x) => null;
    String int2String<T>(int x) => null;
    String string2String<T>(String x) => null;
    var x = int2int;
    x = <T>(x) => x;
    x = <T>(x) => x+1;
    var y = int2String;
    y = <T>(x) => x;
    y = <T>(x) => x.substring(3);
    var z = string2String;
    z = <T>(x) => x.substring(3);
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 59, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 133, 24),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 181, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 211, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 264, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 340, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 366, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 394, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 453, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 529, 26),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 580, 1),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 612, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 757, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 822, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 856, 1),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 879, 9),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 901, 1),
    ]);
  }

  test_downwardsInferenceOnInstanceCreations_inferDownwards() async {
    await assertErrorsInCode('''
class A<S, T> {
  S x;
  T y;
  A(this.x, this.y);
  A.named(this.x, this.y);
}

class B<S, T> extends A<T, S> {
  B(S y, T x) : super(x, y);
  B.named(S y, T x) : super.named(x, y);
}

class C<S> extends B<S, S> {
  C(S a) : super(a, a);
  C.named(S a) : super.named(a, a);
}

class D<S, T> extends B<T, int> {
  D(T a) : super(a, 3);
  D.named(T a) : super.named(a, 3);
}

class E<S, T> extends A<C<S>, T> {
  E(T a) : super(null, a);
}

class F<S, T> extends A<S, T> {
  F(S x, T y, {List<S> a, List<T> b}) : super(x, y);
  F.named(S x, T y, [S a, T b]) : super(a, b);
}

void main() {
  {
    A<int, String> a0 = new A(3, "hello");
    A<int, String> a1 = new A.named(3, "hello");
    A<int, String> a2 = new A<int, String>(3, "hello");
    A<int, String> a3 = new A<int, String>.named(3, "hello");
    A<int, String> a4 = new A<int, dynamic>(3, "hello");
    A<int, String> a5 = new A<dynamic, dynamic>.named(3, "hello");
  }
  {
    A<int, String> a0 = new A("hello", 3);
    A<int, String> a1 = new A.named("hello", 3);
  }
  {
    A<int, String> a0 = new B("hello", 3);
    A<int, String> a1 = new B.named("hello", 3);
    A<int, String> a2 = new B<String, int>("hello", 3);
    A<int, String> a3 = new B<String, int>.named("hello", 3);
    A<int, String> a4 = new B<String, dynamic>("hello", 3);
    A<int, String> a5 = new B<dynamic, dynamic>.named("hello", 3);
  }
  {
    A<int, String> a0 = new B(3, "hello");
    A<int, String> a1 = new B.named(3, "hello");
  }
  {
    A<int, int> a0 = new C(3);
    A<int, int> a1 = new C.named(3);
    A<int, int> a2 = new C<int>(3);
    A<int, int> a3 = new C<int>.named(3);
    A<int, int> a4 = new C<dynamic>(3);
    A<int, int> a5 = new C<dynamic>.named(3);
  }
  {
    A<int, int> a0 = new C("hello");
    A<int, int> a1 = new C.named("hello");
  }
  {
    A<int, String> a0 = new D("hello");
    A<int, String> a1 = new D.named("hello");
    A<int, String> a2 = new D<int, String>("hello");
    A<int, String> a3 = new D<String, String>.named("hello");
    A<int, String> a4 = new D<num, dynamic>("hello");
    A<int, String> a5 = new D<dynamic, dynamic>.named("hello");
  }
  {
    A<int, String> a0 = new D(3);
    A<int, String> a1 = new D.named(3);
  }
  {
    A<C<int>, String> a0 = new E("hello");
  }
  { // Check named and optional arguments
    A<int, String> a0 = new F(3, "hello",
        a: [3],
        b: ["hello"]);
    A<int, String> a1 = new F(3, "hello",
        a: ["hello"],
        b: [3]);
    A<int, String> a2 = new F.named(3, "hello", 3, "hello");
    A<int, String> a3 = new F.named(3, "hello");
    A<int, String> a4 = new F.named(3, "hello", "hello", 3);
    A<int, String> a5 = new F.named(3, "hello", "hello");
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 612, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 655, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 704, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 760, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 822, 2),
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 827, 31),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 879, 2),
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 884, 41),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 954, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 965, 7),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 974, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 997, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1014, 7),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1023, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1054, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1097, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1146, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1202, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1264, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1269, 34),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1324, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1329, 41),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1399, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1410, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1413, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1442, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1459, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1462, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1496, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1527, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1564, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1600, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1642, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1647, 17),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1682, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1687, 23),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1736, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1747, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1773, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1790, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1827, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1867, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1913, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1966, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2028, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 2033, 28),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2082, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 2087, 38),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2154, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2165, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2188, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2205, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2239, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2325, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2406, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 2441, 7),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 2463, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2487, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2548, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2597, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2626, 7),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2635, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2658, 2),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2687, 7),
    ]);
  }

  test_downwardsInferenceOnListLiterals_inferDownwards() async {
    await assertErrorsInCode('''
void foo([List<String> list1 = const [],
          List<String> list2 = const [42]]) {
}

void main() {
  {
    List<int> l0 = [];
    List<int> l1 = [3];
    List<int> l2 = ["hello"];
    List<int> l3 = ["hello", 3];
  }
  {
    List<dynamic> l0 = [];
    List<dynamic> l1 = [3];
    List<dynamic> l2 = ["hello"];
    List<dynamic> l3 = ["hello", 3];
  }
  {
    List<int> l0 = <num>[];
    List<int> l1 = <num>[3];
    List<int> l2 = <num>["hello"];
    List<int> l3 = <num>["hello", 3];
  }
  {
    Iterable<int> i0 = [];
    Iterable<int> i1 = [3];
    Iterable<int> i2 = ["hello"];
    Iterable<int> i3 = ["hello", 3];
  }
  {
    const List<int> c0 = const [];
    const List<int> c1 = const [3];
    const List<int> c2 = const ["hello"];
    const List<int> c3 = const ["hello", 3];
  }
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 79, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 122, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 145, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 169, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 175, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 199, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 205, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 244, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 271, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 299, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 333, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 374, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 379, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 402, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 407, 8),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 431, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 436, 14),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 442, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 466, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, 471, 17),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 477, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 516, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 543, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 571, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 577, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 605, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 611, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 652, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 687, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 723, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 735, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 765, 2),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 777, 7),
    ]);
  }

  test_downwardsInferenceOnListLiterals_inferIfValueTypesMatchContext() async {
    await assertNoErrorsInCode(r'''
class DartType {}
typedef void Asserter<T>(T type);
typedef Asserter<T> AsserterBuilder<S, T>(S arg);

Asserter<DartType> _isInt;
Asserter<DartType> _isString;

abstract class C {
  static AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
  static AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf([_isInt, _isString]);
    assertBOf([_isInt, _isString]);
    assertCOf([_isInt, _isString]);
    assertDOf([_isInt, _isString]);
    assertEOf([_isInt, _isString]);
  }
  }

  abstract class G<T> {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  AsserterBuilder<List<Asserter<DartType>>, DartType> get assertDOf;

  method(AsserterBuilder<List<Asserter<DartType>>, DartType> assertEOf) {
    assertAOf([_isInt, _isString]);
    this.assertAOf([_isInt, _isString]);
    this.assertDOf([_isInt, _isString]);
    assertEOf([_isInt, _isString]);
  }
}

AsserterBuilder<List<Asserter<DartType>>, DartType> assertBOf;
AsserterBuilder<List<Asserter<DartType>>, DartType> get assertCOf => null;

main() {
  AsserterBuilder<List<Asserter<DartType>>, DartType> assertAOf;
  assertAOf([_isInt, _isString]);
  assertBOf([_isInt, _isString]);
  assertCOf([_isInt, _isString]);
  C.assertBOf([_isInt, _isString]);
  C.assertCOf([_isInt, _isString]);

  C c;
  c.assertAOf([_isInt, _isString]);
  c.assertDOf([_isInt, _isString]);

  G<int> g;
  g.assertAOf([_isInt, _isString]);
  g.assertDOf([_isInt, _isString]);
}
''');
  }

  test_downwardsInferenceOnMapLiterals() async {
    await assertErrorsInCode('''
void foo([Map<int, String> m1 = const {1: "hello"},
    Map<int, String> m2 = const {
      // One error is from type checking and the other is from const evaluation.
      "hello": "world"
    }]) {
}
void main() {
  {
    Map<int, String> l0 = {};
    Map<int, String> l1 = {3: "hello"};
    Map<int, String> l2 = {
      "hello": "hello"
    };
    Map<int, String> l3 = {
      3: 3
    };
    Map<int, String> l4 = {
      3: "hello",
      "hello": 3
    };
  }
  {
    Map<dynamic, dynamic> l0 = {};
    Map<dynamic, dynamic> l1 = {3: "hello"};
    Map<dynamic, dynamic> l2 = {"hello": "hello"};
    Map<dynamic, dynamic> l3 = {3: 3};
    Map<dynamic, dynamic> l4 = {3:"hello", "hello": 3};
  }
  {
    Map<dynamic, String> l0 = {};
    Map<dynamic, String> l1 = {3: "hello"};
    Map<dynamic, String> l2 = {"hello": "hello"};
    Map<dynamic, String> l3 = {3: 3};
    Map<dynamic, String> l4 = {
      3: "hello",
      "hello": 3
    };
  }
  {
    Map<int, dynamic> l0 = {};
    Map<int, dynamic> l1 = {3: "hello"};
    Map<int, dynamic> l2 = {
      "hello": "hello"
    };
    Map<int, dynamic> l3 = {3: 3};
    Map<int, dynamic> l4 = {
      3:"hello",
      "hello": 3
    };
  }
  {
    Map<int, String> l0 = <num, dynamic>{};
    Map<int, String> l1 = <num, dynamic>{3: "hello"};
    Map<int, String> l3 = <num, dynamic>{3: 3};
  }
  {
    const Map<int, String> l0 = const {};
    const Map<int, String> l1 = const {3: "hello"};
    const Map<int, String> l2 = const {
      "hello": "hello"
    };
    const Map<int, String> l3 = const {
      3: 3
    };
    const Map<int, String> l4 = const {
      3:"hello",
      "hello": 3
    };
  }
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 173, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 241, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 271, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 311, 2),
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 324, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 369, 2),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 385, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 415, 2),
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 446, 7),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 455, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 498, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 533, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 578, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 629, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 668, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 731, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 765, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 809, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 859, 2),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 868, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 897, 2),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 937, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 976, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1007, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1048, 2),
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 1061, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1107, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1142, 2),
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 1172, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1219, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP, 1224, 16),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1263, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP, 1268, 26),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1317, 2),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP, 1322, 20),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1379, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1421, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1473, 2),
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 1492, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1543, 2),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 1565, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1601, 2),
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 1637, 7),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 1646, 1),
    ]);
  }

  test_fieldRefersToStaticGetter() async {
    await assertNoErrorsInCode('''
class C {
  final x = _x;
  static int get _x => null;
}
''');
    var x = _resultUnitElement.classes[0].fields[0];
    _assertTypeStr(x.type, 'int');
  }

  test_fieldRefersToTopLevelGetter() async {
    await assertNoErrorsInCode('''
class C {
  final x = y;
}
int get y => null;
''');
    var x = _resultUnitElement.classes[0].fields[0];
    _assertTypeStr(x.type, 'int');
  }

  test_futureOr_subtyping() async {
    await assertErrorsInCode(r'''
void add(int x) {}
add2(int y) {}
main() {
  Future<int> f;
  var a = f.then(add);
  var b = f.then(add2);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 1),
    ]);
  }

  test_futureThen() async {
    String build(
            {required String declared,
            required String downwards,
            required String upwards}) =>
        '''
import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void main() {
  $declared f;
  $downwards<int> t1 = f.then((_) async => await new $upwards<int>.value(1));
  $downwards<int> t2 = f.then((_) async {
     return await new $upwards<int>.value(2);});
  $downwards<int> t3 = f.then((_) async => 3);
  $downwards<int> t4 = f.then((_) async {
    return 4;});
  $downwards<int> t5 = f.then((_) => new $upwards<int>.value(5));
  $downwards<int> t6 = f.then((_) {return new $upwards<int>.value(6);});
  $downwards<int> t7 = f.then((_) async => new $upwards<int>.value(7));
  $downwards<int> t8 = f.then((_) async {
    return new $upwards<int>.value(8);});
}
''';

    await _assertNoErrors(
        build(declared: "MyFuture", downwards: "Future", upwards: "Future"));
    await _assertNoErrors(
        build(declared: "MyFuture", downwards: "Future", upwards: "MyFuture"));
    await _assertNoErrors(
        build(declared: "MyFuture", downwards: "MyFuture", upwards: "Future"));
    await _assertNoErrors(build(
        declared: "MyFuture", downwards: "MyFuture", upwards: "MyFuture"));
    await _assertNoErrors(
        build(declared: "Future", downwards: "Future", upwards: "MyFuture"));
    await _assertNoErrors(
        build(declared: "Future", downwards: "Future", upwards: "Future"));
  }

  test_futureThen_conditional() async {
    String build(
            {required String declared,
            required String downwards,
            required String upwards}) =>
        '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void main() {
  $declared<bool> f;
  $downwards<int> t1 = f.then(
      (x) async => x ? 2 : await new $upwards<int>.value(3));
  $downwards<int> t2 = f.then((x) async { // TODO(leafp): Why the duplicate here?
    return await x ? 2 : new $upwards<int>.value(3);});
  $downwards<int> t5 = f.then(
      (x) => x ? 2 : new $upwards<int>.value(3));
  $downwards<int> t6 = f.then(
      (x) {return x ? 2 : new $upwards<int>.value(3);});
}
''';
    await _assertNoErrors(
        build(declared: "MyFuture", downwards: "Future", upwards: "Future"));
    disposeAnalysisContextCollection();

    await _assertNoErrors(
        build(declared: "MyFuture", downwards: "Future", upwards: "MyFuture"));
    disposeAnalysisContextCollection();

    await _assertNoErrors(
        build(declared: "MyFuture", downwards: "MyFuture", upwards: "Future"));
    disposeAnalysisContextCollection();

    await _assertNoErrors(build(
        declared: "MyFuture", downwards: "MyFuture", upwards: "MyFuture"));
    disposeAnalysisContextCollection();

    await _assertNoErrors(
        build(declared: "Future", downwards: "Future", upwards: "MyFuture"));
    disposeAnalysisContextCollection();

    await _assertNoErrors(
        build(declared: "Future", downwards: "Future", upwards: "Future"));
    disposeAnalysisContextCollection();
  }

  test_futureThen_downwardsMethodTarget() async {
    // Not working yet, see: https://github.com/dart-lang/sdk/issues/27114
    await assertErrorsInCode(r'''
main() {
  Future<int> f;
  Future<List<int>> b = f
      .then((x) => [])
      .whenComplete(() {});
  b = f.then((x) => []);
}
  ''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
  }

  test_futureThen_explicitFuture() async {
    await assertErrorsInCode(r'''
m1() {
  Future<int> f;
  var x = f.then<Future<List<int>>>((x) => []);
  Future<List<int>> y = x;
}
m2() {
  Future<int> f;
  var x = f.then<List<int>>((x) => []);
  Future<List<int>> y = x;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 67, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 92, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 96, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 185, 1),
    ]);
  }

  test_futureThen_upwards() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27088.
    String build(
            {required String declared,
            required String downwards,
            required String upwards}) =>
        '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void main() {
  var f = foo().then((_) => 2.3);
  $downwards<int> f2 = f;

  // The unnecessary cast is to illustrate that we inferred <double> for
  // the generic type args, even though we had a return type context.
  $downwards<num> f3 = foo().then(
      (_) => 2.3) as $upwards<double>;
}
$declared foo() => new $declared<int>.value(1);
    ''';

    await assertErrorsInCode(
      build(declared: "MyFuture", downwards: "Future", upwards: "Future"),
      [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 309, 2),
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 314, 1),
        error(HintCode.UNUSED_LOCAL_VARIABLE, 475, 2),
        error(HintCode.UNNECESSARY_CAST, 480, 47),
      ],
    );
    disposeAnalysisContextCollection();

    await assertErrorsInCode(
      build(declared: "MyFuture", downwards: "MyFuture", upwards: "MyFuture"),
      [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 311, 2),
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 316, 1),
        error(HintCode.UNUSED_LOCAL_VARIABLE, 479, 2),
        error(HintCode.UNNECESSARY_CAST, 484, 49),
      ],
    );
    disposeAnalysisContextCollection();

    await assertErrorsInCode(
      build(declared: "Future", downwards: "Future", upwards: "Future"),
      [
        error(HintCode.UNUSED_LOCAL_VARIABLE, 309, 2),
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 314, 1),
        error(HintCode.UNUSED_LOCAL_VARIABLE, 475, 2),
        error(HintCode.UNNECESSARY_CAST, 480, 47),
      ],
    );
    disposeAnalysisContextCollection();
  }

  test_futureThen_upwardsFromBlock() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27113.
    await assertErrorsInCode(r'''
main() {
  Future<int> base;
  var f = base.then((x) { return x == 0; });
  var g = base.then((x) => x == 0);
  Future<bool> b = f;
  b = g;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 125, 1),
    ]);
  }

  test_futureUnion_asyncConditional() async {
    String build(
            {required String downwards,
            required String upwards,
            String expectedInfo = ''}) =>
        '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(x) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

$downwards<int> g1(bool x) async {
  return x ? 42 : new $upwards.value(42); }
$downwards<int> g2(bool x) async =>
  x ? 42 : new $upwards.value(42);
$downwards<int> g3(bool x) async {
  var y = x ? 42 : ${expectedInfo}new $upwards.value(42);
  return y;
}
    ''';

    await assertNoErrorsInCode(
      build(downwards: "Future", upwards: "Future", expectedInfo: ''),
    );
    disposeAnalysisContextCollection();

    await assertNoErrorsInCode(
      build(downwards: "Future", upwards: "MyFuture"),
    );
    disposeAnalysisContextCollection();
  }

  test_futureUnion_downwards() async {
    String build(
        {required String declared,
        required String downwards,
        required String upwards,
        String expectedError = ''}) {
      return '''
import 'dart:async';
class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([x]) {}
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

$declared f;
// Instantiates Future<int>
$downwards<int> t1 = f.then((_) =>
   new $upwards.value($expectedError'hi'));

// Instantiates List<int>
$downwards<List<int>> t2 = f.then((_) => [3]);
$downwards<List<int>> g2() async { return [3]; }
$downwards<List<int>> g3() async {
  return new $upwards.value(
      [3]); }
''';
    }

    await assertErrorsInCode(
      build(
        declared: "MyFuture",
        downwards: "Future",
        upwards: "Future",
        expectedError: '',
      ),
      [
        error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 338, 4),
      ],
    );
    disposeAnalysisContextCollection();

    await assertErrorsInCode(
      build(
        declared: "MyFuture",
        downwards: "Future",
        upwards: "MyFuture",
      ),
      [],
    );
    disposeAnalysisContextCollection();

    await assertErrorsInCode(
      build(
        declared: "Future",
        downwards: "Future",
        upwards: "Future",
        expectedError: '',
      ),
      [
        error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 336, 4),
      ],
    );
    disposeAnalysisContextCollection();

    await assertErrorsInCode(
      build(
        declared: "Future",
        downwards: "Future",
        upwards: "MyFuture",
      ),
      [],
    );
    disposeAnalysisContextCollection();
  }

  test_futureUnion_downwardsGenericMethodWithFutureReturn() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27134
    //
    // We need to take a future union into account for both directions of
    // generic method inference.
    await assertErrorsInCode(r'''
foo() async {
  Future<List<A>> f1 = null;
  Future<List<A>> f2 = null;
  List<List<A>> merged = await Future.wait([f1, f2]);
}

class A {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 88, 6),
    ]);
  }

  test_futureUnion_downwardsGenericMethodWithGenericReturn() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27284
    await assertErrorsInCode(r'''
T id<T>(T x) => x;

main() async {
  Future<String> f;
  String s = await id(f);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 64, 1),
    ]);
  }

  test_futureUnion_upwardsGenericMethods() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/27151
    await assertErrorsInCode(r'''
main() async {
  var b = new Future<B>.value(new B());
  var c = new Future<C>.value(new C());
  var lll = [b, c];
  var result = await Future.wait(lll);
  var result2 = await Future.wait([b, c]);
  List<A> list = result;
  list = result2;
}

class A {}
class B extends A {}
class C extends A {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 207, 4),
    ]);
  }

  test_genericFunctions_returnTypedef() async {
    await assertErrorsInCode(r'''
typedef void ToValue<T>(T value);

main() {
  ToValue<T> f<T>(T x) => null;
  var x = f<int>(42);
  var y = f(42);
  ToValue<int> takesInt = x;
  takesInt = y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 130, 8),
    ]);
  }

  test_genericMethods_basicDownwardInference() async {
    await assertErrorsInCode(r'''
T f<S, T>(S s) => null;
main() {
  String x = f(42);
  String y = (f)(42);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 42, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);
  }

  test_genericMethods_dartMathMinMax() async {
    await assertErrorsInCode('''
import 'dart:math';

void printInt(int x) => print(x);
void printDouble(double x) => print(x);

num myMax(num x, num y) => max(x, y);

main() {
  // Okay if static types match.
  printInt(max(1, 2));
  printInt(min(1, 2));
  printDouble(max(1.0, 2.0));
  printDouble(min(1.0, 2.0));

  // No help for user-defined functions from num->num->num.
  printInt(myMax(1, 2));
  printInt(myMax(1, 2) as int);

  // An int context means doubles are rejected
  printInt(max(1, 2.0));
  printInt(min(1, 2.0));
  // A double context means ints are accepted as doubles
  printDouble(max(1, 2.0));
  printDouble(min(1, 2.0));

  // Types other than int and double are not accepted.
  printInt(min("hi", "there"));
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 467, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 492, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 683, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 689, 7),
    ]);
  }

  test_genericMethods_doNotInferInvalidOverrideOfGenericMethod() async {
    await assertErrorsInCode('''
class C {
T m<T>(T x) => x;
}
class D extends C {
m(x) => x;
}
main() {
  int y = new D().m<int>(42);
  print(y);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 50, 1,
          contextMessages: [message('/home/test/lib/test.dart', 12, 1)]),
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD, 91, 5),
    ]);
  }

  test_genericMethods_downwardsInferenceAffectsArguments() async {
    await assertErrorsInCode(r'''
T f<T>(List<T> s) => null;
main() {
  String x = f(['hi']);
  String y = f([42]);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 69, 1),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 76, 2),
    ]);
  }

  test_genericMethods_downwardsInferenceFold() async {
    // Regression from https://github.com/dart-lang/sdk/issues/25491
    // The first example works now, but the latter requires a full solution to
    // https://github.com/dart-lang/sdk/issues/25490
    await assertErrorsInCode(r'''
void main() {
  List<int> o;
  int y = o.fold(0, (x, y) => x + y);
  var z = o.fold(0, (x, y) => x + y);
  y = z;
}
void functionExpressionInvocation() {
  List<int> o;
  int y = (o.fold)(0, (x, y) => x + y);
  var z = (o.fold)(0, (x, y) => x + y);
  y = z;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 175, 1),
    ]);
  }

  test_genericMethods_handleOverrideOfNonGenericWithGeneric() async {
    // Regression test for crash when adding genericity
    await assertErrorsInCode('''
class C {
  m(x) => x;
  dynamic g(int x) => x;
}
class D extends C {
  T m<T>(T x) => x;
  T g<T>(T x) => x;
}
main() {
  int y = (new D() as C).m(42);
  print(y);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 74, 1,
          contextMessages: [message('/home/test/lib/test.dart', 12, 1)]),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 94, 1,
          contextMessages: [message('/home/test/lib/test.dart', 33, 1)]),
      error(HintCode.UNNECESSARY_CAST, 132, 12),
    ]);
  }

  test_genericMethods_inferenceError() async {
    await assertErrorsInCode(r'''
main() {
  List<String> y;
  Iterable<String> x = y.map((String z) => 1.0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 46, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE, 70, 3),
    ]);
  }

  test_genericMethods_inferGenericFunctionParameterType() async {
    await assertNoErrorsInCode('''
class C<T> extends D<T> {
  f<U>(x) { return null; }
}
class D<T> {
  F<U> f<U>(U u) => null;
}
typedef void F<V>(V v);
''');
    var f = _resultUnitElement.getType('C')!.methods[0];
    _assertTypeStr(f.type, 'void Function(U) Function<U>(U)');
  }

  test_genericMethods_inferGenericFunctionParameterType2() async {
    await assertNoErrorsInCode('''
class C<T> extends D<T> {
  f<U>(g) => null;
}
abstract class D<T> {
  void f<U>(G<U> g);
}
typedef List<V> G<V>();
''');
    var f = _resultUnitElement.getType('C')!.methods[0];
    _assertTypeStr(f.type, 'void Function<U>(List<U> Function())');
  }

  test_genericMethods_inferGenericFunctionReturnType() async {
    await assertNoErrorsInCode('''
class C<T> extends D<T> {
  f<U>(x) { return null; }
}
class D<T> {
  F<U> f<U>(U u) => null;
}
typedef V F<V>();
''');
    var f = _resultUnitElement.getType('C')!.methods[0];
    _assertTypeStr(f.type, 'U Function() Function<U>(U)');
  }

  test_genericMethods_inferGenericMethodType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25668
    await assertNoErrorsInCode('''
class C {
  T m<T>(T x) => x;
}
class D extends C {
  m<S>(x) => x;
}
main() {
  int y = new D().m<int>(42);
  print(y);
}
''');
  }

  test_genericMethods_IterableAndFuture() async {
    await assertErrorsInCode('''
Future<int> make(int x) => (new Future(() => x));

main() {
  Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
  Future<List<int>> results = Future.wait(list);
  Future<String> results2 = results.then((List<int> list)
    => list.fold('', (x, y) => x + y.toString()));

  Future<String> results3 = results.then((List<int> list)
    => list.fold('', (String x, y) => x + y.toString()));

  Future<String> results4 = results.then((List<int> list)
    => list.fold<String>('', (x, y) => x + y.toString()));
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 183, 8),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 257, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 293, 8),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 355, 33),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 410, 8),
    ]);
  }

  test_genericMethods_nestedGenericInstantiation() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;
class Trace {
  List<Frame> frames = [];
}
class Frame {
  String location = '';
}
main() {
  List<Trace> traces = [];
  var longest = traces.map((trace) {
    return trace.frames.map((frame) => frame.location.length)
        .fold(0, math.max);
  }).fold(0, math.max);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 153, 7),
    ]);
  }

  test_genericMethods_usesGreatestLowerBound() async {
    await assertErrorsInCode(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;

main() {
  var v = generic((F f) => null, (G g) => null);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 118, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int> Function(num)');
  }

  test_genericMethods_usesGreatestLowerBound_topLevel() async {
    await assertNoErrorsInCode(r'''
typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => null;

var v = generic((F f) => null, (G g) => null);
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<int> Function(num)');
  }

  test_infer_assignToIndex() async {
    await assertNoErrorsInCode(r'''
List<double> a = <double>[];
var b = (a[0] = 1.0);
''');
  }

  test_infer_assignToProperty() async {
    await assertNoErrorsInCode(r'''
class A {
  int f;
}
var v_assign = (new A().f = 1);
var v_plus = (new A().f += 1);
var v_minus = (new A().f -= 1);
var v_multiply = (new A().f *= 1);
var v_prefix_pp = (++new A().f);
var v_prefix_mm = (--new A().f);
var v_postfix_pp = (new A().f++);
var v_postfix_mm = (new A().f--);
''');
  }

  test_infer_assignToProperty_custom() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator +(other) => this;
  A operator -(other) => this;
}
class B {
  A a;
}
var v_prefix_pp = (++new B().a);
var v_prefix_mm = (--new B().a);
var v_postfix_pp = (new B().a++);
var v_postfix_mm = (new B().a--);
''');
  }

  test_infer_assignToRef() async {
    await assertNoErrorsInCode(r'''
class A {
  int f;
}
A a = new A();
var b = (a.f = 1);
var c = 0;
var d = (c = 1);
''');
  }

  test_infer_binary_custom() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator +(other) => 1;
  double operator -(other) => 2.0;
}
var v_add = new A() + 'foo';
var v_minus = new A() - 'bar';
''');
  }

  test_infer_binary_doubleDouble() async {
    await assertNoErrorsInCode(r'''
var a_equal = 1.0 == 2.0;
var a_notEqual = 1.0 != 2.0;
var a_add = 1.0 + 2.0;
var a_subtract = 1.0 - 2.0;
var a_multiply = 1.0 * 2.0;
var a_divide = 1.0 / 2.0;
var a_floorDivide = 1.0 ~/ 2.0;
var a_greater = 1.0 > 2.0;
var a_less = 1.0 < 2.0;
var a_greaterEqual = 1.0 >= 2.0;
var a_lessEqual = 1.0 <= 2.0;
var a_modulo = 1.0 % 2.0;
''');
  }

  test_infer_binary_doubleInt() async {
    await assertNoErrorsInCode(r'''
var a_equal = 1.0 == 2;
var a_notEqual = 1.0 != 2;
var a_add = 1.0 + 2;
var a_subtract = 1.0 - 2;
var a_multiply = 1.0 * 2;
var a_divide = 1.0 / 2;
var a_floorDivide = 1.0 ~/ 2;
var a_greater = 1.0 > 2;
var a_less = 1.0 < 2;
var a_greaterEqual = 1.0 >= 2;
var a_lessEqual = 1.0 <= 2;
var a_modulo = 1.0 % 2;
''');
  }

  test_infer_binary_intDouble() async {
    await assertNoErrorsInCode(r'''
var a_equal = 1 == 2.0;
var a_notEqual = 1 != 2.0;
var a_add = 1 + 2.0;
var a_subtract = 1 - 2.0;
var a_multiply = 1 * 2.0;
var a_divide = 1 / 2.0;
var a_floorDivide = 1 ~/ 2.0;
var a_greater = 1 > 2.0;
var a_less = 1 < 2.0;
var a_greaterEqual = 1 >= 2.0;
var a_lessEqual = 1 <= 2.0;
var a_modulo = 1 % 2.0;
''');
  }

  test_infer_binary_intInt() async {
    await assertNoErrorsInCode(r'''
var a_equal = 1 == 2;
var a_notEqual = 1 != 2;
var a_bitXor = 1 ^ 2;
var a_bitAnd = 1 & 2;
var a_bitOr = 1 | 2;
var a_bitShiftRight = 1 >> 2;
var a_bitShiftLeft = 1 << 2;
var a_add = 1 + 2;
var a_subtract = 1 - 2;
var a_multiply = 1 * 2;
var a_divide = 1 / 2;
var a_floorDivide = 1 ~/ 2;
var a_greater = 1 > 2;
var a_less = 1 < 2;
var a_greaterEqual = 1 >= 2;
var a_lessEqual = 1 <= 2;
var a_modulo = 1 % 2;
''');
  }

  test_infer_conditional() async {
    await assertNoErrorsInCode(r'''
var a = 1 == 2 ? 1 : 2.0;
var b = 1 == 2 ? 1.0 : 2;
''');
  }

  test_infer_prefixExpression() async {
    await assertNoErrorsInCode(r'''
var a_not = !true;
var a_complement = ~1;
var a_negate = -1;
''');
  }

  test_infer_prefixExpression_custom() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
  int operator ~() => 1;
  double operator -() => 2.0;
}
var a = new A();
var v_complement = ~a;
var v_negate = -a;
''');
  }

  test_infer_throw() async {
    await assertNoErrorsInCode(r'''
var t = true;
var a = (throw 0);
var b = (throw 0) ? 1 : 2;
var c = t ? (throw 1) : 2;
var d = t ? 1 : (throw 2);
''');
  }

  test_infer_typeCast() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T> extends A<T> {
  foo() {}
}
A<num> a = new B<int>();
var b = (a as B<int>);
main() {
  b.foo();
}
''');
  }

  test_infer_typedListLiteral() async {
    await assertNoErrorsInCode(r'''
var a = <int>[];
var b = <double>[1.0, 2.0, 3.0];
var c = <List<int>>[];
var d = <dynamic>[1, 2.0, false];
''');
  }

  test_infer_typedMapLiteral() async {
    await assertNoErrorsInCode(r'''
var a = <int, String>{0: 'aaa', 1: 'bbb'};
var b = <double, int>{1.1: 1, 2.2: 2};
var c = <List<int>, Map<String, double>>{};
var d = <int, dynamic>{};
var e = <dynamic, int>{};
var f = <dynamic, dynamic>{};
''');
  }

  test_infer_use_of_void() async {
    await assertNoErrorsInCode('''
class B {
  void f() {}
}
class C extends B {
  f() {}
}
var x = new C().f();
''');
    assertType(findElement.topVar('x').type, 'void');
  }

  test_inferConstsTransitively() async {
    newFile('$testPackageLibPath/b.dart', '''
const b1 = 2;
''');

    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
import 'b.dart';
const a1 = m2;
const a2 = b1;
''');

    await assertErrorsInCode('''
import 'a.dart';
const m1 = a1;
const m2 = a2;

foo() {
  int i;
  i = m1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);
  }

  test_inferCorrectlyOnMultipleVariablesDeclaredTogether() async {
    await assertErrorsInCode('''
class A {
  var x, y = 2, z = "hi";
}

class B implements A {
  var x = 2, y = 3, z, w = 2;
}

foo() {
  String s;
  int i;

  s = new B().x;
  s = new B().y;
  s = new B().z;
  s = new B().w;

  i = new B().x;
  i = new B().y;
  i = new B().z;
  i = new B().w;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 112, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 121, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 148, 9),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 182, 9),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 234, 9),
    ]);
  }

  test_inferFromComplexExpressionsIfOuterMostValueIsPrecise() async {
    await assertErrorsInCode('''
class A { int x; B operator+(other) => null; }
class B extends A { B(ignore); }
var a = new A();
// Note: it doesn't matter that some of these refer to 'x'.
var b = new B(x);  // allocations
var c1 = [x];      // list literals
var c2 = const [];
var d = <dynamic, dynamic>{'a': 'b'};     // map literals
var e = new A()..x = 3; // cascades
var f = 2 + 3;          // binary expressions are OK if the left operand
                        // is from a library in a different strongest
                        // connected component.
var g = -3;
var h = new A() + 3;
var i = - new A();
var j = null as B;

test1() {
  a = "hi";
  a = new B(3);
  b = "hi";
  b = new B(3);
  c1 = [];
  c1 = {};
  c2 = [];
  c2 = {};
  d = {};
  d = 3;
  e = new A();
  e = {};
  f = 3;
  f = false;
  g = 1;
  g = false;
  h = false;
  h = new B('b');
  i = false;
  j = new B('b');
  j = false;
  j = [];
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 171, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 201, 1),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 572, 1),
      error(HintCode.UNNECESSARY_CAST, 591, 9),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 619, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 647, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 687, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 709, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 729, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 753, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 772, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 794, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 807, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 869, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 882, 2),
    ]);
  }

  test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields() async {
    await assertErrorsInCode('''
class A {
  var x;
}

class B implements A {
  var x = 2;
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 78, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 99, 1),
    ]);
  }

  test_inferFromRhsOnlyIfItWontConflictWithOverriddenFields2() async {
    await assertErrorsInCode('''
class A {
  final x = null;
}

class B implements A {
  final x = 2;
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 110, 1),
    ]);
  }

  test_inferFromVariablesInCycleLibsWhenFlagIsOn() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
var x = 2; // ok to infer
''');

    await assertNoErrorsInCode('''
import 'a.dart';
var y = x; // now ok :)

test1() {
  // ignore:unused_local_variable
  int t = 3;
  t = x;
  t = y;
}
''');
  }

  test_inferFromVariablesInCycleLibsWhenFlagIsOn2() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
class A { static var x = 2; }
''');

    await assertNoErrorsInCode('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  // ignore:unused_local_variable
  int t = 3;
  t = A.x;
  t = B.y;
}
''');
  }

  test_inferFromVariablesInNonCycleImportsWithFlag() async {
    newFile('$testPackageLibPath/a.dart', '''
var x = 2;
''');

    await assertErrorsInCode('''
import 'a.dart';
var y = x;

test1() {
  x = "hi";
  y = "hi";
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 45, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 57, 4),
    ]);
  }

  test_inferFromVariablesInNonCycleImportsWithFlag2() async {
    newFile('$testPackageLibPath/a.dart', '''
class A { static var x = 2; }
''');

    await assertErrorsInCode('''
import 'a.dart';
class B { static var y = A.x; }

test1() {
  A.x = "hi";
  B.y = "hi";
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 68, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 82, 4),
    ]);
  }

  test_inferGenericMethodType_named() async {
    await assertErrorsInCode('''
class C {
  T m<T>(int a, {String b, T c}) => null;
}
main() {
 var y = new C().m(1, b: 'bbb', c: 2.0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 68, 1),
    ]);

    var y = findElement.localVar('y');
    _assertTypeStr(y.type, 'double');
  }

  test_inferGenericMethodType_positional() async {
    await assertErrorsInCode('''
class C {
  T m<T>(int a, [T b]) => null;
}
main() {
  var y = new C().m(1, 2.0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 59, 1),
    ]);

    var y = findElement.localVar('y');
    _assertTypeStr(y.type, 'double');
  }

  test_inferGenericMethodType_positional2() async {
    await assertErrorsInCode('''
class C {
  T m<T>(int a, [String b, T c]) => null;
}
main() {
  var y = new C().m(1, 'bbb', 2.0);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 69, 1),
    ]);

    var y = findElement.localVar('y');
    _assertTypeStr(y.type, 'double');
  }

  test_inferGenericMethodType_required() async {
    await assertErrorsInCode('''
class C {
  T m<T>(T x) => x;
}
main() {
  var y = new C().m(42);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);

    var y = findElement.localVar('y');
    _assertTypeStr(y.type, 'int');
  }

  test_inferListLiteralNestedInMapLiteral() async {
    await assertErrorsInCode(r'''
class Resource {}
class Folder extends Resource {}

Resource getResource(String str) => null;

class Foo<T> {
  Foo(T t);
}

main() {
  // List inside map
  var map = <String, List<Folder>>{
    'pkgA': [getResource('/pkgA/lib/')],
    'pkgB': [getResource('/pkgB/lib/')]
  };
  // Also try map inside list
  var list = <Map<String, Folder>>[
    { 'pkgA': getResource('/pkgA/lib/') },
    { 'pkgB': getResource('/pkgB/lib/') },
  ];
  // Instance creation too
  var foo = new Foo<List<Folder>>(
    [getResource('/pkgA/lib/')]
  );
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 161, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 313, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 467, 3),
    ]);
  }

  test_inferLocalFunctionReturnType() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26414
    await assertErrorsInCode(r'''
main() {
  f0 () => 42;
  f1 () async => 42;

  f2 () { return 42; }
  f3 () async { return 42; }
  f4 () sync* { yield 42; }
  f5 () async* { yield 42; }

  num f6() => 42;

  f7 () => f7();
  f8 () => f9();
  f9 () => f5();
}
''', [
      error(HintCode.UNUSED_ELEMENT, 11, 2),
      error(HintCode.UNUSED_ELEMENT, 26, 2),
      error(HintCode.UNUSED_ELEMENT, 48, 2),
      error(HintCode.UNUSED_ELEMENT, 71, 2),
      error(HintCode.UNUSED_ELEMENT, 100, 2),
      error(HintCode.UNUSED_ELEMENT, 162, 2),
      error(HintCode.UNUSED_ELEMENT, 177, 2),
      error(HintCode.UNUSED_ELEMENT, 194, 2),
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 203, 2,
          contextMessages: [message(testFilePath, 211, 2)]),
    ]);

    void assertLocalFunctionType(String name, String expected) {
      var type = findElement.localFunction(name).type;
      _assertTypeStr(type, expected);
    }

    assertLocalFunctionType('f0', 'int Function()');
    assertLocalFunctionType('f1', 'Future<int> Function()');

    assertLocalFunctionType('f2', 'int Function()');
    assertLocalFunctionType('f3', 'Future<int> Function()');
    assertLocalFunctionType('f4', 'Iterable<int> Function()');
    assertLocalFunctionType('f5', 'Stream<int> Function()');

    assertLocalFunctionType('f6', 'num Function()');

    // Recursive cases: these infer in declaration order.
    assertLocalFunctionType('f7', 'dynamic Function()');
    assertLocalFunctionType('f8', 'dynamic Function()');
    assertLocalFunctionType('f9', 'Stream<int> Function()');
  }

  test_inferParameterType_setter_fromField() async {
    await assertNoErrorsInCode('''
class C extends D {
  set foo(x) {}
}
class D {
  int foo;
}
''');
    var f = _resultUnitElement.getType('C')!.accessors[0];
    _assertTypeStr(f.type, 'void Function(int)');
  }

  test_inferParameterType_setter_fromSetter() async {
    await assertNoErrorsInCode('''
class C extends D {
  set foo(x) {}
}
class D {
  set foo(int x) {}
}
''');
    var f = _resultUnitElement.getType('C')!.accessors[0];
    _assertTypeStr(f.type, 'void Function(int)');
  }

  test_inferred_nonstatic_field_depends_on_static_field_complex() async {
    await assertNoErrorsInCode('''
class C {
  static var x = 'x';
  var y = {
    'a': {'b': 'c'},
    'd': {'e': x}
  };
}
''');
    var x = _resultUnitElement.getType('C')!.fields[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'String');
    var y = _resultUnitElement.getType('C')!.fields[1];
    expect(y.name, 'y');
    _assertTypeStr(y.type, 'Map<String, Map<String, String>>');
  }

  test_inferred_nonstatic_field_depends_on_toplevel_var_simple() async {
    await assertNoErrorsInCode('''
var x = 'x';
class C {
  var y = x;
}
''');
    var x = _resultUnitElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'String');
    var y = _resultUnitElement.getType('C')!.fields[0];
    expect(y.name, 'y');
    _assertTypeStr(y.type, 'String');
  }

  test_inferredInitializingFormalChecksDefaultValue() async {
    await assertErrorsInCode('''
class Foo {
  var x = 1;
  Foo([this.x = "1"]);
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 41, 3),
    ]);
  }

  test_inferredType_blockClosure_noArgs_noReturn() async {
    await assertErrorsInCode('''
main() {
  var f = () {};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var f = findElement.localVar('f');
    _assertTypeStr(f.type, 'Null Function()');
  }

  test_inferredType_cascade() async {
    await assertNoErrorsInCode('''
class A {
  int a;
  List<int> b;
  void m() {}
}
var v = new A()..a = 1..b.add(2)..m();
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'A');
  }

  test_inferredType_customBinaryOp() async {
    await assertNoErrorsInCode('''
class C {
  bool operator*(C other) => true;
}
C c;
var x = c*c;
''');
    var x = _resultUnitElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customBinaryOp_viaInterface() async {
    await assertNoErrorsInCode('''
class I {
  bool operator*(C other) => true;
}
abstract class C implements I {}
C c;
var x = c*c;
''');
    var x = _resultUnitElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customIndexOp() async {
    await assertErrorsInCode('''
class C {
  bool operator[](int index) => true;
}
main() {
  C c;
  var x = c[0];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 72, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customIndexOp_viaInterface() async {
    await assertErrorsInCode('''
class I {
  bool operator[](int index) => true;
}
abstract class C implements I {}
main() {
  C c;
  var x = c[0];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 105, 1),
    ]);

    var x = findElement.localVar('x');
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customUnaryOp() async {
    await assertNoErrorsInCode('''
class C {
  bool operator-() => true;
}
C c;
var x = -c;
''');
    var x = _resultUnitElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_customUnaryOp_viaInterface() async {
    await assertNoErrorsInCode('''
class I {
  bool operator-() => true;
}
abstract class C implements I {}
C c;
var x = -c;
''');
    var x = _resultUnitElement.topLevelVariables[1];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_extractMethodTearOff() async {
    await assertNoErrorsInCode('''
class C {
  bool g() => true;
}
C f() => null;
var x = f().g;
''');
    var x = _resultUnitElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool Function()');
  }

  test_inferredType_extractMethodTearOff_viaInterface() async {
    await assertNoErrorsInCode('''
class I {
  bool g() => true;
}
abstract class C implements I {}
C f() => null;
var x = f().g;
''');
    var x = _resultUnitElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool Function()');
  }

  test_inferredType_fromTopLevelExecutableTearoff() async {
    await assertNoErrorsInCode('''
var v = print;
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'void Function(Object)');
  }

  test_inferredType_invokeMethod() async {
    await assertNoErrorsInCode('''
class C {
  bool g() => true;
}
C f() => null;
var x = f().g();
''');
    var x = _resultUnitElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_invokeMethod_viaInterface() async {
    await assertNoErrorsInCode('''
class I {
  bool g() => true;
}
abstract class C implements I {}
C f() => null;
var x = f().g();
''');
    var x = _resultUnitElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'bool');
  }

  test_inferredType_isEnum() async {
    await assertNoErrorsInCode('''
enum E { v1 }
final x = E.v1;
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'E');
  }

  test_inferredType_isEnumValues() async {
    await assertNoErrorsInCode('''
enum E { v1 }
final x = E.values;
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'List<E>');
  }

  test_inferredType_isTypedef() async {
    await assertNoErrorsInCode('''
typedef void F();
final x = <String, F>{};
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Map<String, void Function()>');
  }

  test_inferredType_isTypedef_parameterized() async {
    await assertNoErrorsInCode('''
typedef T F<T>();
final x = <String, F<int>>{};
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Map<String, int Function()>');
  }

  test_inferredType_usesSyntheticFunctionType() async {
    await assertNoErrorsInCode('''
int f() => null;
String g() => null;
var v = [f, g];
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function()>');
  }

  test_inferredType_usesSyntheticFunctionType_functionTypedParam() async {
    await assertNoErrorsInCode('''
int f(int x(String y)) => null;
String g(int x(String y)) => null;
var v = [f, g];
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function(int Function(String))>');
  }

  test_inferredType_usesSyntheticFunctionType_namedParam() async {
    await assertNoErrorsInCode('''
int f({int x}) => null;
String g({int x}) => null;
var v = [f, g];
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function({int x})>');
  }

  test_inferredType_usesSyntheticFunctionType_positionalParam() async {
    await assertNoErrorsInCode('''
int f([int x]) => null;
String g([int x]) => null;
var v = [f, g];
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function([int])>');
  }

  test_inferredType_usesSyntheticFunctionType_requiredParam() async {
    await assertNoErrorsInCode('''
int f(int x) => null;
String g(int x) => null;
var v = [f, g];
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'List<Object Function(int)>');
  }

  test_inferredType_viaClosure_multipleLevelsOfNesting() async {
    await assertNoErrorsInCode('''
class C {
  static final f = (bool b) =>
      (int i) => {i: b};
}
''');
    var f = _resultUnitElement.getType('C')!.fields[0];
    _assertTypeStr(f.type, 'Map<int, bool> Function(int) Function(bool)');
  }

  test_inferredType_viaClosure_typeDependsOnArgs() async {
    await assertNoErrorsInCode('''
class C {
  static final f = (bool b) => b;
}
''');
    var f = _resultUnitElement.getType('C')!.fields[0];
    _assertTypeStr(f.type, 'bool Function(bool)');
  }

  test_inferredType_viaClosure_typeIndependentOfArgs_field() async {
    await assertNoErrorsInCode('''
class C {
  static final f = (bool b) => 1;
}
''');
    var f = _resultUnitElement.getType('C')!.fields[0];
    _assertTypeStr(f.type, 'int Function(bool)');
  }

  test_inferredType_viaClosure_typeIndependentOfArgs_topLevel() async {
    await assertNoErrorsInCode('''
final f = (bool b) => 1;
''');
    var f = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(f.type, 'int Function(bool)');
  }

  test_inferReturnOfStatementLambda() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26139
    await assertNoErrorsInCode(r'''
List<String> strings() {
  var stuff = [].expand((i) {
    return <String>[];
  });
  return stuff.toList();
}
  ''');
  }

  test_inferStaticsTransitively() async {
    newFile('$testPackageLibPath/b.dart', '''
final b1 = 2;
''');

    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
import 'b.dart';
final a1 = m2;
class A {
  static final a2 = b1;
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
final m1 = a1;
final m2 = A.a2;

foo() {
  // ignore:unused_local_variable
  int i;
  i = m1;
}
''');
  }

  test_inferStaticsTransitively2() async {
    await assertErrorsInCode('''
const x1 = 1;
final x2 = 1;
final y1 = x1;
final y2 = x2;

foo() {
  int i;
  i = y1;
  i = y2;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 73, 1),
    ]);
  }

  test_inferStaticsTransitively3() async {
    newFile('$testPackageLibPath/a.dart', '''
const a1 = 3;
const a2 = 4;
class A {
  static const a3 = null;
}
''');

    await assertNoErrorsInCode('''
import 'a.dart' show a1, A;
import 'a.dart' as p show a2, A;
const t1 = 1;
const t2 = t1;
const t3 = a1;
const t4 = p.a2;
const t5 = A.a3;
const t6 = p.A.a3;

foo() {
  // ignore:unused_local_variable
  int i;
  i = t1;
  i = t2;
  i = t3;
  i = t4;
}
''');
  }

  test_inferStaticsWithMethodInvocations() async {
    newFile('$testPackageLibPath/a.dart', '''
m3(String a, String b, [a1,a2]) {}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
class T {
  static final T foo = m1(m2(m3('', '')));
  static T m1(String m) { return null; }
  static String m2(e) { return ''; }
}
''');
  }

  test_inferTypeOnOverriddenFields2() async {
    await assertErrorsInCode('''
class A {
  int x = 2;
}

class B extends A {
  get x => 3;
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 80, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 84, 9),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 101, 1),
    ]);
  }

  test_inferTypeOnOverriddenFields4() async {
    await assertErrorsInCode('''
class A {
  final int x = 2;
}

class B implements A {
  get x => 3;
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 93, 9),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 110, 1),
    ]);
  }

  test_inferTypeOnVar() async {
    // Error also expected when declared type is `int`.
    await assertErrorsInCode('''
test1() {
  int x = 3;
  x = "hi";
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 4),
    ]);
  }

  test_inferTypeOnVar2() async {
    await assertErrorsInCode('''
test2() {
  var x = 3;
  x = "hi";
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 4),
    ]);
  }

  test_inferTypeOnVarFromField() async {
    await assertErrorsInCode('''
class A {
  int x = 0;

  test1() {
    var a = x;
    a = "hi";
    a = 3;
    var b = y;
    b = "hi";
    b = 4;
    var c = z;
    c = "hi";
    c = 4;
  }

  int y; // field def after use
  final z = 42; // should infer `int`
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 44, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 59, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 84, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 99, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 124, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 139, 4),
    ]);
  }

  test_inferTypeOnVarFromTopLevel() async {
    await assertErrorsInCode('''
int x = 0;

test1() {
  var a = x;
  a = "hi";
  a = 3;
  var b = y;
  b = "hi";
  b = 4;
  var c = z;
  c = "hi";
  c = 4;
}

int y = 0; // field def after use
final z = 42; // should infer `int`
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 28, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 41, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 75, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 96, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 109, 4),
    ]);
  }

  test_inferTypeRegardlessOfDeclarationOrderOrCycles() async {
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';

class B extends A { }
''');

    await assertErrorsInCode('''
import 'a.dart';
class C extends B {
  get x => null;
}
class A {
  int get x => 0;
}
foo() {
  int y = new C().x;
  String z = new C().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 100, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 124, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 128, 9),
    ]);
  }

  test_inferTypesOnGenericInstantiations_3() async {
    await assertErrorsInCode('''
class A<T> {
  final T x = null;
  final T w = null;
}

class B implements A<int> {
  get x => 3;
  get w => "hello";
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 109, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 138, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 142, 9),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 159, 1),
    ]);
  }

  test_inferTypesOnGenericInstantiations_4() async {
    await assertErrorsInCode('''
class A<T> {
  T x;
}

class B<E> extends A<E> {
  E y;
  get x => y;
}

foo() {
  int y = new B<String>().x;
  String z = new B<String>().x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 87, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 91, 17),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 119, 1),
    ]);
  }

  test_inferTypesOnGenericInstantiations_5() async {
    await assertErrorsInCode('''
abstract class I<E> {
  String m(a, String f(v, E e));
}

abstract class A<E> implements I<E> {
  const A();
  String m(a, String f(v, E e));
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  m(a, f(v, E e)) { return null; }
}

foo () {
  int y = new B().m(null, null);
  String z = new B().m(null, null);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 310, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 314, 21),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 346, 1),
    ]);
  }

  test_inferTypesOnGenericInstantiations_infer() async {
    await assertErrorsInCode('''
class A<T> {
  final T x = null;
}

class B implements A<int> {
  dynamic get x => 3;
}

foo() {
  String y = new B().x;
  int z = new B().x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 78, 1,
          contextMessages: [message('/home/test/lib/test.dart', 23, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 106, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 127, 1),
    ]);
  }

  test_inferTypesOnGenericInstantiationsInLibraryCycle() async {
    // Note: this is a regression test for bug #48.
    newFile('$testPackageLibPath/a.dart', '''
import 'test.dart';
abstract class I<E> {
  A<E> m(a, String f(v, int e));
}
''');

    await assertErrorsInCode('''
import 'a.dart';

abstract class A<E> implements I<E> {
  const A();

  final E value = null;
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  m(a, f(v, int e)) { return null; }
}

foo () {
  int y = new B<String>().m(null, null).value;
  String z = new B<String>().m(null, null).value;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 264, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 268, 35),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 314, 1),
    ]);
  }

  test_inferTypesOnLoopIndices_forEachLoop() async {
    await assertErrorsInCode('''
class Foo {
  int bar = 42;
}

class Bar<T extends Iterable<String>> {
  void foo(T t) {
    for (var i in t) {
      int x = i;
    }
  }
}

class Baz<T, E extends Iterable<T>, S extends E> {
  void foo(S t) {
    for (var i in t) {
      int x = i;
      T y = i;
    }
  }
}

test() {
  var list = <Foo>[];
  for (var x in list) {
    String y = x;
  }

  for (dynamic x in list) {
    String y = x;
  }

  for (String x in list) {
    String y = x;
  }

  var z;
  for(z in list) {
    String y = z;
  }

  Iterable iter = list;
  for (Foo x in iter) {
    var y = x;
  }

  dynamic iter2 = list;
  for (Foo x in iter2) {
    var y = x;
  }

  var map = <String, Foo>{};
  // Error: map must be an Iterable.
  for (var x in map) {
    String y = x;
  }

  // We're not properly inferring that map.keys is an Iterable<String>
  // and that x is a String.
  for (var x in map.keys) {
    String y = x;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 122, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 126, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 244, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 248, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 259, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 345, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 349, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 396, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 427, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 446, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 497, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 565, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 634, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 728, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 746, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 897, 1),
    ]);
  }

  test_inferTypesOnLoopIndices_forLoopWithInference() async {
    await assertErrorsInCode('''
test() {
  for (var i = 0; i < 10; i++) {
    int j = i + 1;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 50, 1),
    ]);
  }

  test_inferVariableVoid() async {
    await assertNoErrorsInCode('''
void f() {}
var x = f();
  ''');
    var x = _resultUnitElement.topLevelVariables[0];
    expect(x.name, 'x');
    _assertTypeStr(x.type, 'void');
  }

  test_lambdaDoesNotHavePropagatedTypeHint() async {
    await assertNoErrorsInCode(r'''
List<String> getListOfString() => const <String>[];

void foo() {
  List myList = getListOfString();
  myList.map((type) => 42);
}

void bar() {
  var list;
  try {
    list = <String>[];
  } catch (_) {
    return;
  }
  list.map((value) => '$value');
}
  ''');
  }

  test_listLiterals() async {
    await assertErrorsInCode(r'''
test1() {
  var x = [1, 2, 3];
  x.add('hi');
  x.add(4.0);
  x.add(4);
  List<num> y = x;
}
test2() {
  var x = [1, 2.0, 3];
  x.add('hi');
  x.add(4.0);
  List<int> y = x;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 39, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 54, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 84, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 134, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 167, 1),
    ]);
  }

  test_listLiterals_topLevel() async {
    await assertErrorsInCode(r'''
var x1 = [1, 2, 3];
test1() {
  x1.add('hi');
  x1.add(4.0);
  x1.add(4);
  List<num> y = x1;
}
var x2 = [1, 2.0, 3];
test2() {
  x2.add('hi');
  x2.add(4.0);
  List<int> y = x2;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 39, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 55, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 86, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 137, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 171, 1),
    ]);
  }

  test_listLiteralsCanInferNull_topLevel() async {
    await assertNoErrorsInCode(r'''
var x = [null];
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'List<Null>');
  }

  test_listLiteralsCanInferNullBottom() async {
    await assertErrorsInCode(r'''
test1() {
  var x = [null];
  x.add(42);
}
''', [
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL, 36, 2),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'List<Null>');
  }

  test_mapLiterals() async {
    await assertErrorsInCode(r'''
test1() {
  var x = { 1: 'x', 2: 'y' };
  x[3] = 'z';
  x['hi'] = 'w';
  x[4.0] = 'u';
  x[3] = 42;
  Map<num, String> y = x;
}

test2() {
  var x = { 1: 'x', 2: 'y', 3.0: new RegExp('.') };
  x[3] = 'z';
  x['hi'] = 'w';
  x[4.0] = 'u';
  x[3] = 42;
  Pattern p = null;
  x[2] = p;
  Map<int, String> y = x;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 58, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 75, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 96, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 119, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 209, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 247, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 302, 1),
    ]);
  }

  test_mapLiterals_topLevel() async {
    await assertErrorsInCode(r'''
var x1 = { 1: 'x', 2: 'y' };
test1() {
  x1[3] = 'z';
  x1['hi'] = 'w';
  x1[4.0] = 'u';
  x1[3] = 42;
  Map<num, String> y = x1;
}

var x2 = { 1: 'x', 2: 'y', 3.0: new RegExp('.') };
test2() {
  x2[3] = 'z';
  x2['hi'] = 'w';
  x2[4.0] = 'u';
  x2[3] = 42;
  Pattern p = null;
  x2[2] = p;
  Map<int, String> y = x2;
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 59, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 77, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 99, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 122, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 214, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 254, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 310, 1),
    ]);
  }

  test_mapLiteralsCanInferNull() async {
    await assertErrorsInCode(r'''
test1() {
  var x = { null: null };
  x[3] = 'z';
}
''', [
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL, 40, 1),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL, 45, 3),
    ]);

    var x = findElement.localVar('x');
    _assertTypeStr(x.type, 'Map<Null, Null>');
  }

  test_mapLiteralsCanInferNull_topLevel() async {
    await assertNoErrorsInCode(r'''
var x = { null: null };
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Map<Null, Null>');
  }

  test_methodCall_withTypeArguments_instanceMethod() async {
    await assertNoErrorsInCode('''
class C {
  D<T> f<T>() => null;
}
class D<T> {}
var f = new C().f<int>();
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'D<int>');
  }

  test_methodCall_withTypeArguments_instanceMethod_identifierSequence() async {
    await assertNoErrorsInCode('''
class C {
  D<T> f<T>() => null;
}
class D<T> {}
C c;
var f = c.f<int>();
''');
    var v = _resultUnitElement.topLevelVariables[1];
    expect(v.name, 'f');
    _assertTypeStr(v.type, 'D<int>');
  }

  test_methodCall_withTypeArguments_staticMethod() async {
    await assertNoErrorsInCode('''
class C {
  static D<T> f<T>() => null;
}
class D<T> {}
var f = C.f<int>();
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'D<int>');
  }

  test_methodCall_withTypeArguments_topLevelFunction() async {
    await assertNoErrorsInCode('''
D<T> f<T>() => null;
class D<T> {}
var g = f<int>();
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'D<int>');
  }

  test_noErrorWhenDeclaredTypeIsNumAndAssignedNull() async {
    await assertErrorsInCode('''
test1() {
  num x = 3;
  x = null;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 16, 1),
    ]);
  }

  test_nullCoalescingOperator() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26552
    await assertErrorsInCode(r'''
main() {
  List<int> x;
  var y = x ?? [];
  List<int> z = y;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 55, 1),
    ]);
  }

  test_nullCoalescingOperator2() async {
    // Don't do anything if we already have a context type.
    await assertErrorsInCode(r'''
main() {
  List<int> x;
  List<num> y = x ?? [];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);

    var y = findElement.localVar('y');
    _assertTypeStr(y.type, 'List<num>');
  }

  test_nullLiteralShouldNotInferAsBottom() async {
    // Regression test for https://github.com/dart-lang/dev_compiler/issues/47
    await assertErrorsInCode(r'''
var h = null;
void foo(int f(Object _)) {}

main() {
  var f = (Object x) => null;
  String y = f(42);

  f = (x) => 'hello';

  var g = null;
  g = 'hello';
  (g.foo());

  h = 'hello';
  (h.foo());

  foo((x) => null);
  foo((x) => throw "not implemented");
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 92, 1),
      error(CompileTimeErrorCode.INVALID_CAST_LITERAL, 117, 7),
    ]);
  }

  test_propagateInferenceToFieldInClass() async {
    await assertErrorsInCode('''
class A {
  int x = 2;
}

test() {
  var a = new A();
  A b = a;                      // doesn't require down cast
  print(a.x);     // doesn't require dynamic invoke
  print(a.x + 2); // ok to use in bigger expression
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
    ]);
  }

  test_propagateInferenceToFieldInClassDynamicWarnings() async {
    await assertErrorsInCode('''
class A {
  int x = 2;
}

test() {
  dynamic a = new A();
  A b = a;
  print(a.x);
  print((a.x) + 2);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);
  }

  test_propagateInferenceTransitively() async {
    await assertErrorsInCode('''
class A {
  int x = 2;
}

test5() {
  var a1 = new A();
  a1.x = "hi";

  A a2 = new A();
  a2.x = "hi";
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 65, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 99, 4),
    ]);
  }

  test_propagateInferenceTransitively2() async {
    await assertNoErrorsInCode('''
class A {
  int x = 42;
}

class B {
  A a = new A();
}

class C {
  B b = new B();
}

class D {
  C c = new C();
}

void main() {
  var d1 = new D();
  print(d1.c.b.a.x);

  D d2 = new D();
  print(d2.c.b.a.x);
}
''');
  }

  test_referenceToTypedef() async {
    await assertNoErrorsInCode('''
typedef void F();
final x = F;
''');
    var x = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(x.type, 'Type');
  }

  test_refineBinaryExpressionType_typeParameter_T_double() async {
    await assertErrorsInCode('''
class C<T extends num> {
  T a;

  void op(double b) {
    double r1 = a + b;
    double r2 = a - b;
    double r3 = a * b;
    double r4 = a / b;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 112, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 135, 2),
    ]);
  }

  test_refineBinaryExpressionType_typeParameter_T_int() async {
    await assertErrorsInCode('''
class C<T extends num> {
  T a;

  void op(int b) {
    T r1 = a + b;
    T r2 = a - b;
    T r3 = a * b;
  }

  void opEq(int b) {
    a += b;
    a -= b;
    a *= b;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 76, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 94, 2),
    ]);
  }

  test_refineBinaryExpressionType_typeParameter_T_T() async {
    await assertErrorsInCode('''
class C<T extends num> {
  T a;

  void op(T b) {
    T r1 = a + b;
    T r2 = a - b;
    T r3 = a * b;
  }

  void opEq(T b) {
    a += b;
    a -= b;
    a *= b;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 56, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 74, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 92, 2),
    ]);
  }

  test_staticMethod_tearoff() async {
    await assertNoErrorsInCode('''
const v = C.f;
class C {
  static int f(String s) => null;
}
''');
    var v = _resultUnitElement.topLevelVariables[0];
    _assertTypeStr(v.type, 'int Function(String)');
  }

  test_unsafeBlockClosureInference_closureCall() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26962
    await assertErrorsInCode('''
main() {
  var v = ((x) => 1.0)(() { return 1; });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'double');
  }

  test_unsafeBlockClosureInference_constructorCall_explicitDynamicParam() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T x());
}
var v = new C<dynamic>(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C<dynamic>');
  }

  test_unsafeBlockClosureInference_constructorCall_explicitTypeParam() async {
    await assertNoErrorsInCode('''
class C<T> {
  C(T x());
}
var v = new C<int>(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C<int>');
  }

  test_unsafeBlockClosureInference_constructorCall_implicitTypeParam() async {
    await assertErrorsInCode('''
class C<T> {
  C(T x());
}
main() {
  var v = new C(
    () {
      return 1;
    });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 42, 1),
    ]);

    var v = findElement.localVar('v');
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C<int>');
  }

  test_unsafeBlockClosureInference_constructorCall_noTypeParam() async {
    await assertNoErrorsInCode('''
class C {
  C(x());
}
var v = new C(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'C');
  }

  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam() async {
    await assertNoErrorsInCode('''
List<T> f<T>(T g()) => <T>[g()];
var v = f<dynamic>(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/25824')
  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr1() async {
    // Note: (f<dynamic>) is not a valid syntax.
    await assertNoErrorsInCode('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f<dynamic>)(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitDynamicParam_viaExpr2() async {
    await assertNoErrorsInCode('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f)<dynamic>(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitTypeParam() async {
    await assertNoErrorsInCode('''
List<T> f<T>(T g()) => <T>[g()];
var v = f<int>(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<int>');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/25824')
  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr1() async {
    // Note: (f<int>) is not a valid syntax.
    await assertNoErrorsInCode('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f<int>)(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_explicitTypeParam_viaExpr2() async {
    await assertNoErrorsInCode('''
List<T> f<T>(T g()) => <T>[g()];
var v = (f)<int>(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_implicitTypeParam() async {
    await assertErrorsInCode('''
main() {
  var v = f(
    () {
      return 1;
    });
}
List<T> f<T>(T g()) => <T>[g()];
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_implicitTypeParam_viaExpr() async {
    await assertErrorsInCode('''
main() {
  var v = (f)(
    () {
      return 1;
    });
}
List<T> f<T>(T g()) => <T>[g()];
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_functionCall_noTypeParam() async {
    await assertErrorsInCode('''
main() {
  var v = f(() { return 1; });
}
double f(x) => 1.0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'double');
  }

  test_unsafeBlockClosureInference_functionCall_noTypeParam_viaExpr() async {
    await assertErrorsInCode('''
main() {
  var v = (f)(() { return 1; });
}
double f(x) => 1.0;
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'double');
  }

  test_unsafeBlockClosureInference_inList_dynamic() async {
    await assertErrorsInCode('''
main() {
  var v = <dynamic>[() { return 1; }];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_inList_typed() async {
    await assertErrorsInCode('''
typedef int F();
main() {
  var v = <F>[() { return 1; }];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int Function()>');
  }

  test_unsafeBlockClosureInference_inList_untyped() async {
    await assertErrorsInCode('''
main() {
  var v = [
    () {
      return 1;
    }];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int Function()>');
  }

  test_unsafeBlockClosureInference_inMap_dynamic() async {
    await assertErrorsInCode('''
main() {
  var v = <int, dynamic>{1: () { return 1; }};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'Map<int, dynamic>');
  }

  test_unsafeBlockClosureInference_inMap_typed() async {
    await assertErrorsInCode('''
typedef int F();
main() {
  var v = <int, F>{1: () { return 1; }};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'Map<int, int Function()>');
  }

  test_unsafeBlockClosureInference_inMap_untyped() async {
    await assertErrorsInCode('''
main() {
  var v = {
    1: () {
      return 1;
    }};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'Map<int, int Function()>');
  }

  test_unsafeBlockClosureInference_methodCall_explicitDynamicParam() async {
    await assertErrorsInCode('''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f<dynamic>(() { return 1; });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<dynamic>');
  }

  test_unsafeBlockClosureInference_methodCall_explicitTypeParam() async {
    await assertErrorsInCode('''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f<int>(() { return 1; });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_methodCall_implicitTypeParam() async {
    await assertErrorsInCode('''
class C {
  List<T> f<T>(T g()) => <T>[g()];
}
main() {
  var v = new C().f(
    () {
      return 1;
    });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);

    var v = findElement.localVar('v');
    _assertTypeStr(v.type, 'List<int>');
  }

  test_unsafeBlockClosureInference_methodCall_noTypeParam() async {
    await assertNoErrorsInCode('''
class C {
  double f(x) => 1.0;
}
var v = new C().f(() { return 1; });
''');
    var v = _resultUnitElement.topLevelVariables[0];
    expect(v.name, 'v');
    _assertTypeStr(v.type, 'double');
  }

  test_voidReturnTypeEquivalentToDynamic() async {
    await assertErrorsInCode(r'''
T run<T>(T f()) {
  print("running");
  var t = f();
  print("done running");
  return t;
}


void printRunning() { print("running"); }
var x = run<dynamic>(printRunning);
var y = run(printRunning);

main() {
  void printRunning() { print("running"); }
  var x = run<dynamic>(printRunning);
  var y = run(printRunning);
  x = 123;
  x = 'hi';
  y = 123;
  y = 'hi';
}
  ''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 259, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 297, 1),
    ]);

    var x = _resultUnitElement.topLevelVariables[0];
    var y = _resultUnitElement.topLevelVariables[1];
    _assertTypeStr(x.type, 'dynamic');
    _assertTypeStr(y.type, 'void');
  }

  Future<void> _assertNoErrors(String code) async {
    await resolveTestCode(code);
    assertErrorsInList(
      result.errors.where((e) {
        return e.errorCode != HintCode.UNUSED_LOCAL_VARIABLE &&
            e.errorCode is! TodoCode;
      }).toList(),
      [],
    );
  }

  void _assertTypeStr(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
  }
}

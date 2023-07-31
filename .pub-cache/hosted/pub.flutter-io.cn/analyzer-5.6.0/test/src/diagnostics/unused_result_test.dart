// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedResultTest);
  });
}

@reflectiveTest
class UnusedResultTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_as() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {}
class B extends A {}

B createB() {
  return createA() as B;
}

@UseResult('')
A createA() {
  return B();
}
''');
  }

  test_as_without_usage() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {}
class B extends A {}

void test() {
  createA() as B;
}

@UseResult('')
A createA() {
  return B();
}
''', [
      error(HintCode.UNUSED_RESULT, 83, 7),
    ]);
  }

  test_callable() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {

  @useResult
  int call() => 1;
}

void f(A a) {
  a();
}
''', [
      error(HintCode.UNUSED_RESULT, 96, 1,
          text: "The value of 'a' should be used."),
    ]);
  }

  test_callable_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  B b() => B();
}
class B {
  @useResult
  int call(int i) => i;
}

void f(A a) {
  a.b()(5);
}
''', [
      error(HintCode.UNUSED_RESULT, 130, 1,
          text: "The value of 'b' should be used."),
    ]);
  }

  test_callable_propertyAccess() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  B get b => B();
}
class B {
  @useResult
  int call() => 1;
}

void f(A a) {
  a.b();
}
''', [
      error(HintCode.UNUSED_RESULT, 127, 1,
          text: "The value of 'b' should be used."),
    ]);
  }

  test_callable_recursive() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  B call(List l) => B();
}
class B {
  C call() => C();
}
class C {
  @useResult
  int call(String s) => 1;
}
void f(A a) {
  a([])()('');
}
''', [
      error(HintCode.UNUSED_RESULT, 170, 1,
          text: "The value of 'a' should be used."),
    ]);
  }

  test_field_result_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var bar = A().foo; // OK
  print(bar);
}
''');
  }

  test_field_result_assigned_conditional_else() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  var bar = b ? 0 : A().foo; // OK
  print(bar);
}
''');
  }

  test_field_result_assigned_conditional_if() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  var bar = b ? A().foo : 0; // OK
  print(bar);
}
''');
  }

  test_field_result_assigned_conditional_if_parens() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  var c = b ? (A().foo) : 0;
  print(c);
}
''');
  }

  test_field_result_assigned_parenthesized() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var bar = ((A().foo)); // OK
  print(bar);
}
''');
  }

  test_field_result_functionExpression_unused() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  Function foo = () {};
}

void main() {
  A().foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 104, 3),
    ]);
  }

  test_field_result_functionExpression_used() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  Function foo = () {};
}

void main() {
  A().foo();
}
''');
  }

  test_field_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  print(A().foo); // OK
}
''');
  }

  test_field_result_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

int f() => A().foo;
int f2() {
  return A().foo;
}
''');
  }

  test_field_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo = '';
}

void main() {
  A().foo.toString(); // OK
}
''');
  }

  test_field_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo = '';
}

void main() {
  A().foo.hashCode; // OK
}
''');
  }

  test_field_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  A().foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 95, 3),
    ]);
  }

  test_field_result_unassigned_conditional_if() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  b ? A().foo : 0;
}
''', [
      error(HintCode.UNUSED_RESULT, 102, 3),
    ]);
  }

  test_field_result_unassigned_conditional_if_parens() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  b ? (A().foo) : 0;
}
''', [
      error(HintCode.UNUSED_RESULT, 103, 3),
    ]);
  }

  test_field_result_unassigned_in_closure() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(Function g) { }

void main() {
  f(() {
    A().foo;
  });
}
''', [
      error(HintCode.UNUSED_RESULT, 130, 3),
    ]);
  }

  test_field_result_used_conditional_if_parens() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  (b ? A().foo : 0).toString();
}
''');
  }

  test_field_result_used_listLiteral() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var l = [ A().foo ]; // OK
  print(l);
  [ A().foo ]; // Also OK
}
''');
  }

  test_field_result_used_mapLiteral_key() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var m = { A().foo : 'baz'}; // OK
  print(m);
}
''');
  }

  test_field_result_used_mapLiteral_value() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var m = { 'baz': A().foo }; // OK
  print(m);
}
''');
  }

  test_field_result_used_setLiteral() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var s = { A().foo }; // OK
  print(s);
}
''');
  }

  test_field_static_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  static int foo = 0;
}

void main() {
  A.foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 100, 3),
    ]);
  }

  test_getter_expressionStatement_id_dotResult_dotId() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

void f(A a) {
  a.foo.isEven;
}
''');
  }

  test_getter_expressionStatement_result() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int get foo => 0;

void f() {
  foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 77, 3),
    ]);
  }

  test_getter_expressionStatement_result_dotId() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int get foo => 0;

void f() {
  foo.isEven;
}
''');
  }

  test_getter_expressionStatement_result_dotId_dotId() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int get foo => 0;

void f() {
  foo.isEven.hashCode;
}
''');
  }

  test_getter_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

void main() {
  print(A().foo); // OK
}
''');
  }

  test_getter_result_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

int f() => A().foo;
int f2() {
  return A().foo;
}
''');
  }

  test_getter_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String get foo =>  '';
}

void main() {
  A().foo.toString(); // OK
}
''');
  }

  test_getter_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String get foo => '';
}

void main() {
  A().foo.hashCode; // OK
}
''');
  }

  test_getter_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

void main() {
  A().foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 100, 3),
    ]);
  }

  test_import_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@useResult
bool foo() => true;

bool bar() => true;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' hide foo;

bool f() {
  return bar();
}
''');
  }

  test_import_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@useResult
bool foo() => true;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' show foo;

bool f() {
  return foo();
}
''');
  }

  test_method_result_assertInitializer() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

class B {
  B(A a) :
    assert(a.foo() != 7);
}
''');
  }

  test_method_result_assertStatement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

void f(A a) {
  assert(a.foo() != 7);
}
''');
  }

  test_method_result_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

void main() {
  var bar = A().foo(); // OK
  print(bar);
}
''');
  }

  test_method_result_binaryExpression() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

void f(A a) {
  1 + a.foo();
}
''');
  }

  test_method_result_conditional() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  if (a.foo()) {}
}
''');
  }

  test_method_result_constructorCall() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

class B {
  B(int i);
}

void f(A a) {
  new B(a.foo());
}
''');
  }

  test_method_result_doWhile() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  do {}
  while (a.foo());
}
''');
  }

  test_method_result_fieldInitializer() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

class B {
  int i;
  B(A a) : i = a.foo();
}
''');
  }

  test_method_result_for() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

void f(A a) {
  for (var i = 1; i < a.foo(); i++) {}
}
''');
  }

  test_method_result_for_updaters() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

void f(A a) {
  for (var i = 1; i < 7; a.foo()) {}
}
''', [
      error(HintCode.UNUSED_RESULT, 119, 3),
    ]);
  }

  test_method_result_forElement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  List<int> foo() => [];
}

void f(A a) {
  // Note that the list literal is unused, but we unconditionally consider use
  // within a list literal to be "use of result."
  [
    for (var e in a.foo()) e,
  ];
}
''');
  }

  test_method_result_forIn() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  List<int> foo() => [];
}

void f(A a) {
  for (var _ in a.foo()) {}
}
''');
  }

  test_method_result_ifElement() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  // Note that the list literal is unused, but we unconditionally consider use
  // within a list literal to be "use of result."
  [
    if (a.foo()) 1,
  ];
}
''');
  }

  test_method_result_ifNull() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int? foo() => 1;
}

int f(A a) {
  return a.foo() ?? 7;
}
''');
  }

  test_method_result_indexExpression() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

void f(A a, List<int> list) {
  list[a.foo()];
}
''');
  }

  test_method_result_nullCheck_isUsed() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int? foo() => 1;
}

int f(A a) {
  return a.foo()!;
}
''');
  }

  test_method_result_nullCheck_notUsed() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int? foo() => 1;
}

void f(A a) {
  a.foo()!;
}
''', [
      error(HintCode.UNUSED_RESULT, 97, 3),
    ]);
  }

  test_method_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

void main() {
  print(A().foo()); // OK
}
''');
  }

  test_method_result_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

int f() => A().foo();
int f2() {
  return A().foo();
}
''');
  }

  test_method_result_spread() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  List<int> foo() => [];
}

void f(A a) {
  // Note that the list literal is unused, but we unconditionally consider use
  // within a list literal to be "use of result."
  [...a.foo()];
}
''');
  }

  test_method_result_superInitializer() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

class B {
  B(int i);
}

class C extends B {
  C(A a) : super(a.foo());
}
''');
  }

  test_method_result_switchCondition() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  switch (a.foo()) {
    default:
  }
}
''');
  }

  test_method_result_switchCondition_language218() async {
    await assertNoErrorsInCode('''
// @dart = 2.18
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  switch (a.foo()) {}
}
''');
  }

  test_method_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @useResult
  String foo() => '';
}
void main() {
  A().foo().toString(); // OK
}
''');
  }

  test_method_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo() => '';
}

void main() {
  A().foo().hashCode; // OK
}
''');
  }

  test_method_result_thrown() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  throw a.foo();
}
''');
  }

  test_method_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

void main() {
  A().foo();
}
''', [
      error(HintCode.UNUSED_RESULT, 98, 3,
          text: "The value of 'foo' should be used."),
    ]);
  }

  test_method_result_unassigned_cascade() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @useResult
  C m1() => throw '';

  C m2() => throw '';

  void m3() {
    m2()..m1();
  }
}
''', [
      error(HintCode.UNUSED_RESULT, 127, 2,
          text: "The value of 'm1' should be used."),
    ]);
  }

  test_method_result_unassigned_parameterDefined() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @UseResult.unless(parameterDefined: 'value')
  int foo([int? value]) => value ?? 0;
}

void main() {
  A().foo(3);
}
''');
  }

  test_method_result_unassigned_parameterNotDefinedAndCascaded() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @UseResult.unless(parameterDefined: 'value')
  int foo([int? value]) => value ?? 0;
}

void main() {
  A().foo()..toString();
}
''');
  }

  test_method_result_while() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool foo() => false;
}

void f(A a) {
  while (a.foo()) {}
}
''');
  }

  test_method_result_yield() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 1;
}

Stream<int> f(A a) async* {
  yield a.foo();
}
''');
  }

  test_namedExpression() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int m() => 1;
}

void g({int? i}) {}

void f() {
  g(i: A().m());
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/47181
  test_prefixed_classMember() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool b() => true;
}

/// [A.b].
const a = 'a';
''');
  }

  /// https://github.com/dart-lang/sdk/issues/47181
  test_prefixed_importedMember() async {
    newFile('$testPackageLibPath/c.dart', '''
import 'package:meta/meta.dart';

class A {
  @useResult
  bool b() => true;
}
 ''');

    await assertNoErrorsInCode(r'''
import 'c.dart' as c;

/// [c.A.b].
const a = 'a';
''');
  }

  test_topLevelFunction_prefixExpression_bang() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
bool foo() => true;

bool f() {
  return !foo();
}
''');
  }

  test_topLevelFunction_prefixExpression_decrement() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 1;

int f() {
  return --foo;
}
''');
  }

  test_topLevelFunction_prefixExpression_increment() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 1;

int f() {
  return ++foo;
}
''');
  }

  test_topLevelFunction_prefixExpression_minus() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 1;

int f() {
  return -foo();
}
''');
  }

  test_topLevelFunction_prefixExpression_tilde() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 1;

int f() {
  return ~foo();
}
''');
  }

  test_topLevelFunction_result_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;

void main() {
  var x = foo(); // OK
  print(x);
}
''');
  }

  test_topLevelFunction_result_assigned_cascade() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;

void main() {
  var x = foo()..toString(); // OK
  print(x);
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/47473
  test_topLevelFunction_result_assigned_if() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
String foo() => '';

String f(bool b) {
  var f = '';
  if (b) f = foo();
  return f;
}
''');
  }

  test_topLevelFunction_result_awaited_future_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
Future<List<String>> load() async => [];

void f() async {
  var l = [];
  l.add(await load());
}
''');
  }

  test_topLevelFunction_result_optionNamedParam_unassigned_parameterDefined() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@UseResult.unless(parameterDefined: 'value')
int foo({int? value}) => value ?? 0;

void main() {
  foo(value: 3);
}
''');
  }

  test_topLevelFunction_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;

void main() {
  print(foo()); // OK
}
''');
  }

  test_topLevelFunction_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
String foo() => '';

void main() {
  foo().toString();
}
''');
  }

  test_topLevelFunction_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
String foo() => '';

void main() {
  foo().length;
}
''');
  }

  test_topLevelFunction_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;
void bar() {}
int baz() => 0;

void main() {
  foo();
  bar(); // OK
  baz(); // OK
}
''', [
      error(HintCode.UNUSED_RESULT, 108, 3),
    ]);
  }

  test_topLevelFunction_result_unassigned_parameterDefined() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@UseResult.unless(parameterDefined: 'value')
int foo([int? value]) => value ?? 0;

void main() {
  foo(3);
}
''');
  }

  test_topLevelFunction_result_unassigned_parameterUnDefined() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@UseResult.unless(parameterDefined: 'value')
int foo([int? value]) => value ?? 0;

void main() {
  foo();
}
''', [
      error(HintCode.UNUSED_RESULT, 133, 3),
    ]);
  }

  test_topLevelFunction_result_unassigned_parameterUnDefined2() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@UseResult.unless(parameterDefined: 'value')
int foo([String? msg, int? value]) => value ?? 0;

void main() {
  foo('none');
}
''', [
      error(HintCode.UNUSED_RESULT, 146, 3),
    ]);
  }

  test_topLevelFunction_result_used_in_cascade() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;

void main() {
  foo()..toString();
}
''');
  }

  test_topLevelVariable_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

void main() {
  var bar = foo; // OK
  print(bar);
}
''');
  }

  test_topLevelVariable_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

void main() {
  print(foo); // OK
}
''');
  }

  test_topLevelVariable_result_unusedInDoc() async {
    // https://github.com/dart-lang/sdk/issues/47181
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int get f => 1;

/// I love [f].
int g = 1;
''');
  }

  test_topLevelVariable_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

int bar() => foo; // OK
int baz() {
  return foo; // OK
}
''');
  }

  test_topLevelVariable_unused() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

void main() {
  foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 75, 3),
    ]);
  }
}

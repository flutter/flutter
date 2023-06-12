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
      error(HintCode.UNUSED_RESULT, 98, 3),
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
      error(HintCode.UNUSED_RESULT, 131, 2,
          messageContains: ["'m1' should be used."]),
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

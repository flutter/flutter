// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/dependency/library_builder.dart'
    hide buildLibrary;
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ApiReferenceCollectorTest);
    defineReflectiveTests(ExpressionReferenceCollectorTest);
    defineReflectiveTests(ImplReferenceCollectorTest);
    defineReflectiveTests(ShadowReferenceCollectorTest);
    defineReflectiveTests(StatementReferenceCollectorTest);
    defineReflectiveTests(TypeReferenceCollectorTest);
  });
}

final dartCoreUri = Uri.parse('dart:core');

@reflectiveTest
class ApiReferenceCollectorTest extends _Base {
  test_class_constructor_named_body() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C.test() {
    x;
  }
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR, memberOf: 'C');
  }

  test_class_constructor_named_parameter_defaultValue_named() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C.test({A a = x}) {}
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_constructor_named_parameter_defaultValue_positional() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C.test([A a = x]) {}
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_constructor_named_parameter_field_named() async {
    var library = await buildTestLibrary(a, r'''
class C {
  A f1;
  B f2;
  C.test({A this.f1: x, this.f2: y});
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_constructor_named_parameter_field_required() async {
    var library = await buildTestLibrary(a, r'''
class C {
  A f1;
  B f2;
  C.test(A this.f1, this.f2);
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_constructor_named_parameter_required() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C.test(A a, B b) {}
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A', 'B']);
  }

  test_class_constructor_unnamed_body() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C() {
    x;
  }
}
''');
    _assertApi(library, '', NodeKind.CONSTRUCTOR, memberOf: 'C');
  }

  test_class_constructor_unnamed_parameter_required() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C(A a, B b) {}
}
''');
    _assertApi(library, '', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A', 'B']);
  }

  test_class_field_hasType() async {
    var library = await buildTestLibrary(a, r'''
class C {
  int test = x;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['int']);
    _assertApi(library, 'test=', NodeKind.SETTER,
        memberOf: 'C', unprefixed: ['int']);
  }

  test_class_field_hasType_const() async {
    var library = await buildTestLibrary(a, r'''
class C {
  static const int test = x;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['int', 'x']);
  }

  test_class_field_hasType_final() async {
    var library = await buildTestLibrary(a, r'''
class C {
  final int test = x;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['int']);
  }

  test_class_field_hasType_noInitializer() async {
    var library = await buildTestLibrary(a, r'''
class C {
  int test;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['int']);
    _assertApi(library, 'test=', NodeKind.SETTER,
        memberOf: 'C', unprefixed: ['int']);
  }

  test_class_field_noType() async {
    var library = await buildTestLibrary(a, r'''
class C {
  var test = x;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['x']);
    _assertApi(library, 'test=', NodeKind.SETTER,
        memberOf: 'C', unprefixed: ['x']);
  }

  test_class_field_noType_const() async {
    var library = await buildTestLibrary(a, r'''
class C {
  static const test = x;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['x']);
  }

  test_class_field_noType_final() async {
    var library = await buildTestLibrary(a, r'''
class C {
  final test = x;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'C', unprefixed: ['x']);
  }

  test_class_field_noType_noInitializer() async {
    var library = await buildTestLibrary(a, r'''
class C {
  var test;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER, memberOf: 'C');
    _assertApi(library, 'test=', NodeKind.SETTER, memberOf: 'C');
  }

  test_class_method_body() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void test() {
    x;
  }
}
''');
    _assertApi(library, 'test', NodeKind.METHOD, memberOf: 'C');
  }

  test_class_method_parameter_defaultValue_named() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void test({A a = x}) {}
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_method_parameter_defaultValue_positional() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void test([A a = x]) {}
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_method_parameter_required() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void test(A a, B b) {}
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['A', 'B']);
  }

  test_class_method_returnType() async {
    var library = await buildTestLibrary(a, r'''
class C {
  A test() {}
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_method_typeParameter() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void test<T, U extends A, V extends U>(T t, U u, V v) {}
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['A']);
  }

  test_class_typeParameter() async {
    var library = await buildTestLibrary(a, r'''
class X<T extends A<B, C>> {}
''');
    _assertApi(library, 'T', NodeKind.TYPE_PARAMETER,
        typeParameterOf: 'X', unprefixed: ['A', 'B', 'C']);
  }

  test_unit_class() async {
    var library = await buildTestLibrary(a, r'''
class Test<T extends A, U extends T>
  extends B<T> with C, D<E, U>
  implements F<T>, G {
  void test() {
    x
  }
}
''');
    _assertApi(library, 'Test', NodeKind.CLASS,
        unprefixed: ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
  }

  test_unit_classTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
class Test = A with M1, M2 implements I1, I2;
''');
    _assertApi(library, 'Test', NodeKind.CLASS_TYPE_ALIAS,
        unprefixed: ['A', 'I1', 'I2', 'M1', 'M2']);
  }

  test_unit_classTypeAlias_generic() async {
    var library = await buildTestLibrary(a, r'''
class Test<T extends A, U extends T> = B<T> with C<U, D> implements E<T, F>;
''');
    _assertApi(library, 'Test', NodeKind.CLASS_TYPE_ALIAS,
        unprefixed: ['A', 'B', 'C', 'D', 'E', 'F']);
  }

  test_unit_function_body() async {
    var library = await buildTestLibrary(a, r'''
void test() {
  x;
}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_function_parameter_defaultValue_named() async {
    var library = await buildTestLibrary(a, r'''
void test({a = x}) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_function_parameter_defaultValue_positional() async {
    var library = await buildTestLibrary(a, r'''
void test([a = x]) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_function_parameter_named() async {
    var library = await buildTestLibrary(a, r'''
void test({A a, B b}) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_parameter_positional() async {
    var library = await buildTestLibrary(a, r'''
void test([A a, B b]) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_parameter_required() async {
    var library = await buildTestLibrary(a, r'''
void test(A a, B b) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_parameter_required_function() async {
    var library = await buildTestLibrary(a, r'''
void test(A Function(B) a) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_unit_function_parameter_required_functionTyped() async {
    var library = await buildTestLibrary(a, r'''
void test(A a(B b, C c)) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B', 'C']);
  }

  test_unit_function_returnType_absent() async {
    var library = await buildTestLibrary(a, r'''
test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_unit_function_returnType_interface() async {
    var library = await buildTestLibrary(a, r'''
A test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A']);
  }

  test_unit_function_typeParameter() async {
    var library = await buildTestLibrary(a, r'''
void test<T, U extends A, V extends U>(T t, U u, V v) {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A']);
  }

  test_unit_functionTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
typedef A<B, U> Test<T extends C, U extends T>(D d, T t, U u);
''');
    _assertApi(library, 'Test', NodeKind.FUNCTION_TYPE_ALIAS,
        unprefixed: ['A', 'B', 'C', 'D']);
  }

  test_unit_functionTypeAlias_reverseOrderTypeParameters() async {
    var library = await buildTestLibrary(a, r'''
typedef void Test<U extends T, T extends A>();
''');
    _assertApi(library, 'Test', NodeKind.FUNCTION_TYPE_ALIAS,
        unprefixed: ['A']);
  }

  test_unit_genericTypeAlias_function() async {
    var library = await buildTestLibrary(a, r'''
typedef Test<T extends A, U extends T> =
  B<T, C, V> Function<V extends D, W extends E<F, T, V>>(E, T, U, V, V, W);
''');
    _assertApi(library, 'Test', NodeKind.GENERIC_TYPE_ALIAS,
        unprefixed: ['A', 'B', 'C', 'D', 'E', 'F']);
  }

  test_unit_genericTypeAlias_function_reverseOrderTypeParameters() async {
    var library = await buildTestLibrary(a, r'''
typedef Test<U extends T, T extends A> = Function<W extends V, V extends B>();
''');
    _assertApi(library, 'Test', NodeKind.GENERIC_TYPE_ALIAS,
        unprefixed: ['A', 'B']);
  }

  test_unit_mixin() async {
    var library = await buildTestLibrary(a, r'''
mixin Test<T extends A, U extends T>
  on B<T>, C, D<E, U>
  implements F<T>, G {
  void test() {
    x
  }
}
''');
    _assertApi(library, 'Test', NodeKind.MIXIN,
        unprefixed: ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
  }

  test_unit_variable_hasType() async {
    var library = await buildTestLibrary(a, r'''
int test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int']);
    _assertApi(library, 'test=', NodeKind.SETTER, unprefixed: ['int']);
  }

  test_unit_variable_hasType_const() async {
    var library = await buildTestLibrary(a, r'''
const int test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int', 'x']);
  }

  test_unit_variable_hasType_final() async {
    var library = await buildTestLibrary(a, r'''
final int test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int']);
  }

  test_unit_variable_hasType_noInitializer() async {
    var library = await buildTestLibrary(a, r'''
int test;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['int']);
    _assertApi(library, 'test=', NodeKind.SETTER, unprefixed: ['int']);
  }

  test_unit_variable_noType() async {
    var library = await buildTestLibrary(a, r'''
var test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['x']);
    _assertApi(library, 'test=', NodeKind.SETTER, unprefixed: ['x']);
  }

  test_unit_variable_noType_const() async {
    var library = await buildTestLibrary(a, r'''
const test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['x']);
  }

  test_unit_variable_noType_final() async {
    var library = await buildTestLibrary(a, r'''
final test = x;
''');
    _assertApi(library, 'test', NodeKind.GETTER, unprefixed: ['x']);
  }

  test_unit_variable_noType_noInitializer() async {
    var library = await buildTestLibrary(a, r'''
var test;
''');
    _assertApi(library, 'test', NodeKind.GETTER);
    _assertApi(library, 'test=', NodeKind.SETTER);
  }
}

@reflectiveTest
class ExpressionReferenceCollectorTest extends _Base {
  test_adjacentStrings() async {
    var library = await buildTestLibrary(a, r'''
test() {
  'foo' '$x' 'bar';
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_asExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x as Y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['Y', 'x']);
  }

  test_assignmentExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x = y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x=', 'y']);
  }

  test_assignmentExpression_compound() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator+(_) {}
}

class B extends A {}

B x, y;

test() {
  x += y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'x=', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', '+')]);
  }

  test_assignmentExpression_nullAware() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x ??= y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'x=', 'y']);
  }

  test_awaitExpression() async {
    var library = await buildTestLibrary(a, r'''
test() async {
  await x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_binaryExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator+(_) {}
}

class B extends A {}

B x, y;

test() {
  x + y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', '+')]);
  }

  test_binaryExpression_int() async {
    var library = await buildTestLibrary(a, r'''
class A {
  int operator+(_) {}
}

A x;

test() {
  x + 1 + 2;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'A', '+'),
      _ExpectedClassMember(dartCoreUri, 'int', '+'),
    ]);
  }

  test_binaryExpression_sort() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator*(_) {}
}

class B {
  operator+(_) {}
}

A a;
B b;

test() {
  (b + 1) + a * 2;
}
''');
    _assertImpl(
      library,
      'test',
      NodeKind.FUNCTION,
      unprefixed: ['a', 'b'],
      expectedMembers: [
        _ExpectedClassMember(aUri, 'A', '*'),
        _ExpectedClassMember(aUri, 'B', '+'),
      ],
    );
  }

  test_binaryExpression_super() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class B extends A {
  test() {
    super + x;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'B', unprefixed: ['x'], superPrefixed: ['+']);
  }

  test_binaryExpression_super2() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class B extends A {
  test() {
    super == x;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'B', unprefixed: ['x'], superPrefixed: ['==']);
  }

  test_binaryExpression_unique() async {
    var library = await buildTestLibrary(a, r'''
class A {
  A operator+(_) => null;
}

A x;

test() {
  x + 1 + 2 + 3;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '+')]);
  }

  test_binaryExpression_unresolvedOperator() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x, y;

test() {
  x + y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '+')]);
  }

  test_binaryExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x + y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_booleanLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  true;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_cascadeExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x
    ..foo(y)
    ..bar = z;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x',
      'y',
      'z'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'A', 'bar='),
      _ExpectedClassMember(aUri, 'A', 'foo'),
    ]);
  }

  test_conditionalExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x ? y : z;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z']);
  }

  test_doubleLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  1.2;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_functionExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <T extends A, U extends T>(B b, C c, T t, U u) {
    T;
    U;
    x;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'x']);
  }

  test_functionExpressionInvocation() async {
    var library = await buildTestLibrary(a, r'''
test() {
  (x)<T>(y, z);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['T', 'x', 'y', 'z']);
  }

  test_indexExpression_get() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x[y];
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '[]')]);
  }

  test_indexExpression_getSet() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x[y] += x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x',
      'y'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'A', '[]'),
      _ExpectedClassMember(aUri, 'A', '[]=')
    ]);
  }

  test_indexExpression_set() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x[y] = x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '[]=')]);
  }

  test_indexExpression_super_get() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super[x];
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['x'], superPrefixed: ['[]']);
  }

  test_indexExpression_super_getSet() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super[x] += y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['x', 'y'], superPrefixed: ['[]', '[]=']);
  }

  test_indexExpression_super_set() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super[x] = y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['x', 'y'], superPrefixed: ['[]=']);
  }

  test_indexExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x[y];
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_instanceCreationExpression_explicitNew_named() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  new A<T>.named(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'named')]);
  }

  test_instanceCreationExpression_explicitNew_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  new A<T>(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '')]);
  }

  test_instanceCreationExpression_explicitNew_unresolvedClass() async {
    var library = await buildTestLibrary(a, r'''
test() {
  new A<T>.named(x);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x']);
  }

  test_instanceCreationExpression_implicitNew_named() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  A<T>.named(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'named')]);
  }

  test_instanceCreationExpression_implicitNew_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  A<T>(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '')]);
  }

  test_instanceCreationExpression_implicitNew_unresolvedClass_named() async {
    var library = await buildTestLibrary(a, r'''
test() {
  A<T>.named(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x', 'y']);
  }

  test_integerLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  0;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_isExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x is Y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['Y', 'x']);
  }

  test_listLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <A>[x, y];
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y']);
  }

  test_mapLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <A, B>{x: y, v: w};
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'v', 'w', 'x', 'y']);
  }

  test_methodInvocation_instance_withoutTarget_function() async {
    var library = await buildTestLibrary(a, r'''
void foo(a, {b}) {}

test() {
  foo(x, b: y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['foo', 'x', 'y']);
  }

  test_methodInvocation_instance_withoutTarget_method() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void foo(a, {b}) {}

  test() {
    foo(x, b: y);
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['foo', 'x', 'y']);
  }

  test_methodInvocation_instance_withTarget() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  x.foo<T>(y, b: z);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['T', 'x', 'y', 'z'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'foo')]);
  }

  test_methodInvocation_instance_withTarget_super() async {
    var library = await buildTestLibrary(a, r'''
class A {
  void foo(a, b) {}
}

class B extends A {
  test() {
    super.foo(x, y);
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'B', unprefixed: ['x', 'y'], superPrefixed: ['foo']);
  }

  test_methodInvocation_static_withTarget() async {
    var library = await buildTestLibrary(a, r'''
class A {}

test() {
  A.foo<T>(x);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'T', 'x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'foo')]);
  }

  test_nullLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  null;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_parenthesizedExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  ((x));
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_postfixExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {}
class B extend A {}

B x, y;

test() {
  x++;
  y--;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x',
      'y'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'B', '+'),
      _ExpectedClassMember(aUri, 'B', '-')
    ]);
  }

  test_postfixExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x++;
  y--;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_prefixedIdentifier_importPrefix() async {
    newFile(b, content: 'var b = 0;');
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as pb;

test() {
  pb.b;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, prefixed: {
      'pb': ['b']
    });
  }

  test_prefixedIdentifier_importPrefix_unresolvedIdentifier() async {
    newFile(b, content: '');
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as pb;

test() {
  pb.b;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, prefixed: {
      'pb': ['b']
    });
  }

  test_prefixedIdentifier_interfaceProperty() async {
    var library = await buildTestLibrary(a, r'''
class A {
  int get y => 0;
}

class B extends A {}

B x;
test() {
  x.y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'y')]);
  }

  test_prefixedIdentifier_static() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class B extends A {}

test() {
  B.x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['B'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'x')]);
  }

  test_prefixedIdentifier_unresolvedPrefix() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x.y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_prefixExpression() async {
    var library = await buildTestLibrary(a, r'''
class A {
  operator-() {}
}

class B extend A {}

B x;

test() {
  -x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'B', 'unary-')]);
  }

  test_prefixExpression_unresolvedOperator() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  -x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'unary-')]);
  }

  test_prefixExpression_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
test() {
  -x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_propertyAccess_get() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  (x).foo;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'foo')]);
  }

  test_propertyAccess_getSet() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  (x).foo += 1;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: [
      'x'
    ], expectedMembers: [
      _ExpectedClassMember(aUri, 'A', 'foo'),
      _ExpectedClassMember(aUri, 'A', 'foo='),
    ]);
  }

  test_propertyAccess_set() async {
    var library = await buildTestLibrary(a, r'''
class A {}

A x;

test() {
  (x).foo = 1;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'foo=')]);
  }

  test_propertyAccess_super_get() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super.foo;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', superPrefixed: ['foo']);
  }

  test_propertyAccess_super_getSet() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super.foo += 1;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', superPrefixed: ['foo', 'foo=']);
  }

  test_propertyAccess_super_set() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    super.foo = 1;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', superPrefixed: ['foo=']);
  }

  test_rethrowExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  try {
  } on A {
    rethrow;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['A']);
  }

  test_setLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  <A>{x, y, z};
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y', 'z']);
  }

  test_simpleIdentifier() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_simpleIdentifier_sort() async {
    var library = await buildTestLibrary(a, r'''
test() {
  d; c; a; b; e;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['a', 'b', 'c', 'd', 'e']);
  }

  test_simpleIdentifier_synthetic() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x +;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_simpleIdentifier_unique() async {
    var library = await buildTestLibrary(a, r'''
test() {
  x; x; y; x; y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_simpleStringLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  '';
  """""";
  r"""""";
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_stringInterpolation() async {
    var library = await buildTestLibrary(a, r'''
test() {
  '$x ${y}';
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_symbolLiteral() async {
    var library = await buildTestLibrary(a, r'''
test() {
  #foo.bar;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_thisExpression() async {
    var library = await buildTestLibrary(a, r'''
class C {
  test() {
    this;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD, memberOf: 'C');
  }

  test_throwExpression() async {
    var library = await buildTestLibrary(a, r'''
test() {
  throw x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }
}

@reflectiveTest
class ImplReferenceCollectorTest extends _Base {
  test_class_constructor() async {
    var library = await buildTestLibrary(a, r'''
class C {
  var f;
  C.test(A a, {b: x, this.f: y}) {
    z;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['x', 'y', 'z']);
  }

  test_class_constructor_factoryRedirect_named() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class X {
  factory X.test() = A.named;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X',
        unprefixed: ['A'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'named')]);
  }

  test_class_constructor_factoryRedirect_named_prefixed() async {
    newFile(b, content: 'class A {}');

    var library = await buildTestLibrary(a, r'''
import 'b.dart' as p;

class X {
  factory X.test() = p.A.named;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X',
        prefixed: {
          'p': ['A']
        },
        expectedMembers: [
          _ExpectedClassMember(bUri, 'A', 'named')
        ]);
  }

  test_class_constructor_factoryRedirect_named_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
class X {
  factory X.test() = A.named;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X', unprefixed: ['A']);
  }

  test_class_constructor_factoryRedirect_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class X {
  factory X.test() = A;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X',
        unprefixed: ['A'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '')]);
  }

  test_class_constructor_factoryRedirect_unnamed_prefixed() async {
    newFile(b, content: 'class A {}');

    var library = await buildTestLibrary(a, r'''
import 'b.dart' as p;

class X {
  factory X.test() = p.A;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X',
        prefixed: {
          'p': ['A']
        },
        expectedMembers: [
          _ExpectedClassMember(bUri, 'A', '')
        ]);
  }

  test_class_constructor_factoryRedirect_unnamed_unresolvedTarget() async {
    var library = await buildTestLibrary(a, r'''
class X {
  factory X.test() = A;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X', unprefixed: ['A']);
  }

  test_class_constructor_initializer_assert() async {
    var library = await buildTestLibrary(a, r'''
class C {
  C.test(a) : assert(a > x, y);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['x', 'y']);
  }

  test_class_constructor_initializer_field() async {
    var library = await buildTestLibrary(a, r'''
class C {
  var f;

  C.test() : f = x;
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['x']);
  }

  test_class_constructor_initializer_super_named() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class C extends A {
  C.test() : super.named(x);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C',
        unprefixed: ['A', 'x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', 'named')]);
  }

  test_class_constructor_initializer_super_named_unresolvedSuper() async {
    var library = await buildTestLibrary(a, r'''
class C extends A {
  C.test() : super.named(x);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A', 'x']);
  }

  test_class_constructor_initializer_super_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class A {}

class C extends A {
  C.test() : super(x);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C',
        unprefixed: ['A', 'x'],
        expectedMembers: [_ExpectedClassMember(aUri, 'A', '')]);
  }

  test_class_constructor_initializer_super_unnamed_unresolvedSuper() async {
    var library = await buildTestLibrary(a, r'''
class C extends A {
  C.test() : super(x);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['A', 'x']);
  }

  test_class_constructor_initializer_this_named() async {
    var library = await buildTestLibrary(a, r'''
class C extends A {
  C.test() : this.named(x);

  C.named(a);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['x']);
  }

  test_class_constructor_initializer_this_unnamed() async {
    var library = await buildTestLibrary(a, r'''
class C extends A {
  C.test() : this(x);

  C(a);
}
''');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'C', unprefixed: ['x']);
  }

  test_class_method() async {
    var library = await buildTestLibrary(a, r'''
class C {
  void test(A a, {b: x}) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'C', unprefixed: ['x', 'y']);
  }

  test_class_typeParameter() async {
    var library = await buildTestLibrary(a, r'''
class C<T extends A> {}
''');
    _assertImpl(library, 'T', NodeKind.TYPE_PARAMETER, typeParameterOf: 'C');
  }

  test_classTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
class Test = A with B implements C;
''');
    _assertImpl(library, 'Test', NodeKind.CLASS_TYPE_ALIAS);
  }

  test_functionTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
typedef A Test<T extends B>(C c, T t);
''');
    _assertImpl(library, 'Test', NodeKind.FUNCTION_TYPE_ALIAS);
  }

  test_unit_class() async {
    var library = await buildTestLibrary(a, r'''
class Test<T extends A, U extends T> extends B with C, implements D {
  void test() {
    x;
  }
}
''');
    _assertImpl(library, 'Test', NodeKind.CLASS);
  }

  test_unit_classTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
class Test<T extends V, U extends T> = A<T> with B<U, W>;
''');
    _assertImpl(library, 'Test', NodeKind.CLASS_TYPE_ALIAS);
  }

  test_unit_function() async {
    var library = await buildTestLibrary(a, r'''
void test(A a, {b: x}) {
  y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_unit_mixin() async {
    var library = await buildTestLibrary(a, r'''
mixin Test<T extends A, U extends T> on B<T>, C<D, U> {
  void test() {
    x;
  }
}
''');
    _assertImpl(library, 'Test', NodeKind.MIXIN);
  }

  test_unit_variable() async {
    var library = await buildTestLibrary(a, r'''
int test = x;
''');
    _assertImpl(library, 'test', NodeKind.GETTER, unprefixed: ['x']);
    _assertImpl(library, 'test=', NodeKind.SETTER); // empty
  }

  test_unit_variable_noInitializer() async {
    var library = await buildTestLibrary(a, r'''
int test;
''');
    _assertImpl(library, 'test', NodeKind.GETTER);
    _assertImpl(library, 'test=', NodeKind.SETTER); // empty
  }
}

@reflectiveTest
class ShadowReferenceCollectorTest extends _Base {
  test_importPrefix_with_classMember_getter_field() async {
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as p;

class X {
  p.A<B> test() {}

  int p;
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'X', unprefixed: ['B', 'p']);
  }

  test_importPrefix_with_classMember_method() async {
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as p;

class X {
  p.A<B> test() {}

  p() {}
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'X', unprefixed: ['B', 'p']);
  }

  test_importPrefix_with_function() async {
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as p;

p() {} // this is a compilation error

class X extends p.A<B> {}
''');
    _assertApi(library, 'X', NodeKind.CLASS, unprefixed: [
      'B'
    ], prefixed: {
      'p': ['A']
    });
  }

  test_syntacticScope_class_constructor() async {
    var library = await buildTestLibrary(a, r'''
class X {
  X.test(A a, X b) {
    X;
  }
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X', unprefixed: ['A']);
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR, memberOf: 'X');
  }

  test_syntacticScope_class_constructor_parameters() async {
    var library = await buildTestLibrary(a, r'''
class X {
  X.test(a, b, c) {
    a; b; c;
    d;
  }
}
''');
    _assertApi(library, 'test', NodeKind.CONSTRUCTOR, memberOf: 'X');
    _assertImpl(library, 'test', NodeKind.CONSTRUCTOR,
        memberOf: 'X', unprefixed: ['d']);
  }

  test_syntacticScope_class_field() async {
    var library = await buildTestLibrary(a, r'''
class X {
  var test = x + X + test;
}
''');
    _assertApi(library, 'test', NodeKind.GETTER,
        memberOf: 'X', unprefixed: ['x']);
    _assertImpl(library, 'test', NodeKind.GETTER,
        memberOf: 'X', unprefixed: ['x']);
  }

  test_syntacticScope_class_method() async {
    var library = await buildTestLibrary(a, r'''
class X {
  test(A a, X b, test c) {
    X;
    test;
    B;
  }
}
''');
    _assertApi(library, 'test', NodeKind.METHOD,
        memberOf: 'X', unprefixed: ['A']);
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'X', unprefixed: ['B']);
  }

  test_syntacticScope_class_method_parameters() async {
    var library = await buildTestLibrary(a, r'''
class X {
  test(a, b, c) {
    a; b; c;
    d;
  }
}
''');
    _assertApi(library, 'test', NodeKind.METHOD, memberOf: 'X');
    _assertImpl(library, 'test', NodeKind.METHOD,
        memberOf: 'X', unprefixed: ['d']);
  }

  test_syntacticScope_class_typeParameter_ofClass() async {
    var library = await buildTestLibrary(a, r'''
class X<T extends A<B, X, T>> {}
''');
    _assertApi(library, 'T', NodeKind.TYPE_PARAMETER,
        typeParameterOf: 'X', unprefixed: ['A', 'B']);
  }

  test_syntacticScope_unit_class() async {
    var library = await buildTestLibrary(a, r'''
class X extends A<B, X> {}
''');
    _assertApi(library, 'X', NodeKind.CLASS, unprefixed: ['A', 'B']);
  }

  test_syntacticScope_unit_function() async {
    var library = await buildTestLibrary(a, r'''
test(A a, test b) {
  test;
  B;
}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A']);
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['B']);
  }

  test_syntacticScope_unit_function_parameters() async {
    var library = await buildTestLibrary(a, r'''
test(a, b, {c}) {
  a; b; c;
  d;
}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['d']);
  }

  test_syntacticScope_unit_functionTypeAlias() async {
    var library = await buildTestLibrary(a, r'''
typedef X(A a, X b);
''');
    _assertApi(library, 'X', NodeKind.FUNCTION_TYPE_ALIAS, unprefixed: ['A']);
  }

  test_syntacticScope_unit_mixin() async {
    var library = await buildTestLibrary(a, r'''
mixin X on A<B, X> {}
''');
    _assertApi(library, 'X', NodeKind.MIXIN, unprefixed: ['A', 'B']);
  }
}

@reflectiveTest
class StatementReferenceCollectorTest extends _Base {
  test_assertStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  assert(x, y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_block_localScope() async {
    var library = await buildTestLibrary(a, r'''
test() {
  var x = 0;
  {
    var y = 0;
    {
      x;
      y;
    }
    x;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_breakStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (true) {
    break;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_continueStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (true) {
    continue;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_doStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  do {
    x;
  } while (y);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_emptyStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (true);
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION);
  }

  test_forEachStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (A a in x) {
    a;
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y']);
  }

  test_forEachStatement_body_singleStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (var a in x) a;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_forEachStatement_iterableAsLoopVariable() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (A x in x) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y']);
  }

  test_forEachStatement_loopIdentifier() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (x in y) {
    z;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z']);
  }

  test_forStatement_initialization() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (x; y; z) {
    z2;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z', 'z2']);
  }

  test_forStatement_variables() async {
    var library = await buildTestLibrary(a, r'''
test() {
  for (A a = x, b = y, c = a; z; a, b, z2) {
    z3;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'x', 'y', 'z', 'z2', 'z3']);
  }

  test_functionDeclarationStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  A foo(B b) {
    x;
    C;
    b;
    foo();
  }
  foo();
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'x']);
  }

  test_ifStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  if (x) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_ifStatement_else() async {
    var library = await buildTestLibrary(a, r'''
test() {
  if (x) {
    y;
  } else {
    z;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z']);
  }

  test_labeledStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  label: x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_returnStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  return x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }

  test_switchStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  switch (x) {
    case y:
      var local1 = 1;
      z;
      local1;
      break;
    default:
      var local2 = 2;
      z2;
      local2;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['x', 'y', 'z', 'z2']);
  }

  test_switchStatement_localScopePerCase() async {
    var library = await buildTestLibrary(a, r'''
test() {
  switch (0) {
    case 0:
      var v1 = 1;
      var v2 = 2;
      v1;
      v2;
    default:
      v1;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['v1']);
  }

  test_tryStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  try {
    var local1 = 1;
    x;
    local1;
  } finally {
    var local2 = 2;
    y;
    local2;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_tryStatement_catch() async {
    var library = await buildTestLibrary(a, r'''
test() {
  try {
    var local1 = 1;
    x;
    local1;
  } on A {
    var local2 = 2;
    y;
    local2;
  } on B catch (ex1) {
    var local3 = 3;
    z;
    ex1;
    local3;
  } catch (ex2, st2) {
    ex2;
    st2;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'x', 'y', 'z']);
  }

  test_variableDeclarationStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  var a = x, b = y;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_whileStatement() async {
    var library = await buildTestLibrary(a, r'''
test() {
  while (x) {
    y;
  }
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x', 'y']);
  }

  test_yieldStatement() async {
    var library = await buildTestLibrary(a, r'''
test() sync* {
  yield x;
}
''');
    _assertImpl(library, 'test', NodeKind.FUNCTION, unprefixed: ['x']);
  }
}

@reflectiveTest
class TypeReferenceCollectorTest extends _Base {
  test_dynamic() async {
    var library = await buildTestLibrary(a, r'''
dynamic test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }

  test_function() async {
    var library = await buildTestLibrary(a, r'''
A Function(B) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_function_generic() async {
    var library = await buildTestLibrary(a, r'''
A Function<T, U extends B>(T t, C c, D<T> d, E e) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'D', 'E']);
  }

  test_function_nested_generic() async {
    var library = await buildTestLibrary(a, r'''
A Function<T>(B Function<U>(U, C, T) f, D) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'D']);
  }

  test_function_parameter_named() async {
    var library = await buildTestLibrary(a, r'''
A Function({B, C}) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B', 'C']);
  }

  test_function_parameter_positional() async {
    var library = await buildTestLibrary(a, r'''
A Function([B, C]) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B', 'C']);
  }

  test_function_shadow_typeParameters() async {
    var library = await buildTestLibrary(a, r'''
A Function<T2 extends U2, U2>(B) test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A', 'B']);
  }

  test_interface_generic() async {
    var library = await buildTestLibrary(a, r'''
A<B, C<D>> test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION,
        unprefixed: ['A', 'B', 'C', 'D']);
  }

  test_interface_prefixed() async {
    var library = await buildTestLibrary(a, r'''
import 'b.dart' as pb;
import 'c.dart' as pc;
A<pb.B2, pc.C2, pb.B1, pc.C1, pc.C3> test() {}
''');
    _assertApi(
      library,
      'test',
      NodeKind.FUNCTION,
      unprefixed: ['A'],
      prefixed: {
        'pb': ['B1', 'B2'],
        'pc': ['C1', 'C2', 'C3']
      },
    );
  }

  test_interface_simple() async {
    var library = await buildTestLibrary(a, r'''
A test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION, unprefixed: ['A']);
  }

  test_void() async {
    var library = await buildTestLibrary(a, r'''
void test() {}
''');
    _assertApi(library, 'test', NodeKind.FUNCTION);
  }
}

class _Base extends BaseDependencyTest {
  void _assertApi(Library library, String name, NodeKind kind,
      {String? memberOf,
      String? typeParameterOf,
      List<String> unprefixed = const [],
      Map<String, List<String>> prefixed = const {},
      List<String> superPrefixed = const [],
      List<_ExpectedClassMember> expectedMembers = const []}) {
    var node = getNode(
      library,
      name: name,
      kind: kind,
      memberOf: memberOf,
      typeParameterOf: typeParameterOf,
    );
    _assertDependencies(
      node.api,
      unprefixed: unprefixed,
      prefixed: prefixed,
      superPrefixed: superPrefixed,
      expectedMembers: expectedMembers,
    );
  }

  void _assertDependencies(Dependencies dependencies,
      {List<String> unprefixed = const [],
      Map<String, List<String>> prefixed = const {},
      List<String> superPrefixed = const [],
      List<_ExpectedClassMember> expectedMembers = const []}) {
    expect(dependencies.unprefixedReferencedNames, unprefixed);
    expect(dependencies.importPrefixes, prefixed.keys);
    expect(dependencies.importPrefixedReferencedNames, prefixed.values);
    expect(dependencies.superReferencedNames, superPrefixed);

    var actualMembers = dependencies.classMemberReferences;
    if (actualMembers.length != expectedMembers.length) {
      fail('Expected: $expectedMembers\nActual: $actualMembers');
    }
    expect(actualMembers, hasLength(expectedMembers.length));
    for (var i = 0; i < actualMembers.length; i++) {
      var actualMember = actualMembers[i];
      var expectedMember = expectedMembers[i];
      if (actualMember.target.libraryUri != expectedMember.targetUri ||
          actualMember.target.name != expectedMember.targetName ||
          actualMember.name != expectedMember.name) {
        fail('Expected: $expectedMember\nActual: $actualMember');
      }
    }
  }

  void _assertImpl(Library library, String name, NodeKind kind,
      {String? memberOf,
      String? typeParameterOf,
      List<String> unprefixed = const [],
      Map<String, List<String>> prefixed = const {},
      List<String> superPrefixed = const [],
      List<_ExpectedClassMember> expectedMembers = const []}) {
    var node = getNode(
      library,
      name: name,
      kind: kind,
      memberOf: memberOf,
      typeParameterOf: typeParameterOf,
    );
    _assertDependencies(
      node.impl,
      unprefixed: unprefixed,
      prefixed: prefixed,
      superPrefixed: superPrefixed,
      expectedMembers: expectedMembers,
    );
  }
}

class _ExpectedClassMember {
  final Uri targetUri;
  final String targetName;
  final String name;

  _ExpectedClassMember(
    this.targetUri,
    this.targetName,
    this.name,
  );

  @override
  String toString() {
    return '($targetUri, $targetName, $name)';
  }
}

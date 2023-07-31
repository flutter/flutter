// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/potentially_constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsConstantTypeExpressionTest);
    defineReflectiveTests(PotentiallyConstantTest);
  });
}

@reflectiveTest
class IsConstantTypeExpressionTest extends PubPackageResolutionTest {
  test_class() async {
    await _assertConst(r'''
int x;
''');
  }

  test_class_prefix() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await _assertConst(r'''
import 'a.dart' as p;
p.A x;
''');
  }

  test_class_prefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');
    await _assertNeverConst(r'''
import 'a.dart' deferred as p;
p.A x;
''');
  }

  test_class_typeArguments() async {
    await _assertConst(r'''
List<int> x;
''');
  }

  test_class_typeArguments_notConst() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    List<T> x;
  }
}
''');
  }

  test_dynamic() async {
    await _assertConst(r'''
dynamic x;
''');
  }

  test_genericFunctionType() async {
    await _assertConst(r'''
int Function<T extends num, U>(int, bool) x;
''');
  }

  test_genericFunctionType_formalParameterType() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    Function(T) x;
  }
}
''');
  }

  test_genericFunctionType_returnType() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    T Function() x;
  }
}
''');
  }

  test_genericFunctionType_typeParameterBound() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  m() {
    Function<U extends T>() x;
  }
}
''');
  }

  test_typeParameter_ofClass() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  T x;
}
''');
  }

  test_typeParameter_ofClass_nested() async {
    await _assertPotentiallyConst(r'''
class A<T> {
  List<T> x;
}
''');
  }

  test_typeParameter_ofFunction() async {
    await _assertPotentiallyConst('''
void foo<T>() {
  T x;
}
''');
  }

  test_typeParameter_ofFunctionType() async {
    await _assertPotentiallyConst('''
class A<U> {
  const A();
  void foo() {
    void Function<X>(X) x;
  }
}
''');
  }

  test_void() async {
    await _assertConst(r'''
void x;
''');
  }

  Future<void> _assertConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type!;
    expect(isPotentiallyConstantTypeExpression(type), isTrue);
    expect(isConstantTypeExpression(type), isTrue);
  }

  Future<void> _assertNeverConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type!;
    expect(isPotentiallyConstantTypeExpression(type), isFalse);
    expect(isConstantTypeExpression(type), isFalse);
  }

  Future<void> _assertPotentiallyConst(String code) async {
    await resolveTestCode(code);
    var type = findNode.variableDeclarationList('x;').type!;
    expect(isPotentiallyConstantTypeExpression(type), isTrue);
    expect(isConstantTypeExpression(type), isFalse);
  }
}

@reflectiveTest
class PotentiallyConstantTest extends PubPackageResolutionTest {
  test_adjacentStrings() async {
    await _assertConst(r'''
var x = 'a' 'b';
''', () => _xInitializer());
  }

  test_asExpression() async {
    await _assertConst(r'''
const a = 0;
var x = a as int;
''', () => _xInitializer());
  }

  test_asExpression_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = a as int;
''', () => _xInitializer(), () => [findNode.simple('a as')]);
  }

  test_asExpression_typeParameter() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a as T;
  }
}
''', () => _xInitializer());
  }

  test_asExpression_typeParameter_29() async {
    await _assertNotConst(r'''
// @dart = 2.9
const a = 0;
class A<T> {
  m() {
    var x = a as T;
  }
}
''', () => _xInitializer(), () => [findNode.namedType('T;')]);
  }

  test_asExpression_typeParameter_nested() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a as List<T>;
  }
}
''', () => _xInitializer());
  }

  test_binaryExpression_andEager_const_const() async {
    await _assertConst(r'''
const a = false;
const b = false;
var x = a & b;
''', () => _xInitializer());
  }

  test_binaryExpression_andEager_const_notConst() async {
    await _assertNotConst(r'''
const a = false;
final b = false;
var x = a & b;
''', () => _xInitializer(), () => [findNode.simple('b;')]);
  }

  test_binaryExpression_andEager_notConst_const() async {
    await _assertNotConst(r'''
final a = false;
const b = false;
var x = a & b;
''', () => _xInitializer(), () => [findNode.simple('a &')]);
  }

  test_binaryExpression_andEager_notConst_notConst() async {
    await _assertNotConst(
      r'''
final a = false;
final b = false;
var x = a & b;
''',
      () => _xInitializer(),
      () => [
        findNode.simple('a &'),
        findNode.simple('b;'),
      ],
    );
  }

  test_binaryExpression_andLazy_const_const() async {
    await _assertConst(r'''
const a = false;
const b = false;
var x = a && b;
''', () => _xInitializer());
  }

  test_binaryExpression_andLazy_const_notConst() async {
    await _assertNotConst(r'''
const a = false;
final b = false;
var x = a && b;
''', () => _xInitializer(), () => [findNode.simple('b;')]);
  }

  test_binaryExpression_andLazy_notConst_const() async {
    await _assertNotConst(r'''
final a = false;
const b = false;
var x = a && b;
''', () => _xInitializer(), () => [findNode.simple('a &')]);
  }

  test_binaryExpression_andLazy_notConst_notConst() async {
    await _assertNotConst(
      r'''
final a = false;
final b = false;
var x = a && b;
''',
      () => _xInitializer(),
      () => [
        findNode.simple('a &'),
        findNode.simple('b;'),
      ],
    );
  }

  test_binaryExpression_ifNull_const_const() async {
    await _assertConst(r'''
const a = 0;
const b = 1;
var x = a ?? b;
''', () => _xInitializer());
  }

  test_binaryExpression_ifNull_const_notConst() async {
    await _assertNotConst(r'''
const a = 0;
final b = 1;
var x = a ?? b;
''', () => _xInitializer(), () => [findNode.simple('b;')]);
  }

  test_binaryExpression_ifNull_notConst_const() async {
    await _assertNotConst(r'''
final a = 0;
const b = 1;
var x = a ?? b;
''', () => _xInitializer(), () => [findNode.simple('a ??')]);
  }

  test_binaryExpression_ifNull_notConst_notConst() async {
    await _assertNotConst(
      r'''
final a = 0;
final b = 1;
var x = a ?? b;
''',
      () => _xInitializer(),
      () => [
        findNode.simple('a ??'),
        findNode.simple('b;'),
      ],
    );
  }

  test_binaryExpression_orEager_const_const() async {
    await _assertConst(r'''
const a = false;
const b = false;
var x = a | b;
''', () => _xInitializer());
  }

  test_binaryExpression_orEager_const_notConst() async {
    await _assertNotConst(r'''
const a = false;
final b = false;
var x = a | b;
''', () => _xInitializer(), () => [findNode.simple('b;')]);
  }

  test_binaryExpression_orEager_notConst_const() async {
    await _assertNotConst(r'''
final a = false;
const b = false;
var x = a | b;
''', () => _xInitializer(), () => [findNode.simple('a |')]);
  }

  test_binaryExpression_orEager_notConst_notConst() async {
    await _assertNotConst(
      r'''
final a = false;
final b = false;
var x = a | b;
''',
      () => _xInitializer(),
      () => [
        findNode.simple('a |'),
        findNode.simple('b;'),
      ],
    );
  }

  test_binaryExpression_orLazy_const_const() async {
    await _assertConst(r'''
const a = false;
const b = false;
var x = a || b;
''', () => _xInitializer());
  }

  test_binaryExpression_orLazy_const_notConst() async {
    await _assertNotConst(r'''
const a = false;
final b = false;
var x = a || b;
''', () => _xInitializer(), () => [findNode.simple('b;')]);
  }

  test_binaryExpression_orLazy_notConst_const() async {
    await _assertNotConst(r'''
final a = false;
const b = false;
var x = a || b;
''', () => _xInitializer(), () => [findNode.simple('a |')]);
  }

  test_binaryExpression_orLazy_notConst_notConst() async {
    await _assertNotConst(
      r'''
final a = false;
final b = false;
var x = a || b;
''',
      () => _xInitializer(),
      () => [
        findNode.simple('a |'),
        findNode.simple('b;'),
      ],
    );
  }

  test_conditional() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
const c = 0;
var x = a ? b : c;
''', () => _xInitializer());
  }

  test_conditional_final() async {
    await _assertNotConst(
        r'''
final a = 0;
final b = 0;
final c = 0;
var x = a ? b : c;
''',
        () => _xInitializer(),
        () => [
              findNode.simple('a ?'),
              findNode.simple('b :'),
              findNode.simple('c;')
            ]);
  }

  test_constructorReference_explicitTypeArguments() async {
    await _assertConst('''
class A {
  final B Function() x;
  const A(): x = B<int>.new;
}

class B<T> {}
''', () => findNode.constructorReference('B<int>.new'));
  }

  test_constructorReference_explicitTypeArguments_nonConst() async {
    await _assertNotConst('''
import '' deferred as self;
class A {
  Object x;
  const A(): x = B<self.A>.new;
}

class B<T> {}
''', () => findNode.constructorReference('B<self.A>.new'),
        () => [findNode.typeAnnotation('self.A')]);
  }

  test_constructorReference_noTypeArguments() async {
    await _assertConst('''
class A {
  final B Function() x;
  const A(): x = B.new;
}

class B {}
''', () => findNode.constructorReference('B.new'));
  }

  test_functionReference_explicitTypeArguments() async {
    await _assertConst('''
class A {
  final int Function(int) x;
  const A(): x = id<int>;
}

X id<X>(X x) => x;
''', () => findNode.functionReference('id<int>'));
  }

  test_functionReference_explicitTypeArguments_nonConst() async {
    await _assertNotConst('''
import '' deferred as self;
class A {
  final int Function(int) x;
  const A(): x = id<self.A>;
}

X id<X>(X x) => x;
''', () => findNode.functionReference('id<self.A>'),
        () => [findNode.typeAnnotation('self.A')]);
  }

  test_functionReference_noTypeArguments() async {
    await _assertConst('''
class A {
  final int Function(int) x;
  const A(): x = id;
}

X id<X>(X x) => x;
''', () => findNode.simple('id;'));
  }

  test_ifElement_then() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
var x = const [if (a) b];
''', () => _xInitializer());
  }

  test_ifElement_then_final() async {
    await _assertNotConst(r'''
final a = 0;
final b = 0;
var x = const [if (a) b];
''', () => _xInitializer(),
        () => [findNode.simple('a)'), findNode.simple('b]')]);
  }

  test_ifElement_thenElse() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
const c = 0;
var x = const [if (a) b else c];
''', () => _xInitializer());
  }

  test_instanceCreation() async {
    await _assertNotConst(r'''
class A {
  const A();
}

var x = new A(); // x
''', () => _xInitializer(), () => [findNode.instanceCreation('A(); // x')]);
  }

  test_instanceCreation_const() async {
    await _assertConst(r'''
class A {
  const A();
}

var x = const A();
''', () => _xInitializer());
  }

  test_isExpression() async {
    await _assertConst(r'''
const a = 0;
var x = a is int;
''', () => _xInitializer());
  }

  test_isExpression_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = a is int;
''', () => _xInitializer(), () => [findNode.simple('a is')]);
  }

  test_isExpression_typeParameter() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a is T;
  }
}
''', () => _xInitializer());
  }

  test_isExpression_typeParameter_29() async {
    await _assertNotConst(r'''
// @dart = 2.9
const a = 0;
class A<T> {
  m() {
    var x = a is T;
  }
}
''', () => _xInitializer(), () => [findNode.namedType('T;')]);
  }

  test_isExpression_typeParameter_nested() async {
    await _assertConst(r'''
const a = 0;
class A<T> {
  m() {
    var x = a is List<T>;
  }
}
''', () => _xInitializer());
  }

  test_listLiteral() async {
    await _assertConst(r'''
var x = const [0, 1, 2];
''', () => _xInitializer());
  }

  test_listLiteral_notConst() async {
    await _assertNotConst(r'''
var x = [0, 1, 2];
''', () => _xInitializer(), () => [findNode.listLiteral('0,')]);
  }

  test_listLiteral_notConst_element() async {
    await _assertNotConst(r'''
final a = 0;
final b = 1;
var x = const [a, b, 2];
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b,')]);
  }

  test_listLiteral_ofDynamic() async {
    await _assertConst('''
var x = const <dynamic>[];
''', () => _xInitializer());
  }

  test_listLiteral_ofNever() async {
    await _assertConst('''
var x = const <Never>[];
''', () => _xInitializer());
  }

  test_listLiteral_ofVoid() async {
    await _assertConst('''
var x = const <void>[];
''', () => _xInitializer());
  }

  test_listLiteral_typeArgument() async {
    await _assertConst(r'''
var x = const <int>[0, 1, 2];
''', () => _xInitializer());
  }

  test_listLiteral_typeArgument_notConstType() async {
    await _assertNotConst('''
import '' deferred as self;
class A {
  m() {
    var x = const <self.A>[];
  }
}
''', () => _xInitializer(), () => [findNode.namedType('A>[')]);
  }

  test_literal_bool() async {
    await _assertConst(r'''
var x = true;
''', () => _xInitializer());
  }

  test_literal_double() async {
    await _assertConst(r'''
var x = 1.2;
''', () => _xInitializer());
  }

  test_literal_int() async {
    await _assertConst(r'''
var x = 0;
''', () => _xInitializer());
  }

  test_literal_null() async {
    await _assertConst(r'''
var x = null;
''', () => _xInitializer());
  }

  test_literal_simpleString() async {
    await _assertConst(r'''
var x = '123';
''', () => _xInitializer());
  }

  test_literal_symbol() async {
    await _assertConst(r'''
var x = #a.b.c;
''', () => _xInitializer());
  }

  test_mapLiteral() async {
    await _assertConst(r'''
var x = const {0: 1};
''', () => _xInitializer());
  }

  test_mapLiteral_notConst() async {
    await _assertNotConst(r'''
var x = {0: 1};
''', () => _xInitializer(), () => [findNode.setOrMapLiteral('0: 1')]);
  }

  test_mapLiteral_notConst_key() async {
    await _assertNotConst(r'''
final a = 1;
final b = 2;
var x = const {0: 0, a: 1, b: 2};
''', () => _xInitializer(),
        () => [findNode.simple('a:'), findNode.simple('b:')]);
  }

  test_mapLiteral_notConst_value() async {
    await _assertNotConst(r'''
final a = 1;
final b = 2;
var x = const {0: 0, 1: a, 2: b};
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b}')]);
  }

  test_mapLiteral_typeArgument() async {
    await _assertConst(r'''
var x = const <int, int>{0: 0};
''', () => _xInitializer());
  }

  test_mapLiteral_typeArgument_notConstType() async {
    await _assertNotConst(r'''
class A<T> {
  m() {
    var x = const <T, T>{};
  }
}
''', () => _xInitializer(),
        () => [findNode.namedType('T,'), findNode.namedType('T>{')]);
  }

  test_methodInvocation_identical() async {
    await _assertConst(r'''
const a = 0;
const b = 0;
var x = identical(a, b);
''', () => _xInitializer());
  }

  test_methodInvocation_identical_final() async {
    await _assertNotConst(r'''
final a = 0;
final b = 0;
var x = identical(a, b);
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b)')]);
  }

  test_methodInvocation_name() async {
    await _assertNotConst(r'''
const a = 0;
const b = 0;
var x = foo(a, b);
''', () => _xInitializer(), () => [findNode.methodInvocation('foo')]);
  }

  test_methodInvocation_target() async {
    await _assertNotConst(r'''
var x = a.foo();
''', () => _xInitializer(), () => [findNode.methodInvocation('a.foo()')]);
  }

  test_namedExpression() async {
    await _assertConst(r'''
void f({a}) {}

var x = f(a: 0);
''', () => findNode.namedExpression('a: 0'));
  }

  test_parenthesizedExpression_const() async {
    await _assertConst(r'''
const a = 0;
var x = (a);
''', () => _xInitializer());
  }

  test_parenthesizedExpression_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = (a);
''', () => _xInitializer(), () => [findNode.simple('a);')]);
  }

  test_postfixExpression() async {
    await _assertNotConst(r'''
const a = 0;
var x = a++;
''', () => _xInitializer(), () => [findNode.postfix('a++')]);
  }

  test_prefixedIdentifier_importPrefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');
    await _assertNotConst(r'''
import 'a.dart' deferred as p;
var x = p.a + 1;
''', () => _xInitializer(), () => [findNode.prefixed('p.a')]);
  }

  test_prefixedIdentifier_importPrefix_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void f() {}
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.f;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_importPrefix_topVar() async {
    newFile('$testPackageLibPath/a.dart', r'''
const a = 0;
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.a + 1;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_length_const() async {
    await _assertConst(r'''
const a = 'abc';
var x = a.length;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_length_final() async {
    await _assertNotConst(r'''
final a = 'abc';
var x = a.length;
''', () => _xInitializer(), () => [findNode.simple('a.')]);
  }

  test_prefixedIdentifier_method_instance() async {
    await _assertNotConst(r'''
class A {
  const A();
  m() {};
}

const a = const A();

var x = a.m;
''', () => _xInitializer(), () => [findNode.prefixed('a.m')]);
  }

  test_prefixedIdentifier_method_static() async {
    await _assertConst(r'''
class A {
  static m() {};
}

var x = A.m;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_method_static_viaInstance() async {
    await _assertNotConst(r'''
class A {
  const A();
  static m() {};
}

const a = const A();

var x = a.m;
''', () => _xInitializer(), () => [findNode.prefixed('a.m')]);
  }

  test_prefixedIdentifier_prefix_variable() async {
    await _assertNotConst(r'''
class A {
  final a = 0;
  const A();
}

const a = const A();

var x = a.b + 1;
''', () => _xInitializer(), () => [findNode.prefixed('a.b + 1')]);
  }

  test_prefixedIdentifier_staticField_const() async {
    await _assertConst(r'''
class A {
  static const a = 0;
}
var x = A.a + 1;
''', () => _xInitializer());
  }

  test_prefixedIdentifier_staticField_final() async {
    await _assertNotConst(
      r'''
class A {
  static final a = 0;
}
var x = A.a + 1;
''',
      () => _xInitializer(),
      () => [findNode.prefixed('A.a')],
    );
  }

  test_prefixedIdentifier_typedef_interfaceType() async {
    newFile('$testPackageLibPath/a.dart', r'''
typedef A = List<int>;
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.A;
''', () => _xInitializer());
  }

  test_prefixExpression_bang() async {
    await _assertConst(r'''
const a = 0;
var x = !a;
''', () => _xInitializer());
  }

  test_prefixExpression_minus() async {
    await _assertConst(r'''
const a = 0;
var x = -a;
''', () => _xInitializer());
  }

  test_prefixExpression_minus_final() async {
    await _assertNotConst(r'''
final a = 0;
var x = -a;
''', () => _xInitializer(), () => [findNode.simple('a;')]);
  }

  test_prefixExpression_plusPlus() async {
    await _assertNotConst(r'''
const a = 0;
var x = ++a;
''', () => _xInitializer(), () => [findNode.prefix('++a')]);
  }

  test_prefixExpression_tilde() async {
    await _assertConst(r'''
const a = 0;
var x = ~a;
''', () => _xInitializer());
  }

  test_propertyAccess_length_final() async {
    await _assertNotConst(r'''
final a = 'abc';
var x = (a).length;
''', () => _xInitializer(), () => [findNode.simple('a).')]);
  }

  test_propertyAccess_length_stringLiteral() async {
    await _assertConst(r'''
var x = 'abc'.length;
''', () => _xInitializer());
  }

  test_propertyAccess_staticField_withPrefix_const() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');
    await _assertConst(r'''
import 'a.dart' as p;
var x = p.A.a + 1;
''', () => _xInitializer());
  }

  test_propertyAccess_staticField_withPrefix_deferred() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const a = 0;
}
''');
    await _assertNotConst(r'''
import 'a.dart' deferred as p;
var x = p.A.a + 1;
''', () => _xInitializer(), () => [findNode.propertyAccess('p.A.a')]);
  }

  test_propertyAccess_staticField_withPrefix_final() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static final a = 0;
}
''');
    await _assertNotConst(r'''
import 'a.dart' as p;
var x = p.A.a + 1;
''', () => _xInitializer(), () => [findNode.simple('a + 1')]);
  }

  test_propertyAccess_target_instanceCreation() async {
    await _assertNotConst(r'''
class A {
  final a = 0;
}

var x = A().a + 1;
''', () => _xInitializer(), () => [findNode.propertyAccess('A().a')]);
  }

  test_propertyAccess_target_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final a = 0;
  const A();
}

const a = const A();
''');
    await _assertNotConst(r'''
import 'a.dart' as p;

var x = p.a.b + 1;
''', () => _xInitializer(), () => [findNode.propertyAccess('p.a.b + 1')]);
  }

  test_recordLiteral() async {
    await _assertConst(r'''
var x = const (0, 1, 2);
''', () => _xInitializer());
  }

  test_recordLiteral_constructorParameter() async {
    await _assertConst(r'''
class C {
  final Object f;
  const C(int a) : f = (0, a);
}
''', () => findNode.recordLiteral('(0'));
  }

  test_recordLiteral_notConst() async {
    await _assertConst(r'''
var x = (0, 1, 2);
''', () => _xInitializer());
  }

  test_recordLiteral_notConst_element() async {
    await _assertNotConst(r'''
final a = 0;
final b = 1;
var x = const (a, b, 2);
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b,')]);
  }

  test_setLiteral() async {
    await _assertConst(r'''
var x = const {0, 1, 2};
''', () => _xInitializer());
  }

  test_setLiteral_notConst() async {
    await _assertNotConst(r'''
var x = {0, 1, 2};
''', () => _xInitializer(), () => [findNode.setOrMapLiteral('0,')]);
  }

  test_setLiteral_notConst_element() async {
    await _assertNotConst(r'''
final a = 0;
final b = 1;
var x = const {a, b, 2};
''', () => _xInitializer(),
        () => [findNode.simple('a,'), findNode.simple('b,')]);
  }

  test_setLiteral_typeArgument() async {
    await _assertConst(r'''
var x = const <int>{0, 1, 2};
''', () => _xInitializer());
  }

  test_setLiteral_typeArgument_notConstType() async {
    await _assertNotConst('''
import '' deferred as self;
class A {
  m() {
    var x = const <self.A>{};
  }
}
''', () => _xInitializer(), () => [findNode.namedType('A>{')]);
  }

  test_simpleIdentifier_class() async {
    await _assertConst(r'''
var x = int;
''', () => _xInitializer());
  }

  test_simpleIdentifier_function() async {
    await _assertConst(r'''
var x = f;

void f() {}
''', () => _xInitializer());
  }

  test_simpleIdentifier_localVar_const() async {
    await _assertConst(r'''
main() {
  const a = 0;
  var x = a + 1;
}
''', () => _xInitializer());
  }

  test_simpleIdentifier_localVar_final() async {
    await _assertNotConst(
      r'''
main() {
  final a = 0;
  var x = a + 1;
}
''',
      () => _xInitializer(),
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_method_static() async {
    await _assertConst(r'''
class A {
  static m() {};

  final Object f;

  const A() : f = m; // ref
}
''', () => findNode.simple('m; // ref'));
  }

  test_simpleIdentifier_parameterOfConstConstructor_inBody() async {
    await _assertNotConst(
      r'''
class C {
  const C(int a) {
    var x = a + 1;
  }
}
''',
      () => _xInitializer(),
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_parameterOfConstConstructor_inInitializer() async {
    await _assertConst(r'''
class C {
  final int f;
  const C(int a) : f = a + 1;
}
''', () => findNode.constructorFieldInitializer('f =').expression);
  }

  test_simpleIdentifier_parameterOfConstConstructor_notConst() async {
    await _assertNotConst(
      r'''
class C {
  final int f;
  C(int a) : f = a + 1;
}
''',
      () => findNode.constructorFieldInitializer('f =').expression,
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_topVar_const() async {
    await _assertConst(r'''
const a = 0;
var x = a + 1;
''', () => _xInitializer());
  }

  test_simpleIdentifier_topVar_final() async {
    await _assertNotConst(
      r'''
final a = 0;
var x = a + 1;
''',
      () => _xInitializer(),
      () => [findNode.simple('a +')],
    );
  }

  test_simpleIdentifier_typedef_functionType() async {
    await _assertConst(r'''
typedef A = void Function();
var x = A;
''', () => _xInitializer());
  }

  test_simpleIdentifier_typedef_interfaceType() async {
    await _assertConst(r'''
typedef A = List<int>;
var x = A;
''', () => _xInitializer());
  }

  test_simpleIdentifier_typeParameter_class() async {
    await _assertConst(r'''
class A<T> {
  final Object f;
  A() : f = T;
}
''', () => findNode.simple('T;'));
  }

  test_simpleIdentifier_typeParameter_class_214() async {
    await _assertNotConst(r'''
// @dart = 2.14
class A<T> {
  final Object f;
  A() : f = T;
}
''', () => findNode.simple('T;'), () => [findNode.simple('T;')]);
  }

  test_spreadElement() async {
    await _assertConst(r'''
const a = [0, 1, 2];
var x = const [...a];
''', () => _xInitializer());
  }

  test_spreadElement_final() async {
    await _assertNotConst(r'''
final a = [0, 1, 2];
var x = const [...a];
''', () => _xInitializer(), () => [findNode.simple('a];')]);
  }

  test_stringInterpolation_topVar_const() async {
    await _assertConst(r'''
const a = 0;
var x = 'a $a b';
''', () => _xInitializer());
  }

  test_stringInterpolation_topVar_final() async {
    await _assertNotConst(
      r'''
final a = 0;
var x = 'a $a b';
''',
      () => _xInitializer(),
      () => [findNode.simple('a b')],
    );
  }

  test_stringLiteral() async {
    await _assertConst(r'''
var x = 'a';
''', () => _xInitializer());
  }

  test_typeLiteral() async {
    await _assertConst('''
class A {
  Type x;
  const A(): x = List<int>;
}
''', () => findNode.typeLiteral('List<int>'));
  }

  test_typeLiteral_nonConst() async {
    await _assertNotConst('''
import '' deferred as self;
class A {
  Type x;
  const A(): x = List<self.A>;
}
''', () => findNode.typeLiteral('List<self.A>'),
        () => [findNode.typeAnnotation('self.A')]);
  }

  _assertConst(String code, AstNode Function() getNode) async {
    await resolveTestCode(code);
    var node = getNode();
    var notConstList = getNotPotentiallyConstants(
      node,
      featureSet: featureSet,
    );
    expect(notConstList, isEmpty);
  }

  _assertNotConst(String code, AstNode Function() getNode,
      List<AstNode> Function() getNotConstList) async {
    await resolveTestCode(code);
    var node = getNode();
    var notConstList = getNotPotentiallyConstants(
      node,
      featureSet: featureSet,
    );

    var expectedNotConst = getNotConstList();
    expect(notConstList, unorderedEquals(expectedNotConst));
  }

  Expression _xInitializer() {
    return findNode.variableDeclaration('x = ').initializer!;
  }
}

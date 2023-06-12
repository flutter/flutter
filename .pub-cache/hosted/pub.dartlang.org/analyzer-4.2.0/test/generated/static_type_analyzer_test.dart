// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeAnalyzerTest);
  });
}

@reflectiveTest
class StaticTypeAnalyzerTest extends PubPackageResolutionTest {
  test_flatten_derived() async {
    await assertNoErrorsInCode('''
abstract class Derived<T> extends Future<T> {
  factory Derived() => throw 'foo';
}
late Derived<dynamic> derivedDynamic;
late Derived<int> derivedInt;
late Derived<Derived> derivedDerived;
late Derived<Derived<int>> derivedDerivedInt;
    ''');
    var dynamicType = typeProvider.dynamicType;
    var derivedDynamicType = findElement.topVar('derivedDynamic').type;
    var derivedIntType = findElement.topVar('derivedInt').type;
    var derivedDerivedType = findElement.topVar('derivedDerived').type;
    var derivedDerivedIntType = findElement.topVar('derivedDerivedInt').type;
    // class Derived<T> extends Future<T> { ... }
    // flatten(Derived) = dynamic
    expect(_flatten(derivedDynamicType), dynamicType);
    // flatten(Derived<int>) = int
    expect(_flatten(derivedIntType), intType);
    // flatten(Derived<Derived>) = Derived
    expect(_flatten(derivedDerivedType), derivedDynamicType);
    // flatten(Derived<Derived<int>>) = Derived<int>
    expect(_flatten(derivedDerivedIntType), derivedIntType);
  }

  test_flatten_inhibit_recursion() async {
    await assertErrorsInCode('''
class A extends B {}
class B extends A {}
late A a;
late B b;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
    ]);
    var aType = findElement.topVar('a').type;
    var bType = findElement.topVar('b').type;
    // flatten(A) = A and flatten(B) = B, since neither class contains Future
    // in its class hierarchy.  Even though there is a loop in the class
    // hierarchy, flatten() should terminate.
    expect(_flatten(aType), aType);
    expect(_flatten(bType), bType);
  }

  test_flatten_related_derived_types() async {
    await assertErrorsInCode('''
abstract class Derived<T> extends Future<T> {
  factory Derived() => throw 'foo';
}
abstract class A extends Derived<int> implements Derived<num> {
  factory A() => throw 'foo';
}
abstract class B extends Future<num> implements Future<int> {
  factory B() => throw 'foo';
}
late A a;
late B b;
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 99, 1),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 99, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 133, 12),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 195, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 228, 11),
    ]);
    InterfaceType intType = typeProvider.intType;
    InterfaceType numType = typeProvider.numType;
    var aType = findElement.topVar('a').type;
    var bType = findElement.topVar('b').type;
    // The code in flatten() that inhibits infinite recursion shouldn't be
    // fooled by the fact that Derived appears twice in the type hierarchy.
    expect(_flatten(aType), intType);
    expect(_flatten(bType), numType);
  }

  test_flatten_related_types() async {
    await assertErrorsInCode('''
abstract class A extends Future<int> implements Future<num> {
  factory A() => throw 'foo';
}
abstract class B extends Future<num> implements Future<int> {
  factory B() => throw 'foo';
}
late A a;
late B b;
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 15, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 48, 11),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 109, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 142, 11),
    ]);
    InterfaceType intType = typeProvider.intType;
    InterfaceType numType = typeProvider.numType;
    var aType = findElement.topVar('a').type;
    var bType = findElement.topVar('b').type;
    expect(_flatten(aType), intType);
    expect(_flatten(bType), numType);
  }

  test_flatten_simple() async {
    // No code needs to be analyzed but we still need to call
    // assertNoErrorsInCode to get the typeProvider initialized.
    await assertNoErrorsInCode('');
    InterfaceType intType = typeProvider.intType;
    DartType dynamicType = typeProvider.dynamicType;
    InterfaceType futureDynamicType = typeProvider.futureDynamicType;
    InterfaceType futureIntType = typeProvider.futureType(intType);
    InterfaceType futureFutureDynamicType =
        typeProvider.futureType(futureDynamicType);
    InterfaceType futureFutureIntType = typeProvider.futureType(futureIntType);
    // flatten(int) = int
    expect(_flatten(intType), intType);
    // flatten(dynamic) = dynamic
    expect(_flatten(dynamicType), dynamicType);
    // flatten(Future) = dynamic
    expect(_flatten(futureDynamicType), dynamicType);
    // flatten(Future<int>) = int
    expect(_flatten(futureIntType), intType);
    // flatten(Future<Future>) = Future<dynamic>
    expect(_flatten(futureFutureDynamicType), futureDynamicType);
    // flatten(Future<Future<int>>) = Future<int>
    expect(_flatten(futureFutureIntType), futureIntType);
  }

  test_flatten_unrelated_types() async {
    await assertErrorsInCode('''
abstract class A extends Future<int> implements Future<String> {
  factory A() => throw 'foo';
}
abstract class B extends Future<String> implements Future<int> {
  factory B() => throw 'foo';
}
late A a;
late B b;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 15, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 48, 14),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 112, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 112, 1),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 112, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 112, 1),
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 148, 11),
    ]);
    var aType = findElement.topVar('a').type;
    var bType = findElement.topVar('b').type;
    // flatten(A) = A and flatten(B) = B, since neither string nor int is more
    // specific than the other.
    expect(_flatten(aType), intType);
    expect(_flatten(bType), stringType);
  }

  test_visitAdjacentStrings() async {
    await assertNoErrorsInCode('''
test() => 'a' 'b';
''');
    expect(findNode.adjacentStrings("'a' 'b'").staticType,
        same(typeProvider.stringType));
  }

  test_visitAsExpression() async {
    await assertNoErrorsInCode('''
class A {
  test() => this as B;
}
class B extends A {}
late B b;
''');
    var bType = findElement.topVar('b').type;
    expect(findNode.as_('this as B').staticType, bType);
  }

  test_visitAwaitExpression_flattened() async {
    await assertNoErrorsInCode('''
test(Future<Future<int>> e) async => await e;
''');
    InterfaceType futureIntType = typeProvider.futureType(typeProvider.intType);
    expect(findNode.awaitExpression('await e').staticType, futureIntType);
  }

  test_visitAwaitExpression_simple() async {
    await assertNoErrorsInCode('''
test(Future<int> e) async => await e;
''');
    // await e, where e has type Future<int>
    InterfaceType intType = typeProvider.intType;
    expect(findNode.awaitExpression('await e').staticType, intType);
  }

  test_visitBooleanLiteral_false() async {
    await assertNoErrorsInCode('''
test() => false;
''');
    expect(findNode.booleanLiteral('false').staticType,
        same(typeProvider.boolType));
  }

  test_visitBooleanLiteral_true() async {
    await assertNoErrorsInCode('''
test() => true;
''');
    expect(findNode.booleanLiteral('true').staticType,
        same(typeProvider.boolType));
  }

  test_visitCascadeExpression() async {
    await assertNoErrorsInCode('''
test(String a) => a..length;
''');
    expect(findNode.cascade('a..length').staticType, typeProvider.stringType);
  }

  test_visitConditionalExpression_differentTypes() async {
    await assertNoErrorsInCode('''
test(bool b) => b ? 1.0 : 0;
''');
    expect(findNode.conditionalExpression('b ? 1.0 : 0').staticType,
        typeProvider.numType);
  }

  test_visitConditionalExpression_sameTypes() async {
    await assertNoErrorsInCode('''
test(bool b) => b ? 1 : 0;
''');
    expect(findNode.conditionalExpression('b ? 1 : 0').staticType,
        same(typeProvider.intType));
  }

  test_visitDoubleLiteral() async {
    await assertNoErrorsInCode('''
test() => 4.33;
''');
    expect(findNode.doubleLiteral('4.33').staticType,
        same(typeProvider.doubleType));
  }

  test_visitInstanceCreationExpression_named() async {
    await assertNoErrorsInCode('''
class C {
  C.m();
}
test() => new C.m();
late C c;
''');
    var cType = findElement.topVar('c').type;
    expect(findNode.instanceCreation('new C.m()').staticType, cType);
  }

  test_visitInstanceCreationExpression_typeParameters() async {
    await assertNoErrorsInCode('''
class C<E> {}
class I {}
test() => new C<I>();
late I i;
''');
    var iType = findElement.topVar('i').type;
    InterfaceType type =
        findNode.instanceCreation('new C<I>()').staticType as InterfaceType;
    List<DartType> typeArgs = type.typeArguments;
    expect(typeArgs.length, 1);
    expect(typeArgs[0], iType);
  }

  test_visitInstanceCreationExpression_unnamed() async {
    await assertNoErrorsInCode('''
class C {}
test() => new C();
late C c;
''');
    var cType = findElement.topVar('c').type;
    expect(findNode.instanceCreation('new C()').staticType, cType);
  }

  test_visitIntegerLiteral() async {
    await assertNoErrorsInCode('''
test() => 42;
''');
    var node = findNode.integerLiteral('42');
    expect(node.staticType, same(typeProvider.intType));
  }

  test_visitIsExpression_negated() async {
    await assertNoErrorsInCode('''
test(Object a) => a is! String;
''');
    expect(findNode.isExpression('a is! String').staticType,
        same(typeProvider.boolType));
  }

  test_visitIsExpression_notNegated() async {
    await assertNoErrorsInCode('''
test(Object a) => a is String;
''');
    expect(findNode.isExpression('a is String').staticType,
        same(typeProvider.boolType));
  }

  test_visitMethodInvocation() async {
    await assertNoErrorsInCode('''
m() => 0;
test() => m();
''');
  }

  test_visitNamedExpression() async {
    await assertNoErrorsInCode('''
test(dynamic d, String a) => d(n: a);
''');
    expect(
        findNode.namedExpression('n: a').staticType, typeProvider.stringType);
  }

  test_visitNullLiteral() async {
    await assertNoErrorsInCode('''
test() => null;
''');
    expect(
        findNode.nullLiteral('null').staticType, same(typeProvider.nullType));
  }

  test_visitParenthesizedExpression() async {
    await assertNoErrorsInCode('''
test() => (0);
''');
    expect(
        findNode.parenthesized('(0)').staticType, same(typeProvider.intType));
  }

  test_visitSimpleStringLiteral() async {
    await assertNoErrorsInCode('''
test() => 'a';
''');
    expect(findNode.stringLiteral("'a'").staticType,
        same(typeProvider.stringType));
  }

  test_visitStringInterpolation() async {
    await assertNoErrorsInCode(r'''
test() => "a${'b'}c";
''');
    expect(findNode.stringInterpolation(r'''"a${'b'}c"''').staticType,
        same(typeProvider.stringType));
  }

  test_visitSuperExpression() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
}
class B extends A {
  test() => super.foo;
}
late B b;
''');
    var bType = findElement.topVar('b').type;
    expect(findNode.super_('super').staticType, bType);
  }

  test_visitSymbolLiteral() async {
    await assertNoErrorsInCode('''
test() => #a;
''');
    expect(
        findNode.symbolLiteral('#a').staticType, same(typeProvider.symbolType));
  }

  test_visitThisExpression() async {
    await assertNoErrorsInCode('''
class A {}
class B extends A {
  test() => this;
}
late B b;
''');
    var bType = findElement.topVar('b').type;
    expect(findNode.this_('this').staticType, bType);
  }

  test_visitThrowExpression_withValue() async {
    await assertNoErrorsInCode('''
test() => throw 0;
''');
    var node = findNode.throw_('throw 0');
    expect(node.staticType, same(typeProvider.bottomType));
  }

  DartType _flatten(DartType type) => typeSystem.flatten(type);
}

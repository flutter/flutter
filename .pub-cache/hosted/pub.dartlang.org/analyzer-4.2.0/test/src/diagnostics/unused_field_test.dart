// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldTest);
  });
}

@reflectiveTest
class UnusedFieldTest extends PubPackageResolutionTest {
  test_isUsed_argument() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    print(++_f);
  }
}
print(x) {}
''');
  }

  test_isUsed_extensionOnClass() async {
    await assertNoErrorsInCode(r'''
class Foo {}
extension Bar on Foo {
  int baz() => _baz;
  static final _baz = 7;
}
''');
  }

  test_isUsed_extensionOnEnum() async {
    await assertNoErrorsInCode(r'''
enum Foo {a, b}
extension Bar on Foo {
  int baz() => _baz;
  static final _baz = 1;
}
''');
  }

  test_isUsed_mixin() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int _f = 0;
}
class Bar with M {
  int g() => _f;
}
''');
  }

  test_isUsed_mixinRestriction() async {
    await assertNoErrorsInCode(r'''
class Foo {
  int _f = 0;
}
mixin M on Foo {
  int g() => _f;
}
''');
  }

  test_isUsed_parameterized_subclass() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {
  T _f;
  A._(this._f);
}
class B extends A<int> {
  B._(int f) : super._(f);
}
void main() {
  B b = B._(7);
  print(b._f == 7);
}
''');
  }

  test_isUsed_publicStaticField_privateClass() async {
    await assertNoErrorsInCode(r'''
class _A {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_publicStaticField_privateExtension() async {
    await assertNoErrorsInCode(r'''
extension _A on String {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_publicStaticField_privateMixin() async {
    await assertNoErrorsInCode(r'''
mixin _A {
  static String f1 = "x";
}
void main() => print(_A.f1);
''');
  }

  test_isUsed_reference_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    print(_f);
  }
}
print(x) {}
''');
  }

  test_isUsed_reference_implicitThis_expressionFunctionBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
  m() => _f;
}
''');
  }

  test_isUsed_reference_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    print(_f);
  }
}
class B extends A {
  int _f = 0;
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_propagatedElement() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
}
main() {
  var a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_staticElement() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
}
main() {
  A a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_isUsed_reference_qualified_unresolved() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
}
main(a) {
  print(a._f);
}
print(x) {}
''');
  }

  test_notUsed_compoundAssign() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    _f += 2;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_constructorFieldInitializers() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  A() : _f = 0;
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_extensionOnClass() async {
    await assertErrorsInCode(r'''
class Foo {}
extension Bar on Foo {
  static final _baz = 7;
}
''', [
      error(HintCode.UNUSED_FIELD, 51, 4),
    ]);
  }

  test_notUsed_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  A(this._f);
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_mixin() async {
    await assertErrorsInCode(r'''
mixin M {
  int _f = 0;
}
class Bar with M {}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_mixinRestriction() async {
    await assertErrorsInCode(r'''
class Foo {
  int _f = 0;
}
mixin M on Foo {}
''', [
      error(HintCode.UNUSED_FIELD, 18, 2),
    ]);
  }

  test_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_nullAssign() async {
    await assertNoErrorsInCode(r'''
class A {
  var _f;
  m() {
    _f ??= doSomething();
  }
}
doSomething() => 0;
''');
  }

  test_notUsed_postfixExpr() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    _f++;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_prefixExpr() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    ++_f;
  }
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_notUsed_publicStaticField_privateClass() async {
    await assertErrorsInCode(r'''
class _A {
  static String f1 = "x";
}
void main() => print(_A);
''', [
      error(HintCode.UNUSED_FIELD, 27, 2),
    ]);
  }

  test_notUsed_publicStaticField_privateExtension() async {
    await assertErrorsInCode(r'''
extension _A on String {
  static String f1 = "x";
}
''', [
      error(HintCode.UNUSED_FIELD, 41, 2),
    ]);
  }

  test_notUsed_publicStaticField_privateMixin() async {
    await assertErrorsInCode(r'''
mixin _A {
  static String f1 = "x";
}
void main() => print(_A);
''', [
      error(HintCode.UNUSED_FIELD, 27, 2),
    ]);
  }

  test_notUsed_referenceInComment() async {
    await assertErrorsInCode(r'''
/// [A._f] is great.
class A {
  int _f = 0;
}
''', [
      error(HintCode.UNUSED_FIELD, 37, 2),
    ]);
  }

  test_notUsed_simpleAssignment() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  m() {
    _f = 1;
  }
}
f(A a) {
  a._f = 2;
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
    ]);
  }

  test_privateEnum_publicConstant_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
}

void f() {
 _E.v;
}
''');
  }

  test_privateEnum_publicConstant_notUsed() async {
    await assertErrorsInCode(r'''
enum _E {
  v;
}

void f() {
  _E;
}
''', [
      error(HintCode.UNUSED_FIELD, 12, 1),
    ]);
  }

  test_privateEnum_publicInstanceField_notUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  final int foo = 0;
}

void f() {
  _E.v;
}
''');
  }

  test_privateEnum_publicStaticField_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  static final int foo = 0;
}

void f() {
  _E.v;
  _E.foo;
}
''');
  }

  test_privateEnum_publicStaticField_notUsed() async {
    await assertErrorsInCode(r'''
enum _E {
  v;
  static final int foo = 0;
}

void f() {
  _E.v;
}
''', [
      error(HintCode.UNUSED_FIELD, 34, 3),
    ]);
  }

  test_privateEnum_values_isUsed() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v
}

void f() {
  _E.values;
}
''');
  }

  test_privateEnum_values_isUsed_hasSetter() async {
    await assertNoErrorsInCode(r'''
enum _E {
  v;
  set foo(int _) {}
}

void f() {
  _E.values;
}
''');
  }

  test_publicEnum_privateConstant_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  _v
}

void f() {
  E._v;
}
''');
  }

  test_publicEnum_privateConstant_notUsed() async {
    await assertErrorsInCode(r'''
enum E {
  _v
}
''', [
      error(HintCode.UNUSED_FIELD, 11, 2),
    ]);
  }

  test_publicEnum_privateInstanceField_isUsed() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  final int _foo = 0;
}

void f() {
  E.v._foo;
}
''');
  }

  test_publicEnum_privateInstanceField_notUsed() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int _foo = 0;
}
''', [
      error(HintCode.UNUSED_FIELD, 26, 4),
    ]);
  }
}

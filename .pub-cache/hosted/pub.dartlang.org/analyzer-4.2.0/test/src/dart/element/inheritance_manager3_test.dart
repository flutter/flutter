// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritanceManager3Test);
    defineReflectiveTests(InheritanceManager3WithoutNullSafetyTest);
  });
}

@reflectiveTest
class InheritanceManager3Test extends _InheritanceManager3Base {
  test_getInheritedMap_topMerge_method() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.6
class A {
  void foo({int a}) {}
}
''');

    await resolveTestCode('''
import 'a.dart';

class B {
  void foo({required int? a}) {}
}

class C implements A, B {
  void foo({int? a}) {}
}
''');

    _assertInheritedMap('C', r'''
A.foo: void Function({int a})
''');
  }

  test_getMember_mixin_notMerge_replace() async {
    await resolveTestCode('''
class A<T> {
  T foo() => throw 0;
}

mixin M<T> {
  T foo() => throw 1;
}

class X extends A<dynamic> with M<Object?> {}
class Y extends A<Object?> with M<dynamic> {}
''');
    _assertGetMember2(
      className: 'X',
      name: 'foo',
      expected: 'M.foo: Object? Function()',
    );
    _assertGetMember2(
      className: 'Y',
      name: 'foo',
      expected: 'M.foo: dynamic Function()',
    );
  }

  test_getMember_optIn_inheritsOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await resolveTestCode('''
import 'a.dart';
class B extends A {
  int? bar(int a) => 0;
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int Function(int, int?)',
    );
    _assertGetMember(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int? Function(int)',
    );
  }

  test_getMember_optIn_inheritsOptOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.6
class A {
  int foo(int a, int b) => 0;
}
''');
    await resolveTestCode('''
import 'a.dart';
class B extends A {
  int? bar(int a) => 0;
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );
    _assertGetMember(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int? Function(int)',
    );
  }

  test_getMember_optIn_topMerge_getter_existing() async {
    await resolveTestCode('''
class A {
  dynamic get foo => 0;
}

class B {
  Object? get foo => 0;
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: Object? Function()',
    );
  }

  test_getMember_optIn_topMerge_getter_synthetic() async {
    await resolveTestCode('''
abstract class A {
  Future<void> get foo;
}

abstract class B {
  Future<dynamic> get foo;
}

abstract class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: Future<Object?> Function()',
    );
  }

  test_getMember_optIn_topMerge_method() async {
    await resolveTestCode('''
class A {
  Object? foo(dynamic x) {}
}

class B {
  dynamic foo(Object? x) {}
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: Object? Function(Object?)',
    );
  }

  test_getMember_optIn_topMerge_setter_existing() async {
    await resolveTestCode('''
class A {
  set foo(dynamic _) {}
}

class B {
  set foo(Object? _) {}
}

class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo=',
      expected: 'B.foo=: void Function(Object?)',
    );
  }

  test_getMember_optIn_topMerge_setter_synthetic() async {
    await resolveTestCode('''
abstract class A {
  set foo(Future<void> _);
}

abstract class B {
  set foo(Future<dynamic> _);
}

abstract class X extends A implements B {}
''');

    _assertGetMember(
      className: 'X',
      name: 'foo=',
      expected: 'X.foo=: void Function(Future<Object?>)',
    );
  }

  test_getMember_optOut_inheritsOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await resolveTestCode('''
// @dart = 2.6
import 'a.dart';
class B extends A {
  int bar(int a) => 0;
}
''');
    _assertGetMember2(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );

    _assertGetMember2(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int* Function(int*)*',
    );
  }

  test_getMember_optOut_mixesOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    await resolveTestCode('''
// @dart = 2.6
import 'a.dart';
class B with A {
  int bar(int a) => 0;
}
''');
    _assertGetMember2(
      className: 'B',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );
    _assertGetMember2(
      className: 'B',
      name: 'bar',
      expected: 'B.bar: int* Function(int*)*',
    );
  }

  test_getMember_optOut_passOptIn() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  int foo(int a, int? b) => 0;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.6
import 'a.dart';
class B extends A {
  int bar(int a) => 0;
}
''');
    await resolveTestCode('''
import 'b.dart';
class C extends B {}
''');
    _assertGetMember(
      className: 'C',
      name: 'foo',
      expected: 'A.foo: int* Function(int*, int*)*',
    );
    _assertGetMember(
      className: 'C',
      name: 'bar',
      expected: 'B.bar: int* Function(int*)*',
    );
  }
}

@reflectiveTest
class InheritanceManager3WithoutNullSafetyTest
    extends _InheritanceManager3Base {
  test_getInherited_closestSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

class X extends B {
  void foo() {}
}
''');
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: void Function()',
    );
  }

  test_getInherited_interfaces() async {
    await resolveTestCode('''
abstract class I {
  void foo();
}

abstract class J {
  void foo();
}

class X implements I, J {
  void foo() {}
}
''');
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'I.foo: void Function()',
    );
  }

  test_getInherited_mixin() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

mixin M {
  void foo() {}
}

class X extends A with M {
  void foo() {}
}
''');
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'M.foo: void Function()',
    );
  }

  test_getInherited_preferImplemented() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class I {
  void foo() {}
}

class X extends A implements I {
  void foo() {}
}
''');
    _assertGetInherited(
      className: 'X',
      name: 'foo',
      expected: 'A.foo: void Function()',
    );
  }

  test_getInheritedConcreteMap_accessor_extends() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedConcreteMap_accessor_implements() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_accessor_with() async {
    await resolveTestCode('''
mixin A {
  int get foo => 0;
}

class B extends Object with A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedConcreteMap_implicitExtends() async {
    await resolveTestCode('''
class A {}
''');
    _assertInheritedConcreteMap('A', '');
  }

  test_getInheritedConcreteMap_method_extends() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedConcreteMap_method_extends_abstract() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

class B extends A {}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_method_extends_invalidForImplements() async {
    await resolveTestCode('''
abstract class I {
  void foo(int x, {int y});
  void bar(String s);
}

class A {
  void foo(int x) {}
}

class C extends A implements I {}
''');
    _assertInheritedConcreteMap('C', r'''
A.foo: void Function(int)
''');
  }

  test_getInheritedConcreteMap_method_implements() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    _assertInheritedConcreteMap('B', '');
  }

  test_getInheritedConcreteMap_method_with() async {
    await resolveTestCode('''
mixin A {
  void foo() {}
}

class B extends Object with A {}
''');
    _assertInheritedConcreteMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedConcreteMap_method_with2() async {
    await resolveTestCode('''
mixin A {
  void foo() {}
}

mixin B {
  void bar() {}
}

class C extends Object with A, B {}
''');
    _assertInheritedConcreteMap('C', r'''
A.foo: void Function()
B.bar: void Function()
''');
  }

  test_getInheritedMap_accessor_extends() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

class B extends A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedMap_accessor_implements() async {
    await resolveTestCode('''
class A {
  int get foo => 0;
}

abstract class B implements A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedMap_accessor_with() async {
    await resolveTestCode('''
mixin A {
  int get foo => 0;
}

class B extends Object with A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
''');
  }

  test_getInheritedMap_closestSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

class X extends B {}
''');
    _assertInheritedMap('X', r'''
B.foo: void Function()
''');
  }

  test_getInheritedMap_field_extends() async {
    await resolveTestCode('''
class A {
  int foo;
}

class B extends A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
A.foo=: void Function(int)
''');
  }

  test_getInheritedMap_field_implements() async {
    await resolveTestCode('''
class A {
  int foo;
}

abstract class B implements A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
A.foo=: void Function(int)
''');
  }

  test_getInheritedMap_field_with() async {
    await resolveTestCode('''
mixin A {
  int foo;
}

class B extends Object with A {}
''');
    _assertInheritedMap('B', r'''
A.foo: int Function()
A.foo=: void Function(int)
''');
  }

  test_getInheritedMap_implicitExtendsObject() async {
    await resolveTestCode('''
class A {}
''');
    _assertInheritedMap('A', '');
  }

  test_getInheritedMap_method_extends() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {}
''');
    _assertInheritedMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_method_implements() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

abstract class B implements A {}
''');
    _assertInheritedMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_method_with() async {
    await resolveTestCode('''
mixin A {
  void foo() {}
}

class B extends Object with A {}
''');
    _assertInheritedMap('B', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_preferImplemented() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class I {
  void foo() {}
}

class X extends A implements I {
  void foo() {}
}
''');
    _assertInheritedMap('X', r'''
A.foo: void Function()
''');
  }

  test_getInheritedMap_union_conflict() async {
    await resolveTestCode('''
abstract class I {
  int foo();
  void bar();
}

abstract class J {
  double foo();
  void bar();
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.bar: void Function()
''');
  }

  test_getInheritedMap_union_differentNames() async {
    await resolveTestCode('''
abstract class I {
  int foo();
}

abstract class J {
  double bar();
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.foo: int Function()
J.bar: double Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_getters() async {
    await resolveTestCode('''
abstract class I {
  int get foo;
}

abstract class J {
  int get foo;
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.foo: int Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_methods() async {
    await resolveTestCode('''
abstract class I {
  void foo();
}

abstract class J {
  void foo();
}

abstract class A implements I, J {}
''');
    _assertInheritedMap('A', r'''
I.foo: void Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_2_setters() async {
    await resolveTestCode('''
abstract class I {
  void set foo(num _);
}

abstract class J {
  void set foo(int _);
}

abstract class A implements I, J {}
abstract class B implements J, I {}
''');
    _assertInheritedMap('A', r'''
I.foo=: void Function(num)
''');

    _assertInheritedMap('B', r'''
I.foo=: void Function(num)
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_getters() async {
    await resolveTestCode('''
class A {}
class B extends A {}
class C extends B {}

abstract class I1 {
  A get foo;
}

abstract class I2 {
  B get foo;
}

abstract class I3 {
  C get foo;
}

abstract class D implements I1, I2, I3 {}
abstract class E implements I3, I2, I1 {}
''');
    _assertInheritedMap('D', r'''
I3.foo: C Function()
''');

    _assertInheritedMap('E', r'''
I3.foo: C Function()
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_methods() async {
    await resolveTestCode('''
class A {}
class B extends A {}
class C extends B {}

abstract class I1 {
  void foo(A _);
}

abstract class I2 {
  void foo(B _);
}

abstract class I3 {
  void foo(C _);
}

abstract class D implements I1, I2, I3 {}
abstract class E implements I3, I2, I1 {}
''');
    _assertInheritedMap('D', r'''
I1.foo: void Function(A)
''');
  }

  test_getInheritedMap_union_multipleSubtypes_3_setters() async {
    await resolveTestCode('''
class A {}
class B extends A {}
class C extends B {}

abstract class I1 {
  set foo(A _);
}

abstract class I2 {
  set foo(B _);
}

abstract class I3 {
  set foo(C _);
}

abstract class D implements I1, I2, I3 {}
abstract class E implements I3, I2, I1 {}
''');
    _assertInheritedMap('D', r'''
I1.foo=: void Function(A)
''');

    _assertInheritedMap('E', r'''
I1.foo=: void Function(A)
''');
  }

  test_getInheritedMap_union_oneSubtype_2_methods() async {
    await resolveTestCode('''
abstract class I1 {
  int foo();
}

abstract class I2 {
  int foo([int _]);
}

abstract class A implements I1, I2 {}
abstract class B implements I2, I1 {}
''');
    _assertInheritedMap('A', r'''
I2.foo: int Function([int])
''');

    _assertInheritedMap('B', r'''
I2.foo: int Function([int])
''');
  }

  test_getInheritedMap_union_oneSubtype_3_methods() async {
    await resolveTestCode('''
abstract class I1 {
  int foo();
}

abstract class I2 {
  int foo([int _]);
}

abstract class I3 {
  int foo([int _, int __]);
}

abstract class A implements I1, I2, I3 {}
abstract class B implements I3, I2, I1 {}
''');
    _assertInheritedMap('A', r'''
I3.foo: int Function([int, int])
''');

    _assertInheritedMap('B', r'''
I3.foo: int Function([int, int])
''');
  }

  test_getMember() async {
    await resolveTestCode('''
abstract class I1 {
  void f(int i);
}

abstract class I2 {
  void f(Object o);
}

abstract class C implements I1, I2 {}
''');
    _assertGetMember(
      className: 'C',
      name: 'f',
      expected: 'I2.f: void Function(Object)',
    );
  }

  test_getMember_concrete() async {
    await resolveTestCode('''
class A {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_abstract() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}
''');
    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
    );
  }

  test_getMember_concrete_fromMixedClass() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class X with A {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_fromMixedClass2() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B = Object with A;

class X with B {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_fromMixedClass_skipObject() async {
    await resolveTestCode('''
class A {
  String toString() => 'A';
}

class B {}

class X extends A with B {}
''');
    _assertGetMember(
      className: 'X',
      name: 'toString',
      concrete: true,
      expected: 'A.toString: String Function()',
    );
  }

  test_getMember_concrete_fromMixin() async {
    await resolveTestCode('''
mixin M {
  void foo() {}
}

class X with M {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      concrete: true,
      expected: 'M.foo: void Function()',
    );
  }

  test_getMember_concrete_fromSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {}

abstract class C extends B {}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_missing() async {
    await resolveTestCode('''
abstract class A {}
''');
    _assertGetMember(
      className: 'A',
      name: 'foo',
      concrete: true,
    );
  }

  test_getMember_concrete_noSuchMethod() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

abstract class C extends B {}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );

    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_concrete_noSuchMethod_mixin() async {
    await resolveTestCode('''
class A {
  void foo();

  noSuchMethod(_) {}
}

abstract class B extends Object with A {}
''');
// noSuchMethod forwarders are not mixed-in.
    // https://github.com/dart-lang/sdk/issues/33553#issuecomment-424638320
    _assertGetMember(
      className: 'B',
      name: 'foo',
      concrete: true,
    );
  }

  test_getMember_concrete_noSuchMethod_moreSpecificSignature() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B implements A {
  noSuchMethod(_) {}
}

class C extends B {
  void foo([int a]);
}
''');
    _assertGetMember(
      className: 'C',
      name: 'foo',
      concrete: true,
      expected: 'C.foo: void Function([int])',
    );
  }

  test_getMember_method_covariantByDeclaration_inherited() async {
    await resolveTestCode('''
abstract class A {
  void foo(covariant num a);
}

abstract class B extends A {
  void foo(int a);
}
''');
    var member = manager.getMember2(
      findElement.classOrMixin('B'),
      Name(null, 'foo'),
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    // But we need a way to check covariance.
    // Maybe check the element display string, not the type.
    expect(member.parameters[0].isCovariant, isTrue);
  }

  test_getMember_method_covariantByDeclaration_merged() async {
    await resolveTestCode('''
class A {
  void foo(covariant num a) {}
}

class B {
  void foo(int a) {}
}

class C extends B implements A {}
''');
    var member = manager.getMember2(
      findElement.classOrMixin('C'),
      Name(null, 'foo'),
      concrete: true,
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    expect(member.declaration, same(findElement.method('foo', of: 'B')));
    expect(member.parameters[0].isCovariant, isTrue);
  }

  test_getMember_preferLatest_mixin() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

mixin M1 {
  void foo() {}
}

mixin M2 {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends A with M1, M2 implements I {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'M2.foo: void Function()',
    );
  }

  test_getMember_preferLatest_superclass() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends B implements I {}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'B.foo: void Function()',
    );
  }

  test_getMember_preferLatest_this() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

abstract class I {
  void foo();
}

class X extends A implements I {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      expected: 'X.foo: void Function()',
    );
  }

  test_getMember_setter_covariantByDeclaration_inherited() async {
    await resolveTestCode('''
abstract class A {
  set foo(covariant num a);
}

abstract class B extends A {
  set foo(int a);
}
''');
    var member = manager.getMember2(
      findElement.classOrMixin('B'),
      Name(null, 'foo='),
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    // But we need a way to check covariance.
    // Maybe check the element display string, not the type.
    expect(member.parameters[0].isCovariant, isTrue);
  }

  test_getMember_setter_covariantByDeclaration_merged() async {
    await resolveTestCode('''
class A {
  set foo(covariant num a) {}
}

class B {
  set foo(int a) {}
}

class C extends B implements A {}
''');
    var member = manager.getMember2(
      findElement.classOrMixin('C'),
      Name(null, 'foo='),
      concrete: true,
    )!;
    // TODO(scheglov) It would be nice to use `_assertGetMember`.
    expect(member.declaration, same(findElement.setter('foo', of: 'B')));
    expect(member.parameters[0].isCovariant, isTrue);
  }

  test_getMember_super_abstract() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

class B extends A {
  noSuchMethod(_) {}
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_forMixin_interface() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

mixin M implements A {}
''');
    _assertGetMember(
      className: 'M',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_forMixin_superclassConstraint() async {
    await resolveTestCode('''
abstract class A {
  void foo();
}

mixin M on A {}
''');
    _assertGetMember(
      className: 'M',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_super_forObject() async {
    await resolveTestCode('''
class A {}
''');
    var member = manager.getMember2(
      typeProvider.objectType.element,
      Name(null, 'hashCode'),
      forSuper: true,
    );
    expect(member, isNull);
  }

  test_getMember_super_fromMixin() async {
    await resolveTestCode('''
mixin M {
  void foo() {}
}

class X extends Object with M {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'X',
      name: 'foo',
      forSuper: true,
      expected: 'M.foo: void Function()',
    );
  }

  test_getMember_super_fromSuper() async {
    await resolveTestCode('''
class A {
  void foo() {}
}

class B extends A {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: void Function()',
    );
  }

  test_getMember_super_missing() async {
    await resolveTestCode('''
class A {}

class B extends A {}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
    );
  }

  test_getMember_super_noSuchMember() async {
    await resolveTestCode('''
class A {
  void foo();
  noSuchMethod(_) {}
}

class B extends A {
  void foo() {}
}
''');
    _assertGetMember(
      className: 'B',
      name: 'foo',
      forSuper: true,
      expected: 'A.foo: void Function()',
    );
  }
}

class _InheritanceManager3Base extends PubPackageResolutionTest {
  late final InheritanceManager3 manager;

  @override
  Future<void> resolveTestFile() async {
    await super.resolveTestFile();
    manager = InheritanceManager3();
  }

  void _assertExecutable(ExecutableElement? element, String? expected) {
    if (expected != null && element != null) {
      var enclosingElement = element.enclosingElement;

      var type = element.type;
      var typeStr = typeString(type);

      var actual = '${enclosingElement.name}.${element.name}: $typeStr';
      expect(actual, expected);

      if (element is PropertyAccessorElement) {
        var variable = element.variable;
        expect(variable.enclosingElement, same(element.enclosingElement));
        expect(variable.name, element.displayName);
        if (element.isGetter) {
          expect(variable.type, element.returnType);
        } else {
          expect(variable.type, element.parameters[0].type);
        }
      }
    } else {
      expect(element, isNull);
    }
  }

  void _assertGetInherited({
    required String className,
    required String name,
    String? expected,
  }) {
    var member = manager.getInherited2(
      findElement.classOrMixin(className),
      Name(null, name),
    );

    _assertExecutable(member, expected);
  }

  void _assertGetMember({
    required String className,
    required String name,
    String? expected,
    bool concrete = false,
    bool forSuper = false,
  }) {
    var member = manager.getMember2(
      findElement.classOrMixin(className),
      Name(null, name),
      concrete: concrete,
      forSuper: forSuper,
    );

    _assertExecutable(member, expected);
  }

  void _assertGetMember2({
    required String className,
    required String name,
    String? expected,
  }) {
    _assertGetMember(
      className: className,
      name: name,
      expected: expected,
      concrete: false,
    );

    _assertGetMember(
      className: className,
      name: name,
      expected: expected,
      concrete: true,
    );
  }

  void _assertInheritedConcreteMap(String className, String expected) {
    var element = findElement.classOrMixin(className);
    var map = manager.getInheritedConcreteMap2(element);
    _assertNameToExecutableMap(map, expected);
  }

  void _assertInheritedMap(String className, String expected) {
    var element = findElement.classOrMixin(className);
    var map = manager.getInheritedMap2(element);
    _assertNameToExecutableMap(map, expected);
  }

  void _assertNameToExecutableMap(
      Map<Name, ExecutableElement> map, String expected) {
    var lines = <String>[];
    for (var entry in map.entries) {
      var element = entry.value;
      var type = element.type;

      var enclosingElement = element.enclosingElement;
      if (enclosingElement.name == 'Object') continue;

      var typeStr = type.getDisplayString(withNullability: false);
      lines.add('${enclosingElement.name}.${element.name}: $typeStr');
    }

    lines.sort();
    var actual = lines.isNotEmpty ? '${lines.join('\n')}\n' : '';

    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }
}

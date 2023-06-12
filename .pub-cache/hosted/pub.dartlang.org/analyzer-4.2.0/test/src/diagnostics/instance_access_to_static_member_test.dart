// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceAccessToStaticMemberTest);
  });
}

@reflectiveTest
class InstanceAccessToStaticMemberTest extends PubPackageResolutionTest {
  test_class_method() async {
    await assertErrorsInCode('''
class C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 47, 1,
          correctionContains: "class 'C'"),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_extension_getter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static int get a => 0;
}

C g(C c) => C();
f(C c) {
  g(c).a;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 92, 1,
          correctionContains: "extension 'E'"),
    ]);
    assertElement(
      findNode.simple('a;'),
      findElement.getter('a'),
    );
  }

  test_extension_getter_unnamed() async {
    await assertErrorsInCode('''
class C {}

extension on C {
  static int get a => 0;
}

C g(C c) => C();
f(C c) {
  g(c).a;
}
''', [
      error(
          CompileTimeErrorCode
              .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
          90,
          1),
    ]);
    assertElement(
      findNode.simple('a;'),
      findElement.getter('a'),
    );
  }

  test_extension_method() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 68, 1,
          correctionContains: "extension 'E'"),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_extension_method_unnamed() async {
    await assertErrorsInCode('''
class C {}

extension on C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(
          CompileTimeErrorCode
              .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
          66,
          1),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_extension_referring_to_class_member() async {
    await assertErrorsInCode('''
class C {
  static void m() {}
}
extension on int {
  foo(C c) {
    c.m(); // ERROR
  }
}
test(int i) {
  i.foo(C());
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 71, 1,
          correctionContains: "class 'C'"),
    ]);
  }

  test_extension_setter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static set a(int v) {}
}

f(C c) {
  c.a = 2;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 72, 1),
    ]);

    assertResolvedNodeText(findNode.assignment('a ='), r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: c
      staticElement: self::@function::f::@parameter::c
      staticType: C
    period: .
    identifier: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@extension::E::@setter::a::@parameter::v
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::a
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_method_reference() async {
    await assertErrorsInCode(r'''
class A {
  static m() {}
}
f(A a) {
  a.m;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1,
          correctionContains: "class 'A'"),
    ]);
  }

  test_method_reference_extension() async {
    await assertErrorsInCode(r'''
extension E on int {
  static m<T>() {}
}
f(int a) {
  a.m<int>;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 57, 1,
          correctionContains: "extension 'E'"),
    ]);
  }

  test_method_reference_extension_unnamed() async {
    await assertErrorsInCode(r'''
extension on int {
  static m<T>() {}
}
f(int a) {
  a.m<int>;
}
''', [
      error(
          CompileTimeErrorCode
              .INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION,
          55,
          1),
    ]);
  }

  test_method_reference_mixin() async {
    await assertErrorsInCode(r'''
mixin A {
  static m() {}
}
f(A a) {
  a.m;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1,
          correctionContains: "mixin 'A'"),
    ]);
  }

  test_method_reference_typeInstantiation() async {
    await assertErrorsInCode(r'''
class A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 44, 1,
          correctionContains: "class 'A'"),
    ]);
  }

  test_method_reference_typeInstantiation_mixin() async {
    await assertErrorsInCode(r'''
mixin A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 44, 1,
          correctionContains: "mixin 'A'"),
    ]);
  }

  test_mixin_method() async {
    await assertErrorsInCode('''
mixin A {
  static void a() {}
}

f(A a) {
  a.a();
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 47, 1,
          correctionContains: "mixin 'A'"),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_propertyAccess_field() async {
    await assertErrorsInCode(r'''
class A {
  static var f;
}
f(A a) {
  a.f;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1),
    ]);
  }

  test_propertyAccess_getter() async {
    await assertErrorsInCode(r'''
class A {
  static get f => 42;
}
f(A a) {
  a.f;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 47, 1),
    ]);
  }

  test_propertyAccess_setter() async {
    await assertErrorsInCode(r'''
class A {
  static set f(x) {}
}
f(A a) {
  a.f = 42;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 46, 1),
    ]);
  }
}

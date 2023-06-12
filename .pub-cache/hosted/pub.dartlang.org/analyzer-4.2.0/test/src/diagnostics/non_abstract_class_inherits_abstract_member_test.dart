// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      NonAbstractClassInheritsAbstractMemberTest,
    );
    defineReflectiveTests(
      NonAbstractClassInheritsAbstractMemberWithoutNullSafetyTest,
    );
  });
}

@reflectiveTest
class NonAbstractClassInheritsAbstractMemberTest
    extends PubPackageResolutionTest
    with NonAbstractClassInheritsAbstractMemberTestCases {
  test_abstract_field_final_implement_getter() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract final int x;
}
class B implements A {
  int get x => 0;
}
''');
  }

  test_abstract_field_final_implement_none() async {
    await assertErrorsInCode('''
abstract class A {
  abstract final int x;
}
class B implements A {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          51,
          1),
    ]);
  }

  test_abstract_field_implement_getter() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x;
}
class B implements A {
  int get x => 0;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          45,
          1),
    ]);
  }

  test_abstract_field_implement_getter_and_setter() async {
    await assertNoErrorsInCode('''
abstract class A {
  abstract int x;
}
class B implements A {
  int get x => 0;
  void set x(int value) {}
}
''');
  }

  test_abstract_field_implement_none() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x;
}
class B implements A {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          45,
          1),
    ]);
  }

  test_abstract_field_implement_setter() async {
    await assertErrorsInCode('''
abstract class A {
  abstract int x;
}
class B implements A {
  void set x(int value) {}
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          45,
          1),
    ]);
  }

  test_enum_getter_fromInterface() async {
    await assertErrorsInCode('''
class A {
  int get foo => 0;
}

enum E implements A {
  v;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          38,
          1),
    ]);
  }

  test_enum_getter_fromMixin() async {
    await assertErrorsInCode('''
mixin M {
  int get foo;
}

enum E with M {
  v;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          33,
          1),
    ]);
  }

  test_enum_method_fromInterface() async {
    await assertErrorsInCode('''
class A {
  void foo() {}
}

enum E implements A {
  v;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          34,
          1),
    ]);
  }

  test_enum_method_fromMixin() async {
    await assertErrorsInCode('''
mixin M {
  void foo();
}

enum E with M {
  v;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          32,
          1),
    ]);
  }

  test_enum_setter_fromInterface() async {
    await assertErrorsInCode('''
class A {
  set foo(int _) {}
}

enum E implements A {
  v;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          38,
          1),
    ]);
  }

  test_enum_setter_fromMixin() async {
    await assertErrorsInCode('''
mixin M {
  set foo(int _);
}

enum E with M {
  v;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36,
          1),
    ]);
  }

  test_external_field_final_implement_getter() async {
    await assertNoErrorsInCode('''
class A {
  external final int x;
}
class B implements A {
  int get x => 0;
}
''');
  }

  test_external_field_final_implement_none() async {
    await assertErrorsInCode('''
class A {
  external final int x;
}
class B implements A {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          42,
          1),
    ]);
  }

  test_external_field_implement_getter() async {
    await assertErrorsInCode('''
class A {
  external int x;
}
class B implements A {
  int get x => 0;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36,
          1),
    ]);
  }

  test_external_field_implement_getter_and_setter() async {
    await assertNoErrorsInCode('''
class A {
  external int x;
}
class B implements A {
  int get x => 0;
  void set x(int value) {}
}
''');
  }

  test_external_field_implement_none() async {
    await assertErrorsInCode('''
class A {
  external int x;
}
class B implements A {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          36,
          1),
    ]);
  }

  test_external_field_implement_setter() async {
    await assertErrorsInCode('''
class A {
  external int x;
}
class B implements A {
  void set x(int value) {}
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36,
          1),
    ]);
  }
}

mixin NonAbstractClassInheritsAbstractMemberTestCases
    on PubPackageResolutionTest {
  test_abstractsDontOverrideConcretes_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get g => 0;
}
abstract class B extends A {
  int get g;
}
class C extends B {}
''');
  }

  test_abstractsDontOverrideConcretes_method() async {
    await assertNoErrorsInCode(r'''
class A {
  m(p) {}
}
abstract class B extends A {
  m(p);
}
class C extends B {}
''');
  }

  test_abstractsDontOverrideConcretes_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  set s(v) {}
}
abstract class B extends A {
  set s(v);
}
class C extends B {}
''');
  }

  test_classTypeAlias_interface() async {
    // issue 15979
    await assertNoErrorsInCode(r'''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
abstract class B = A with M implements I;
''');
  }

  test_classTypeAlias_mixin() async {
    // issue 15979
    await assertNoErrorsInCode(r'''
abstract class M {
  m();
}
abstract class A {}
abstract class B = A with M;
''');
  }

  test_classTypeAlias_superclass() async {
    // issue 15979
    await assertNoErrorsInCode(r'''
class M {}
abstract class A {
  m();
}
abstract class B = A with M;
''');
  }

  test_fivePlus() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
  q();
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
          62,
          1),
    ]);
  }

  test_four() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
  p();
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
          55,
          1),
    ]);
  }

  test_mixin_concreteGetter() async {
    // issue 17034
    await assertNoErrorsInCode(r'''
class A {
  var a;
}
abstract class M {
  get a;
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_mixin_concreteMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
abstract class M {
  m();
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_mixin_concreteSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  var a;
}
abstract class M {
  set a(dynamic v);
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_noSuchMethod_concreteAccessor() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get g;
}
class B extends A {
  noSuchMethod(v) => '';
}
''');
  }

  test_noSuchMethod_concreteMethod() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  m(p);
}
class B extends A {
  noSuchMethod(v) => '';
}
''');
  }

  test_noSuchMethod_mixin() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends Object with A {
  m(p);
}
''');
  }

  test_noSuchMethod_superclass() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends A {
  m(p);
}
''');
  }

  test_one_classTypeAlias_interface() async {
    // issue 15979
    await assertErrorsInCode('''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
class B = A with M implements I;
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          74,
          1),
    ]);
  }

  test_one_classTypeAlias_mixin() async {
    // issue 15979
    await assertErrorsInCode('''
abstract class M {
  m();
}
abstract class A {}
class B = A with M;
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          54,
          1),
    ]);
  }

  test_one_classTypeAlias_superclass() async {
    // issue 15979
    await assertErrorsInCode('''
class M {}
abstract class A {
  m();
}
class B = A with M;
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          45,
          1),
    ]);
  }

  test_one_getter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  int get g {return 1;}
}
class C implements I {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          42,
          1),
    ]);
  }

  test_one_getter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  int get g;
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          40,
          1),
    ]);
  }

  test_one_method_fromInterface() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28,
          1),
    ]);
  }

  test_one_method_fromInterface_abstractNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
}
class C implements I {
  noSuchMethod(v);
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          28,
          1),
    ]);
  }

  test_one_method_fromInterface_abstractOverrideNSM() async {
    await assertNoErrorsInCode('''
class I {
  m(p) {}
}
class B {
  noSuchMethod(v) => null;
}
class C extends B implements I {
  noSuchMethod(v);
}
''');
  }

  test_one_method_fromInterface_ifcNSM() async {
    await assertErrorsInCode('''
class I {
  m(p) {}
  noSuchMethod(v) => null;
}
class C implements I {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          55,
          1),
    ]);
  }

  test_one_method_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  m(p);
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          35,
          1),
    ]);
  }

  test_one_method_optionalParamCount() async {
    // issue 7640
    await assertErrorsInCode('''
abstract class A {
  int x(int a);
}
abstract class B {
  int x(int a, [int b]);
}
class C implements A, B {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          89,
          1),
    ]);
  }

  test_one_mixinInherits_getter() async {
    // issue 15001
    await assertErrorsInCode('''
abstract class A { get g1; get g2; }
abstract class B implements A { get g1 => 1; }
class C extends Object with B {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          90,
          1),
    ]);
  }

  test_one_mixinInherits_method() async {
    // issue 15001
    await assertErrorsInCode('''
abstract class A { m1(); m2(); }
abstract class B implements A { m1() => 1; }
class C extends Object with B {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84,
          1),
    ]);
  }

  test_one_mixinInherits_setter() async {
    // issue 15001
    await assertErrorsInCode('''
abstract class A { set s1(v); set s2(v); }
abstract class B implements A { set s1(v) {} }
class C extends Object with B {}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          96,
          1),
    ]);
  }

  test_one_noSuchMethod_interface() async {
    // issue 15979
    await assertErrorsInCode('''
class I {
  noSuchMethod(v) => '';
}
abstract class A {
  m();
}
class B extends A implements I {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          71,
          1),
    ]);
  }

  test_one_setter_and_implicitSetter() async {
    // test from language/override_inheritance_abstract_test_14.dart
    await assertErrorsInCode('''
abstract class A {
  set field(_);
}
abstract class I {
  var field;
}
class B extends A implements I {
  get field => 0;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          77,
          1),
    ]);
  }

  test_one_setter_fromInterface() async {
    await assertErrorsInCode('''
class I {
  set s(int i) {}
}
class C implements I {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          36,
          1),
    ]);
  }

  test_one_setter_fromSuperclass() async {
    await assertErrorsInCode('''
abstract class A {
  set s(int i);
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          43,
          1),
    ]);
  }

  test_one_superclasses_interface() async {
    // issue 11154
    await assertErrorsInCode('''
class A {
  get a => 'a';
}
abstract class B implements A {
  get b => 'b';
}
class C extends B {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          84,
          1),
    ]);
  }

  test_one_variable_fromInterface_missingGetter() async {
    // issue 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  set v(_) {}
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27,
          1),
    ]);
  }

  test_one_variable_fromInterface_missingSetter() async {
    // issue 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
  get v => 1;
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          27,
          1),
    ]);
  }

  test_overridesConcreteMethodInObject() async {
    await assertNoErrorsInCode(r'''
class A {
  String toString([String prefix = '']) => '${prefix}Hello';
}
class C {}
class B extends A with C {}
''');
  }

  test_three() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
  o();
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE,
          48,
          1),
    ]);
  }

  test_two() async {
    await assertErrorsInCode('''
abstract class A {
  m();
  n();
}
class C extends A {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          41,
          1),
    ]);
  }

  test_two_fromInterface_missingBoth() async {
    // issue 16133
    await assertErrorsInCode('''
class I {
  var v;
}
class C implements I {
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO,
          27,
          1),
    ]);
  }
}

@reflectiveTest
class NonAbstractClassInheritsAbstractMemberWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with
        WithoutNullSafetyMixin,
        NonAbstractClassInheritsAbstractMemberTestCases {}

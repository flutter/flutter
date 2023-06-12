// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDriverResolutionTest);
  });
}

@reflectiveTest
class ClassDriverResolutionTest extends PubPackageResolutionTest {
  test_element_allSupertypes() async {
    await assertNoErrorsInCode(r'''
class A {}
class B {}
class C {}
class D {}
class E {}

class X1 extends A {}
class X2 implements B {}
class X3 extends A implements B {}
class X4 extends A with B implements C {}
class X5 extends A with B, C implements D, E {}
''');

    assertElementTypes(
      findElement.class_('X1').allSupertypes,
      ['Object', 'A'],
    );
    assertElementTypes(
      findElement.class_('X2').allSupertypes,
      ['Object', 'B'],
    );
    assertElementTypes(
      findElement.class_('X3').allSupertypes,
      ['Object', 'A', 'B'],
    );
    assertElementTypes(
      findElement.class_('X4').allSupertypes,
      ['Object', 'A', 'B', 'C'],
    );
    assertElementTypes(
      findElement.class_('X5').allSupertypes,
      ['Object', 'A', 'B', 'C', 'D', 'E'],
    );
  }

  test_element_allSupertypes_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T, U> {}
class C<T> extends B<int, T> {}

class X1 extends A<String> {}
class X2 extends B<String, List<int>> {}
class X3 extends C<double> {}
''');

    assertElementTypes(
      findElement.class_('X1').allSupertypes,
      ['Object', 'A<String>'],
    );
    assertElementTypes(
      findElement.class_('X2').allSupertypes,
      ['Object', 'B<String, List<int>>'],
    );
    assertElementTypes(
      findElement.class_('X3').allSupertypes,
      ['Object', 'B<int, double>', 'C<double>'],
    );
  }

  test_element_allSupertypes_recursive() async {
    await assertErrorsInCode(r'''
class A extends B {}
class B extends C {}
class C extends A {}

class X extends A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 48, 1),
    ]);

    assertElementTypes(
      findElement.class_('X').allSupertypes,
      ['A', 'B', 'C'],
    );
  }

  test_element_typeFunction_extends() async {
    await assertErrorsInCode(r'''
class A extends Function {}
''', [
      error(HintCode.DEPRECATED_EXTENDS_FUNCTION, 16, 8),
    ]);
    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_with() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C extends Object with A, Function, B {}
''', [
      error(HintCode.DEPRECATED_MIXIN_FUNCTION, 53, 8),
    ]);

    assertElementTypes(
      findElement.class_('C').mixins,
      ['A', 'B'],
    );
  }

  test_error_conflictingConstructorAndStaticField_field() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static int foo = 0;
}
''', [
      error(
          CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD, 14, 3),
    ]);
  }

  test_error_conflictingConstructorAndStaticField_getter() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER, 14,
          3),
    ]);
  }

  test_error_conflictingConstructorAndStaticField_OK_notSameClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static int foo = 0;
}
class B extends A {
  B.foo();
}
''');
  }

  test_error_conflictingConstructorAndStaticField_OK_notStatic() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
  int foo = 0;
}
''');
  }

  test_error_conflictingConstructorAndStaticField_setter() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER, 14,
          3),
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD, 14,
          3),
    ]);
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notSameClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
  }

  test_error_conflictingConstructorAndStaticMethod_OK_notStatic() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
  void foo() {}
}
''');
  }

  test_error_conflictingFieldAndMethod_inSuper_field() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_error_conflictingFieldAndMethod_inSuper_getter() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_error_conflictingFieldAndMethod_inSuper_setter() async {
    await assertErrorsInCode(r'''
class A {
  foo() {}
}
class B extends A {
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD, 49, 3),
    ]);
  }

  test_error_conflictingMethodAndField_inSuper_field() async {
    await assertErrorsInCode(r'''
class A {
  int foo = 0;
}
class B extends A {
  foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 49, 3),
    ]);
  }

  test_error_conflictingMethodAndField_inSuper_getter() async {
    await assertErrorsInCode(r'''
class A {
  get foo => 0;
}
class B extends A {
  foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 50, 3),
    ]);
  }

  test_error_conflictingMethodAndField_inSuper_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD, 50, 3),
    ]);
  }

  test_error_duplicateConstructorNamed() async {
    await assertErrorsInCode(r'''
class C {
  C.foo();
  C.foo();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME, 23, 5),
    ]);
  }

  test_error_duplicateConstructorNamed_oneIsInvalid() async {
    await assertErrorsInCode(r'''
class A {}
class C {
  A.foo();
  C.foo();
}
''', [
      error(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 23, 1),
    ]);
  }

  test_error_duplicateConstructorUnnamed() async {
    await assertErrorsInCode(r'''
class C {
  C();
  C();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 19, 1),
    ]);
  }

  test_error_duplicateConstructorUnnamed_bothNew() async {
    await assertErrorsInCode(r'''
class C {
  C.new();
  C.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 23, 5),
    ]);
  }

  test_error_duplicateConstructorUnnamed_oneIsInvalid() async {
    await assertErrorsInCode(r'''
class A {}
class C {
  A.new();
  C();
}
''', [
      error(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 23, 1),
    ]);
  }

  test_error_duplicateConstructorUnnamed_oneNew() async {
    await assertErrorsInCode(r'''
class C {
  C();
  C.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 19, 5),
    ]);
  }

  test_error_extendsNonClass_dynamic() async {
    await assertErrorsInCode(r'''
class A extends dynamic {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 7),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_error_extendsNonClass_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends E {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 31, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');

    var eRef = findNode.namedType('E {}');
    assertNamedType(eRef, findElement.enum_('E'), 'E');
  }

  test_error_extendsNonClass_mixin() async {
    await assertErrorsInCode(r'''
mixin M {}
class A extends M {} // ref
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');

    var mRef = findNode.namedType('M {} // ref');
    assertNamedType(mRef, findElement.mixin('M'), 'M');
  }

  test_error_extendsNonClass_variable() async {
    await assertErrorsInCode(r'''
int v = 0;
class A extends v {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_error_extendsNonClass_variable_generic() async {
    await assertErrorsInCode(r'''
int v = 0;
class A extends v<int> {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 27, 1),
    ]);

    var a = findElement.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_error_memberWithClassName_field() async {
    await assertErrorsInCode(r'''
class C {
  int C = 42;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_error_memberWithClassName_getter() async {
    await assertErrorsInCode(r'''
class C {
  int get C => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 20, 1),
    ]);
  }

  test_error_memberWithClassName_getter_static() async {
    await assertErrorsInCode(r'''
class C {
  static int get C => 0;
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 27, 1),
    ]);

    var method = findNode.methodDeclaration('C =>');
    expect(method.isGetter, isTrue);
    expect(method.isStatic, isTrue);
    assertElement(method, findElement.getter('C'));
  }

  test_error_memberWithClassName_setter() async {
    await assertErrorsInCode(r'''
class C {
  set C(_) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_error_memberWithClassName_setter_static() async {
    await assertErrorsInCode(r'''
class C {
  static set C(_) {}
}
''', [
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 23, 1),
    ]);

    var method = findNode.methodDeclaration('C(_)');
    expect(method.isSetter, isTrue);
    expect(method.isStatic, isTrue);
  }

  test_issue32815() async {
    await assertErrorsInCode(r'''
class A<T> extends B<T> {}
class B<T> extends A<T> {}
class C<T> extends B<T> implements I<T> {}

abstract class I<T> {}

main() {
  Iterable<I<int>> x = [new C()];
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 33, 1),
      error(
          CompileTimeErrorCode
              .NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS,
          60,
          1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 150, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_extends() async {
    await assertErrorsInCode(r'''
class A extends B {}
class B extends A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_extends_implements() async {
    await assertErrorsInCode(r'''
class A extends B {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 27, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_implements() async {
    await assertErrorsInCode(r'''
class A implements B {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 30, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_mixin() async {
    await assertErrorsInCode(r'''
class M1 = Object with M2;
class M2 = Object with M1;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 2),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 33, 2),
    ]);
  }

  test_recursiveInterfaceInheritance_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    await assertErrorsInCode('''
class C = D with M;
class D = C with M;
class M {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 26, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_tail() async {
    await assertErrorsInCode(r'''
abstract class A implements A {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS, 15,
          1),
    ]);
  }

  test_recursiveInterfaceInheritance_tail2() async {
    await assertErrorsInCode(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 48, 1),
    ]);
  }

  test_recursiveInterfaceInheritance_tail3() async {
    await assertErrorsInCode(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 15, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 48, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 81, 1),
    ]);
  }

  test_recursiveInterfaceInheritanceExtends() async {
    await assertErrorsInCode(r'''
class A extends A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS, 6, 1),
    ]);
  }

  test_recursiveInterfaceInheritanceExtends_abstract() async {
    await assertErrorsInCode(r'''
class C extends C {
  var bar = 0;
  m();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS, 6, 1),
    ]);
  }

  test_recursiveInterfaceInheritanceImplements() async {
    await assertErrorsInCode('''
class A implements A {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS, 6,
          1),
    ]);
  }

  test_recursiveInterfaceInheritanceImplements_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B = A with M implements B;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS, 28,
          1),
    ]);
  }

  test_recursiveInterfaceInheritanceWith() async {
    await assertErrorsInCode(r'''
class M = Object with M;
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH, 6, 1),
    ]);
  }

  test_undefinedSuperGetter() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  get g {
    return super.g;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_GETTER, 58, 1),
    ]);
  }

  test_undefinedSuperMethod() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  m() {
    return super.m();
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_METHOD, 56, 1),
    ]);
  }

  test_undefinedSuperOperator_binaryExpression() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator +(value) {
    return super + value;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 1),
    ]);
  }

  test_undefinedSuperOperator_indexBoth() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index]++;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 7),
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 7),
    ]);
  }

  test_undefinedSuperOperator_indexGetter() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index + 1];
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 70, 11),
    ]);
  }

  test_undefinedSuperOperator_indexSetter() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator []=(index, value) {
    super[index] = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR, 71, 7),
    ]);
  }

  test_undefinedSuperSetter() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  f() {
    super.m = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SUPER_SETTER, 49, 1),
    ]);
  }
}

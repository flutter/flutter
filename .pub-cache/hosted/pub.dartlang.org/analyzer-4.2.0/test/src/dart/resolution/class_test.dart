// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAliasCannotReferenceItselfTest);
  });
}

@reflectiveTest
class TypeAliasCannotReferenceItselfTest extends PubPackageResolutionTest {
  test_functionTypeAlias_typeParameterBounds() async {
    await assertErrorsInCode('''
typedef A<T extends A<int>>();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_functionTypedParameter_returnType() async {
    await assertErrorsInCode('''
typedef A(A b());
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_generic() async {
    await assertErrorsInCode(r'''
typedef F = void Function(List<G> l);
typedef G = void Function(List<F> l);
main() {
  F? foo(G? g) => g;
  foo(null);
}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 46, 1),
    ]);
  }

  test_genericTypeAlias_typeParameterBounds() async {
    await assertErrorsInCode('''
typedef A<T extends A<int>> = void Function();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_infiniteParameterBoundCycle() async {
    await assertErrorsInCode(r'''
typedef F<X extends F<X>> = F Function();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_issue11987() async {
    await assertErrorsInCode(r'''
typedef void F(List<G> l);
typedef void G(List<F> l);
main() {
  F? foo(G? g) => g;
  foo(null);
}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 13, 1),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 40, 1),
    ]);
  }

  test_issue19459() async {
    // A complex example involving multiple classes.  This is legal, since
    // typedef F references itself only via a class.
    await assertNoErrorsInCode(r'''
class A<B, C> {}
abstract class D {
  f(E e);
}
abstract class E extends A<dynamic, F> {}
typedef D F();
''');
  }

  test_nonFunction_aliasedType_cycleOf2() async {
    await assertErrorsInCode('''
typedef T1 = T2;
typedef T2 = T1;
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 2),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 25, 2),
    ]);
  }

  test_nonFunction_aliasedType_directly_functionWithIt() async {
    await assertErrorsInCode('''
typedef T = void Function(T);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_nonFunction_aliasedType_directly_it_none() async {
    await assertErrorsInCode('''
typedef T = T;
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_nonFunction_aliasedType_directly_it_question() async {
    await assertErrorsInCode('''
typedef T = T?;
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_nonFunction_aliasedType_directly_ListOfIt() async {
    await assertErrorsInCode('''
typedef T = List<T>;
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_nonFunction_typeParameterBounds() async {
    await assertErrorsInCode('''
typedef T<X extends T<Never>> = List<X>;
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_parameterType_named() async {
    await assertErrorsInCode('''
typedef A({A a});
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_parameterType_positional() async {
    await assertErrorsInCode('''
typedef A([A a]);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_parameterType_required() async {
    await assertErrorsInCode('''
typedef A(A a);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_parameterType_typeArgument() async {
    await assertErrorsInCode('''
typedef A(List<A> a);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }

  test_referencesReturnType_inTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef B A();
class B {
  A? a;
}
''');
  }

  test_returnClass_withTypeAlias() async {
    // A typedef is allowed to indirectly reference itself via a class.
    await assertNoErrorsInCode(r'''
typedef C A();
typedef A B();
class C {
  B? a;
}
''');
  }

  test_returnType() async {
    await assertErrorsInCode('''
typedef A A();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 10, 1),
    ]);
  }

  test_returnType_indirect() async {
    await assertErrorsInCode(r'''
typedef B A();
typedef A B();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 10, 1),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 25, 1),
    ]);
  }

  test_usingRecordType_directly() async {
    await assertErrorsInCode(r'''
typedef F = (F, int) Function();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
    ]);
  }
}

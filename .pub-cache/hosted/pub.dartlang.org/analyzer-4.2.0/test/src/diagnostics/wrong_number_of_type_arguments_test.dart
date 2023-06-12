// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends PubPackageResolutionTest {
  test_class_tooFew() async {
    await assertErrorsInCode(r'''
class A<E, F> {}
A<A>? a;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 17, 5),
    ]);
  }

  test_class_tooMany() async {
    await assertErrorsInCode(r'''
class A<E> {}
A<A, A>? a;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 14, 8),
    ]);
  }

  test_classAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B<F extends num> = A<F> with M;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 4),
    ]);
  }

  test_const_nonGeneric() async {
    await assertErrorsInCode('''
class C {
  const C();
}

f() {
  return const C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 6),
    ]);
  }

  test_const_tooFew() async {
    await assertErrorsInCode('''
class C<K, V> {
  const C();
}

f() {
  return const C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 53, 6),
    ]);
  }

  test_const_tooMany() async {
    await assertErrorsInCode('''
class C<E> {
  const C();
}

f() {
  return const C<int, int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 50, 11),
    ]);
  }

  test_dynamic() async {
    await assertErrorsInCode(r'''
dynamic<int> v;
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 0, 12),
    ]);
  }

  test_functionReference_tooFew() async {
    await assertErrorsInCode('''
f() {
  void foo<T, U>() {}
  foo<int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 33, 5),
    ]);
  }

  test_functionReference_tooMany() async {
    await assertErrorsInCode('''
f() {
  void foo<T>() {}
  foo<int, int>;
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION, 30, 10),
    ]);
  }

  test_functionTypeExpression_tooFew() async {
    await assertErrorsInCode('''
f(void Function<T, U>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int>;
}
''', [
      error(
          CompileTimeErrorCode
              .WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION,
          80,
          5),
    ]);
  }

  test_functionTypeExpression_tooMany() async {
    await assertErrorsInCode('''
f(void Function<T>() foo, void Function<T, U>() bar) {
  (1 == 2 ? foo : bar)<int, String>;
}
''', [
      error(CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION, 57,
          20),
    ]);
  }

  test_metadata_1of0() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

@A<int>()
void f() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 28, 5),
    ]);
  }

  test_metadata_1of0_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

typedef B = A;

@B<int>()
void f() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 44, 5),
    ]);
  }

  test_metadata_1of2() async {
    await assertErrorsInCode(r'''
class A<T, U> {
  const A();
}

@A<int>()
void f() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 34, 5),
    ]);
  }

  test_metadata_1of2_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

typedef B<T, U> = A;

@B<int>()
void f() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 50, 5),
    ]);
  }

  test_metadata_2of1() async {
    await assertErrorsInCode(r'''
class A<T> {
  const A();
}

@A<int, String>()
void f() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 31, 13),
    ]);
  }

  test_metadata_2of1_viaTypeAlias() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

typedef B<T> = A;

@B<int, String>()
void f() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 13),
    ]);
  }

  test_new_nonGeneric() async {
    await assertErrorsInCode('''
class C {}

f() {
  return new C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 31, 6),
    ]);
  }

  test_new_tooFew() async {
    await assertErrorsInCode('''
class C<K, V> {}

f() {
  return new C<int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 37, 6),
    ]);
  }

  test_new_tooMany() async {
    await assertErrorsInCode('''
class C<E> {}

f() {
  return new C<int, int>();
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 34, 11),
    ]);
  }

  test_type_tooFew() async {
    await assertErrorsInCode(r'''
class A<K, V> {
  late K element;
}
f(A<int> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 38, 6),
    ]);
  }

  test_type_tooMany() async {
    await assertErrorsInCode(r'''
class A<E> {
  late E element;
}
f(A<int, int> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 35, 11),
    ]);
  }

  test_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  late T<int> f;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 20, 6),
    ]);
  }

  test_typeTest_tooFew() async {
    await assertErrorsInCode(r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 49, 4),
    ]);
  }

  test_typeTest_tooMany() async {
    await assertErrorsInCode(r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 46, 7),
    ]);
  }
}

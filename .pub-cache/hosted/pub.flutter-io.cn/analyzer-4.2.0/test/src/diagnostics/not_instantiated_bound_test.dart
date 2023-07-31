// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotInstantiatedBoundTest);
  });
}

@reflectiveTest
class NotInstantiatedBoundTest extends PubPackageResolutionTest {
  test_argument_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<K>> {}
class C<T extends A> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 51, 1),
    ]);
  }

  test_argumentDeep_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<List<K>>> {}
class C<T extends A> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 57, 1),
    ]);
  }

  test_class_bound_argument_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T extends int> {}
class C<T extends A<B>> {}
''');
  }

  test_class_bound_argument_recursive_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<K, V> {}
class B<T extends int> {}
class C<T extends A<B, B>> {}
''');
  }

  test_class_bound_bound_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class C<T extends A<int>> {}
class D<T extends C> {}
''');
  }

  test_class_function_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<T extends void Function()> {}
class B<T extends A> {}
''');
  }

  test_class_instantiated() async {
    await assertNoErrorsInCode(r'''
class A<T extends int> {}
class C1<T extends A> {}
class C2<T extends List<A>> {}
''');
  }

  test_class_recursion_boundArgument_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<T extends B<A>> {}
class B<T extends A<B>> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 20, 1),
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 47, 1),
    ]);
  }

  test_class_recursion_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<T extends B> {} // points to a
class B<T extends A> {} // points to b
class C<T extends A> {} // points to a cyclical type
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 18, 1),
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 57, 1),
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 96, 1),
    ]);
  }

  test_class_recursion_notInstantiated_genericFunctionType() async {
    await assertErrorsInCode(r'''
class A<T extends void Function(A)> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 32, 1),
    ]);
  }

  test_class_recursion_notInstantiated_genericFunctionType2() async {
    await assertErrorsInCode(r'''
class A<T extends void Function<U extends A>()> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 42, 1),
    ]);
  }

  test_class_recursion_typedef_notInstantiated() async {
    await assertErrorsInCode(r'''
typedef F(C value);
class C<T extends F> {}
class D<T extends C> {}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 8, 1),
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 38, 1),
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 62, 1),
    ]);
  }

  test_class_typedef_instantiated() async {
    await assertNoErrorsInCode(r'''
typedef void F<T extends int>();
class C<T extends F> {}
''');
  }

  test_direct_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<K, V extends K> {}
class C<T extends A> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 45, 1),
    ]);
  }

  test_functionType_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<T extends Function(T)> {}
class B<T extends T Function()> {}
class C<T extends A> {}
class D<T extends B> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 87, 1),
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 111, 1),
    ]);
  }

  test_indirect_notInstantiatedt() async {
    await assertErrorsInCode(r'''
class A<K, V extends K> {}
class C<T extends List<A>> {}
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 50, 1),
    ]);
  }

  test_typedef_argument_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<K>> {}
typedef void F<T extends A>();
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 58, 1),
    ]);
  }

  test_typedef_argumentDeep_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<K, V extends List<List<K>>> {}
typedef void F<T extends A>();
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 64, 1),
    ]);
  }

  test_typedef_class_instantiated() async {
    await assertNoErrorsInCode(r'''
class C<T extends int> {}
typedef void F<T extends C>();
''');
  }

  test_typedef_direct_notInstantiated() async {
    await assertErrorsInCode(r'''
class A<K, V extends K> {}
typedef void F<T extends A>();
''', [
      error(CompileTimeErrorCode.NOT_INSTANTIATED_BOUND, 52, 1),
    ]);
  }
}

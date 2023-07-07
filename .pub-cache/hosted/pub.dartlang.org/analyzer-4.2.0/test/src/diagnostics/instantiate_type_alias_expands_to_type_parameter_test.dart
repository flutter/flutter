// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstantiateTypeAliasExpandsToTypeParameterTest);
  });
}

@reflectiveTest
class InstantiateTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER;

  test_const_generic_noArguments_unnamed_typeParameter() async {
    await assertErrorsInCode(r'''
typedef A<T> = T;

void f() {
  const A();
}
''', [
      error(_errorCode, 38, 1),
    ]);
  }

  test_const_notGeneric_unnamed_class() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

typedef X = A;

void f() {
  const X();
}
''');
  }

  test_new_generic_noArguments_unnamed_typeParameter() async {
    await assertErrorsInCode(r'''
typedef A<T> = T;

void f() {
  new A();
}
''', [
      error(_errorCode, 36, 1),
    ]);
  }

  test_new_generic_withArgument_named_typeParameter() async {
    await assertErrorsInCode(r'''
class A {
  A.named();
}

typedef B<T> = T;

void f() {
  new B<A>.named();
}
''', [
      error(_errorCode, 62, 1),
    ]);
  }

  test_new_generic_withArgument_unnamed_typeParameter() async {
    await assertErrorsInCode(r'''
class A {}

typedef B<T> = T;

void f() {
  new B<A>();
}
''', [
      error(_errorCode, 48, 1),
    ]);
  }

  test_new_notGeneric_unnamed_class() async {
    await assertNoErrorsInCode(r'''
class A {}

typedef X = A;

void f() {
  new X();
}
''');
  }

  test_new_notGeneric_unnamed_typeParameter2() async {
    await assertErrorsInCode(r'''
typedef A<T> = T;
typedef B<T> = A<T>;

void f() {
  new B();
}
''', [
      error(_errorCode, 57, 1),
    ]);
  }
}

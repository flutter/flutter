// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstInitializedWithNonConstantValueTest);
  });
}

@reflectiveTest
class ConstInitializedWithNonConstantValueTest
    extends PubPackageResolutionTest {
  test_dynamic() async {
    await assertErrorsInCode(r'''
f(p) {
  const c = p;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 19,
          1),
    ]);
  }

  test_finalField() async {
    // Regression test for bug #25526; previously, two errors were reported.
    await assertErrorsInCode(r'''
class Foo {
  final field = 0;
  foo([int x = field]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 46, 5),
    ]);
  }

  test_functionExpression() async {
    await assertErrorsInCode('''
const a = () {};
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 10,
          5),
    ]);
  }

  test_missingConstInListLiteral() async {
    await assertNoErrorsInCode('''
const List L = [0];
''');
  }

  test_missingConstInMapLiteral() async {
    await assertNoErrorsInCode('''
const Map M = {'a' : 0};
''');
  }

  test_newInstance_constConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
const a = new A();
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 35,
          7),
    ]);
  }

  test_newInstance_externalFactoryConstConstructor() async {
    // We can't evaluate "const A()" because its constructor is external.  But
    // the code is correct--we shouldn't report an error.
    await assertNoErrorsInCode(r'''
class A {
  external const factory A();
}
const x = const A();
''');
  }

  test_nonStaticField_inGenericClass() async {
    await assertErrorsInCode('''
class C<T> {
  const C();
  T? get t => null;
}

const x = const C().t;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 59,
          11),
    ]);
  }

  test_propertyExtraction_targetNotConst() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  int m() => 0;
}
final a = const A();
const c = a.m;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 72,
          1),
    ]);
  }

  test_typeLiteral_interfaceType() async {
    await assertNoErrorsInCode(r'''
const a = int;
''');
  }

  test_typeLiteral_typeAlias_interfaceType() async {
    await assertNoErrorsInCode(r'''
typedef A = int;
const a = A;
''');
  }
}

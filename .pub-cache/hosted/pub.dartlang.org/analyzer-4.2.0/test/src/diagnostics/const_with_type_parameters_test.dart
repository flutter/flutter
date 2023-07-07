// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithTypeParametersConstructorTearoffTest);
    defineReflectiveTests(ConstWithTypeParametersFunctionTearoffTest);
    defineReflectiveTests(ConstWithTypeParametersTest);
  });
}

@reflectiveTest
class ConstWithTypeParametersConstructorTearoffTest
    extends PubPackageResolutionTest {
  test_asExpression_functionType() async {
    await assertErrorsInCode('''
void f<T>(T a) {}
void g() {
  const [f as void Function<T>(T, [int])];
}
''', [
      // This error is reported because the cast fails if the type on the right
      // has type parameters.
      // TODO(srawlins): Deduplicate these two errors.
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 38, 31),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 60, 1),
    ]);
  }

  test_defaultValue() async {
    await assertErrorsInCode('''
class A<T> {
  void m([var fn = A<T>.new]) {}
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF,
          34, 1),
    ]);
  }

  test_defaultValue_fieldFormalParameter() async {
    await assertErrorsInCode('''
class A<T> {
  A<T> Function() fn;
  A([this.fn = A<T>.new]);
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF,
          52, 1),
    ]);
  }

  test_defaultValue_noTypeVariableInferredFromParameter() async {
    await assertErrorsInCode('''
class A<T> {
  void m([A<T> Function() fn = A.new]) {}
}
''', [
      // `A<dynamic> Function()` cannot be assigned to `A<T> Function()`, but
      // there should not be any other error reported here.
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 44, 5),
    ]);
  }

  test_direct() async {
    await assertErrorsInCode('''
class A<T> {
  void m() {
    const c = A<T>.new;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF,
          42, 1),
    ]);
  }

  test_fieldValue_constClass() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  final x = A<T>.new;
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF,
          40, 1),
    ]);
  }

  test_indirect() async {
    await assertErrorsInCode('''
class A<T> {
  void m() {
    const c = A<List<T>>.new;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 36, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF,
          47, 1),
    ]);
  }

  test_isExpression_functionType() async {
    await assertErrorsInCode('''
class A<T> {
  void m() {
    const [false is void Function(T)];
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 60, 1),
    ]);
  }

  test_nonConst() async {
    await assertNoErrorsInCode('''
class A<T> {
  void m() {
    A<T>.new;
  }
}
''');
  }
}

@reflectiveTest
class ConstWithTypeParametersFunctionTearoffTest
    extends PubPackageResolutionTest {
  test_defaultValue() async {
    await assertErrorsInCode('''
void f<T>(T a) {}
class A<U> {
  void m([void Function(U) fn = f<U>]) {}
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF,
          65, 1),
    ]);
  }

  test_direct() async {
    await assertErrorsInCode('''
void f<T>(T a) {}
class A<U> {
  void m() {
    const c = f<U>;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF,
          60, 1),
    ]);
  }

  test_fieldValue_constClass() async {
    await assertErrorsInCode('''
void f<T>(T a) {}
class A<U> {
  const A();
  final x = f<U>;
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF,
          58, 1),
    ]);
  }

  test_fieldValue_extension() async {
    await assertErrorsInCode('''
void f<T>(T a) {}
class A<U> {}
extension<U> on A<U> {
  final x = f<U>;
}
''', [
      // An instance field is illegal, but we should not also report an
      // additional error for the type variable.
      error(ParserErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 63, 1),
    ]);
  }

  test_fieldValue_nonConstClass() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
class A<U> {
  final x = f<U>;
}
''');
  }

  test_indirect() async {
    await assertErrorsInCode('''
void f<T>(T a) {}
class A<U> {
  void m() {
    const c = f<List<U>>;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF,
          65, 1),
    ]);
  }

  test_nonConst() async {
    await assertNoErrorsInCode('''
void f<T>(T a) {}
class A<U> {
  void m() {
    f<U>;
  }
}
''');
  }
}

@reflectiveTest
class ConstWithTypeParametersTest extends PubPackageResolutionTest {
  test_direct() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<T>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 51, 1),
    ]);
  }

  test_indirect() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<List<T>>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 56, 1),
    ]);
  }

  test_indirect_functionType_returnType() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<T Function()>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 51, 1),
    ]);
  }

  test_indirect_functionType_simpleParameter() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<void Function(T)>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 65, 1),
    ]);
  }

  test_indirect_functionType_typeParameter() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<void Function<U>()>();
  }
}
''');
  }

  test_indirect_functionType_typeParameter_typeParameterBound() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<void Function<U extends T>()>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 75, 1),
    ]);
  }

  test_nonConstContext() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
  void m() {
    A<T>();
  }
}
''');
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingDefaultValueForParameterTest);
    defineReflectiveTests(MissingDefaultValueForParameterWithAnnotationTest);
  });
}

@reflectiveTest
class MissingDefaultValueForParameterTest extends PubPackageResolutionTest {
  test_closure_nonNullable_named_optional_default() async {
    await assertNoErrorsInCode('''
var f = ({int a = 0}) {};
''');
  }

  test_closure_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
var f = ({int a}) {};
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 14, 1),
    ]);
  }

  test_closure_nonNullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
var f = ([int a = 0]) {};
''');
  }

  test_closure_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
var f = ([int a]) {};
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          14, 1),
    ]);
  }

  test_constructor_externalFactory_nonNullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  external factory C({int a});
}
''');
  }

  test_constructor_externalFactory_nonNullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  external factory C([int a]);
}
''');
  }

  test_constructor_externalFactory_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  external factory C({int? a});
}
''');
  }

  test_constructor_factory_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  factory C({int a}) => C._();
  C._();
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 27, 1),
    ]);
  }

  test_constructor_factory_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  factory C([int a]) => C._();
  C._();
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          27, 1),
    ]);
  }

  test_constructor_factory_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  factory C({int? a}) => C._();
  C._();
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  C({int a});
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 19, 1),
    ]);
  }

  test_constructor_generative_nonNullable_named_optional_super_hasDefault_explicit() async {
    await assertNoErrorsInCode('''
class A {
  A({required int a});
}
class B extends A{
  B({super.a = 0});
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_hasDefault_fromSuper() async {
    await assertNoErrorsInCode('''
class A {
  A({int a = 0});
}
class B extends A{
  B({super.a});
}
''');
  }

  test_constructor_generative_nonNullable_named_optional_super_noDefault() async {
    await assertErrorsInCode('''
class A {
  A({int? a});
}
class B extends A{
  B({int super.a});
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 61, 1),
    ]);
  }

  test_constructor_generative_nonNullable_named_optional_super_noDefault_fromSuper() async {
    await assertErrorsInCode('''
class A {
  A({num a = 1.2});
}
class B extends A{
  B({int super.a});
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 66, 1),
    ]);
  }

  test_constructor_generative_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  C([int a]);
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          19, 1),
    ]);
  }

  test_constructor_generative_nonNullable_positional_optional_super_hasDefault_explicit() async {
    await assertNoErrorsInCode('''
class A {
  A(int a);
}
class B extends A{
  B([super.a = 0]);
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_super_hasDefault_fromSuper() async {
    await assertNoErrorsInCode('''
class A {
  A([int a = 0]);
}
class B extends A{
  B([super.a]);
}
''');
  }

  test_constructor_generative_nonNullable_positional_optional_super_noDefault() async {
    await assertErrorsInCode('''
class A {
  A([int? a]);
}
class B extends A{
  B([int super.a]);
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          61, 1),
    ]);
  }

  test_constructor_generative_nonNullable_positional_optional_super_noDefault_fromSuper() async {
    await assertErrorsInCode('''
class A {
  A([num a = 1.2]);
}
class B extends A{
  B([int super.a]);
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          66, 1),
    ]);
  }

  test_constructor_generative_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  C({int? a});
}
''');
  }

  test_constructor_generative_nullable_named_optional_noDefault_fieldFormal() async {
    await assertNoErrorsInCode('''
class C {
  int? f;
  C({this.f});
}
''');
  }

  test_constructor_redirectingFactory_nonNullable_named_optional() async {
    await assertNoErrorsInCode('''
class A {
  factory A({int a}) = B;
}

class B implements A {
  B({int a = 0});
}
''');
  }

  test_constructor_redirectingFactory_nonNullable_positional_optional() async {
    await assertNoErrorsInCode('''
class A {
  factory A([int a]) = B;
}

class B implements A {
  B([int a = 0]);
}
''');
  }

  test_constructor_redirectingFactory_nullable_named_optional() async {
    await assertNoErrorsInCode('''
class A {
  factory A({int? a}) = B;
}

class B implements A {
  B({int? a});
}
''');
  }

  test_fieldFormalParameter_functionTyped_named_optional() async {
    await assertNoErrorsInCode('''
class A {
  dynamic f;
  A(void this.f({int a, int? b}));
}
''');
  }

  test_fieldFormalParameter_functionTyped_positional_optional() async {
    await assertNoErrorsInCode('''
class A {
  dynamic f;
  A(void this.f([int a, int? b]));
}
''');
  }

  test_function_external_nonNullable_named_optional_default() async {
    await assertNoErrorsInCode('''
external void f({int a = 0});
''');
  }

  test_function_external_nonNullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
external void f({int a});
''');
  }

  test_function_external_nonNullable_named_required_noDefault() async {
    await assertNoErrorsInCode('''
external void f({required int a});
''');
  }

  test_function_external_nonNullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
external void f([int a = 0]);
''');
  }

  test_function_external_nonNullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
external void f([int a]);
''');
  }

  test_function_external_nonNullable_positional_required_noDefault() async {
    await assertNoErrorsInCode('''
external void f(int a);
''');
  }

  test_function_external_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
external void f({int? a});
''');
  }

  test_function_external_nullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
external void f([int? a]);
''');
  }

  test_function_native_nonNullable_named_optional_default() async {
    await assertErrorsInCode('''
void f({int a = 0}) native;
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 20, 7),
    ]);
  }

  test_function_native_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
void f({int a}) native;
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 16, 7),
    ]);
  }

  test_function_native_nonNullable_positional_optional_default() async {
    await assertErrorsInCode('''
void f([int a = 0]) native;
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 20, 7),
    ]);
  }

  test_function_native_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
void f([int a]) native;
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 16, 7),
    ]);
  }

  test_function_nonNullable_named_optional_default() async {
    await assertNoErrorsInCode('''
void f({int a = 0}) {}
''');
  }

  test_function_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
void f({int a}) {}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 12, 1),
    ]);
  }

  test_function_nonNullable_named_required() async {
    await assertNoErrorsInCode('''
void f({required int a}) {}
''');
  }

  test_function_nonNullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
void f([int a = 0]) {}
''');
  }

  test_function_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
void f([int a]) {}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          12, 1),
    ]);
  }

  test_function_nonNullable_positional_required() async {
    await assertNoErrorsInCode('''
void f(int a) {}
''');
  }

  test_function_nullable_named_optional_default() async {
    await assertNoErrorsInCode('''
void f({int? a = 0}) {}
''');
  }

  test_function_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
void f({int? a}) {}
''');
  }

  test_function_nullable_named_required() async {
    await assertNoErrorsInCode('''
void f({required int? a}) {}
''');
  }

  test_function_nullable_positional_optional_default() async {
    await assertNoErrorsInCode('''
void f([int? a = 0]) {}
''');
  }

  test_function_nullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
void f([int? a]) {}
''');
  }

  test_function_nullable_positional_required() async {
    await assertNoErrorsInCode('''
void f(int? a) {}
''');
  }

  test_functionTypeAlias_named_optional() async {
    await assertNoErrorsInCode('''
typedef void F({int a, int? b});
''');
  }

  test_functionTypeAlias_positional_optional() async {
    await assertNoErrorsInCode('''
typedef void F([int a, int? b]);
''');
  }

  test_functionTypedFormalParameter_named_optional() async {
    await assertNoErrorsInCode('''
void f(void p({int a, int? b})) {}
''');
  }

  test_functionTypedFormalParameter_positional_optional() async {
    await assertNoErrorsInCode('''
void f(void p([int a, int? b])) {}
''');
  }

  test_genericFunctionType_named_optional() async {
    await assertNoErrorsInCode('''
void f(void Function({int a, int? b}) p) {}
''');
  }

  test_genericFunctionType_positional_optional() async {
    await assertNoErrorsInCode('''
void f(void Function([int a, int? b]) p) {}
''');
  }

  test_genericFunctionType_positional_optional2() async {
    await assertNoErrorsInCode('''
void f(void Function([int, int?]) p) {}
''');
  }

  test_method_abstract_nonNullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
abstract class C {
  void foo({int a});
}
''');
  }

  test_method_abstract_nonNullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
abstract class C {
  void foo([int a]);
}
''');
  }

  test_method_abstract_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
abstract class C {
  void foo({int? a});
}
''');
  }

  test_method_abstract_potentiallyNonNullable_named_optional() async {
    await assertNoErrorsInCode('''
abstract class A<T> {
  void foo({T a});
}
''');
  }

  test_method_abstract_potentiallyNonNullable_positional_optional() async {
    await assertNoErrorsInCode('''
abstract class A<T extends Object?> {
  void foo([T a]);
}
''');
  }

  test_method_external_nonNullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  external void foo({int a});
}
''');
  }

  test_method_external_nonNullable_positional_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  external void foo([int a]);
}
''');
  }

  test_method_external_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  external void foo({int? a});
}
''');
  }

  test_method_external_potentiallyNonNullable_named_optional() async {
    await assertNoErrorsInCode('''
class A<T> {
  external void foo({T a});
}
''');
  }

  test_method_external_potentiallyNonNullable_positional_optional() async {
    await assertNoErrorsInCode('''
class A<T extends Object?> {
  external void foo([T a]);
}
''');
  }

  test_method_native_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  void foo({int a}) native;
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 30, 7),
    ]);
  }

  test_method_native_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  void foo([int a]) native;
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 30, 7),
    ]);
  }

  test_method_native_nullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  void foo({int? a}) native;
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 31, 7),
    ]);
  }

  test_method_native_potentiallyNonNullable_named_optional() async {
    await assertErrorsInCode('''
class A<T> {
  void foo({T a}) native;
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 31, 7),
    ]);
  }

  test_method_native_potentiallyNonNullable_positional_optional() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void foo([T a]) native;
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 47, 7),
    ]);
  }

  test_method_nonNullable_named_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  void foo({int a}) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 26, 1),
    ]);
  }

  test_method_nonNullable_positional_optional_noDefault() async {
    await assertErrorsInCode('''
class C {
  void foo([int a]) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          26, 1),
    ]);
  }

  test_method_nullable_named_optional_noDefault() async {
    await assertNoErrorsInCode('''
class C {
  void foo({int? a}) {}
}
''');
  }

  test_method_potentiallyNonNullable_named_optional() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void foo({T a}) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER, 43, 1),
    ]);
  }

  test_method_potentiallyNonNullable_positional_optional() async {
    await assertErrorsInCode('''
class A<T extends Object?> {
  void foo([T a]) {}
}
''', [
      error(CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL,
          43, 1),
    ]);
  }
}

@reflectiveTest
class MissingDefaultValueForParameterWithAnnotationTest
    extends PubPackageResolutionTest {
  test_method_withAnnotation() async {
    writeTestPackageConfigWithMeta();
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class C {
  void foo({@required int a}) {}
}
''', [
      error(
          CompileTimeErrorCode
              .MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION,
          70,
          1),
    ]);
  }
}

// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongTypeParameterVarianceInSuperinterfaceTest);
  });
}

@reflectiveTest
class WrongTypeParameterVarianceInSuperinterfaceTest
    extends PubPackageResolutionTest {
  test_class_extends_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
class B<X> extends A<F<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        55,
        1,
      ),
    ]);
  }

  test_class_extends_function_parameterType_parameterType() async {
    await assertNoErrorsInCode(r'''
typedef F1<X> = void Function(X);
typedef F2<X> = void Function(F1<X>);
class A<X> {}
class B<X> extends A<F2<X>> {}
''');
  }

  test_class_extends_function_parameterType_returnType() async {
    await assertErrorsInCode(r'''
typedef F1<X> = X Function();
typedef F2<X> = void Function(F1<X>);
class A<X> {}
class B<X> extends A<F2<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        90,
        1,
      ),
    ]);
  }

  test_class_extends_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
class B<X> extends A<F<X>> {}
''');
  }

  test_class_extends_function_returnType_parameterType() async {
    await assertErrorsInCode(r'''
typedef F1<X> = void Function(X);
typedef F2<X> = F1<X> Function();
class A<X> {}
class B<X> extends A<F2<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        90,
        1,
      ),
    ]);
  }

  test_class_extends_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
class B<X> extends A<X> {}
''');
  }

  test_class_implements_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
class B<X> implements A<F<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        55,
        1,
      ),
    ]);
  }

  test_class_implements_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
class B<X> implements A<F<X>> {}
''');
  }

  test_class_implements_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
class B<X> implements A<X> {}
''');
  }

  test_class_with_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
class B<X> extends Object with A<F<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        55,
        1,
      ),
    ]);
  }

  test_class_with_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
class B<X> extends Object with A<F<X>> {}
''');
  }

  test_class_with_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
class B<X> extends Object with A<X> {}
''');
  }

  test_classTypeAlias_extends_function_invariant() async {
    await assertErrorsInCode(r'''
typedef F<X> = X Function(X);
class A<X> {}
mixin M {}
class B<X> = A<F<X>> with M;
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        63,
        1,
      ),
    ]);
  }

  test_classTypeAlias_extends_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin M {}
class B<X> = A<F<X>> with M;
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        66,
        1,
      ),
    ]);
  }

  test_classTypeAlias_extends_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
mixin M {}
class B<X> = A<F<X>> with M;
''');
  }

  test_classTypeAlias_extends_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
mixin M {}
class B<X> = A<X> with M;
''');
  }

  test_classTypeAlias_implements_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin M {}
class B<X> = Object with M implements A<F<X>>;
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        66,
        1,
      ),
    ]);
  }

  test_classTypeAlias_implements_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
mixin M {}
class B<X> = Object with M implements A<F<X>>;
''');
  }

  test_classTypeAlias_implements_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
mixin M {}
class B<X> = Object with M implements A<X>;
''');
  }

  test_classTypeAlias_with_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
mixin M<X> {}
class B<X> = Object with M<F<X>>;
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        55,
        1,
      ),
    ]);
  }

  test_classTypeAlias_with_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
mixin M<X> {}
class B<X> = Object with M<F<X>>;
''');
  }

  test_classTypeAlias_with_withoutFunction() async {
    await assertNoErrorsInCode(r'''
mixin M<X> {}
class B<X> = Object with M<X>;
''');
  }

  test_enum_implements_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
enum E<X> implements A<F<X>> {
  v
}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        54,
        1,
      ),
    ]);
  }

  test_enum_implements_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
enum E<X> implements A<F<X>> {
  v
}
''');
  }

  test_enum_implements_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
enum E<X> implements A<X> {
  v
}
''');
  }

  test_enum_with_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
enum E<X> with A<F<X>> {
  v
}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        54,
        1,
      ),
    ]);
  }

  test_enum_with_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
enum E<X> with A<F<X>> {
  v
}
''');
  }

  test_enum_with_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
enum E<X> with A<X> {
  v
}
''');
  }

  test_mixin_implements_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin B<X> implements A<F<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        55,
        1,
      ),
    ]);
  }

  test_mixin_implements_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
mixin B<X> implements A<F<X>> {}
''');
  }

  test_mixin_implements_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
mixin B<X> implements A<X> {}
''');
  }

  test_mixin_on_function_parameterType() async {
    await assertErrorsInCode(r'''
typedef F<X> = void Function(X);
class A<X> {}
mixin B<X> on A<F<X>> {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        55,
        1,
      ),
    ]);
  }

  test_mixin_on_function_returnType() async {
    await assertNoErrorsInCode(r'''
typedef F<X> = X Function();
class A<X> {}
mixin B<X> on A<F<X>> {}
''');
  }

  test_mixin_on_withoutFunction() async {
    await assertNoErrorsInCode(r'''
class A<X> {}
mixin B<X> on A<X> {}
''');
  }

  test_typeParameter_bound() async {
    await assertErrorsInCode(r'''
class A<X> {}
class B<X> extends A<void Function<Y extends X>()> {}
''', [
      error(
          CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
          22,
          1),
    ]);
  }
}

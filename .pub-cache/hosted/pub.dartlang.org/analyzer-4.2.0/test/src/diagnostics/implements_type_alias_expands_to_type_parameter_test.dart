// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplementsTypeAliasExpandsToTypeParameterTest);
  });
}

@reflectiveTest
class ImplementsTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}
typedef T = A;
class B implements T {}
''');
  }

  test_class_typeParameter_noTypeArguments() async {
    await assertErrorsInCode(r'''
class A {}
typedef T<X extends A> = X;
class B implements T {}
''', [
      error(
          CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
          58,
          1),
    ]);
  }

  test_class_typeParameter_withTypeArguments() async {
    await assertErrorsInCode(r'''
class A {}
typedef T<X extends A> = X;
class B implements T<A> {}
''', [
      error(
          CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
          58,
          1),
    ]);
  }

  test_mixin_typeParameter_noTypeArguments() async {
    await assertErrorsInCode(r'''
class A {}
typedef T<X extends A> = X;
mixin M implements T {}
''', [
      error(
          CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
          58,
          1),
    ]);
  }
}

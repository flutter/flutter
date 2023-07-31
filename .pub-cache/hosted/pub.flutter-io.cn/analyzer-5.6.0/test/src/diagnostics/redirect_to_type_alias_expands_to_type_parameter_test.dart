// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectTypeAliasExpandsToTypeParameterTest);
  });
}

@reflectiveTest
class RedirectTypeAliasExpandsToTypeParameterTest
    extends PubPackageResolutionTest {
  test_generic_typeParameter_withArgument_named() async {
    await assertErrorsInCode(r'''
class A implements C {
  A.named();
}

typedef B<T> = T;

class C {
  factory C() = B<A>.named;
}
''', [
      error(
          CompileTimeErrorCode.REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
          84,
          1),
    ]);
  }

  test_generic_typeParameter_withArgument_unnamed() async {
    await assertErrorsInCode(r'''
class A implements C {}

typedef B<T> = T;

class C {
  factory C() = B<A>;
}
''', [
      error(
          CompileTimeErrorCode.REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
          70,
          1),
    ]);
  }

  test_generic_typeParameter_withoutArgument_unnamed() async {
    await assertErrorsInCode(r'''
class A implements C {}

typedef B<T> = T;

class C {
  factory C() = B;
}
''', [
      error(
          CompileTimeErrorCode.REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER,
          70,
          1),
    ]);
  }

  test_notGeneric_class_named() async {
    await assertNoErrorsInCode(r'''
class A implements C {
  A.named();
}

typedef B = A;

class C {
  factory C() = B.named;
}
''');
  }

  test_notGeneric_class_unnamed() async {
    await assertNoErrorsInCode(r'''
class A implements C {}

typedef B = A;

class C {
  factory C() = B;
}
''');
  }
}

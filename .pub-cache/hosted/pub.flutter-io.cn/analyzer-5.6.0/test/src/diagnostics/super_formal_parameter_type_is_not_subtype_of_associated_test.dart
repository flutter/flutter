// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperFormalParameterTypeIsNotSubtypeOfAssociatedTest);
  });
}

@reflectiveTest
class SuperFormalParameterTypeIsNotSubtypeOfAssociatedTest
    extends PubPackageResolutionTest {
  test_generic_requiredPositional_explicit_notSubtype() async {
    await assertErrorsInCode(r'''
class A<T> {
  A(T a);
}

class B extends A<int> {
  B(num super.a);
}
''', [
      error(
          CompileTimeErrorCode
              .SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED,
          65,
          1),
    ]);
  }

  test_generic_requiredPositional_explicit_same() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T a);
}

class B extends A<num> {
  B(num super.a);
}
''');
  }

  test_generic_requiredPositional_explicit_subtype() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T a);
}

class B extends A<num> {
  B(int super.a);
}
''');
  }

  test_requiredNamed_explicit_notSubtype() async {
    await assertErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required num super.a});
}
''', [
      error(
          CompileTimeErrorCode
              .SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED,
          80,
          1),
    ]);
  }

  test_requiredNamed_explicit_same() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required num a});
}

class B extends A {
  B({required num super.a});
}
''');
  }

  test_requiredNamed_explicit_subtype() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required num a});
}

class B extends A {
  B({required int super.a});
}
''');
  }

  test_requiredNamed_inherited() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int a});
}

class B extends A {
  B({required super.a});
}
''');
  }

  test_requiredPositional_explicit_notSubtype() async {
    await assertErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(num super.a);
}
''', [
      error(
          CompileTimeErrorCode
              .SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED,
          59,
          1),
    ]);
  }

  /// No implicit coercions, like downcast from `dynamic`.
  test_requiredPositional_explicit_notSubtype_dynamic() async {
    await assertErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(dynamic super.a);
}
''', [
      error(
          CompileTimeErrorCode
              .SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED,
          63,
          1),
    ]);
  }

  test_requiredPositional_explicit_same() async {
    await assertNoErrorsInCode(r'''
class A {
  A(num a);
}

class B extends A {
  B(num super.a);
}
''');
  }

  test_requiredPositional_explicit_subtype() async {
    await assertNoErrorsInCode(r'''
class A {
  A(num a);
}

class B extends A {
  B(int super.a);
}
''');
  }

  test_requiredPositional_inherited() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int a);
}

class B extends A {
  B(super.a);
}
''');
  }
}

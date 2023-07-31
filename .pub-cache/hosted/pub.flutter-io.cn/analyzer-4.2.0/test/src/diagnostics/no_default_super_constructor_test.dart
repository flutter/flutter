// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultSuperConstructorTest);
    defineReflectiveTests(NoDefaultSuperConstructorWithoutNullSafetyTest);
  });
}

@reflectiveTest
class NoDefaultSuperConstructorTest extends PubPackageResolutionTest
    with NoDefaultSuperConstructorTestCases {
  test_super_optionalNamed_subclass_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {
  B();
}
''');
  }

  test_super_optionalNamed_subclass_implicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {}
''');
  }

  test_super_optionalNamed_subclass_superParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  A({int? a});
}
class B extends A {
  B({super.a});
}
''');
  }

  test_super_optionalPositional_subclass_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {
  B();
}
''');
  }

  test_super_optionalPositional_subclass_implicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {}
''');
  }

  test_super_optionalPositional_subclass_superParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  A([int? a]);
}
class B extends A {
  B(super.a);
}
''');
  }

  test_super_requiredNamed_legacySubclass_explicitConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A({required String s});
}
''');
    await assertNoErrorsInCode(r'''
// @dart=2.8
import 'a.dart';

class B extends A {
  B();
}
''');
  }

  test_super_requiredNamed_legacySubclass_implicitConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A({required String s});
}O
''');
    await assertNoErrorsInCode(r'''
// @dart=2.8
import 'a.dart';

class B extends A {}
''');
  }

  test_super_requiredNamed_subclass_explicit() async {
    await assertErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS,
          58, 1),
    ]);
  }

  test_super_requiredNamed_subclass_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 42, 1),
    ]);
  }

  test_super_requiredNamed_subclass_superParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({required super.a});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_oneLeft() async {
    await assertErrorsInCode(r'''
class A {
  A({required int? a, required int? b});
}
class B extends A {
  B({required super.a});
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS,
          75, 1),
    ]);
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_hasDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({super.a = 0});
}
''');
  }

  test_super_requiredNamed_subclass_superParameter_optionalNamed_noDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  A({required int? a});
}
class B extends A {
  B({super.a});
}
''');
  }

  test_super_requiredPositional_subclass_explicit() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS,
          42, 1),
    ]);
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B extends A {
  B([super.a = 0]);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_optionalPositional_withoutDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B extends A {
  B([super.a]);
}
''');
  }

  test_super_requiredPositional_subclass_superParameter_requiredPositional() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int? a);
}
class B extends A {
  B(super.a);
}
''');
  }
}

mixin NoDefaultSuperConstructorTestCases on PubPackageResolutionTest {
  test_super_implicit_subclass_explicit() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  B();
}
''');
  }

  test_super_implicit_subclass_implicit() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
''');
  }

  test_super_noParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  B();
}
''');
  }

  test_super_requiredPositional_subclass_explicit_language214() async {
    await assertErrorsInCode(r'''
// @dart = 2.14
class A {
  A(p);
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, 58, 1),
    ]);
  }

  test_super_requiredPositional_subclass_external() async {
    await assertNoErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  external B();
}
''');
  }

  test_super_requiredPositional_subclass_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 26, 1),
    ]);
  }
}

@reflectiveTest
class NoDefaultSuperConstructorWithoutNullSafetyTest
    extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, NoDefaultSuperConstructorTestCases {
  test_super_requiredPositional_subclass_explicit() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, 42, 1),
    ]);
  }
}

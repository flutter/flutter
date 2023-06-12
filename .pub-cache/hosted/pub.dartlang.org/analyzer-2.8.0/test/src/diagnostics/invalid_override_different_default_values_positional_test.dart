// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidOverrideDifferentDefaultValuesPositionalTest);
    defineReflectiveTests(
      InvalidOverrideDifferentDefaultValuesPositionalWithNullSafetyTest,
    );
  });
}

@reflectiveTest
class InvalidOverrideDifferentDefaultValuesPositionalTest
    extends PubPackageResolutionTest {
  test_abstract_different_base_value() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  void foo([x = 0]) {}
}

abstract class B extends A {
  void foo([x = 1]);
}
''',
      expectedErrorsByNullability(nullable: [], legacy: [
        error(
            StaticWarningCode
                .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
            86,
            5),
      ]),
    );
  }

  test_abstract_noDefault_base_noDefault() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo([x]);
}

abstract class B extends A {
  void foo([x]);
}
''');
  }

  test_abstract_noDefault_base_value() async {
    await assertErrorsInCode(
        r'''
abstract class A {
  void foo([x = 0]) {}
}

abstract class B extends A {
  void foo([x]);
}
''',
        expectedErrorsByNullability(nullable: [], legacy: [
          error(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              86,
              1),
        ]));
  }

  test_abstract_noDefault_multipleBase_differentValue() async {
    await assertErrorsInCode(
        r'''
abstract class A {
  void foo([x = 0]) {}
}

abstract class B {
  void foo([x = 1]);
}

abstract class C extends A implements B {
  void foo([x]);
}
''',
        expectedErrorsByNullability(nullable: [], legacy: [
          error(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              142,
              1),
          error(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              142,
              1),
        ]));
  }

  test_abstract_noDefault_multipleBase_sameValue() async {
    await assertErrorsInCode(
        r'''
abstract class A {
  void foo([x = 0]);
}

abstract class B {
  void foo([x = 0]);
}

abstract class C extends A implements B {
  void foo([x]);
}
''',
        expectedErrorsByNullability(nullable: [], legacy: [
          error(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              140,
              1),
          error(
              StaticWarningCode
                  .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
              140,
              1),
        ]));
  }

  test_abstract_value_base_noDefault() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo([x]);
}

abstract class B extends A {
  void foo([x = 0]);
}
''');
  }

  test_concrete_different() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo([x = 0]) {}
}
class B extends A {
  void foo([x = 1]) {}
}
''',
      expectedErrorsByNullability(nullable: [], legacy: [
        error(
            StaticWarningCode
                .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
            67,
            5),
      ]),
    );
  }

  test_concrete_equal() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  void foo([x = 1]);
}

class C extends A {
  void foo([x = 3 - 2]) {}
}
''');
  }

  test_concrete_equal_function() async {
    await assertNoErrorsInCode(r'''
nothing() => 'nothing';

class A {
  void foo(String a, [orElse = nothing]) {}
}

class B extends A {
  void foo(String a, [orElse = nothing]) {}
}
''');
  }

  test_concrete_equal_otherLibrary() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  void foo([x = 0]) {}
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart';

class C extends A {
  void foo([a = 0]) {}
}
''');
  }

  test_concrete_equal_otherLibrary_listLiteral() async {
    newFile('$testPackageLibPath/other.dart', content: '''
class C {
  void foo([x = const ['x']]) {}
}
''');
    await assertNoErrorsInCode('''
import 'other.dart';
class D extends C {
  void foo([x = const ['x']]) {}
}
''');
  }

  test_concrete_explicitNull_overriddenWith_implicitNull() async {
    // If the base class provided an explicit null value for a default
    // parameter, then it is ok for the derived class to let the default value
    // be implicit, because the implicit default value of null matches the
    // explicit default value of null.
    await assertNoErrorsInCode(r'''
class A {
  void foo([x = null]) {}
}
class B extends A {
  void foo([x]) {}
}
''');
  }

  test_concrete_implicitNull_overriddenWith_value() async {
    // If the base class lets the default parameter be implicit, then it is ok
    // for the derived class to provide an explicit default value, even if it's
    // not null.
    await assertNoErrorsInCode(r'''
class A {
  void foo([x]) {}
}
class B extends A {
  void foo([x = 1]) {}
}
''');
  }

  test_concrete_undefined_base() async {
    // Note: we expect some errors due to the constant referring to undefined
    // values, but there should not be any INVALID_OVERRIDE... error.
    await assertErrorsInCode('''
class A {
  void foo([x = Undefined.value]) {}
}
class B extends A {
  void foo([x = 1]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 26, 9),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 26, 9),
    ]);
  }

  test_concrete_undefined_both() async {
    // Note: we expect some errors due to the constant referring to undefined
    // values, but there should not be any INVALID_OVERRIDE... error.
    await assertErrorsInCode('''
class A {
  void foo([x = Undefined.value]) {}
}
class B extends A {
  void foo([x = Undefined2.value2]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 26, 9),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 26, 9),
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 85, 10),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 85, 10),
    ]);
  }

  test_concrete_undefined_derived() async {
    // Note: we expect some errors due to the constant referring to undefined
    // values, but there should not be any INVALID_OVERRIDE... error.
    await assertErrorsInCode('''
class A {
  void foo([x = 1]) {}
}
class B extends A {
  void foo([x = Undefined.value]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 71, 9),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 71, 9),
    ]);
  }

  test_concrete_value_overriddenWith_implicitNull() async {
    // If the base class provided an explicit value for a default parameter,
    // then it is a static warning for the derived class to provide a different
    // value, even if implicitly.
    await assertErrorsInCode(
      r'''
class A {
  void foo([x = 1]) {}
}
class B extends A {
  void foo([x]) {}
}
''',
      expectedErrorsByNullability(nullable: [], legacy: [
        error(
            StaticWarningCode
                .INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_POSITIONAL,
            67,
            1),
      ]),
    );
  }
}

@reflectiveTest
class InvalidOverrideDifferentDefaultValuesPositionalWithNullSafetyTest
    extends InvalidOverrideDifferentDefaultValuesPositionalTest {
  test_concrete_equal_optIn_extends_optOut() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A {
  void foo([int a = 0]) {}
}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

class B extends A {
  void foo([int a = 0]) {}
}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_concrete_equal_optOut_extends_optIn() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  void foo([int a = 0]) {}
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

class B extends A {
  void foo([int a = 0]) {}
}
''');
  }
}

// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultSuperConstructorTest);
    defineReflectiveTests(NoDefaultSuperConstructorWithNullSafetyTest);
  });
}

@reflectiveTest
class NoDefaultSuperConstructorTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, NoDefaultSuperConstructorTestCases {}

mixin NoDefaultSuperConstructorTestCases on PubPackageResolutionTest {
  test_explicitDefaultSuperConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  B() {}
}
''');
  }

  test_implicitDefaultSuperConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
}
class B extends A {
  B() {}
}
''');
  }

  test_missingDefaultSuperConstructor_explicitConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  B() {}
}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, 42, 1),
    ]);
  }

  test_missingDefaultSuperConstructor_externalConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  external B();
}
''');
  }

  test_missingDefaultSuperConstructor_implicitConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 26, 1),
    ]);
  }

  test_missingDefaultSuperConstructor_onlyNamedSuperConstructor() async {
    await assertErrorsInCode(r'''
class A { A.named() {} }
class B extends A {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 31, 1),
    ]);
  }
}

@reflectiveTest
class NoDefaultSuperConstructorWithNullSafetyTest
    extends PubPackageResolutionTest with NoDefaultSuperConstructorTestCases {
  test_super_requiredParameter_legacySubclass_explicitConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
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

  test_super_requiredParameter_legacySubclass_implicitConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  A({required String s});
}
''');
    await assertNoErrorsInCode(r'''
// @dart=2.8
import 'a.dart';

class B extends A {}
''');
  }
}

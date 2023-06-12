// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedConstructorInInitializerDefaultTest);
  });
}

@reflectiveTest
class UndefinedConstructorInInitializerDefaultTest
    extends PubPackageResolutionTest {
  test_hasOptionalParameters_defined() async {
    await assertNoErrorsInCode(r'''
class A {
  A([p]) {}
}
class B extends A {
  B();
}
''');
  }

  test_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          49, 1),
    ]);
  }

  test_implicit_defined() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  B();
}
''');
  }

  test_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          55, 7),
    ]);
  }
}

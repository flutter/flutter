// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedConstructorInInitializerTest);
  });
}

@reflectiveTest
class UndefinedConstructorInInitializerTest extends PubPackageResolutionTest {
  test_explicit_named() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  B() : super.named();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, 39, 13,
          messageContains: ["class 'A'", "named 'named'"]),
    ]);
  }

  test_explicit_named_defined() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_explicit_unnamed_defined() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  B() : super();
}
''');
  }

  test_redirecting_defined() async {
    await assertNoErrorsInCode(r'''
class Foo {
  Foo.ctor();
}
class Bar extends Foo {
  Bar() : this.ctor();
  Bar.ctor() : super.ctor();
}
''');
  }
}

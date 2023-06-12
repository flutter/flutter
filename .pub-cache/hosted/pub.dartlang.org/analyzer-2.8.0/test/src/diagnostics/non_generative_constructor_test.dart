// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonGenerativeConstructorTest);
  });
}

@reflectiveTest
class NonGenerativeConstructorTest extends PubPackageResolutionTest {
  test_explicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A.named() => throw 0;
  A.generative();
}
class B extends A {
  B() : super.named();
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 90, 13),
    ]);
  }

  test_generative() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
  factory A() => throw 0;
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_generative_external() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
  factory A() => throw 0;
}
class B extends A {
  external B();
}
''');
  }

  test_implicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => throw 0;
  A.named();
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 73, 1),
    ]);
  }
}

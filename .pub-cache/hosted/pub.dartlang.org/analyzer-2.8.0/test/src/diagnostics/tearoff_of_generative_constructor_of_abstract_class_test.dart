// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TearoffOfGenerativeConstructorOfAbstractClassTest);
  });
}

@reflectiveTest
class TearoffOfGenerativeConstructorOfAbstractClassTest
    extends PubPackageResolutionTest {
  test_abstractClass_factoryConstructor() async {
    await assertNoErrorsInCode('''
abstract class A {
  factory A() => B();
}

class B implements A {}

void foo() {
  A.new;
}
''');
  }

  test_abstractClass_factoryConstructor_viaEquals() async {
    await assertNoErrorsInCode('''
abstract class A {
  factory A() = B;
}

class B implements A {}

void foo() {
  A.new;
}
''');
  }

  test_abstractClass_generativeConstructor() async {
    await assertErrorsInCode('''
abstract class A {
  A();
}

void foo() {
  A.new;
}
''', [
      error(
          CompileTimeErrorCode
              .TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS,
          44,
          5),
    ]);
  }

  test_concreteClass_factoryConstructor() async {
    await assertNoErrorsInCode('''
class A {
  factory A() => A.two();

  A.two();
}

void foo() {
  A.new;
}
''');
  }

  test_concreteClass_factoryConstructor_viaEquals() async {
    await assertNoErrorsInCode('''
class A {
  factory A() = A.two;

  A.two();
}

void foo() {
  A.new;
}
''');
  }

  test_concreteClass_generativeConstructor() async {
    await assertNoErrorsInCode('''
class A {
  A();
}

void foo() {
  A.new;
}
''');
  }
}

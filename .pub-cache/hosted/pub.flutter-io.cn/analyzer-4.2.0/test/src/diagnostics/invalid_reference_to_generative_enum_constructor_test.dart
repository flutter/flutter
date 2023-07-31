// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidReferenceToGenerativeEnumConstructorTest);
  });
}

@reflectiveTest
class InvalidReferenceToGenerativeEnumConstructorTest
    extends PubPackageResolutionTest {
  test_factory_named() async {
    await assertNoErrorsInCode('''
enum E {
  v();

  factory E.named() => v;
}

void f() {
  E.named;
  E.named();
}
''');
  }

  test_factory_unnamed() async {
    await assertNoErrorsInCode('''
enum E {
  v.named();

  const E.named();
  factory E() => v;
}

void f() {
  E.new;
  E();
}
''');
  }

  test_generative_named_constructorReference() async {
    await assertErrorsInCode('''
enum E {
  v.named();

  const E.named();
}

void f() {
  E.named;
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          58,
          7),
    ]);
  }

  test_generative_named_instanceCreation_implicitNew() async {
    await assertErrorsInCode('''
enum E {
  v.named();

  const E.named();
}

void f() {
  E.named();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          58,
          7),
    ]);
  }

  test_generative_named_redirectingConstructorInvocation() async {
    await assertNoErrorsInCode('''
enum E {
  v;

  const E() : this.named();
  const E.named();
}
''');
  }

  test_generative_named_redirectingFactory() async {
    await assertErrorsInCode('''
enum E {
  v;

  const factory E() = E.named;
  const E.named();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          37,
          7),
    ]);
  }

  test_generative_unnamed_constructorReference() async {
    await assertErrorsInCode('''
enum E {
  v
}

void f() {
  E.new;
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          29,
          5),
    ]);
  }

  test_generative_unnamed_instanceCreation_explicitConst() async {
    await assertErrorsInCode('''
enum E {
  v
}

void f() {
  const E();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          35,
          1),
    ]);
  }

  test_generative_unnamed_instanceCreation_explicitNew() async {
    await assertErrorsInCode('''
enum E {
  v
}

void f() {
  new E();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          33,
          1),
    ]);
  }

  test_generative_unnamed_instanceCreation_implicitNew() async {
    await assertErrorsInCode('''
enum E {
  v
}

void f() {
  E();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          29,
          1),
    ]);
  }

  test_generative_unnamed_redirectingConstructorInvocation() async {
    await assertNoErrorsInCode('''
enum E {
  v1,
  v2.named();

  const E();
  const E.named() : this();
}
''');
  }

  test_generative_unnamed_redirectingFactory() async {
    await assertErrorsInCode('''
enum E {
  v;

  const factory E.named() = E;
  const E();
}
''', [
      error(
          CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR,
          43,
          1),
    ]);
  }
}

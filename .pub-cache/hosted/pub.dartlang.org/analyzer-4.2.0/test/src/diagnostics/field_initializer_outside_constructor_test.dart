// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerOutsideConstructorTest);
  });
}

@reflectiveTest
class FieldInitializerOutsideConstructorTest extends PubPackageResolutionTest {
  test_closure() async {
    await assertErrorsInCode(r'''
class A {
  dynamic field = ({this.field}) {};
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 30, 10),
    ]);
  }

  test_defaultParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  m([this.x = 0]) {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 28, 6),
    ]);
  }

  test_functionTypedFieldFormalParameter() async {
    // TODO(srawlins) Fix the duplicate error messages.
    await assertErrorsInCode(r'''
class A {
  int Function()? x;
  m(int this.x()) {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 35, 12),
      error(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 39, 4),
    ]);
  }

  test_inFunctionTypedParameter() async {
    await assertErrorsInCode(r'''
class A {
  int? x;
  A(int p(this.x));
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 30, 6),
    ]);
  }

  test_method() async {
    // TODO(brianwilkerson) Fix the duplicate error messages.
    await assertErrorsInCode(r'''
class A {
  int? x;
  m(this.x) {}
}
''', [
      error(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 24, 4),
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 24, 6),
    ]);
  }

  test_topLevelFunction() async {
    await assertErrorsInCode(r'''
f(this.x(y)) {}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 2, 9),
    ]);
  }
}

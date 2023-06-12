// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerFactoryConstructorTest);
  });
}

@reflectiveTest
class FieldInitializerFactoryConstructorTest extends PubPackageResolutionTest {
  test_class_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x = 0;
  factory A(this.x) => throw 0;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, 35, 6),
    ]);
  }

  test_class_fieldFormalParameter_functionTyped() async {
    await assertErrorsInCode(r'''
class A {
  int Function()? x;
  factory A(int this.x());
}
''', [
      // TODO(srawlins): Only report one error. Theoretically change Fasta to
      // report "Field initiailizer in factory constructor" as a parse error.
      error(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, 43, 12),
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 56, 1),
    ]);
  }

  test_enum_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int x = 0;
  const E();
  factory E._(this.x) => throw 0;
}

void f() {
  E._(0);
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, 60, 6),
    ]);
  }
}

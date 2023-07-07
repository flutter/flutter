// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentNotEnabledTest);
  });
}

@reflectiveTest
class ExperimentNotEnabledTest extends PubPackageResolutionTest {
  test_constructor_tearoffs_disabled_grammar() async {
    await assertErrorsInCode('''
// @dart = 2.12
class Foo<X> {
  const Foo.bar();
  int get baz => 0;
}
main() {
  Foo<int>.bar.baz();
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 86, 5),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 96, 3),
    ]);
  }

  test_constructor_tearoffs_disabled_grammar_pre_nnbd() async {
    await assertErrorsInCode('''
// @dart=2.9
class Foo<X> {
  const Foo.bar();
  int get baz => 0;
}
main() {
  Foo<int>.bar.baz();
}
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 83, 5),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 93, 3),
    ]);
  }

  test_nonFunctionTypeAliases_disabled() async {
    await assertErrorsInCode(r'''
// @dart = 2.12
typedef A = int;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);
  }

  test_nonFunctionTypeAliases_disabled_nullable() async {
    await assertErrorsInCode(r'''
// @dart = 2.12
typedef A = int?;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);
  }
}

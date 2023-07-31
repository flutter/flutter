// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstMapAsExpressionStatementTest);
  });
}

@reflectiveTest
class NonConstMapAsExpressionStatementTest extends PubPackageResolutionTest {
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/42850')
  test_beginningOfExpressiontatement() async {
    // TODO(srawlins) Fasta is not recovering well.
    // Ideally we would produce a single diagnostic:
    // CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT
    addTestFile(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}
''');
    await resolveTestFile();
    expect(result.errors[0].errorCode,
        CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/42850')
  test_expressionStatementOnly() async {
    // TODO(danrubel) Fasta is not recovering well.
    // Ideally we would produce a single diagnostic:
    // CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT
    addTestFile(r'''
f() {
  {'a' : 0, 'b' : 1};
}
''');
    await resolveTestFile();
    expect(result.errors[0].errorCode,
        CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT);
  }
}

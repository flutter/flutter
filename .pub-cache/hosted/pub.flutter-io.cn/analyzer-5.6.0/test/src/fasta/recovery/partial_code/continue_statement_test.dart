// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ContinueStatementTest().buildAll();
}

class ContinueStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'continue_statement',
        [
          TestDescriptor(
              'keyword',
              'continue',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP
              ],
              "continue;",
              expectedErrorsInValidCode: [
                ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP
              ],
              failing: ['labeled', 'localFunctionNonVoid']),
          TestDescriptor(
              'label',
              'continue a',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP
              ],
              "continue a;",
              expectedErrorsInValidCode: [
                ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP
              ]),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}

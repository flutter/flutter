// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  WhileStatementTest().buildAll();
}

class WhileStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'while_statement',
      <TestDescriptor>[
        TestDescriptor(
          'keyword',
          'while',
          [
            ParserErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN
          ],
          "while (_s_)",
          expectedErrorsInValidCode: [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN
          ],
        ),
        TestDescriptor(
          'leftParen',
          'while (',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN
          ],
          "while (_s_)",
          expectedErrorsInValidCode: [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN
          ],
        ),
        TestDescriptor(
          'condition',
          'while (a',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN
          ],
          "while (a)",
          expectedErrorsInValidCode: [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN
          ],
        ),
      ],
      [],
      head: 'f() { ',
      tail: ' }',
    );
    buildTests(
      'while_statement',
      <TestDescriptor>[
        TestDescriptor(
          'keyword',
          'while',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          "while (_s_)",
          failing: ['break', 'continue'],
        ),
        TestDescriptor(
          'leftParen',
          'while (',
          [ParserErrorCode.MISSING_IDENTIFIER, ScannerErrorCode.EXPECTED_TOKEN],
          "while (_s_)",
          failing: [
            'assert',
            'block',
            'break',
            'continue',
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'return'
          ],
        ),
        TestDescriptor(
          'condition',
          'while (a',
          [ScannerErrorCode.EXPECTED_TOKEN],
          "while (a)",
          failing: ['break', 'continue'],
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      includeEof: false,
      tail: ' }',
    );
  }
}

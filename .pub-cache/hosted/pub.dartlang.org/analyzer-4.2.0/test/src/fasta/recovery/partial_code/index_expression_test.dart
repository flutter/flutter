// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  IndexStatementTest().buildAll();
}

class IndexStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'index_assignment',
      [
        TestDescriptor(
          'missing_index_no_space',
          'intList[] = 0;',
          [ParserErrorCode.MISSING_IDENTIFIER],
          'intList[_s_] = 0;',
        ),
        TestDescriptor(
          'missing_index_with_space',
          'intList[ ] = 0;',
          [ParserErrorCode.MISSING_IDENTIFIER],
          'intList[_s_] = 0;',
        ),
        TestDescriptor(
          'trailing_comma',
          'intList[x,] = 0;',
          [ParserErrorCode.EXPECTED_TOKEN],
          'intList[x] = 0;',
        ),
        TestDescriptor(
          'trailing_comma_and_identifier',
          'intList[x,y] = 0;',
          [ParserErrorCode.EXPECTED_TOKEN],
          'intList[x] = 0;',
        ),
        TestDescriptor(
          'trailing_identifier_no_comma',
          'intList[x y] = 0;',
          [ParserErrorCode.EXPECTED_TOKEN],
          'intList[x] = 0;',
        ),
      ],
      [], //PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
    buildTests(
      'index_partial',
      [
        TestDescriptor(
          'open',
          'intList[',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          'intList[_s_];',
          failing: [
            'eof',
            'assert',
            'block',
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'return'
          ],
        ),
        TestDescriptor(
          'identifier',
          'intList[x',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          'intList[x];',
          failing: ['eof'],
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}

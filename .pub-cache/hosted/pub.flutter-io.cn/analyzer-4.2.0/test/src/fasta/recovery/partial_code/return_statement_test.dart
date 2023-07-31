// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ReturnStatementTest().buildAll();
}

class ReturnStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'return_statement',
        [
          TestDescriptor(
              'keyword', 'return', [ParserErrorCode.EXPECTED_TOKEN], "return;",
              allFailing: true),
          TestDescriptor('expression', 'return a',
              [ParserErrorCode.EXPECTED_TOKEN], "return a;"),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}

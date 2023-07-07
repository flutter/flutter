// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  InstanceCreationTest().buildAll();
}

class InstanceCreationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'instance_creation_expression',
        <TestDescriptor>[
          ...forKeyword('const'),
          ...forKeyword('new'),
        ],
        <TestSuffix>[],
        head: 'f() => ',
        tail: ';');
  }

  List<TestDescriptor> forKeyword(String keyword) {
    return <TestDescriptor>[
      TestDescriptor(
          '${keyword}_keyword',
          keyword,
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword _s_()"),
      TestDescriptor(
          '${keyword}_name_unnamed',
          '$keyword A',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A()"),
      TestDescriptor(
          '${keyword}_name_named',
          '$keyword A.b',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A.b()"),
      TestDescriptor(
          '${keyword}_name_dot',
          '$keyword A.',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A._s_()"),
      TestDescriptor(
          '${keyword}_leftParen_unnamed',
          '$keyword A(',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A()",
          allFailing: true),
      TestDescriptor(
          '${keyword}_leftParen_named',
          '$keyword A.b(',
          [
            ParserErrorCode.EXPECTED_TOKEN,
          ],
          "$keyword A.b()",
          allFailing: true),
    ];
  }
}

// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  LocalVariableTest().buildAll();
}

class LocalVariableTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'local_variable',
        [
          TestDescriptor(
              'const',
              'const',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "const _s_;",
              allFailing: true),
          TestDescriptor('constName', 'const a',
              [ParserErrorCode.EXPECTED_TOKEN], "const a;",
              failing: <String>[
                'eof',
                'labeled',
                'localFunctionNonVoid',
              ]),
          TestDescriptor('constTypeName', 'const int a',
              [ParserErrorCode.EXPECTED_TOKEN], "const int a;"),
          TestDescriptor(
              'constNameComma',
              'const a,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "const a, _s_;",
              failing: <String>[
                'labeled',
                'localFunctionNonVoid',
              ]),
          TestDescriptor(
              'constTypeNameComma',
              'const int a,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "const int a, _s_;",
              failing: [
                'labeled',
                'localFunctionNonVoid',
              ]),
          TestDescriptor('constNameCommaName', 'const a, b',
              [ParserErrorCode.EXPECTED_TOKEN], "const a, b;"),
          TestDescriptor('constTypeNameCommaName', 'const int a, b',
              [ParserErrorCode.EXPECTED_TOKEN], "const int a, b;"),
          TestDescriptor(
              'final',
              'final',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "final _s_;",
              failing: [
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'localVariable',
              ]),
          TestDescriptor('finalName', 'final a',
              [ParserErrorCode.EXPECTED_TOKEN], "final a;",
              failing: [
                'labeled',
                'localFunctionNonVoid',
              ]),
          TestDescriptor('finalTypeName', 'final int a',
              [ParserErrorCode.EXPECTED_TOKEN], "final int a;"),
          TestDescriptor(
              'type',
              'int',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "int _s_;",
              allFailing: true),
          TestDescriptor(
              'typeName', 'int a', [ParserErrorCode.EXPECTED_TOKEN], "int a;"),
          TestDescriptor(
              'var',
              'var',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "var _s_;",
              failing: [
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'localVariable',
              ]),
          TestDescriptor(
              'varName', 'var a', [ParserErrorCode.EXPECTED_TOKEN], "var a;",
              failing: [
                'labeled',
                'localFunctionNonVoid',
              ]),
          TestDescriptor(
              'varNameEquals',
              'var a =',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "var a = _s_;",
              failing: [
                'block',
                'assert',
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'return'
              ]),
          TestDescriptor('varNameEqualsExpression', 'var a = b',
              [ParserErrorCode.EXPECTED_TOKEN], "var a = b;"),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}

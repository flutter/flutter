// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  EnumDeclarationTest().buildAll();
}

class EnumDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'enum_declaration',
        [
          TestDescriptor(
              'keyword',
              'enum',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_ENUM_BODY
              ],
              'enum _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY],
              failing: ['functionNonVoid', 'getter']),
          TestDescriptor('name', 'enum E', [ParserErrorCode.MISSING_ENUM_BODY],
              'enum E {}',
              expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY]),
          TestDescriptor(
              'missingName',
              'enum {}',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EMPTY_ENUM_BODY
              ],
              'enum _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY]),
          TestDescriptor(
              'leftBrace',
              'enum E {',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'enum E {_s_}',
              failing: [
                'eof' /* tested separately below */,
                'typedef',
                'functionNonVoid',
                'getter',
                'mixin',
                'setter'
              ]),
          TestDescriptor(
              'comma',
              'enum E {,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'enum E {_s_,_s_}',
              failing: [
                'eof' /* tested separately below */,
                'typedef',
                'functionNonVoid',
                'getter',
                'mixin',
                'setter'
              ]),
          TestDescriptor('value', 'enum E {a',
              [ScannerErrorCode.EXPECTED_TOKEN], 'enum E {a}'),
          TestDescriptor(
              'commaValue',
              'enum E {,a',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'enum E {_s_, a}'),
          TestDescriptor('commaRightBrace', 'enum E {,}',
              [ParserErrorCode.MISSING_IDENTIFIER], 'enum E {_s_}'),
          TestDescriptor('commaValueRightBrace', 'enum E {, a}',
              [ParserErrorCode.MISSING_IDENTIFIER], 'enum E {_s_, a}'),
        ],
        PartialCodeTest.declarationSuffixes);
    buildTests('enum_eof', [
      TestDescriptor(
          'leftBrace',
          'enum E {',
          [ParserErrorCode.EMPTY_ENUM_BODY, ScannerErrorCode.EXPECTED_TOKEN],
          'enum E {}',
          expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY]),
      TestDescriptor(
          'comma',
          'enum E {,',
          [ParserErrorCode.MISSING_IDENTIFIER, ScannerErrorCode.EXPECTED_TOKEN],
          'enum E {_s_}'),
    ], []);
  }
}

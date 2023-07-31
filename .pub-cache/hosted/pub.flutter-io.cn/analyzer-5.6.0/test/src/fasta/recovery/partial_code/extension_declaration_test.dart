// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ExtensionDeclarationTest().buildAll();
}

class ExtensionDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'extension_declaration',
        [
          TestDescriptor(
              'keyword',
              'extension',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY,
              ],
              'extension on _s_ {}',
              failing: [
                'getter',
                'functionNonVoid',
                'functionVoid',
                'mixin',
                'setter',
                'typedef'
              ]),
          TestDescriptor(
              'named',
              'extension E',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY,
              ],
              'extension E on _s_ {}',
              failing: ['getter', 'functionNonVoid', 'functionVoid', 'mixin']),
          TestDescriptor(
              'on',
              'extension E on',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY,
              ],
              'extension E on _s_ {}',
              failing: ['getter', 'functionNonVoid', 'functionVoid', 'mixin']),
          TestDescriptor(
              'extendedType',
              'extension E on String',
              [
                ParserErrorCode.EXPECTED_BODY,
              ],
              'extension E on String {}'),
          // Most of the failing tests are because the following text could be
          // a member of the class, so the parser adds the closing brace _after_
          // the declaration that's expected to follow it.
          //
          // The notable exceptions are 'class', 'enum', 'mixin', and 'typedef'.
          TestDescriptor(
              'partialBody',
              'extension E on String {',
              [
                ScannerErrorCode.EXPECTED_TOKEN,
              ],
              'extension E on String {}',
              failing: [
                'class',
                'const',
                'enum',
                'final',
                'functionNonVoid',
                'functionVoid',
                'mixin',
                'getter',
                'setter',
                'typedef',
                'var'
              ]),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}

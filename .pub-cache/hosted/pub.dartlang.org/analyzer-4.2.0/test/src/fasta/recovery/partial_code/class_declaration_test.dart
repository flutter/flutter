// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ClassDeclarationTest().buildAll();
}

class ClassDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'class_declaration',
        [
          TestDescriptor(
              'keyword',
              'class',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class _s_ {}',
              failing: ['functionNonVoid', 'getter']),
          TestDescriptor('named', 'class A', [ParserErrorCode.EXPECTED_BODY],
              'class A {}'),
          TestDescriptor(
              'extend',
              'class A extend',
              [
                ParserErrorCode.EXPECTED_INSTEAD,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A extend _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_INSTEAD],
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'extends',
              'class A extends',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A extends _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'on',
              'class A on',
              [
                ParserErrorCode.EXPECTED_INSTEAD,
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A on _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EXPECTED_INSTEAD],
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor('extendsBody', 'class A extends {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME], 'class A extends _s_ {}'),
          TestDescriptor(
              'extendsWithNameBody',
              'class A extends with B {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A extends _s_ with B {}'),
          TestDescriptor(
              'extendsImplementsNameBody',
              'class A extends implements B {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A extends _s_ implements B {}',
              allFailing: true),
          TestDescriptor(
              'extendsNameWith',
              'class A extends B with',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A extends B with _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'extendsNameWithBody',
              'class A extends B with {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A extends B with _s_ {}'),
          TestDescriptor(
              'extendsNameImplements',
              'class A extends B implements',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A extends B implements _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'extendsNameImplementsBody',
              'class A extends B implements {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A extends B implements _s_ {}'),
          TestDescriptor(
              'extendsNameWithNameImplements',
              'class A extends B with C implements',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A extends B with C implements _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'extendsNameWithNameImplementsBody',
              'class A extends B with C implements {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A extends B with C implements _s_ {}'),
          TestDescriptor(
              'implements',
              'class A implements',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A implements _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'implementsBody',
              'class A implements {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A implements _s_ {}'),
          TestDescriptor(
              'implementsNameComma',
              'class A implements B,',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_BODY
              ],
              'class A implements B, _s_ {}',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'implementsNameCommaBody',
              'class A implements B, {}',
              [ParserErrorCode.EXPECTED_TYPE_NAME],
              'class A implements B, _s_ {}'),
          TestDescriptor(
              'equals',
              'class A =',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'class A = _s_ with _s_;',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'equalsName',
              'class A = B',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              'class A = B with _s_;',
              failing: ['functionVoid', 'functionNonVoid', 'getter']),
          TestDescriptor(
              'equalsNameWith',
              'class A = B with',
              [
                ParserErrorCode.EXPECTED_TYPE_NAME,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'class A = B with _s_;',
              failing: ['functionVoid', 'functionNonVoid', 'getter', 'mixin']),
          TestDescriptor(
              'equalsNameName',
              'class A = B C',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              'class A = B with C;'),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}

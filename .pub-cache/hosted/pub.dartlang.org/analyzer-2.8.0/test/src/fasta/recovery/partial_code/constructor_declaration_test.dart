// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ConstructorTest().buildAll();
}

class ConstructorTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'constructor',
        [
          TestDescriptor(
            'colon',
            'C() :',
            [
              ParserErrorCode.MISSING_INITIALIZER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : _s_ = _s_ {}',
            adjustValidUnitBeforeComparison: setSeparator,
            failing: ['methodNonVoid', 'getter', 'setter'],
          ),
          TestDescriptor(
            'colon_field',
            'C() : f',
            [
              ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : f = _s_ {}',
            adjustValidUnitBeforeComparison: setSeparator,
          ),
          TestDescriptor(
            'colon_field_increment',
            'C() : f++',
            [
              ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : _s_ = f++ {}',
            adjustValidUnitBeforeComparison: setSeparator,
          ),
          TestDescriptor(
            'colon_field_comma',
            'C() : f = 0,',
            [
              ParserErrorCode.MISSING_INITIALIZER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : f = 0, _s_ = _s_ {}',
            adjustValidUnitBeforeComparison: setSeparator,
            failing: ['methodNonVoid', 'getter', 'setter'],
          ),
          TestDescriptor(
            'colon_block',
            'C() : {}',
            [ParserErrorCode.MISSING_INITIALIZER],
            'C() : _s_ = _s_ {}',
            adjustValidUnitBeforeComparison: setSeparator,
          ),
          TestDescriptor(
            'colon_semicolon',
            'C() : ;',
            [ParserErrorCode.MISSING_INITIALIZER],
            'C() : _s_ = _s_ ;',
            adjustValidUnitBeforeComparison: setSeparator,
          ),
          TestDescriptor(
            'super',
            'C() : super',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : super() {}',
          ),
          TestDescriptor(
            'super_dot',
            'C() : super.',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'C() : super._s_() {}',
            failing: ['fieldConst', 'methodNonVoid', 'getter', 'setter'],
          ),
          TestDescriptor(
            'super_qdot',
            'C() : super?.',
            [
              ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER,
              ParserErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_FUNCTION_BODY,
            ],
            'C() : super?._s_() {}',
            expectedErrorsInValidCode: [
              ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER
            ],
            failing: ['methodNonVoid', 'getter', 'setter'],
          ),
        ],
        PartialCodeTest.classMemberSuffixes,
        head: 'class C {',
        tail: '}');
  }

  CompilationUnitImpl setSeparator(CompilationUnitImpl unit) {
    var declaration = unit.declarations[0] as ClassDeclaration;
    var member = declaration.members[0] as ConstructorDeclarationImpl;
    member.separator =
        Token(TokenType.COLON, member.parameters.endToken.charOffset + 1);
    return unit;
  }
}

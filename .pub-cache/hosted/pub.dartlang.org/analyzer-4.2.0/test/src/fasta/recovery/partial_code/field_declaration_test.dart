// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

import 'partial_code_support.dart';

main() {
  MethodTest().buildAll();
}

class MethodTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptAnnotationAndEof = <String>[
      'field',
      'fieldConst',
      'fieldFinal',
      'methodNonVoid',
      'methodVoid',
      'getter',
      'setter'
    ];
    buildTests(
      'field_declaration',
      [
        //
        // Instance field, const.
        //
        TestDescriptor(
          'const_noName',
          'const',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'const _s_;',
          failing: allExceptAnnotationAndEof,
          expectedErrorsInValidCode: [
            CompileTimeErrorCode.CONST_NOT_INITIALIZED
          ],
        ),
        TestDescriptor(
          'const_name',
          'const f',
          [
            ParserErrorCode.EXPECTED_TOKEN,
            CompileTimeErrorCode.CONST_NOT_INITIALIZED
          ],
          'const f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
          expectedErrorsInValidCode: [
            CompileTimeErrorCode.CONST_NOT_INITIALIZED
          ],
        ),
        TestDescriptor(
          'const_equals',
          'const f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'const f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'const_initializer',
          'const f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'const f = 0;',
        ),
        //
        // Instance field, final.
        //
        TestDescriptor(
          'final_noName',
          'final',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'final _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'final_name',
          'final f',
          [ParserErrorCode.EXPECTED_TOKEN],
          'final f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'final_equals',
          'final f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'final f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'final_initializer',
          'final f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'final f = 0;',
        ),
        //
        // Instance field, var.
        //
        TestDescriptor(
          'var_noName',
          'var',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'var _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'var_name',
          'var f',
          [ParserErrorCode.EXPECTED_TOKEN],
          'var f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'var_name_comma',
          'var f,',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'var f, _s_;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'var_equals',
          'var f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'var f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'var_initializer',
          'var f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'var f = 0;',
        ),
        //
        // Instance field, type.
        //
        TestDescriptor(
          'type_noName',
          'A',
          [
            ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
            ParserErrorCode.EXPECTED_TOKEN
          ],
          'A _s_;',
          allFailing: true,
        ),
        TestDescriptor(
          'type_name',
          'A f',
          [ParserErrorCode.EXPECTED_TOKEN],
          'A f;',
        ),
        TestDescriptor(
            'type_name_comma',
            'A f,',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ],
            'A f, _s_;',
            failing: ['methodNonVoid', 'getter', 'setter']),
        TestDescriptor(
          'type_equals',
          'A f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'A f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'type_initializer',
          'A f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'A f = 0;',
        ),
        //
        // Static field, const.
        //
        TestDescriptor(
          'static_const_noName',
          'static const',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static const _s_;',
          failing: allExceptAnnotationAndEof,
          expectedErrorsInValidCode: [
            CompileTimeErrorCode.CONST_NOT_INITIALIZED
          ],
        ),
        TestDescriptor(
          'static_const_name',
          'static const f',
          [
            ParserErrorCode.EXPECTED_TOKEN,
            CompileTimeErrorCode.CONST_NOT_INITIALIZED
          ],
          'static const f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
          expectedErrorsInValidCode: [
            CompileTimeErrorCode.CONST_NOT_INITIALIZED
          ],
        ),
        TestDescriptor(
          'static_const_equals',
          'static const f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static const f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'static_const_initializer',
          'static const f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static const f = 0;',
        ),
        //
        // Static field, final.
        //
        TestDescriptor(
          'static_final_noName',
          'static final',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static final _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'static_final_name',
          'static final f',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static final f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'static_final_equals',
          'static final f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static final f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'static_final_initializer',
          'static final f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static final f = 0;',
        ),
        //
        // Static field, var.
        //
        TestDescriptor(
          'static_var_noName',
          'static var',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static var _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'static_var_name',
          'static var f',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static var f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'static_var_equals',
          'static var f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static var f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'static_var_initializer',
          'static var f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static var f = 0;',
        ),
        //
        // Static field, type.
        //
        TestDescriptor(
          'static_type_noName',
          'static A',
          [
            ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
            ParserErrorCode.EXPECTED_TOKEN
          ],
          'static A _s_;',
          allFailing: true,
        ),
        TestDescriptor(
          'static_type_name',
          'static A f',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static A f;',
        ),
        TestDescriptor(
          'static_type_equals',
          'static A f =',
          [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN],
          'static A f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter'
          ],
        ),
        TestDescriptor(
          'static_type_initializer',
          'static A f = 0',
          [ParserErrorCode.EXPECTED_TOKEN],
          'static A f = 0;',
        ),
      ],
      PartialCodeTest.classMemberSuffixes,
      head: 'class C { ',
      tail: ' }',
    );
  }
}

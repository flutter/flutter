// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypedParameterVarTest);
  });
}

@reflectiveTest
class FunctionTypedParameterVarTest extends ParserDiagnosticsTest {
  test_superFormalParameter_var_functionTyped() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var super.a<T>());
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, 14, 3),
    ]);

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  keyword: var
  superKeyword: super
  period: .
  name: a
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
''');
  }
}

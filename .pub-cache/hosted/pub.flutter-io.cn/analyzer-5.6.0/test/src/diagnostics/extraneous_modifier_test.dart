// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraneousModifierTest);
  });
}

@reflectiveTest
class ExtraneousModifierTest extends ParserDiagnosticsTest {
  test_simpleFormalParameter_const() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const a);
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 14, 5),
    ]);

    var node = parseResult.findNode.simpleFormalParameter('a);');
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: const
  name: a
''');
  }

  test_simpleFormalParameter_var() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.simpleFormalParameter('a);');
    assertParsedNodeText(node, r'''
SimpleFormalParameter
  keyword: var
  name: a
''');
  }

  test_superFormalParameter_var() async {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(var super.a);
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 14, 3),
    ]);

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  keyword: var
  superKeyword: super
  period: .
  name: a
''');
  }
}

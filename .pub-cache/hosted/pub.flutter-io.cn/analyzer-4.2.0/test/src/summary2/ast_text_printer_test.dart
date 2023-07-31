// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/ast_text_printer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/ast/parse_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstTextPrinterTest);
  });
}

/// Assert that the [code] parsed into AST, when it does not have parse errors,
/// and printed with [AstTextPrinter], gives exactly the same [code].
///
/// Whitespaces and newlines are normalized and ignored.
void assertParseCodeAndPrintAst(ParseBase base, String code,
    {bool mightHasParseErrors = false}) {
  code = code.trimRight();
  code = code.replaceAll('\t', ' ');
  code = code.replaceAll('\r\n', '\n');
  code = code.replaceAll('\r', '\n');

  var path = base.newFile('/home/test/lib/test.dart', code).path;

  ParseResult parseResult;
  try {
    parseResult = base.parseUnit(path);
  } catch (e) {
    return;
  }

  // Code with parsing errors cannot be restored.
  if (parseResult.errors.isNotEmpty) {
    if (mightHasParseErrors) return;
    expect(parseResult.errors, isEmpty);
  }

  var buffer = StringBuffer();
  parseResult.unit.accept(
    AstTextPrinter(buffer, parseResult.lineInfo),
  );

//    print('---------------------');
//    print(buffer.toString());
//    print('---------------------');
  expect(buffer.toString(), code);
}

@reflectiveTest
class AstTextPrinterTest extends ParseBase {
  test_commentOnly() async {
    assertParseCodeAndPrintAst(this, r'''
// aaa
// bbb
''');
  }

  test_extensionOverride() async {
    assertParseCodeAndPrintAst(this, '''
extension E on Object {
  int f() => 0;
}

const e = E(null).f();
''');
  }

  test_forElement() async {
    assertParseCodeAndPrintAst(this, r'''
var _ = [1, for (var v in [2, 3, 4]) v, 5];
''');
  }

  test_genericFunctionType_question() async {
    assertParseCodeAndPrintAst(this, '''
void Function()? a;
''');
  }

  test_ifElement_then() async {
    assertParseCodeAndPrintAst(this, r'''
var _ = [1, if (true) 2, 3];
''');
  }

  test_ifElement_thenElse() async {
    assertParseCodeAndPrintAst(this, r'''
var _ = [1, if (true) 2 else 3, 4];
''');
  }

  test_simple() async {
    assertParseCodeAndPrintAst(this, r'''
class C {
  void foo() {
    1;
    2 + 3;
  }
}
''');
  }

  test_spaces_emptyLine() async {
    assertParseCodeAndPrintAst(this, '''
class A {}
${' ' * 2}
class B {}
''');
  }

  test_spreadElement() async {
    assertParseCodeAndPrintAst(this, r'''
var _ = [1, ...[2, 3], 4];
''');
  }

  test_spreadElement_nullable() async {
    assertParseCodeAndPrintAst(this, r'''
var _ = [1, ...?[2, 3], 4];
''');
  }

  test_typeName_question() async {
    assertParseCodeAndPrintAst(this, '''
int? a;
''');
  }
}

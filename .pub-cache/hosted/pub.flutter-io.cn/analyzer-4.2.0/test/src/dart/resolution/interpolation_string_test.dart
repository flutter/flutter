// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InterpolationStringTest);
  });
}

@reflectiveTest
class InterpolationStringTest extends PubPackageResolutionTest {
  void test_contents() async {
    var code = r'''
var bar;
var f = "foo$bar";
''';
    await assertNoErrorsInCode(code);
    final string = findNode.stringInterpolation(r'"foo$bar"');

    expect(string.elements, hasLength(3));

    final foo = string.elements[0] as InterpolationString;
    var quoteOffset = code.indexOf('"');
    expect(foo.contents.lexeme, '"foo');
    expect(foo.contents.offset, quoteOffset);
    expect(foo.contents.end, quoteOffset + '"foo'.length);
  }

  void test_contentsOffset() async {
    var code = r'''
var bar;
var f = "foo${bar}baz";
''';
    await assertNoErrorsInCode(code);
    final string = findNode.stringInterpolation(r'"foo${bar}baz"');
    expect(string.elements, hasLength(3));
    var quoteOffset = code.indexOf('"');

    final foo = string.elements[0] as InterpolationString;
    expect(foo.contentsOffset, quoteOffset + '"'.length);
    expect(foo.contentsEnd, quoteOffset + '"foo'.length);

    final bar = string.elements[2] as InterpolationString;
    expect(bar.contentsOffset, quoteOffset + r'"foo${bar}'.length);
    expect(bar.contentsEnd, quoteOffset + r'"foo${bar}baz'.length);
  }

  void test_contentsOffset_emptyEnd() async {
    var code = r'''
var bar;
var f = "foo${bar}";
''';
    await assertNoErrorsInCode(code);
    final string = findNode.stringInterpolation(r'"foo${bar}"');
    expect(string.elements, hasLength(3));

    final end = string.elements[2] as InterpolationString;
    final endStringOffset = code.indexOf('";');
    expect(end.contentsOffset, endStringOffset);
    expect(end.contentsEnd, endStringOffset);
  }

  void test_contentsOffset_unterminated() async {
    var code = r'''
var bar;
var f = "foo${bar}
// deliberately unclosed
;
''';
    await assertErrorsInCode(code, [
      error(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, code.indexOf('}'), 1)
    ]);
    final string = findNode.stringInterpolation(r'"foo${bar}');
    expect(string.elements, hasLength(3));

    final end = string.elements[2] as InterpolationString;
    final endStringOffset = code.indexOf('}') + 1;
    expect(end.contentsOffset, endStringOffset);
    expect(end.contentsEnd, endStringOffset);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/42634')
  void test_contentsOffset_unterminated_wrongQuote() async {
    var code = r'''
var bar;
var f = "foo${bar}'
// deliberately closed with wrong quote
;
''';
    await assertErrorsInCode(code, [
      error(ScannerErrorCode.UNTERMINATED_STRING_LITERAL, code.indexOf("'"), 1),
    ]);
    final string = findNode.stringInterpolation('"foo\${bar}\'');
    expect(string.elements, hasLength(3));

    final end = string.elements[2] as InterpolationString;
    expect(end.value, "'");
    final endStringOffset = code.indexOf("'") + 1;
    expect(end.contentsOffset, endStringOffset);
    expect(end.contentsEnd, endStringOffset);
  }

  void test_value() async {
    var code = r'''
var bar;
var f = "foo\n$bar";
''';
    await assertNoErrorsInCode(code);
    final string = findNode.stringInterpolation(r'"foo\n$bar"');
    expect(string.elements, hasLength(3));

    final foo = string.elements[0] as InterpolationString;
    expect(foo.value, "foo\n");
  }
}

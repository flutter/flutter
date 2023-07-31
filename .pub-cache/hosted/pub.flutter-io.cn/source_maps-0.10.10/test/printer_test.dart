// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.printer_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'common.dart';

void main() {
  test('printer', () {
    var printer = Printer('output.dart');
    printer
      ..add('var ')
      ..mark(inputVar1)
      ..add('x = 3;\n')
      ..mark(inputFunction)
      ..add('f(')
      ..mark(inputVar2)
      ..add('y) => ')
      ..mark(inputExpr)
      ..add('x + y;\n');
    expect(printer.text, OUTPUT);
    expect(printer.map, jsonEncode(EXPECTED_MAP));
  });

  test('printer projecting marks', () {
    var out = INPUT.replaceAll('long', '_s');
    var printer = Printer('output2.dart');

    var segments = INPUT.split('long');
    expect(segments.length, 6);
    printer
      ..mark(ispan(0, 0))
      ..add(segments[0], projectMarks: true)
      ..mark(inputVar1)
      ..add('_s')
      ..add(segments[1], projectMarks: true)
      ..mark(inputFunction)
      ..add('_s')
      ..add(segments[2], projectMarks: true)
      ..mark(inputVar2)
      ..add('_s')
      ..add(segments[3], projectMarks: true)
      ..mark(inputExpr)
      ..add('_s')
      ..add(segments[4], projectMarks: true)
      ..add('_s')
      ..add(segments[5], projectMarks: true);

    expect(printer.text, out);
    // 8 new lines in the source map:
    expect(printer.map.split(';').length, 8);

    SourceMapSpan asFixed(SourceMapSpan s) =>
        SourceMapSpan(s.start, s.end, s.text, isIdentifier: s.isIdentifier);

    // The result is the same if we use fixed positions
    var printer2 = Printer('output2.dart');
    printer2
      ..mark(SourceLocation(0, sourceUrl: 'input.dart').pointSpan())
      ..add(segments[0], projectMarks: true)
      ..mark(asFixed(inputVar1))
      ..add('_s')
      ..add(segments[1], projectMarks: true)
      ..mark(asFixed(inputFunction))
      ..add('_s')
      ..add(segments[2], projectMarks: true)
      ..mark(asFixed(inputVar2))
      ..add('_s')
      ..add(segments[3], projectMarks: true)
      ..mark(asFixed(inputExpr))
      ..add('_s')
      ..add(segments[4], projectMarks: true)
      ..add('_s')
      ..add(segments[5], projectMarks: true);

    expect(printer2.text, out);
    expect(printer2.map, printer.map);
  });

  group('nested printer', () {
    test('simple use', () {
      var printer = NestedPrinter();
      printer
        ..add('var ')
        ..add('x = 3;\n', span: inputVar1)
        ..add('f(', span: inputFunction)
        ..add('y) => ', span: inputVar2)
        ..add('x + y;\n', span: inputExpr)
        ..build('output.dart');
      expect(printer.text, OUTPUT);
      expect(printer.map, jsonEncode(EXPECTED_MAP));
    });

    test('nested use', () {
      var printer = NestedPrinter();
      printer
        ..add('var ')
        ..add(NestedPrinter()..add('x = 3;\n', span: inputVar1))
        ..add('f(', span: inputFunction)
        ..add(NestedPrinter()..add('y) => ', span: inputVar2))
        ..add('x + y;\n', span: inputExpr)
        ..build('output.dart');
      expect(printer.text, OUTPUT);
      expect(printer.map, jsonEncode(EXPECTED_MAP));
    });

    test('add indentation', () {
      var out = INPUT.replaceAll('long', '_s');
      var lines = INPUT.trim().split('\n');
      expect(lines.length, 7);
      var printer = NestedPrinter();
      for (var i = 0; i < lines.length; i++) {
        if (i == 5) printer.indent++;
        printer.addLine(lines[i].replaceAll('long', '_s').trim());
        if (i == 5) printer.indent--;
      }
      printer.build('output.dart');
      expect(printer.text, out);
    });
  });
}

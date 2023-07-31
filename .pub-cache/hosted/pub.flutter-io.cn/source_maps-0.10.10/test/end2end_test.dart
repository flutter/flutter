// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.end2end_test;

import 'package:test/test.dart';
import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'common.dart';

void main() {
  test('end-to-end setup', () {
    expect(inputVar1.text, 'longVar1');
    expect(inputFunction.text, 'longName');
    expect(inputVar2.text, 'longVar2');
    expect(inputVar1NoSymbol.text, 'longVar1');
    expect(inputFunctionNoSymbol.text, 'longName');
    expect(inputVar2NoSymbol.text, 'longVar2');
    expect(inputExpr.text, 'longVar1 + longVar2');

    expect(outputVar1.text, 'x');
    expect(outputFunction.text, 'f');
    expect(outputVar2.text, 'y');
    expect(outputVar1NoSymbol.text, 'x');
    expect(outputFunctionNoSymbol.text, 'f');
    expect(outputVar2NoSymbol.text, 'y');
    expect(outputExpr.text, 'x + y');
  });

  test('build + parse', () {
    var map = (SourceMapBuilder()
          ..addSpan(inputVar1, outputVar1)
          ..addSpan(inputFunction, outputFunction)
          ..addSpan(inputVar2, outputVar2)
          ..addSpan(inputExpr, outputExpr))
        .build(output.url.toString());
    var mapping = parseJson(map);
    check(outputVar1, mapping, inputVar1, false);
    check(outputVar2, mapping, inputVar2, false);
    check(outputFunction, mapping, inputFunction, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('build + parse - no symbols', () {
    var map = (SourceMapBuilder()
          ..addSpan(inputVar1NoSymbol, outputVar1NoSymbol)
          ..addSpan(inputFunctionNoSymbol, outputFunctionNoSymbol)
          ..addSpan(inputVar2NoSymbol, outputVar2NoSymbol)
          ..addSpan(inputExpr, outputExpr))
        .build(output.url.toString());
    var mapping = parseJson(map);
    check(outputVar1NoSymbol, mapping, inputVar1NoSymbol, false);
    check(outputVar2NoSymbol, mapping, inputVar2NoSymbol, false);
    check(outputFunctionNoSymbol, mapping, inputFunctionNoSymbol, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('build + parse, repeated entries', () {
    var map = (SourceMapBuilder()
          ..addSpan(inputVar1, outputVar1)
          ..addSpan(inputVar1, outputVar1)
          ..addSpan(inputFunction, outputFunction)
          ..addSpan(inputFunction, outputFunction)
          ..addSpan(inputVar2, outputVar2)
          ..addSpan(inputVar2, outputVar2)
          ..addSpan(inputExpr, outputExpr)
          ..addSpan(inputExpr, outputExpr))
        .build(output.url.toString());
    var mapping = parseJson(map);
    check(outputVar1, mapping, inputVar1, false);
    check(outputVar2, mapping, inputVar2, false);
    check(outputFunction, mapping, inputFunction, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('build + parse - no symbols, repeated entries', () {
    var map = (SourceMapBuilder()
          ..addSpan(inputVar1NoSymbol, outputVar1NoSymbol)
          ..addSpan(inputVar1NoSymbol, outputVar1NoSymbol)
          ..addSpan(inputFunctionNoSymbol, outputFunctionNoSymbol)
          ..addSpan(inputFunctionNoSymbol, outputFunctionNoSymbol)
          ..addSpan(inputVar2NoSymbol, outputVar2NoSymbol)
          ..addSpan(inputVar2NoSymbol, outputVar2NoSymbol)
          ..addSpan(inputExpr, outputExpr))
        .build(output.url.toString());
    var mapping = parseJson(map);
    check(outputVar1NoSymbol, mapping, inputVar1NoSymbol, false);
    check(outputVar2NoSymbol, mapping, inputVar2NoSymbol, false);
    check(outputFunctionNoSymbol, mapping, inputFunctionNoSymbol, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('build + parse with file', () {
    var json = (SourceMapBuilder()
          ..addSpan(inputVar1, outputVar1)
          ..addSpan(inputFunction, outputFunction)
          ..addSpan(inputVar2, outputVar2)
          ..addSpan(inputExpr, outputExpr))
        .toJson(output.url.toString());
    var mapping = parse(json);
    check(outputVar1, mapping, inputVar1, true);
    check(outputVar2, mapping, inputVar2, true);
    check(outputFunction, mapping, inputFunction, true);
    check(outputExpr, mapping, inputExpr, true);
  });

  test('printer projecting marks + parse', () {
    var out = INPUT.replaceAll('long', '_s');
    var file = SourceFile.fromString(out, url: 'output2.dart');
    var printer = Printer('output2.dart');
    printer.mark(ispan(0, 0));

    var segments = INPUT.split('long');
    expect(segments.length, 6);
    printer.add(segments[0], projectMarks: true);
    printer.mark(inputVar1);
    printer.add('_s');
    printer.add(segments[1], projectMarks: true);
    printer.mark(inputFunction);
    printer.add('_s');
    printer.add(segments[2], projectMarks: true);
    printer.mark(inputVar2);
    printer.add('_s');
    printer.add(segments[3], projectMarks: true);
    printer.mark(inputExpr);
    printer.add('_s');
    printer.add(segments[4], projectMarks: true);
    printer.add('_s');
    printer.add(segments[5], projectMarks: true);

    expect(printer.text, out);

    var mapping = parse(printer.map);
    void checkHelper(SourceMapSpan inputSpan, int adjustment) {
      var start = inputSpan.start.offset - adjustment;
      var end = (inputSpan.end.offset - adjustment) - 2;
      var span = SourceMapFileSpan(file.span(start, end),
          isIdentifier: inputSpan.isIdentifier);
      check(span, mapping, inputSpan, true);
    }

    checkHelper(inputVar1, 0);
    checkHelper(inputFunction, 2);
    checkHelper(inputVar2, 4);
    checkHelper(inputExpr, 6);

    // We projected correctly lines that have no mappings
    check(file.span(66, 66), mapping, ispan(45, 45), true);
    check(file.span(63, 64), mapping, ispan(45, 45), true);
    check(file.span(68, 68), mapping, ispan(70, 70), true);
    check(file.span(71, 71), mapping, ispan(70, 70), true);

    // Start of the last line
    var oOffset = out.length - 2;
    var iOffset = INPUT.length - 2;
    check(file.span(oOffset, oOffset), mapping, ispan(iOffset, iOffset), true);
    check(file.span(oOffset + 1, oOffset + 1), mapping, ispan(iOffset, iOffset),
        true);
  });
}

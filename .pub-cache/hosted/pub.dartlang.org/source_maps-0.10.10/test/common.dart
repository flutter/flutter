// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common input/output used by builder, parser and end2end tests
library test.common;

import 'package:source_maps/source_maps.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

/// Content of the source file
const String INPUT = '''
/** this is a comment. */
int longVar1 = 3;

// this is a comment too
int longName(int longVar2) {
  return longVar1 + longVar2;
}
''';
var input = SourceFile.fromString(INPUT, url: 'input.dart');

/// A span in the input file
SourceMapSpan ispan(int start, int end, [bool isIdentifier = false]) =>
    SourceMapFileSpan(input.span(start, end), isIdentifier: isIdentifier);

SourceMapSpan inputVar1 = ispan(30, 38, true);
SourceMapSpan inputFunction = ispan(74, 82, true);
SourceMapSpan inputVar2 = ispan(87, 95, true);

SourceMapSpan inputVar1NoSymbol = ispan(30, 38);
SourceMapSpan inputFunctionNoSymbol = ispan(74, 82);
SourceMapSpan inputVar2NoSymbol = ispan(87, 95);

SourceMapSpan inputExpr = ispan(108, 127);

/// Content of the target file
const String OUTPUT = '''
var x = 3;
f(y) => x + y;
''';
var output = SourceFile.fromString(OUTPUT, url: 'output.dart');

/// A span in the output file
SourceMapSpan ospan(int start, int end, [bool isIdentifier = false]) =>
    SourceMapFileSpan(output.span(start, end), isIdentifier: isIdentifier);

SourceMapSpan outputVar1 = ospan(4, 5, true);
SourceMapSpan outputFunction = ospan(11, 12, true);
SourceMapSpan outputVar2 = ospan(13, 14, true);
SourceMapSpan outputVar1NoSymbol = ospan(4, 5);
SourceMapSpan outputFunctionNoSymbol = ospan(11, 12);
SourceMapSpan outputVar2NoSymbol = ospan(13, 14);
SourceMapSpan outputExpr = ospan(19, 24);

/// Expected output mapping when recording the following four mappings:
///      inputVar1       <=   outputVar1
///      inputFunction   <=   outputFunction
///      inputVar2       <=   outputVar2
///      inputExpr       <=   outputExpr
///
/// This mapping is stored in the tests so we can independently test the builder
/// and parser algorithms without relying entirely on end2end tests.
const Map<String, dynamic> EXPECTED_MAP = {
  'version': 3,
  'sourceRoot': '',
  'sources': ['input.dart'],
  'names': ['longVar1', 'longName', 'longVar2'],
  'mappings': 'IACIA;AAGAC,EAAaC,MACR',
  'file': 'output.dart'
};

void check(SourceSpan outputSpan, Mapping mapping, SourceMapSpan inputSpan,
    bool realOffsets) {
  var line = outputSpan.start.line;
  var column = outputSpan.start.column;
  var files = realOffsets ? {'input.dart': input} : null;
  var span = mapping.spanFor(line, column, files: files)!;
  var span2 = mapping.spanForLocation(outputSpan.start, files: files)!;

  // Both mapping APIs are equivalent.
  expect(span.start.offset, span2.start.offset);
  expect(span.start.line, span2.start.line);
  expect(span.start.column, span2.start.column);
  expect(span.end.offset, span2.end.offset);
  expect(span.end.line, span2.end.line);
  expect(span.end.column, span2.end.column);

  // Mapping matches our input location (modulo using real offsets)
  expect(span.start.line, inputSpan.start.line);
  expect(span.start.column, inputSpan.start.column);
  expect(span.sourceUrl, inputSpan.sourceUrl);
  expect(span.start.offset, realOffsets ? inputSpan.start.offset : 0);

  // Mapping includes the identifier, if any
  if (inputSpan.isIdentifier) {
    expect(span.end.line, inputSpan.end.line);
    expect(span.end.column, inputSpan.end.column);
    expect(span.end.offset, span.start.offset + inputSpan.text.length);
    if (realOffsets) expect(span.end.offset, inputSpan.end.offset);
  } else {
    expect(span.end.offset, span.start.offset);
    expect(span.end.line, span.start.line);
    expect(span.end.column, span.start.column);
  }
}

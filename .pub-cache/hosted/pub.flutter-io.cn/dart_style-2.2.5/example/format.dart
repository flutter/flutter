// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart_style.example.format;

import 'dart:io';
import 'dart:mirrors';

import 'package:dart_style/dart_style.dart';
import 'package:dart_style/src/debug.dart' as debug;
import 'package:path/path.dart' as p;

void main(List<String> args) {
  // Enable debugging so you can see some of the formatter's internal state.
  // Normal users do not do this.
  debug.traceChunkBuilder = true;
  debug.traceLineWriter = true;
  debug.traceSplitter = true;
  debug.useAnsiColors = true;

  formatStmt('a is int????;');
}

void formatStmt(String source, [int pageWidth = 80]) {
  runFormatter(source, pageWidth, isCompilationUnit: false);
}

void formatUnit(String source, [int pageWidth = 80]) {
  runFormatter(source, pageWidth, isCompilationUnit: true);
}

void runFormatter(String source, int pageWidth,
    {required bool isCompilationUnit}) {
  try {
    var formatter = DartFormatter(pageWidth: pageWidth);

    String result;
    if (isCompilationUnit) {
      result = formatter.format(source);
    } else {
      result = formatter.formatStatement(source);
    }

    drawRuler('before', pageWidth);
    print(source);
    drawRuler('after', pageWidth);
    print(result);
  } on FormatterException catch (error) {
    print(error.message());
  }
}

void drawRuler(String label, int width) {
  var padding = ' ' * (width - label.length - 1);
  print('$label:$padding|');
}

/// Runs the formatter test starting on [line] at [path] inside the "test"
/// directory.
void runTest(String path, int line) {
  var indentPattern = RegExp(r'^\(indent (\d+)\)\s*');

  // Locate the "test" directory. Use mirrors so that this works with the test
  // package, which loads this suite into an isolate.
  var testDir = p.join(
      p.dirname(currentMirrorSystem()
          .findLibrary(#dart_style.example.format)
          .uri
          .path),
      '../test');

  var lines = File(p.join(testDir, path)).readAsLinesSync();

  // The first line may have a "|" to indicate the page width.
  var pageWidth = 80;
  if (lines[0].endsWith('|')) {
    pageWidth = lines[0].indexOf('|');
    lines = lines.skip(1).toList();
  }

  var i = 0;
  while (i < lines.length) {
    var description = lines[i++].replaceAll('>>>', '').trim();

    // Let the test specify a leading indentation. This is handy for
    // regression tests which often come from a chunk of nested code.
    var leadingIndent = 0;
    var indentMatch = indentPattern.firstMatch(description);
    if (indentMatch != null) {
      leadingIndent = int.parse(indentMatch[1]!);
      description = description.substring(indentMatch.end);
    }

    if (description == '') {
      description = 'line ${i + 1}';
    } else {
      description = 'line ${i + 1}: $description';
    }
    var startLine = i + 1;

    var input = '';
    while (!lines[i].startsWith('<<<')) {
      input += '${lines[i++]}\n';
    }

    var expectedOutput = '';
    while (++i < lines.length && !lines[i].startsWith('>>>')) {
      expectedOutput += '${lines[i]}\n';
    }

    if (line != startLine) continue;

    var isCompilationUnit = p.extension(path) == '.unit';

    var inputCode =
        _extractSelection(input, isCompilationUnit: isCompilationUnit);

    var expected =
        _extractSelection(expectedOutput, isCompilationUnit: isCompilationUnit);

    var formatter = DartFormatter(pageWidth: pageWidth, indent: leadingIndent);

    var actual = formatter.formatSource(inputCode);

    // The test files always put a newline at the end of the expectation.
    // Statements from the formatter (correctly) don't have that, so add
    // one to line up with the expected result.
    var actualText = actual.text;
    if (!isCompilationUnit) actualText += '\n';

    print('$path $description');
    drawRuler('before', pageWidth);
    print(input);
    if (actualText == expected.text) {
      drawRuler('result', pageWidth);
      print(actualText);
    } else {
      print('FAIL');
      drawRuler('expected', pageWidth);
      print(expected.text);
      drawRuler('actual', pageWidth);
      print(actualText);
    }
  }
}

/// Given a source string that contains ‹ and › to indicate a selection, returns
/// a [SourceCode] with the text (with the selection markers removed) and the
/// correct selection range.
SourceCode _extractSelection(String source, {bool isCompilationUnit = false}) {
  var start = source.indexOf('‹');
  source = source.replaceAll('‹', '');

  var end = source.indexOf('›');
  source = source.replaceAll('›', '');

  return SourceCode(source,
      isCompilationUnit: isCompilationUnit,
      selectionStart: start == -1 ? null : start,
      selectionLength: end == -1 ? null : end - start);
}

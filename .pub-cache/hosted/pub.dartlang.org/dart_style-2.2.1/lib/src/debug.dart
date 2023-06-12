// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Internal debugging utilities.
import 'dart:math' as math;

import 'chunk.dart';
import 'line_splitting/rule_set.dart';
import 'rule/rule.dart';

/// Set this to `true` to turn on diagnostic output while building chunks.
bool traceChunkBuilder = false;

/// Set this to `true` to turn on diagnostic output while writing lines.
bool traceLineWriter = false;

/// Set this to `true` to turn on diagnostic output while line splitting.
bool traceSplitter = false;

bool useAnsiColors = false;

const unicodeSection = '\u00a7';
const unicodeMidDot = '\u00b7';

/// The whitespace prefixing each line of output.
String _indent = '';

void indent() {
  _indent = '  $_indent';
}

void unindent() {
  _indent = _indent.substring(2);
}

/// Constants for ANSI color escape codes.
final _gray = _color('\u001b[1;30m');
final _green = _color('\u001b[32m');
final _none = _color('\u001b[0m');
final _bold = _color('\u001b[1m');

/// Prints [message] to stdout with each line correctly indented.
void log([message]) {
  if (message == null) {
    print('');
    return;
  }

  print(_indent + message.toString().replaceAll('\n', '\n$_indent'));
}

/// Wraps [message] in gray ANSI escape codes if enabled.
String gray(message) => '$_gray$message$_none';

/// Wraps [message] in green ANSI escape codes if enabled.
String green(message) => '$_green$message$_none';

/// Wraps [message] in bold ANSI escape codes if enabled.
String bold(message) => '$_bold$message$_none';

/// Prints [chunks] to stdout, one chunk per line, with detailed information
/// about each chunk.
void dumpChunks(int start, List<Chunk> chunks) {
  if (chunks.skip(start).isEmpty) return;

  // Show the spans as vertical bands over their range (unless there are too
  // many).
  var spanSet = <Span>{};
  void addSpans(List<Chunk> chunks) {
    for (var chunk in chunks) {
      spanSet.addAll(chunk.spans);

      if (chunk.isBlock) addSpans(chunk.block.chunks);
    }
  }

  addSpans(chunks);

  var spans = spanSet.toList();
  var rules =
      chunks.map((chunk) => chunk.rule).where((rule) => rule != null).toSet();

  var rows = <List<String>>[];

  void addChunk(List<Chunk> chunks, String prefix, int index) {
    var row = <String>[];
    row.add('$prefix$index:');

    var chunk = chunks[index];
    if (chunk.text.length > 70) {
      row.add(chunk.text.substring(0, 70));
    } else {
      row.add(chunk.text);
    }

    if (spans.length <= 20) {
      var spanBars = '';
      for (var span in spans) {
        if (chunk.spans.contains(span)) {
          if (index == 0 || !chunks[index - 1].spans.contains(span)) {
            if (span.cost == 1) {
              spanBars += '╖';
            } else {
              spanBars += span.cost.toString();
            }
          } else {
            spanBars += '║';
          }
        } else {
          if (index > 0 && chunks[index - 1].spans.contains(span)) {
            spanBars += '╜';
          } else {
            spanBars += ' ';
          }
        }
      }
      row.add(spanBars);
    }

    void writeIf(predicate, String Function() callback) {
      if (predicate) {
        row.add(callback());
      } else {
        row.add('');
      }
    }

    var rule = chunk.rule;
    if (rule == null) {
      row.add('');
      row.add('(no rule)');
      row.add('');
    } else {
      writeIf(rule.cost != 0, () => '\$${rule.cost}');

      var ruleString = rule.toString();
      if (rule.isHardened) ruleString += '!';
      row.add(ruleString);

      var constrainedRules = rule.constrainedRules.toSet().intersection(rules);
      writeIf(constrainedRules.isNotEmpty,
          () => "-> ${constrainedRules.join(" ")}");
    }

    writeIf(chunk.indent != null && chunk.indent != 0,
        () => 'indent ${chunk.indent}');

    writeIf(chunk.nesting?.indent != 0, () => 'nest ${chunk.nesting}');

    writeIf(chunk.flushLeft, () => 'flush');

    writeIf(chunk.canDivide, () => 'divide');

    rows.add(row);

    if (chunk.isBlock) {
      for (var j = 0; j < chunk.block.chunks.length; j++) {
        addChunk(chunk.block.chunks, '$prefix$index.', j);
      }
    }
  }

  for (var i = start; i < chunks.length; i++) {
    addChunk(chunks, '', i);
  }

  var rowWidths = List.filled(rows.first.length, 0);
  for (var row in rows) {
    for (var i = 0; i < row.length; i++) {
      rowWidths[i] = math.max(rowWidths[i], row[i].length);
    }
  }

  var buffer = StringBuffer();
  for (var row in rows) {
    for (var i = 0; i < row.length; i++) {
      var cell = row[i].padRight(rowWidths[i]);

      if (i != 1) cell = gray(cell);

      buffer.write(cell);
      buffer.write('  ');
    }

    buffer.writeln();
  }

  print(buffer.toString());
}

/// Shows all of the constraints between the rules used by [chunks].
void dumpConstraints(List<Chunk> chunks) {
  var rules = chunks.map((chunk) => chunk.rule).whereType<Rule>().toSet();

  for (var rule in rules) {
    var constrainedValues = [];
    for (var value = 0; value < rule.numValues; value++) {
      var constraints = [];
      for (var other in rules) {
        if (rule == other) continue;

        var constraint = rule.constrain(value, other);
        if (constraint != null) {
          constraints.add('$other->$constraint');
        }
      }

      if (constraints.isNotEmpty) {
        constrainedValues.add("$value:(${constraints.join(' ')})");
      }
    }

    log("$rule ${constrainedValues.join(' ')}");
  }
}

/// Convert the line to a [String] representation.
///
/// It will determine how best to split it into multiple lines of output and
/// return a single string that may contain one or more newline characters.
void dumpLines(List<Chunk> chunks, int firstLineIndent, SplitSet splits) {
  var buffer = StringBuffer();

  void writeIndent(int indent) => buffer.write(gray('| ' * (indent ~/ 2)));

  void writeChunksUnsplit(List<Chunk> chunks) {
    for (var chunk in chunks) {
      buffer.write(chunk.text);
      if (chunk.spaceWhenUnsplit) buffer.write(' ');

      // Recurse into the block.
      if (chunk.isBlock) writeChunksUnsplit(chunk.block.chunks);
    }
  }

  writeIndent(firstLineIndent);

  for (var i = 0; i < chunks.length - 1; i++) {
    var chunk = chunks[i];
    buffer.write(chunk.text);

    if (splits.shouldSplitAt(i)) {
      for (var j = 0; j < (chunk.isDouble ? 2 : 1); j++) {
        buffer.writeln();
        writeIndent(splits.getColumn(i));
      }
    } else {
      if (chunk.isBlock) writeChunksUnsplit(chunk.block.chunks);

      if (chunk.spaceWhenUnsplit) buffer.write(' ');
    }
  }

  buffer.write(chunks.last.text);
  log(buffer);
}

String _color(String ansiEscape) => useAnsiColors ? ansiEscape : '';

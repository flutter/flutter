// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'charcode.dart';
import 'location.dart';
import 'span.dart';
import 'span_with_context.dart';

/// Returns the minimum of [obj1] and [obj2] according to
/// [Comparable.compareTo].
T min<T extends Comparable>(T obj1, T obj2) =>
    obj1.compareTo(obj2) > 0 ? obj2 : obj1;

/// Returns the maximum of [obj1] and [obj2] according to
/// [Comparable.compareTo].
T max<T extends Comparable>(T obj1, T obj2) =>
    obj1.compareTo(obj2) > 0 ? obj1 : obj2;

/// Returns whether all elements of [iter] are the same value, according to
/// `==`.
bool isAllTheSame(Iterable<Object?> iter) {
  if (iter.isEmpty) return true;
  final firstValue = iter.first;
  for (var value in iter.skip(1)) {
    if (value != firstValue) {
      return false;
    }
  }
  return true;
}

/// Returns whether [span] covers multiple lines.
bool isMultiline(SourceSpan span) => span.start.line != span.end.line;

/// Sets the first `null` element of [list] to [element].
void replaceFirstNull<E>(List<E?> list, E element) {
  final index = list.indexOf(null);
  if (index < 0) throw ArgumentError('$list contains no null elements.');
  list[index] = element;
}

/// Sets the element of [list] that currently contains [element] to `null`.
void replaceWithNull<E>(List<E?> list, E element) {
  final index = list.indexOf(element);
  if (index < 0) {
    throw ArgumentError('$list contains no elements matching $element.');
  }

  list[index] = null;
}

/// Returns the number of instances of [codeUnit] in [string].
int countCodeUnits(String string, int codeUnit) {
  var count = 0;
  for (var codeUnitToCheck in string.codeUnits) {
    if (codeUnitToCheck == codeUnit) count++;
  }
  return count;
}

/// Finds a line in [context] containing [text] at the specified [column].
///
/// Returns the index in [context] where that line begins, or null if none
/// exists.
int? findLineStart(String context, String text, int column) {
  // If the text is empty, we just want to find the first line that has at least
  // [column] characters.
  if (text.isEmpty) {
    var beginningOfLine = 0;
    while (true) {
      final index = context.indexOf('\n', beginningOfLine);
      if (index == -1) {
        return context.length - beginningOfLine >= column
            ? beginningOfLine
            : null;
      }

      if (index - beginningOfLine >= column) return beginningOfLine;
      beginningOfLine = index + 1;
    }
  }

  var index = context.indexOf(text);
  while (index != -1) {
    // Start looking before [index] in case [text] starts with a newline.
    final lineStart = index == 0 ? 0 : context.lastIndexOf('\n', index - 1) + 1;
    final textColumn = index - lineStart;
    if (column == textColumn) return lineStart;
    index = context.indexOf(text, index + 1);
  }
  // ignore: avoid_returning_null
  return null;
}

/// Returns a two-element list containing the start and end locations of the
/// span from [start] code units (inclusive) to [end] code units (exclusive)
/// after the beginning of [span].
///
/// This is factored out so it can be shared between
/// [SourceSpanExtension.subspan] and [SourceSpanWithContextExtension.subspan].
List<SourceLocation> subspanLocations(SourceSpan span, int start, [int? end]) {
  final text = span.text;
  final startLocation = span.start;
  var line = startLocation.line;
  var column = startLocation.column;

  // Adjust [line] and [column] as necessary if the character at [i] in [text]
  // is a newline.
  void consumeCodePoint(int i) {
    final codeUnit = text.codeUnitAt(i);
    if (codeUnit == $lf ||
        // A carriage return counts as a newline, but only if it's not
        // followed by a line feed.
        (codeUnit == $cr &&
            (i + 1 == text.length || text.codeUnitAt(i + 1) != $lf))) {
      line += 1;
      column = 0;
    } else {
      column += 1;
    }
  }

  for (var i = 0; i < start; i++) {
    consumeCodePoint(i);
  }

  final newStartLocation = SourceLocation(startLocation.offset + start,
      sourceUrl: span.sourceUrl, line: line, column: column);

  SourceLocation newEndLocation;
  if (end == null || end == span.length) {
    newEndLocation = span.end;
  } else if (end == start) {
    newEndLocation = newStartLocation;
  } else {
    for (var i = start; i < end; i++) {
      consumeCodePoint(i);
    }
    newEndLocation = SourceLocation(startLocation.offset + end,
        sourceUrl: span.sourceUrl, line: line, column: column);
  }

  return [newStartLocation, newEndLocation];
}

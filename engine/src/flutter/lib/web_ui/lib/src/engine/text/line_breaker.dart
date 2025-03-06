// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import '../dom.dart';

const Set<int> _kNewlines = <int>{
  0x000A, // LF
  0x000B, // BK
  0x000C, // BK
  0x000D, // CR
  0x0085, // NL
  0x2028, // BK
  0x2029, // BK
};
const Set<int> _kSpaces = <int>{
  0x0020, // SP
  0x200B, // ZW
};

/// Various types of line breaks as defined by the Unicode spec.
enum LineBreakType {
  /// Indicates that a line break is possible but not mandatory.
  opportunity,

  /// Indicates that a line break isn't possible.
  prohibited,

  /// Indicates that this is a hard line break that can't be skipped.
  mandatory,

  /// Indicates the end of the text (which is also considered a line break in
  /// the Unicode spec). This is the same as [mandatory] but it's needed in our
  /// implementation to distinguish between the universal [endOfText] and the
  /// line break caused by "\n" at the end of the text.
  endOfText,
}

List<LineBreakFragment> breakLinesUsingV8BreakIterator(
  String text,
  JSString jsText,
  DomV8BreakIterator iterator,
) {
  final List<LineBreakFragment> breaks = <LineBreakFragment>[];
  int fragmentStart = 0;

  iterator.adoptText(jsText);
  iterator.first();
  while (iterator.next() != -1) {
    final int fragmentEnd = iterator.current().toInt();
    int trailingNewlines = 0;
    int trailingSpaces = 0;

    // Calculate trailing newlines and spaces.
    for (int i = fragmentStart; i < fragmentEnd; i++) {
      final int codeUnit = text.codeUnitAt(i);
      if (_kNewlines.contains(codeUnit)) {
        trailingNewlines++;
        trailingSpaces++;
      } else if (_kSpaces.contains(codeUnit)) {
        trailingSpaces++;
      } else {
        // Always break after a sequence of spaces.
        if (trailingSpaces > 0) {
          breaks.add(
            LineBreakFragment(
              fragmentStart,
              i,
              LineBreakType.opportunity,
              trailingNewlines: trailingNewlines,
              trailingSpaces: trailingSpaces,
            ),
          );
          fragmentStart = i;
          trailingNewlines = 0;
          trailingSpaces = 0;
        }
      }
    }

    final LineBreakType type;
    if (trailingNewlines > 0) {
      type = LineBreakType.mandatory;
    } else if (fragmentEnd == text.length) {
      type = LineBreakType.endOfText;
    } else {
      type = LineBreakType.opportunity;
    }

    breaks.add(
      LineBreakFragment(
        fragmentStart,
        fragmentEnd,
        type,
        trailingNewlines: trailingNewlines,
        trailingSpaces: trailingSpaces,
      ),
    );
    fragmentStart = fragmentEnd;
  }

  if (breaks.isEmpty || breaks.last.type == LineBreakType.mandatory) {
    breaks.add(
      LineBreakFragment(
        text.length,
        text.length,
        LineBreakType.endOfText,
        trailingNewlines: 0,
        trailingSpaces: 0,
      ),
    );
  }

  return breaks;
}

class LineBreakFragment {
  const LineBreakFragment(
    this.start,
    this.end,
    this.type, {
    required this.trailingNewlines,
    required this.trailingSpaces,
  });

  final int start;
  final int end;
  final LineBreakType type;
  final int trailingNewlines;
  final int trailingSpaces;

  @override
  int get hashCode => Object.hash(start, end, type, trailingNewlines, trailingSpaces);

  @override
  bool operator ==(Object other) {
    return other is LineBreakFragment &&
        other.start == start &&
        other.end == end &&
        other.type == type &&
        other.trailingNewlines == trailingNewlines &&
        other.trailingSpaces == trailingSpaces;
  }

  @override
  String toString() {
    return 'LineBreakFragment($start, $end, $type)';
  }
}

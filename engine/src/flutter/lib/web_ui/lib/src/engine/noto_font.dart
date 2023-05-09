// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'text/unicode_range.dart';

class NotoFont {
  NotoFont(this.name, this.url, this._packedRanges);

  final String name;
  final String url;
  final String _packedRanges;
  // A sorted list of Unicode ranges.
  late final List<CodePointRange> _ranges = _unpackFontRange(_packedRanges);

  List<CodePointRange> computeUnicodeRanges() => _ranges;

  // Returns `true` if this font has a glyph for the given [codeunit].
  bool contains(int codeUnit) {
    // Binary search through the unicode ranges to see if there
    // is a range that contains the codeunit.
    int min = 0;
    int max = _ranges.length - 1;
    while (min <= max) {
      final int mid = (min + max) ~/ 2;
      final CodePointRange range = _ranges[mid];
      if (range.start > codeUnit) {
        max = mid - 1;
      } else {
        // range.start <= codeUnit
        if (range.end >= codeUnit) {
          return true;
        }
        min = mid + 1;
      }
    }
    return false;
  }
}

class CodePointRange {
  const CodePointRange(this.start, this.end);

  final int start;
  final int end;

  bool contains(int codeUnit) {
    return start <= codeUnit && codeUnit <= end;
  }

  @override
  bool operator ==(Object other) {
    if (other is! CodePointRange) {
      return false;
    }
    final CodePointRange range = other;
    return range.start == start && range.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end]';
}

final int _kCharPipe = '|'.codeUnitAt(0);
final int _kCharSemicolon = ';'.codeUnitAt(0);

class MutableInt {
  MutableInt(this.value);

  int value;
}

List<CodePointRange> _unpackFontRange(String packedRange) {
    final MutableInt i = MutableInt(0);
    final List<CodePointRange> ranges = <CodePointRange>[];

    while (i.value < packedRange.length) {
      final int rangeStart = _consumeInt36(packedRange, i, until: _kCharPipe);
      final int rangeLength = _consumeInt36(packedRange, i, until: _kCharSemicolon);
      final int rangeEnd = rangeStart + rangeLength;
      ranges.add(CodePointRange(rangeStart, rangeEnd));
    }
    return ranges;
}

int _consumeInt36(String packedData, MutableInt index, {required int until}) {
  // The implementation is similar to:
  //
  // ```dart
  // return int.tryParse(packedData.substring(index, indexOfUntil), radix: 36);
  // ```
  //
  // But using substring is slow when called too many times. This custom
  // implementation parses the integer without extra memory.

  int result = 0;
  while (true) {
    final int charCode = packedData.codeUnitAt(index.value);
    index.value++;
    if (charCode == until) {
      return result;
    }
    result = result * 36 + getIntFromCharCode(charCode);
  }
}

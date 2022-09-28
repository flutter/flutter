// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class NotoFont {
  const NotoFont(this.name, this.url, this._rangeStarts, this._rangeEnds);

  factory NotoFont.fromFlatRanges(String name, String url, List<int> flatRanges) {
    final List<int> starts = <int>[];
    final List<int> ends = <int>[];
    for (int i = 0; i < flatRanges.length; i += 2) {
      starts.add(flatRanges[i]);
      ends.add(flatRanges[i+1]);
    }
    return NotoFont(name, url, starts, ends);
  }

  final String name;
  final String url;
  // A sorted list of Unicode range start points.
  final List<int> _rangeStarts;

  // A sorted list of Unicode range end points.
  final List<int> _rangeEnds;

  List<CodeunitRange> computeUnicodeRanges() {
    final List<CodeunitRange> result = <CodeunitRange>[];
    for (int i = 0; i < _rangeStarts.length; i++) {
      result.add(CodeunitRange(_rangeStarts[i], _rangeEnds[i]));
    }
    return result;
  }

  // Returns `true` if this font has a glyph for the given [codeunit].
  bool contains(int codeUnit) {
    // Binary search through the starts and ends to see if there
    // is a range that contains the codeunit.
    int min = 0;
    int max = _rangeStarts.length - 1;
    while (min <= max) {
      final int mid = (min + max) ~/ 2;
      if (_rangeStarts[mid] > codeUnit) {
        max = mid - 1;
      } else {
        // _rangeStarts[mid] <= codeUnit
        if (_rangeEnds[mid] >= codeUnit) {
          return true;
        }
        min = mid + 1;
      }
    }
    return false;
  }
}

class CodeunitRange {
  const CodeunitRange(this.start, this.end);

  final int start;
  final int end;


  bool contains(int codeUnit) {
    return start <= codeUnit && codeUnit <= end;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! CodeunitRange) {
      return false;
    }
    final CodeunitRange range = other;
    return range.start == start && range.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end]';
}

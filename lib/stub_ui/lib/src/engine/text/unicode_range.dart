// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

enum _ComparisonResult {
  inside,
  higher,
  lower,
}

/// Each instance of [UnicodeRange] represents a range of unicode characters
/// that are assigned a [CharProperty]. For example, the following snippet:
///
/// ```dart
/// UnicodeRange(0x0041, 0x005A, CharProperty.ALetter);
/// ```
///
/// is saying that all characters between 0x0041 ("A") and 0x005A ("Z") are
/// assigned the property [CharProperty.ALetter].
///
/// Note that the Unicode spec uses inclusive ranges and we are doing the
/// same here.
class UnicodeRange<P> {
  const UnicodeRange(this.start, this.end, this.property);

  final int start;

  final int end;

  final P property;

  /// Compare a [value] to this range.
  ///
  /// The return value is either:
  /// - lower: The value is lower than the range.
  /// - higher: The value is higher than the range
  /// - inside: The value is within the range.
  _ComparisonResult compare(int value) {
    if (value < start) return _ComparisonResult.lower;
    if (value > end) return _ComparisonResult.higher;
    return _ComparisonResult.inside;
  }
}

/// Given a list of [UnicodeRange]s, this class performs efficient lookup
/// to find which range a value falls into.
///
/// The lookup algorithm expects the ranges to have the following constraints:
/// - Be sorted.
/// - No overlap between the ranges.
/// - Gaps between ranges are ok.
///
/// This is used in the context of unicode to find out what property a letter
/// has. The properties are then used to decide word boundaries, line break
/// opportunities, etc.
class UnicodePropertyLookup<P> {
  const UnicodePropertyLookup(this.ranges);

  final List<UnicodeRange<P>> ranges;

  P find(int value) {
    final int index = _binarySearch(ranges, value, (a, b) {
      final UnicodeRange<P> range = a;
      switch (range.compare(b)) {
        case _ComparisonResult.higher:
          return -1;
        case _ComparisonResult.lower:
          return 1;
        case _ComparisonResult.inside:
          return 0;
      }
    });
    return index == -1 ? null : ranges[index].property;
  }

  static int _binarySearch<T>(
      List<T> sortedList, T value, int compare(T a, T b)) {
    int min = 0;
    int max = sortedList.length;
    while (min < max) {
      int mid = min + ((max - min) >> 1);
      var element = sortedList[mid];
      int comp = compare(element, value);
      if (comp == 0) return mid;
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }
}

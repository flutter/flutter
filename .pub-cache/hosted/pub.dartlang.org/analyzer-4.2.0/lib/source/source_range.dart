// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:math" as math;

/// A source range defines a range of characters within source code.
class SourceRange {
  /// An empty source range (a range with offset `0` and length `0`).
  static const SourceRange EMPTY = SourceRange(0, 0);

  /// The 0-based index of the first character of the source range.
  final int offset;

  /// The number of characters in the source range.
  final int length;

  /// Initialize a newly created source range using the given [offset] and
  /// [length].
  const SourceRange(this.offset, this.length);

  /// Return the 0-based index of the character immediately after this source
  /// range.
  int get end => offset + length;

  @override
  int get hashCode => 31 * offset + length;

  @override
  bool operator ==(Object other) {
    return other is SourceRange &&
        other.offset == offset &&
        other.length == length;
  }

  /// Return `true` if [x] is in the interval `[offset, offset + length]`.
  bool contains(int x) => offset <= x && x <= offset + length;

  /// Return `true` if [x] is in the interval `(offset, offset + length)`.
  bool containsExclusive(int x) => offset < x && x < offset + length;

  /// Return `true` if the [otherRange] covers this source range.
  bool coveredBy(SourceRange otherRange) => otherRange.covers(this);

  /// Return `true` if this source range covers the [otherRange].
  bool covers(SourceRange otherRange) =>
      offset <= otherRange.offset && otherRange.end <= end;

  /// Return `true` if this source range ends inside the [otherRange].
  bool endsIn(SourceRange otherRange) {
    int thisEnd = end;
    return otherRange.contains(thisEnd);
  }

  /// Return a source range covering [delta] characters before the start of this
  /// source range and [delta] characters after the end of this source range.
  SourceRange getExpanded(int delta) =>
      SourceRange(offset - delta, delta + length + delta);

  /// Return a source range with the same offset as this source range but whose
  /// length is [delta] characters longer than this source range.
  SourceRange getMoveEnd(int delta) => SourceRange(offset, length + delta);

  /// Return a source range with the same length as this source range but whose
  /// offset is [delta] characters after the offset of this source range.
  SourceRange getTranslated(int delta) => SourceRange(offset + delta, length);

  /// Return the minimal source range that covers both this and the
  /// [otherRange].
  SourceRange getUnion(SourceRange otherRange) {
    int newOffset = math.min(offset, otherRange.offset);
    int newEnd =
        math.max(offset + length, otherRange.offset + otherRange.length);
    return SourceRange(newOffset, newEnd - newOffset);
  }

  /// Return `true` if this source range intersects the [otherRange].
  bool intersects(SourceRange? otherRange) {
    if (otherRange == null) {
      return false;
    }
    if (end <= otherRange.offset) {
      return false;
    }
    if (offset >= otherRange.end) {
      return false;
    }
    return true;
  }

  /// Return `true` if this source range starts in the [otherRange].
  bool startsIn(SourceRange otherRange) => otherRange.contains(offset);

  @override
  String toString() => '[offset=$offset, length=$length]';
}

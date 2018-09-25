// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues, TextAffinity, TextPosition;

import 'package:flutter/foundation.dart';

export 'dart:ui' show TextAffinity, TextPosition;

/// A range of characters in a string of text.
@immutable
class TextRange {
  /// Creates a text range.
  ///
  /// The [start] and [end] arguments must not be null. Both the [start] and
  /// [end] must either be greater than or equal to zero or both exactly -1.
  ///
  /// Instead of creating an empty text range, consider using the [empty]
  /// constant.
  const TextRange({
    @required this.start,
    @required this.end
  }) : assert(start != null && start >= -1),
       assert(end != null && end >= -1);

  /// A text range that starts and ends at offset.
  ///
  /// The [offset] argument must be non-null and greater than or equal to -1.
  const TextRange.collapsed(int offset)
    : assert(offset != null && offset >= -1),
      start = offset,
      end = offset;

  /// A text range that contains nothing and is not in the text.
  static const TextRange empty = TextRange(start: -1, end: -1);

  /// The index of the first character in the range.
  ///
  /// If [start] and [end] are both -1, the text range is empty.
  final int start;

  /// The next index after the characters in this range.
  ///
  /// If [start] and [end] are both -1, the text range is empty.
  final int end;

  /// Whether this range represents a valid position in the text.
  bool get isValid => start >= 0 && end >= 0;

  /// Whether this range is empty (but still potentially placed inside the text).
  bool get isCollapsed => start == end;

  /// Whether the start of this range precedes the end.
  bool get isNormalized => end >= start;

  /// The text before this range.
  String textBefore(String text) {
    assert(isNormalized);
    return text.substring(0, start);
  }

  /// The text after this range.
  String textAfter(String text) {
    assert(isNormalized);
    return text.substring(end);
  }

  /// The text inside this range.
  String textInside(String text) {
    assert(isNormalized);
    return text.substring(start, end);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextRange)
      return false;
    final TextRange typedOther = other;
    return typedOther.start == start
        && typedOther.end == end;
  }

  @override
  int get hashCode => hashValues(
    start.hashCode,
    end.hashCode
  );

  @override
  String toString() => 'TextRange(start: $start, end: $end)';
}

/// A range of text that represents a selection.
@immutable
class TextSelection extends TextRange {
  /// Creates a text selection.
  ///
  /// The [baseOffset] and [extentOffset] arguments must not be null.
  const TextSelection({
    @required this.baseOffset,
    @required this.extentOffset,
    this.affinity = TextAffinity.downstream,
    this.isDirectional = false
  }) : super(
         start: baseOffset < extentOffset ? baseOffset : extentOffset,
         end: baseOffset < extentOffset ? extentOffset : baseOffset
       );

  /// Creates a collapsed selection at the given offset.
  ///
  /// A collapsed selection starts and ends at the same offset, which means it
  /// contains zero characters but instead serves as an insertion point in the
  /// text.
  ///
  /// The [offset] argument must not be null.
  const TextSelection.collapsed({
    @required int offset,
    this.affinity = TextAffinity.downstream
  }) : baseOffset = offset, extentOffset = offset, isDirectional = false, super.collapsed(offset);

  /// Creates a collapsed selection at the given text position.
  ///
  /// A collapsed selection starts and ends at the same offset, which means it
  /// contains zero characters but instead serves as an insertion point in the
  /// text.
  TextSelection.fromPosition(TextPosition position)
    : baseOffset = position.offset,
      extentOffset = position.offset,
      affinity = position.affinity,
      isDirectional = false,
      super.collapsed(position.offset);

  /// The offset at which the selection originates.
  ///
  /// Might be larger than, smaller than, or equal to extent.
  final int baseOffset;

  /// The offset at which the selection terminates.
  ///
  /// When the user uses the arrow keys to adjust the selection, this is the
  /// value that changes. Similarly, if the current theme paints a caret on one
  /// side of the selection, this is the location at which to paint the caret.
  ///
  /// Might be larger than, smaller than, or equal to base.
  final int extentOffset;

  /// If the text range is collapsed and has more than one visual location
  /// (e.g., occurs at a line break), which of the two locations to use when
  /// painting the caret.
  final TextAffinity affinity;

  /// Whether this selection has disambiguated its base and extent.
  ///
  /// On some platforms, the base and extent are not disambiguated until the
  /// first time the user adjusts the selection. At that point, either the start
  /// or the end of the selection becomes the base and the other one becomes the
  /// extent and is adjusted.
  final bool isDirectional;

  /// The position at which the selection originates.
  ///
  /// Might be larger than, smaller than, or equal to extent.
  TextPosition get base => TextPosition(offset: baseOffset, affinity: affinity);

  /// The position at which the selection terminates.
  ///
  /// When the user uses the arrow keys to adjust the selection, this is the
  /// value that changes. Similarly, if the current theme paints a caret on one
  /// side of the selection, this is the location at which to paint the caret.
  ///
  /// Might be larger than, smaller than, or equal to base.
  TextPosition get extent => TextPosition(offset: extentOffset, affinity: affinity);

  @override
  String toString() {
    return '$runtimeType(baseOffset: $baseOffset, extentOffset: $extentOffset, affinity: $affinity, isDirectional: $isDirectional)';
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! TextSelection)
      return false;
    final TextSelection typedOther = other;
    return typedOther.baseOffset == baseOffset
        && typedOther.extentOffset == extentOffset
        && typedOther.affinity == affinity
        && typedOther.isDirectional == isDirectional;
  }

  @override
  int get hashCode => hashValues(
    baseOffset.hashCode,
    extentOffset.hashCode,
    affinity.hashCode,
    isDirectional.hashCode
  );

  /// Creates a new [TextSelection] based on the current selection, with the
  /// provided parameters overridden.
  TextSelection copyWith({
    int baseOffset,
    int extentOffset,
    TextAffinity affinity,
    bool isDirectional,
  }) {
    return TextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      affinity: affinity ?? this.affinity,
      isDirectional: isDirectional ?? this.isDirectional,
    );
  }
}

// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Whether a [TextPosition] is visually upstream or downstream of its offset.
///
/// For example, when a text position exists at a line break, a single offset has
/// two visual positions, one prior to the line break (at the end of the first
/// line) and one after the line break (at the start of the second line). A text
/// affinity disambiguates between those cases. (Something similar happens with
/// between runs of bidirectional text.)
enum TextAffinity {
  /// The position has affinity for the upstream side of the text position.
  ///
  /// For example, if the offset of the text position is a line break, the
  /// position represents the end of the first line.
  upstream,

  /// The position has affinity for the downstream side of the text position.
  ///
  /// For example, if the offset of the text position is a line break, the
  /// position represents the start of the second line.
  downstream
}

/// A visual position in a string of text.
class TextPosition {
  const TextPosition({ this.offset, this.affinity: TextAffinity.downstream });

  /// The index of the character just prior to the position.
  final int offset;

  /// If the offset has more than one visual location (e.g., occurs at a line
  /// break), which of the two locations is represented by this position.
  final TextAffinity affinity;
}

/// A range of characters in a string of text.
class TextRange {
  const TextRange({ this.start, this.end });

  /// A text range that starts and ends at offset.
  const TextRange.collapsed(int offset)
    : start = offset,
      end = offset;

  /// A text range that contains nothing and is not in the text.
  static const TextRange empty = const TextRange(start: -1, end: -1);

  /// The index of the first character in the range.
  final int start;

  /// The next index after the characters in this range.
  final int end;

  /// Whether this range represents a valid position in the text.
  bool get isValid => start >= 0 && end >= 0;

  /// Whether this range is empty (but still potentially placed inside the text).
  bool get isCollapsed => start == end;

  /// Whether the start of this range preceeds the end.
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
}

/// A range of text that represents a selection.
class TextSelection extends TextRange {
  const TextSelection({
    int baseOffset,
    int extentOffset,
    this.affinity: TextAffinity.downstream,
    this.isDirectional: false
  }) : baseOffset = baseOffset,
       extentOffset = extentOffset,
       super(
         start: baseOffset < extentOffset ? baseOffset : extentOffset,
         end: baseOffset < extentOffset ? extentOffset : baseOffset
       );

  const TextSelection.collapsed({
    int offset,
    this.affinity: TextAffinity.downstream,
    this.isDirectional: false
  }) : baseOffset = offset, extentOffset = offset, super.collapsed(offset);

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

  /// If the the text range is collpased and has more than one visual location
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
  TextPosition get base => new TextPosition(offset: baseOffset, affinity: affinity);

  /// The position at which the selection terminates.
  ///
  /// When the user uses the arrow keys to adjust the selection, this is the
  /// value that changes. Similarly, if the current theme paints a caret on one
  /// side of the selection, this is the location at which to paint the caret.
  ///
  /// Might be larger than, smaller than, or equal to base.
  TextPosition get extent => new TextPosition(offset: extentOffset, affinity: affinity);
}

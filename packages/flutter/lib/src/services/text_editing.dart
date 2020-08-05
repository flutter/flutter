// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui' show hashValues, TextAffinity, TextPosition, TextRange;

import 'package:flutter/foundation.dart';

export 'dart:ui' show TextAffinity, TextPosition, TextRange;

/// A range of text that represents a selection.
@immutable
class TextSelection extends TextRange {
  /// Creates a text selection.
  ///
  /// The [baseOffset] and [extentOffset] arguments must not be null.
  const TextSelection({
    required this.baseOffset,
    required this.extentOffset,
    this.affinity = TextAffinity.downstream,
    this.isDirectional = false,
  }) : super(
         start: baseOffset < extentOffset ? baseOffset : extentOffset,
         end: baseOffset < extentOffset ? extentOffset : baseOffset,
       );

  /// Creates a collapsed selection at the given offset.
  ///
  /// A collapsed selection starts and ends at the same offset, which means it
  /// contains zero characters but instead serves as an insertion point in the
  /// text.
  ///
  /// The [offset] argument must not be null.
  const TextSelection.collapsed({
    required int offset,
    this.affinity = TextAffinity.downstream,
  }) : baseOffset = offset,
       extentOffset = offset,
       isDirectional = false,
       super.collapsed(offset);

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
    return '${objectRuntimeType(this, 'TextSelection')}(baseOffset: $baseOffset, extentOffset: $extentOffset, affinity: $affinity, isDirectional: $isDirectional)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    return other is TextSelection
        && other.baseOffset == baseOffset
        && other.extentOffset == extentOffset
        && other.affinity == affinity
        && other.isDirectional == isDirectional;
  }

  @override
  int get hashCode => hashValues(
    baseOffset.hashCode,
    extentOffset.hashCode,
    affinity.hashCode,
    isDirectional.hashCode,
  );

  /// Creates a new [TextSelection] based on the current selection, with the
  /// provided parameters overridden.
  TextSelection copyWith({
    int? baseOffset,
    int? extentOffset,
    TextAffinity? affinity,
    bool? isDirectional,
  }) {
    return TextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      affinity: affinity ?? this.affinity,
      isDirectional: isDirectional ?? this.isDirectional,
    );
  }
}

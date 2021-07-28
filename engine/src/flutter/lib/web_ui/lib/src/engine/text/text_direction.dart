// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import 'line_breaker.dart';
import 'unicode_range.dart';

// This data was taken from the source code of the Closure library:
//
// - https://github.com/google/closure-library/blob/9d24a6c1809a671c2e54c328897ebeae15a6d172/closure/goog/i18n/bidi.js#L203-L234
final UnicodePropertyLookup<ui.TextDirection?> _textDirectionLookup = UnicodePropertyLookup<ui.TextDirection?>(
  <UnicodeRange<ui.TextDirection>>[
    // LTR
    const UnicodeRange<ui.TextDirection>(kChar_A, kChar_Z, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(kChar_a, kChar_z, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(0x00C0, 0x00D6, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(0x00D8, 0x00F6, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(0x00F8, 0x02B8, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(0x0300, 0x0590, ui.TextDirection.ltr),
    // RTL
    const UnicodeRange<ui.TextDirection>(0x0591, 0x06EF, ui.TextDirection.rtl),
    const UnicodeRange<ui.TextDirection>(0x06FA, 0x08FF, ui.TextDirection.rtl),
    // LTR
    const UnicodeRange<ui.TextDirection>(0x0900, 0x1FFF, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(0x200E, 0x200E, ui.TextDirection.ltr),
    // RTL
    const UnicodeRange<ui.TextDirection>(0x200F, 0x200F, ui.TextDirection.rtl),
    // LTR
    const UnicodeRange<ui.TextDirection>(0x2C00, 0xD801, ui.TextDirection.ltr),
    // RTL
    const UnicodeRange<ui.TextDirection>(0xD802, 0xD803, ui.TextDirection.rtl),
    // LTR
    const UnicodeRange<ui.TextDirection>(0xD804, 0xD839, ui.TextDirection.ltr),
    // RTL
    const UnicodeRange<ui.TextDirection>(0xD83A, 0xD83B, ui.TextDirection.rtl),
    // LTR
    const UnicodeRange<ui.TextDirection>(0xD83C, 0xDBFF, ui.TextDirection.ltr),
    const UnicodeRange<ui.TextDirection>(0xF900, 0xFB1C, ui.TextDirection.ltr),
    // RTL
    const UnicodeRange<ui.TextDirection>(0xFB1D, 0xFDFF, ui.TextDirection.rtl),
    // LTR
    const UnicodeRange<ui.TextDirection>(0xFE00, 0xFE6F, ui.TextDirection.ltr),
    // RTL
    const UnicodeRange<ui.TextDirection>(0xFE70, 0xFEFC, ui.TextDirection.rtl),
    // LTR
    const UnicodeRange<ui.TextDirection>(0xFEFD, 0xFFFF, ui.TextDirection.ltr),
  ],
  null,
);

/// Represents a block of text with a certain [ui.TextDirection].
class DirectionalPosition {
  const DirectionalPosition(this.lineBreak, this.textDirection, this.isSpaceOnly);

  final LineBreakResult lineBreak;

  final ui.TextDirection? textDirection;

  final bool isSpaceOnly;

  LineBreakType get type => lineBreak.type;

  /// Creates a copy of this [DirectionalPosition] with a different [index].
  ///
  /// The type of the returned [DirectionalPosition] is set to
  /// [LineBreakType.prohibited].
  DirectionalPosition copyWithIndex(int index) {
    return DirectionalPosition(
      LineBreakResult.sameIndex(index, LineBreakType.prohibited),
      textDirection,
      isSpaceOnly,
    );
  }
}

/// Finds the end of the directional block of text that starts at [start] up
/// until [end].
///
/// If the block goes beyond [end], the part after [end] is ignored.
DirectionalPosition getDirectionalBlockEnd(
  String text,
  LineBreakResult start,
  LineBreakResult end,
) {
  if (start.index == end.index) {
    return DirectionalPosition(end, null, false);
  }

  // Check if we are in a space-only block.
  if (start.index == end.indexWithoutTrailingSpaces) {
    return DirectionalPosition(end, null, true);
  }

  final ui.TextDirection? blockDirection = _textDirectionLookup.find(text, start.index);
  int i = start.index + 1;

  while (i < end.indexWithoutTrailingSpaces) {
    final ui.TextDirection? direction = _textDirectionLookup.find(text, i);
    if (direction != blockDirection) {
      // Reached the next block.
      break;
    }
    i++;
  }

  if (i == end.indexWithoutTrailingNewlines) {
    // If all that remains before [end] is new lines, let's include them in the
    // block.
    return DirectionalPosition(end, blockDirection, false);
  }
  return DirectionalPosition(
    LineBreakResult.sameIndex(i, LineBreakType.prohibited),
    blockDirection,
    false,
  );
}

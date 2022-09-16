// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';

import 'package:characters/characters.dart' show CharacterRange;

import 'text_layout_metrics.dart';

/// An interface for retrieving the logical text boundary (left-closed-right-open)
/// at a given location in a document.
///
/// The input [TextPosition] points to a position between 2 code units (which
/// can be visually represented by the caret if the selection were to collapse
/// to that position). The [TextPosition.affinity] is used to determine which
/// code unit it points. For example, `TextPosition(i, upstream)` points to
/// code unit `i - 1` and `TextPosition(i, downstream)` points to code unit `i`.
abstract class TextBoundary {
  /// A constant constructor to enable subclass override.
  const TextBoundary();

  /// Returns the leading text boundary at the given location.
  ///
  /// The return value must be less or equal to the input position.
  TextPosition getLeadingTextBoundaryAt(TextPosition position);

  /// Returns the trailing text boundary at the given location, exclusive.
  ///
  /// The return value must be greater or equal to the input position.
  TextPosition getTrailingTextBoundaryAt(TextPosition position);

  /// Gets the text boundary range that encloses the input position.
  TextRange getTextBoundaryAt(TextPosition position) {
    return TextRange(
      start: getLeadingTextBoundaryAt(position).offset,
      end: getTrailingTextBoundaryAt(position).offset,
    );
  }
}

/// A text boundary that uses characters as logical boundaries.
///
/// This class takes grapheme clusters into account and avoid creating
/// boundaries that generate malformed utf-16 characters.
class CharacterBoundary extends TextBoundary {
  /// Creates a [CharacterBoundary] with the text.
  const CharacterBoundary(this._text);

  final String _text;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    if (position.offset <= 0) {
      return const TextPosition(offset: 0);
    }
    if (position.offset > _text.length ||
        (position.offset == _text.length && position.affinity == TextAffinity.downstream)) {
      return TextPosition(offset: _text.length, affinity: TextAffinity.upstream);
    }
    final int endOffset;
    final int startOffset;
    switch (position.affinity) {
      case TextAffinity.upstream:
        startOffset = math.min(position.offset - 1, _text.length);
        endOffset = math.min(position.offset, _text.length);
        break;
      case TextAffinity.downstream:
        startOffset = math.min(position.offset, _text.length);
        endOffset = math.min(position.offset + 1, _text.length);
        break;
    }
    return TextPosition(
      offset: CharacterRange.at(_text, startOffset, endOffset).stringBeforeLength,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    if (position.offset < 0 ||
        (position.offset == 0 && position.affinity == TextAffinity.upstream)) {
      return const TextPosition(offset: 0);
    }
    if (position.offset >= _text.length) {
      return TextPosition(offset: _text.length, affinity: TextAffinity.upstream);
    }
    final int endOffset;
    final int startOffset;
    switch (position.affinity) {
      case TextAffinity.upstream:
        startOffset = math.min(position.offset - 1, _text.length);
        endOffset = math.min(position.offset, _text.length);
        break;
      case TextAffinity.downstream:
        startOffset = math.min(position.offset, _text.length);
        endOffset = math.min(position.offset + 1, _text.length);
        break;
    }
    final CharacterRange range = CharacterRange.at(_text, startOffset, endOffset);
    return TextPosition(
      offset: _text.length - range.stringAfterLength,
      affinity: TextAffinity.upstream,
    );
  }
}

/// A text boundary that uses words as logical boundaries.
///
/// This class uses [UAX #29](https://unicode.org/reports/tr29/) defined word
/// boundaries to calculate its logical boundaries.
class WordBoundary extends TextBoundary {
  /// Creates a [CharacterBoundary] with the text and layout information.
  const WordBoundary(this._textLayout);

  final TextLayoutMetrics _textLayout;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: _textLayout.getWordBoundary(position).start,
      affinity: TextAffinity.downstream,  // ignore: avoid_redundant_argument_values
    );
  }
  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: _textLayout.getWordBoundary(position).end,
      affinity: TextAffinity.upstream,
    );
  }
}

/// A text boundary that uses line breaks as logical boundaries.
///
/// The input [TextPosition]s will be interpreted as caret locations if
/// [TextLayoutMetrics.getLineAtOffset] is text-affinity-aware.
class LineBreak extends TextBoundary {
  /// Creates a [CharacterBoundary] with the text and layout information.
  const LineBreak(this._textLayout);

  final TextLayoutMetrics _textLayout;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: _textLayout.getLineAtOffset(position).start,
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: _textLayout.getLineAtOffset(position).end,
      affinity: TextAffinity.upstream,
    );
  }
}

/// A text boundary that uses the entire document as logical boundary.
///
/// The document boundary is unique and is a constant function of the input
/// position.
class DocumentBoundary extends TextBoundary {
  /// Creates a [CharacterBoundary] with the text
  const DocumentBoundary(this._text);

  final String _text;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) => const TextPosition(offset: 0);
  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return TextPosition(
      offset: _text.length,
      affinity: TextAffinity.upstream,
    );
  }
}

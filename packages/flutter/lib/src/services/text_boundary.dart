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

  /// Gets the boundary by calling the left-hand side and pipe the result to
  /// right-hand side.
  ///
  /// Combining two text boundaries can be useful if one wants to ignore certain
  /// text before finding the text boundary. For example, use
  /// [WhitespaceBoundary] + [WordBoundary] to ignores any white space before
  /// finding word boundary if the input position happens to be a whitespace
  /// character.
  TextBoundary operator +(TextBoundary other) {
    return _ExpandedTextBoundary(inner: other, outer: this);
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
  /// Creates a [WordBoundary] with the text and layout information.
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

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    return _textLayout.getWordBoundary(position);
  }
}

/// A text boundary that uses line breaks as logical boundaries.
///
/// The input [TextPosition]s will be interpreted as caret locations if
/// [TextLayoutMetrics.getLineAtOffset] is text-affinity-aware.
class LineBreak extends TextBoundary {
  /// Creates a [LineBreak] with the text and layout information.
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

  @override
  TextRange getTextBoundaryAt(TextPosition position) {
    return _textLayout.getLineAtOffset(position);
  }
}

/// A text boundary that uses the entire document as logical boundary.
///
/// The document boundary is unique and is a constant function of the input
/// position.
class DocumentBoundary extends TextBoundary {
  /// Creates a [DocumentBoundary] with the text
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

/// A text boundary that uses the first non-whitespace character as the logical
/// boundary.
///
/// This text boundary uses [TextLayoutMetrics.isWhitespace] to identify white
/// spaces, this includes newline characters from ASCII and separators from the
/// [unicode separator category](https://en.wikipedia.org/wiki/Whitespace_character).
class WhitespaceBoundary extends TextBoundary {
  /// Creates a [WhitespaceBoundary] with the text.
  const WhitespaceBoundary(this._text);

  final String _text;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    // Handles outside of string end.
    if (position.offset > _text.length || (position.offset == _text.length  && position.affinity == TextAffinity.downstream)) {
      position = TextPosition(offset: _text.length, affinity: TextAffinity.upstream);
    }
    // Handles outside of string start.
    if (position.offset <= 0) {
      return const TextPosition(offset: 0);
    }
    int index = position.offset;
    if (position.affinity == TextAffinity.downstream && !TextLayoutMetrics.isWhitespace(_text.codeUnitAt(index))) {
      return position;
    }

    while ((index -= 1) >= 0) {
      if (!TextLayoutMetrics.isWhitespace(_text.codeUnitAt(index))) {
        return TextPosition(offset: index + 1, affinity: TextAffinity.upstream);
      }
    }
    return const TextPosition(offset: 0);
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    // Handles outside of right bound.
    if (position.offset >= _text.length) {
      return TextPosition(offset: _text.length, affinity: TextAffinity.upstream);
    }
    // Handles outside of left bound.
    if (position.offset < 0 || (position.offset == 0 && position.affinity == TextAffinity.upstream)) {
      position = const TextPosition(offset: 0);
    }

    int index = position.offset;
    if (position.affinity == TextAffinity.upstream && !TextLayoutMetrics.isWhitespace(_text.codeUnitAt(index - 1))) {
      return position;
    }

    for (; index < _text.length; index += 1) {
      if (!TextLayoutMetrics.isWhitespace(_text.codeUnitAt(index))) {
        return TextPosition(offset: index);
      }
    }
    return TextPosition(offset: _text.length, affinity: TextAffinity.upstream);
  }
}

/// Gets the boundary by calling the [outer] and pipe the result to
/// [inner].
class _ExpandedTextBoundary extends TextBoundary {
  /// Creates a [_ExpandedTextBoundary] with inner and outter boundaries
  const _ExpandedTextBoundary({required this.inner, required this.outer});

  /// The inner boundary to call with the result from [outer].
  final TextBoundary inner;

  /// The outer boundary to call with the input position.
  ///
  /// The result is piped to the [inner] before returning to the caller.
  final TextBoundary outer;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return inner.getLeadingTextBoundaryAt(
      outer.getLeadingTextBoundaryAt(position),
    );
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return inner.getTrailingTextBoundaryAt(
      outer.getTrailingTextBoundaryAt(position),
    );
  }
}

/// A text boundary that will push input text position forward or backward
/// one affinity
///
/// To push a text position forward one affinity unit, this proxy converts
/// affinity to downstream if it is upstream; otherwise it increase the offset
/// by one with its affinity sets to upstream. For example,
/// `TextPosition(1, upstream)` becomes `TextPosition(1, downstream)`,
/// `TextPosition(4, downstream)` becomes `TextPosition(5, upstream)`.
///
/// See also:
/// * [PushTextPosition.forward], a text boundary to push the input position
///   forward.
/// * [PushTextPosition.backward], a text boundary to push the input position
///   backward.
class PushTextPosition extends TextBoundary {
  const PushTextPosition._(this._forward);

  /// A text boundary that pushes the input position forward.
  static const TextBoundary forward = PushTextPosition._(true);

  /// A text boundary that pushes the input position backward.
  static const TextBoundary backward = PushTextPosition._(false);

  /// Whether to push the input position forward or backward.
  final bool _forward;

  TextPosition _calculateTargetPosition(TextPosition position) {
    if (_forward) {
      switch(position.affinity) {
        case TextAffinity.upstream:
          return TextPosition(offset: position.offset);
        case TextAffinity.downstream:
          return position = TextPosition(
            offset: position.offset + 1,
            affinity: TextAffinity.upstream,
          );
      }
    } else {
      switch(position.affinity) {
        case TextAffinity.upstream:
          return position = TextPosition(offset: position.offset - 1);
        case TextAffinity.downstream:
          return TextPosition(
            offset: position.offset,
            affinity: TextAffinity.upstream,
          );
      }
    }
  }

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) => _calculateTargetPosition(position);

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) => _calculateTargetPosition(position);
}

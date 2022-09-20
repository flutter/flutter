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
  /// A const constructor to allow subclass overrides.
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

/// A text boundary that use the first non-whitespace character as the logical
/// boundary.
///
/// This text boundary uses [TextLayoutMetrics.isWhitespace] to identify white
/// spaces, this include newline characters from ASCII and separators from the
/// [unicode separator category](https://www.compart.com/en/unicode/category/Zs).
class WhitespaceBoundary extends TextBoundary {
  /// Creates a [_WhitespaceBoundary] with the text.
  const WhitespaceBoundary(this._text);

  final String _text;

  @override
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    // Handles outside of right bound.
    if (position.offset > _text.length || (position.offset == _text.length  && position.affinity == TextAffinity.downstream)) {
      position = TextPosition(offset: _text.length, affinity: TextAffinity.upstream);
    }
    // Handles outside of left bound.
    if (position.offset <= 0) {
      return const TextPosition(offset: 0);
    }
    int index = position.offset;
    if (position.affinity == TextAffinity.downstream && !TextLayoutMetrics.isWhitespace(_text.codeUnitAt(index))) {
      return position;
    }

    for (index -= 1; index >= 0; index -= 1) {
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
///
/// This class is useful if one wants to ignore characters before finding the
/// text boundary. For example, use [WhitespaceBoundary] as the
/// [outer] to ignores any white space before finding the boundary
/// of [inner] if the input position happens to be a whitespace
/// character.
class ExpandedTextBoundary extends TextBoundary {
  /// Creates a [ExpandedTextBoundary] with inner and outter boundaries
  const ExpandedTextBoundary({required this.inner, required this.outer});

  /// The inner boundary to call with the result from [outer].
  final TextBoundary inner;

  /// The outer boundary to call with the input position.
  ///
  /// The result is piped to the [inner] before returning the the caller.
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

/// A proxy text boundary that will push input text position forward or backward
/// one affinity unit before sending it to the [textBoundary].
///
/// If the [forward] is true, this proxy text boundary push the position
/// forward; otherwise, backward.
///
/// To push a text position forward one affinity unit, this proxy converts
/// affinity to downstream if it is upstream; otherwise it increase the offset
/// by one with its affinity sets to upstream. For example,
/// `TextPosition(1, upstream)` becomes `TextPosition(1, downstream)`,
/// `TextPosition(4, downstream)` becomes `TextPosition(5, upstream)`.
///
/// This class is used to kick-start the text position to find the next boundary
/// determined by [textBoundary] so that it won't be trapped if the input
/// text position is right at the edge.
class PushTextPosition extends TextBoundary {
  /// Creates a proxy to push the input position before sending it to the
  /// [textBoundary].
  const PushTextPosition({required this.textBoundary, required this.forward});

  /// The text boundary this proxy sends to.
  final TextBoundary textBoundary;

  /// Whether to push the input position forward or backward.
  final bool forward;

  TextPosition _calculateTargetPosition(TextPosition position) {
    if (forward) {
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
  TextPosition getLeadingTextBoundaryAt(TextPosition position) {
    return textBoundary.getLeadingTextBoundaryAt(_calculateTargetPosition(position));
  }

  @override
  TextPosition getTrailingTextBoundaryAt(TextPosition position) {
    return textBoundary.getTrailingTextBoundaryAt(_calculateTargetPosition(position));
  }
}

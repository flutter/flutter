// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
/// @docImport 'text_painter.dart';
library;

import 'dart:math' as math;
import 'dart:ui' show TextRange;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

/// The default string used to replace elided text: a horizontal ellipsis.
const String _kEllipsis = '\u2026';

/// A single edit applied to a string when truncating it: the [range] of the
/// original text is displayed as [replacement].
///
/// A list of [TextElision]s, as returned by [TextTruncation.elide], describes
/// how the original text is transformed into the text that is displayed.
///
/// See also:
///
///  * [TextTruncation], which produces [TextElision]s for a given level of
///    truncation.
@immutable
class TextElision {
  /// Creates an elision that displays [range] of the original text as
  /// [replacement].
  ///
  /// The [replacement] defaults to a horizontal ellipsis (`…`).
  const TextElision(this.range, [this.replacement = _kEllipsis]);

  /// The range of the *original* text that is elided, in UTF-16 code units.
  ///
  /// The range must be valid, normalized, and aligned to grapheme cluster
  /// boundaries.
  final TextRange range;

  /// The string displayed in place of [range]. Usually an ellipsis.
  final String replacement;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextElision && other.range == range && other.replacement == replacement;
  }

  @override
  int get hashCode => Object.hash(range, replacement);

  @override
  String toString() => '${objectRuntimeType(this, 'TextElision')}($range, "$replacement")';
}

/// Describes how text is shortened so that it fits when it is displayed with
/// [TextOverflow.truncate].
///
/// A [TextTruncation] maps an integer *level* to a set of [TextElision]s. Level
/// 0 always means "no elisions", and higher levels remove more of the text. The
/// framework searches for the smallest level whose result fits in the
/// available space and displays that result.
///
/// Levels count grapheme clusters (as defined by `package:characters`) in the
/// built-in truncations, so that user-perceived characters such as emoji are
/// never split.
///
/// {@tool snippet}
///
/// This example truncates an email address by eliding the end of the local
/// part, so that the domain always remains visible:
///
/// ```dart
/// class EmailTruncation extends TextTruncation {
///   const EmailTruncation();
///
///   @override
///   int maxLevel(String text) {
///     final int at = text.indexOf('@');
///     // The number of graphemes that can be dropped before the '@'.
///     return at < 0 ? 0 : text.substring(0, at).characters.length;
///   }
///
///   @override
///   List<TextElision> elide(String text, int level) {
///     if (level == 0) {
///       return const <TextElision>[];
///     }
///     final int at = text.indexOf('@');
///     // Drop the last `level` graphemes of the local part.
///     final Characters user = text.substring(0, at).characters;
///     final int keep = user.take(user.length - level).string.length;
///     return <TextElision>[TextElision(TextRange(start: keep, end: at))];
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [TextOverflow.truncate], which uses a [TextTruncation] to decide how
///    overflowing text is displayed.
///  * [TextElision], the edits produced by a [TextTruncation].
@immutable
abstract class TextTruncation {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TextTruncation();

  /// Truncates the end of the text, replacing the removed graphemes with
  /// [ellipsis].
  ///
  /// For example, `verylongusername@gmail.com` may be displayed as
  /// `verylongusername@gm…`.
  ///
  /// This is intended for single-line text.
  const factory TextTruncation.end({String ellipsis}) = _EndTextTruncation;

  /// Truncates the start of the text, replacing the removed graphemes with
  /// [ellipsis].
  ///
  /// For example, `verylongusername@gmail.com` may be displayed as
  /// `…ername@gmail.com`.
  ///
  /// This is intended for single-line text.
  const factory TextTruncation.start({String ellipsis}) = _StartTextTruncation;

  /// Truncates the middle of the text, replacing the removed graphemes with
  /// [ellipsis].
  ///
  /// For example, `verylongusername@gmail.com` may be displayed as
  /// `verylong…gmail.com`.
  ///
  /// This is intended for single-line text.
  const factory TextTruncation.middle({String ellipsis}) = _MiddleTextTruncation;

  /// The largest meaningful level for [text].
  ///
  /// The framework never asks for a level larger than this. If the text still
  /// does not fit at this level, it is displayed at this level and clipped.
  ///
  /// Level 0 always means "no elisions", so returning 0 disables truncation
  /// for [text].
  int maxLevel(String text);

  /// Returns the elisions to apply to [text] at [level].
  ///
  /// The returned list must satisfy the following requirements:
  ///
  ///  * Level 0 returns an empty list.
  ///  * Ranges are non-overlapping, sorted, within the bounds of [text], and
  ///    aligned to grapheme cluster boundaries.
  ///  * Monotonic: for a fixed [text], the laid-out width of the result is
  ///    non-increasing as [level] increases. The framework uses a binary search
  ///    to find the smallest level that fits, so violating this requirement
  ///    makes the chosen level unspecified (but never throws).
  ///
  /// In debug mode, the framework asserts that the ranges are well formed.
  List<TextElision> elide(String text, int level);
}

/// Returns the UTF-16 offsets of every grapheme cluster boundary in [text],
/// including 0 and `text.length`.
List<int> _graphemeBoundaries(String text) {
  final boundaries = <int>[0];
  var offset = 0;
  for (final String grapheme in text.characters) {
    offset += grapheme.length;
    boundaries.add(offset);
  }
  return boundaries;
}

abstract class _BuiltInTextTruncation extends TextTruncation {
  const _BuiltInTextTruncation({this.ellipsis = _kEllipsis});

  final String ellipsis;

  String get _name;

  @override
  int maxLevel(String text) => text.characters.length;

  @override
  List<TextElision> elide(String text, int level) {
    if (level <= 0) {
      return const <TextElision>[];
    }
    final List<int> boundaries = _graphemeBoundaries(text);
    final int graphemeCount = boundaries.length - 1;
    final TextRange range = _elidedRange(boundaries, graphemeCount, math.min(level, graphemeCount));
    return <TextElision>[TextElision(range, ellipsis)];
  }

  /// Returns the range of the text to elide when [level] graphemes (out of
  /// [graphemeCount]) are removed.
  TextRange _elidedRange(List<int> boundaries, int graphemeCount, int level);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is _BuiltInTextTruncation &&
        other.ellipsis == ellipsis;
  }

  @override
  int get hashCode => Object.hash(runtimeType, ellipsis);

  @override
  String toString() {
    final args = ellipsis == _kEllipsis ? '' : 'ellipsis: "$ellipsis"';
    return 'TextTruncation.$_name($args)';
  }
}

class _EndTextTruncation extends _BuiltInTextTruncation {
  const _EndTextTruncation({super.ellipsis});

  @override
  String get _name => 'end';

  @override
  TextRange _elidedRange(List<int> boundaries, int graphemeCount, int level) {
    return TextRange(start: boundaries[graphemeCount - level], end: boundaries[graphemeCount]);
  }
}

class _StartTextTruncation extends _BuiltInTextTruncation {
  const _StartTextTruncation({super.ellipsis});

  @override
  String get _name => 'start';

  @override
  TextRange _elidedRange(List<int> boundaries, int graphemeCount, int level) {
    return TextRange(start: 0, end: boundaries[level]);
  }
}

class _MiddleTextTruncation extends _BuiltInTextTruncation {
  const _MiddleTextTruncation({super.ellipsis});

  @override
  String get _name => 'middle';

  @override
  TextRange _elidedRange(List<int> boundaries, int graphemeCount, int level) {
    // Keep the remaining graphemes split between the head and the tail, with
    // the head getting the extra grapheme when the split is uneven. Both the
    // head and the tail shrink (or stay the same) as the level increases, so
    // the kept text at level + 1 is always a subset of the kept text at level.
    final int kept = graphemeCount - level;
    final int head = (kept + 1) ~/ 2;
    final int tail = kept ~/ 2;
    return TextRange(start: boundaries[head], end: boundaries[graphemeCount - tail]);
  }
}

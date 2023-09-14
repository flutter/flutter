// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'inline_span.dart';
import 'text_span.dart';

/// Signature for a function that builds an [InlineSpan] link.
///
/// The link displays [displayString] and links to [linkString] when tapped.
/// These are distinct because sometimes a link may be split across multiple
/// [TextSpan]s.
///
/// For example, consider the [TextSpan]s
/// `[TextSpan(text: 'http://'), TextSpan(text: 'google.com'), TextSpan(text: '/')]`.
/// This builder would be called three times, with the following parameters:
///
///  1. `displayString: 'http://', linkString: 'http://google.com/'`
///  2. `displayString: 'google.com', linkString: 'http://google.com/'`
///  3. `displayString: '/', linkString: 'http://google.com/'`
///
/// {@template flutter.painting.LinkBuilder.recognizer}
/// It's necessary for the owning widget to manage the lifecycle of any
/// [GestureRecognizer]s created in this function, such as for handling a tap on
/// the link. See [TextSpan.recognizer] for more.
/// {@endtemplate}
///
/// {@tool dartpad}
/// This example shows how to use [TextLinker] to link both URLs and Twitter
/// handles in a [TextSpan] tree. It also illustrates the difference between
/// `displayString` and `linkString`.
///
/// ** See code in examples/api/lib/painting/text_linker/text_linker.1.dart **
/// {@end-tool}
typedef InlineLinkBuilder = InlineSpan Function(
  String displayString,
  String linkString,
);

/// Specifies a way to find and style parts of some text.
///
/// [TextLinker]s can be applied to some text using the [linkSpans] method.
///
/// {@tool dartpad}
/// This example shows how to use [TextLinker] to link both URLs and Twitter
/// handles in the same text.
///
/// ** See code in examples/api/lib/painting/text_linker/text_linker.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to use [TextLinker] to link both URLs and Twitter
/// handles in a [TextSpan] tree instead of a flat string.
///
/// ** See code in examples/api/lib/painting/text_linker/text_linker.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow full control
///    over matching and building different types of links.
///  * [LinkedText.new], which is simpler than using [TextLinker] and
///    automatically manages the lifecycle of any [GestureRecognizer]s.
class TextLinker {
  /// Creates an instance of [TextLinker] with a [RegExp] and an [InlineLinkBuilder
  /// [InlineLinkBuilder].
  ///
  /// Does not manage the lifecycle of any [GestureRecognizer]s created in the
  /// [InlineLinkBuilder], so it's the responsibility of the caller to do so.
  /// See [TextSpan.recognizer] for more.
  TextLinker({
    required this.regExp,
    required this.linkBuilder,
  });

  /// Builds an [InlineSpan] to display the text that it's passed.
  ///
  /// {@macro flutter.painting.LinkBuilder.recognizer}
  final InlineLinkBuilder linkBuilder;

  /// Matches text that should be turned into a link with [linkBuilder].
  final RegExp regExp;

  /// Applies the given [TextLinker]s to the given [InlineSpan]s and returns the
  /// new resulting spans and any created [GestureRecognizer]s.
  static Iterable<InlineSpan> linkSpans(Iterable<InlineSpan> spans, Iterable<TextLinker> textLinkers) {
    final _LinkedSpans linkedSpans = _LinkedSpans(
      spans: spans,
      textLinkers: textLinkers,
    );
    return linkedSpans.linkedSpans;
  }

  // Turns all matches from the regExp into a list of TextRanges.
  static Iterable<TextRange> _textRangesFromText(String text, RegExp regExp) {
    final Iterable<RegExpMatch> matches = regExp.allMatches(text);
    return matches.map((RegExpMatch match) {
      return TextRange(
        start: match.start,
        end: match.end,
      );
    });
  }

  /// Apply this [TextLinker] to a [String].
  Iterable<_TextLinkerMatch> _link(String text) {
    final Iterable<TextRange> textRanges = _textRangesFromText(text, regExp);
    return textRanges.map((TextRange textRange) {
      return _TextLinkerMatch(
        textRange: textRange,
        linkBuilder: linkBuilder,
        linkString: text.substring(textRange.start, textRange.end),
      );
    });
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TextLinker')}($regExp)';
}

/// A matched replacement on some string.
///
/// Produced by applying a [TextLinker]'s [RegExp] to a string.
class _TextLinkerMatch {
  _TextLinkerMatch({
    required this.textRange,
    required this.linkBuilder,
    required this.linkString,
  }) : assert(textRange.end - textRange.start == linkString.length);

  final InlineLinkBuilder linkBuilder;
  final TextRange textRange;

  /// The string that [textRange] matches.
  final String linkString;

  /// Get all [_TextLinkerMatch]s obtained from applying the given
  /// `textLinker`s with the given `text`.
  static List<_TextLinkerMatch> fromTextLinkers(Iterable<TextLinker> textLinkers, String text) {
    return textLinkers
        .fold<List<_TextLinkerMatch>>(
          <_TextLinkerMatch>[],
          (List<_TextLinkerMatch> previousValue, TextLinker value) {
            return previousValue..addAll(value._link(text));
        });
  }

  @override
  String toString() => '${objectRuntimeType(this, '_TextLinkerMatch')}($textRange, $linkBuilder, $linkString)';
}

/// Used to cache information about a span's recursive text.
///
/// Avoids repeatedly calling [TextSpan.toPlainText].
class _TextCache {
  factory _TextCache({
    required InlineSpan span,
  }) {
    if (span is! TextSpan) {
      return _TextCache._(
        text: '',
        lengths: <InlineSpan, int>{span: 0},
      );
    }

    _TextCache childrenTextCache = _TextCache._empty();
    for (final InlineSpan child in span.children ?? <InlineSpan>[]) {
      final _TextCache childTextCache = _TextCache(
        span: child,
      );
      childrenTextCache = childrenTextCache._merge(childTextCache);
    }

    final String text = (span.text ?? '') + childrenTextCache.text;
    return _TextCache._(
      text: text,
      lengths: <InlineSpan, int>{
        span: text.length,
        ...childrenTextCache._lengths,
      },
    );
  }

  factory _TextCache.fromMany({
    required Iterable<InlineSpan> spans,
  }) {
    _TextCache textCache = _TextCache._empty();
    for (final InlineSpan span in spans) {
      final _TextCache spanTextCache = _TextCache(
        span: span,
      );
      textCache = textCache._merge(spanTextCache);
    }
    return textCache;
  }

  _TextCache._empty(
  ) : text = '',
      _lengths = <InlineSpan, int>{};

  const _TextCache._({
    required this.text,
    required Map<InlineSpan, int> lengths,
  }) : _lengths = lengths;

  /// The flattened text of all spans in the span tree.
  final String text;

  /// A [Map] containing the lengths of all spans in the span tree.
  ///
  /// The length is defined as the length of the flattened text at the point in
  /// the tree where the node resides.
  ///
  /// The length of [text] is the length of the root node in [_lengths].
  final Map<InlineSpan, int> _lengths;

  /// Merges the given _TextCache with this one by appending it to the end.
  ///
  /// Returns a new _TextCache and makes no modifications to either passed in.
  _TextCache _merge(_TextCache other) {
    return _TextCache._(
      text: text + other.text,
      lengths: Map<InlineSpan, int>.from(_lengths)..addAll(other._lengths),
    );
  }

  int? getLength(InlineSpan span) => _lengths[span];

  @override
  String toString() => '${objectRuntimeType(this, '_TextCache')}($text, $_lengths)';
}

/// Signature for the output of linking an InlineSpan to some
/// _TextLinkerMatches.
typedef _LinkSpanRecursion = (
  /// The output of linking the input InlineSpan.
  InlineSpan linkedSpan,
  /// The provided _TextLinkerMatches, but with those completely used during
  /// linking removed.
  Iterable<_TextLinkerMatch> unusedTextLinkerMatches,
);

/// Signature for the output of linking a List of InlineSpans to some
/// _TextLinkerMatches.
typedef _LinkSpansRecursion = (
  /// The output of linking the input InlineSpans.
  Iterable<InlineSpan> linkedSpans,
  /// The provided _TextLinkerMatches, but with those completely used during
  /// linking removed.
  Iterable<_TextLinkerMatch> unusedTextLinkerMatches,
);

/// Applies some [TextLinker]s to some [InlineSpan]s and produces a new list of
/// [linkedSpans] as well as the [recognizers] created for each generated link.
class _LinkedSpans {
  factory _LinkedSpans({
    required Iterable<InlineSpan> spans,
    required Iterable<TextLinker> textLinkers,
  }) {
    // Flatten the spans and store all string lengths, so that matches across
    // span boundaries can be matched in the flat string. This is calculated
    // once in the beginning to avoid recomputing.
    final _TextCache textCache = _TextCache.fromMany(spans: spans);

    final Iterable<_TextLinkerMatch> textLinkerMatches =
        _cleanTextLinkerMatches(
          _TextLinkerMatch.fromTextLinkers(textLinkers, textCache.text),
        );

    final (Iterable<InlineSpan> linkedSpans, Iterable<_TextLinkerMatch> _) =
        _linkSpansRecurse(
          spans,
          textCache,
          textLinkerMatches,
        );

    return _LinkedSpans._(
      linkedSpans: linkedSpans,
    );
  }

  const _LinkedSpans._({
    required this.linkedSpans,
  });

  final Iterable<InlineSpan> linkedSpans;

  static List<_TextLinkerMatch> _cleanTextLinkerMatches(Iterable<_TextLinkerMatch> textLinkerMatches) {
    final List<_TextLinkerMatch> nextTextLinkerMatches = textLinkerMatches.toList();

    // Sort by start.
    nextTextLinkerMatches.sort((_TextLinkerMatch a, _TextLinkerMatch b) {
      return a.textRange.start.compareTo(b.textRange.start);
    });

    // Validate that there are no overlapping matches.
    int lastEnd = 0;
    for (final _TextLinkerMatch textLinkerMatch in nextTextLinkerMatches) {
      if (textLinkerMatch.textRange.start < lastEnd) {
        throw ArgumentError('Matches must not overlap. Overlapping text was "${textLinkerMatch.linkString}" located at ${textLinkerMatch.textRange.start}-${textLinkerMatch.textRange.end}.');
      }
      lastEnd = textLinkerMatch.textRange.end;
    }

    // Remove empty ranges.
    nextTextLinkerMatches.removeWhere((_TextLinkerMatch textLinkerMatch) {
      return textLinkerMatch.textRange.start == textLinkerMatch.textRange.end;
    });

    return nextTextLinkerMatches;
  }

  // `index` is the index of the start of `span` in the overall flattened tree
  // string.
  static _LinkSpansRecursion _linkSpansRecurse(Iterable<InlineSpan> spans, _TextCache textCache, Iterable<_TextLinkerMatch> textLinkerMatches, [int index = 0]) {
    final List<InlineSpan> output = <InlineSpan>[];
    Iterable<_TextLinkerMatch> nextTextLinkerMatches = textLinkerMatches;
    int nextIndex = index;
    for (final InlineSpan span in spans) {
      final (InlineSpan childSpan, Iterable<_TextLinkerMatch> childTextLinkerMatches) = _linkSpanRecurse(
        span,
        textCache,
        nextTextLinkerMatches,
        nextIndex,
      );
      output.add(childSpan);
      nextTextLinkerMatches = childTextLinkerMatches;
      nextIndex += textCache.getLength(span)!;
    }

    return (output, nextTextLinkerMatches);
  }

  // `index` is the index of the start of `span` in the overall flattened tree
  // string.
  static _LinkSpanRecursion _linkSpanRecurse(InlineSpan span, _TextCache textCache, Iterable<_TextLinkerMatch> textLinkerMatches, [int index = 0]) {
    if (span is! TextSpan) {
      return (span, textLinkerMatches);
    }

    final List<InlineSpan> nextChildren = <InlineSpan>[];
    List<_TextLinkerMatch> nextTextLinkerMatches = <_TextLinkerMatch>[...textLinkerMatches];
    int lastLinkEnd = index;
    if (span.text?.isNotEmpty ?? false) {
      final int textEnd = index + span.text!.length;
      for (final _TextLinkerMatch textLinkerMatch in textLinkerMatches) {
        if (textLinkerMatch.textRange.start >= textEnd) {
          // Because ranges is ordered, there are no more relevant ranges for this
          // text.
          break;
        }
        if (textLinkerMatch.textRange.end <= index) {
          // This range ends before this span and is therefore irrelevant to it.
          // It should have been removed from ranges.
          assert(false, 'Invalid ranges.');
          nextTextLinkerMatches.removeAt(0);
          continue;
        }
        if (textLinkerMatch.textRange.start > index) {
          // Add the unlinked text before the range.
          nextChildren.add(TextSpan(
            text: span.text!.substring(
              lastLinkEnd - index,
              textLinkerMatch.textRange.start - index,
            ),
          ));
        }
        // Add the link itself.
        final int linkStart = math.max(textLinkerMatch.textRange.start, index);
        lastLinkEnd = math.min(textLinkerMatch.textRange.end, textEnd);
        final InlineSpan nextChild = textLinkerMatch.linkBuilder(
          span.text!.substring(linkStart - index, lastLinkEnd - index),
          textLinkerMatch.linkString,
        );
        nextChildren.add(nextChild);
        if (textLinkerMatch.textRange.end > textEnd) {
          // If we only partially used this range, keep it in nextRanges. Since
          // overlapping ranges have been removed, this must be the last relevant
          // range for this span.
          break;
        }
        nextTextLinkerMatches.removeAt(0);
      }

      // Add any extra text after any ranges.
      final String remainingText = span.text!.substring(lastLinkEnd - index);
      if (remainingText.isNotEmpty) {
        nextChildren.add(TextSpan(
          text: remainingText,
        ));
      }
    }

    // Recurse on the children.
    if (span.children?.isNotEmpty ?? false) {
      final (
        Iterable<InlineSpan> childrenSpans,
        Iterable<_TextLinkerMatch> childrenTextLinkerMatches,
      ) = _linkSpansRecurse(
        span.children!,
        textCache,
        nextTextLinkerMatches,
        index + (span.text?.length ?? 0),
      );
      nextTextLinkerMatches = childrenTextLinkerMatches.toList();
      nextChildren.addAll(childrenSpans);
    }

    return (
      TextSpan(
        style: span.style,
        children: nextChildren,
      ),
      nextTextLinkerMatches,
    );
  }
}

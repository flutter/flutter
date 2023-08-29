// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

/// A callback that passes a [String] representing a link that has been tapped.
typedef LinkTapCallback = void Function(String linkString);

/// Builds an [InlineSpan] for displaying a link on [displayString] linking to
/// [linkString].
///
/// Creates a [TapGestureRecognizer] and returns it so that its lifecycle can be
/// maintained by the caller.
///
/// {@template flutter.painting.LinkBuilder.recognizer}
/// It's necessary to call [TapGestureRecognizer.dispose] on the returned
/// recognizer when the owning widget is disposed. See [TextSpan.recognizer].
/// {@endtemplate}
typedef LinkBuilder = (InlineSpan, TapGestureRecognizer) Function(
  String displayString,
  String linkString,
);

/// Finds [TextRange]s in the given [String].
typedef TextRangesFinder = Iterable<TextRange> Function(String text);

/// A widget that displays text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive, and clicking one
/// calls [onTap].
///
/// Works with either a flat [String] (`text`) or a list of [InlineSpan]s
/// (`spans`).
///
/// {@tool dartpad}
/// This example shows how to create a [LinkedText] that turns URLs into
/// working links.
///
/// ** See code in examples/api/lib/widgets/linked_text/linked_text.0.dart **
/// {@end-tool}
class LinkedText extends StatefulWidget {
  /// Creates an instance of [LinkedText] from the given [text] or [spans],
  /// highlighting any URLs by default.
  ///
  /// {@template flutter.widgets.LinkedText.new}
  /// By default, highlights URLs in the [text] or [spans] and makes them
  /// tappable with [onTap].
  ///
  /// If [textRanges] is given, then makes those ranges in the text interactive
  /// instead of URLs.
  /// {@endtemplate}
  ///
  /// {@tool dartpad}
  /// This example shows how to create a [LinkedText] that turns URLs into
  /// working links.
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.0.dart **
  /// {@end-tool}
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText] to link URLs in a TextSpan tree
  /// instead of in a flat string.
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.3.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow full
  ///    control over matching and building different types of links.
  LinkedText({
    super.key,
    this.style,
    required LinkTapCallback onTap,
    List<InlineSpan>? spans,
    String? text,
    Iterable<TextRange>? textRanges,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       textLinkers = <TextLinker>[
         TextLinker(
           textRangesFinder: textRanges == null
               ? defaultTextRangesFinder
               : (String text) => textRanges,
           linkBuilder: getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  /// Create an instance of [LinkedText] where text matched by the given
  /// [RegExp] is made interactive.
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText.regExp] to link Twitter handles.
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.1.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow full
  ///    control over matching and building different types of links.
  LinkedText.regExp({
    super.key,
    this.style,
    required LinkTapCallback onTap,
    required RegExp regExp,
    List<InlineSpan>? spans,
    String? text,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       textLinkers = <TextLinker>[
         TextLinker(
           textRangesFinder: TextLinker.textRangesFinderFromRegExp(regExp),
           linkBuilder: getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  /// Create an instance of [LinkedText] where the given [textLinkers] are
  /// applied.
  ///
  /// {@template flutter.widgets.LinkedText.textLinkers}
  /// Useful for independently matching different types of strings with
  /// different behaviors. For example, highlighting both URLs and Twitter
  /// handles with different style and/or behavior.
  /// {@endtemplate}
  ///
  /// {@tool dartpad}
  /// This example shows how to use [LinkedText.textLinkers] to link both URLs
  /// and Twitter handles independently.
  ///
  /// ** See code in examples/api/lib/widgets/linked_text/linked_text.2.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [LinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  LinkedText.textLinkers({
    super.key,
    String? text,
    List<InlineSpan>? spans,
    required this.textLinkers,
    this.style,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       assert(textLinkers.isNotEmpty),
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  static final RegExp _urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

  /// A [TextRangesFinder] that returns [TextRange]s for URLs.
  ///
  /// Matches full (https://www.example.com/?q=1) and shortened (example.com)
  /// URLs.
  ///
  /// Excludes:
  ///
  ///   * URLs with any protocol other than http or https.
  ///   * Email addresses.
  static final TextRangesFinder defaultTextRangesFinder = TextLinker.textRangesFinderFromRegExp(_urlRegExp);

  /// The spans on which to create links by applying [textLinkers].
  final List<InlineSpan> spans;

  /// Defines what parts of the text to match and how to link them.
  ///
  /// [TextLinker]s are applied in the order given. Overlapping matches are not
  /// supported.
  late final List<TextLinker> textLinkers;

  /// The [TextStyle] to apply to the output [InlineSpan].
  final TextStyle? style;

  /// Returns a [LinkBuilder] that highlights the given text and sets the given
  /// [onTap] handler.
  static LinkBuilder getDefaultLinkBuilder(LinkTapCallback onTap) {
    return (String displayString, String linkString) {
      final TapGestureRecognizer recognizer = TapGestureRecognizer()
          ..onTap = () => onTap(linkString);
      return (
        InlineLink(
          recognizer: recognizer,
          text: displayString,
        ),
        recognizer,
      );
    };
  }

  /// Apply the given [TextLinker]s to the given [InlineSpan]s and return the
  /// new resulting spans and any created [TapGestureRecognizer]s.
  ///
  /// {@macro flutter.painting.LinkBuilder.recognizer}
  static (Iterable<InlineSpan>, Iterable<TapGestureRecognizer>) linkSpans(Iterable<InlineSpan> spans, Iterable<TextLinker> textLinkers) {
    final _LinkedSpans linkedSpans = _LinkedSpans(
      spans: spans,
      textLinkers: textLinkers,
    );
    return (
      linkedSpans.linkedSpans,
      linkedSpans.recognizers,
    );
  }

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final GlobalKey _textKey = GlobalKey();
  Iterable<TapGestureRecognizer>? _recognizers;
  late Iterable<InlineSpan> _linkedSpans;

  void _disposeRecognizers() {
    if (_recognizers == null) {
      return;
    }
    for (final TapGestureRecognizer recognizer in _recognizers!) {
      recognizer.dispose();
    }
  }

  void _linkSpans() {
    final (Iterable<InlineSpan> linkedSpans, Iterable<TapGestureRecognizer> recognizers) =
        LinkedText.linkSpans(widget.spans, widget.textLinkers);
    _linkedSpans = linkedSpans;
    _disposeRecognizers();
    _recognizers = recognizers;
  }

  @override
  void initState() {
    super.initState();
    _linkSpans();
  }

  @override
  void didUpdateWidget(LinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.spans != oldWidget.spans || widget.textLinkers != oldWidget.textLinkers) {
      _linkSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text.rich(
      key: _textKey,
      TextSpan(
        style: widget.style ?? DefaultTextStyle.of(context).style,
        children: _linkedSpans.toList(),
      ),
    );
  }
}

/// Specifies a way to find and style parts of a [String].
///
/// By calling [getSpans] with a [String], produces a [List] of [InlineSpan]s
/// where the parts of the [String] matched by [textRangesFinder] have been
/// turned into links using [linkBuilder].
class TextLinker {
  /// Creates an instance of [TextLinker].
  const TextLinker({
    required this.textRangesFinder,
    required this.linkBuilder,
  });

  /// Builds an [InlineSpan] to display the text that it's passed.
  final LinkBuilder linkBuilder;

  /// Returns [TextRange]s that should be built with [linkBuilder].
  final TextRangesFinder textRangesFinder;

  /// Returns a flat list of [InlineSpan]s for multiple [TextLinker]s.
  ///
  /// Similar to [getSpans], but for multiple [TextLinker]s instead of just one.
  static (List<InlineSpan>, List<TapGestureRecognizer>) getSpansForMany(Iterable<TextLinker> textLinkers, String text) {
    final List<_TextLinkerMatch> combinedTextRanges = textLinkers
        .fold<List<_TextLinkerMatch>>(
          <_TextLinkerMatch>[],
          (List<_TextLinkerMatch> previousValue, TextLinker value) {
            final Iterable<TextRange> textRanges = value.textRangesFinder(text);
            for (final TextRange textRange in textRanges) {
              previousValue.add(_TextLinkerMatch(
                textRange: textRange,
                linkBuilder: value.linkBuilder,
                linkString: text.substring(textRange.start, textRange.end),
              ));
            }
            return previousValue;
        });

    return _TextLinkerMatch.getSpansForMany(combinedTextRanges, text);
  }

  /// Creates a [TextRangesFinder] that finds all the matches of the given [RegExp].
  static TextRangesFinder textRangesFinderFromRegExp(RegExp regExp) {
    return (String text) {
      return _textRangesFromText(
        text: text,
        regExp: regExp,
      );
    };
  }

  // Turns all matches from the regExp into a list of TextRanges.
  static Iterable<TextRange> _textRangesFromText({
    required String text,
    required RegExp regExp,
  }) {
    final Iterable<RegExpMatch> matches = regExp.allMatches(text);
    return matches.map((RegExpMatch match) {
      return TextRange(
        start: match.start,
        end: match.end,
      );
    });
  }

  /// Builds the [InlineSpan]s for the given text.
  ///
  /// Builds [linkBuilder] for any ranges found by [textRangesFinder]. All other
  /// text is presented in a plain [TextSpan].
  (List<InlineSpan>, List<TapGestureRecognizer>) getSpans(String text) {
    final Iterable<_TextLinkerMatch> textLinkerMatches = _link(text);
    return _TextLinkerMatch.getSpansForMany(textLinkerMatches, text);
  }

  /// Apply this [TextLinker] to a [String].
  Iterable<_TextLinkerMatch> _link(String text) {
    final Iterable<TextRange> textRanges = textRangesFinder(text);
    return textRanges.map((TextRange textRange) {
      return _TextLinkerMatch(
        textRange: textRange,
        linkBuilder: linkBuilder,
        linkString: text.substring(textRange.start, textRange.end),
      );
    });
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TextLinker')}($linkBuilder, $textRangesFinder)';
}

/// A matched replacement on some [String].
///
/// Produced by applying a [TextLinker]'s [TextRangesFinder] to a string.
class _TextLinkerMatch {
  _TextLinkerMatch({
    required this.textRange,
    required this.linkBuilder,
    required this.linkString,
  }) : assert(textRange.end - textRange.start == linkString.length);

  final LinkBuilder linkBuilder;
  final TextRange textRange;

  /// The [String] that [textRange] matches.
  final String linkString;

  /// Get all [_TextLinkerMatch]s obtained from applying the given
  // `textLinker`s with the given `text`.
  static List<_TextLinkerMatch> fromTextLinkers(Iterable<TextLinker> textLinkers, String text) {
    return textLinkers
        .fold<List<_TextLinkerMatch>>(
          <_TextLinkerMatch>[],
          (List<_TextLinkerMatch> previousValue, TextLinker value) {
            return previousValue..addAll(value._link(text));
        });
  }

  /// Returns a list of [InlineSpan]s representing all of the [text].
  ///
  /// Ranges matched by [textLinkerMatches] are built with their respective
  /// [LinkBuilder], and other text is represented with a simple [TextSpan].
  static (List<InlineSpan>, List<TapGestureRecognizer>) getSpansForMany(Iterable<_TextLinkerMatch> textLinkerMatches, String text) {
    // Sort so that overlapping ranges can be detected and ignored.
    final List<_TextLinkerMatch> textLinkerMatchesList = textLinkerMatches
        .toList()
        ..sort((_TextLinkerMatch a, _TextLinkerMatch b) {
          return a.textRange.start.compareTo(b.textRange.start);
        });

    final List<InlineSpan> spans = <InlineSpan>[];
    final List<TapGestureRecognizer> recognizers = <TapGestureRecognizer>[];
    int index = 0;
    for (final _TextLinkerMatch textLinkerMatch in textLinkerMatchesList) {
      // Ignore overlapping ranges.
      if (index > textLinkerMatch.textRange.start) {
        continue;
      }
      if (index < textLinkerMatch.textRange.start) {
        spans.add(TextSpan(
          text: text.substring(index, textLinkerMatch.textRange.start),
        ));
      }
      final (InlineSpan nextChild, TapGestureRecognizer recognizer) =
          textLinkerMatch.linkBuilder(
            text.substring(
              textLinkerMatch.textRange.start,
              textLinkerMatch.textRange.end,
            ),
            textLinkerMatch.linkString,
          );
      spans.add(nextChild);
      recognizers.add(recognizer);

      index = textLinkerMatch.textRange.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(
        text: text.substring(index),
      ));
    }

    return (spans, recognizers);
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

    final (Iterable<InlineSpan> linkedSpans, Iterable<_TextLinkerMatch> _, Iterable<TapGestureRecognizer> recognizers) =
        _linkSpansRecurse(
          spans,
          textCache,
          textLinkerMatches,
        );

    return _LinkedSpans._(
      linkedSpans: linkedSpans,
      recognizers: recognizers,
    );
  }

  const _LinkedSpans._({
    required this.linkedSpans,
    required this.recognizers,
  });

  final Iterable<InlineSpan> linkedSpans;
  final Iterable<TapGestureRecognizer> recognizers;

  /// Apply the given [TextLinker]s to the given [InlineSpan]s and return the
  /// new resulting spans and any created [TapGestureRecognizer]s.
  ///
  /// {@macro flutter.painting.LinkBuilder.recognizer}
  static (Iterable<InlineSpan>, Iterable<TapGestureRecognizer>) linkSpans(Iterable<InlineSpan> spans, Iterable<TextLinker> textLinkers) {
    // Flatten the spans and store all string lengths, so that matches across
    // span boundaries can be matched in the flat string. This is calculated
    // once in the beginning to avoid recomputing.
    final _TextCache textCache = _TextCache.fromMany(spans: spans);

    final Iterable<_TextLinkerMatch> textLinkerMatches =
        _cleanTextLinkerMatches(
          _TextLinkerMatch.fromTextLinkers(textLinkers, textCache.text),
        );

    final (Iterable<InlineSpan> output, Iterable<_TextLinkerMatch> _, Iterable<TapGestureRecognizer> recognizers) =
        _linkSpansRecurse(
          spans,
          textCache,
          textLinkerMatches,
        );
    return (output, recognizers);
  }

  static List<_TextLinkerMatch> _cleanTextLinkerMatches(Iterable<_TextLinkerMatch> textLinkerMatches) {
    final List<_TextLinkerMatch> nextTextLinkerMatches = textLinkerMatches.toList();

    // Sort by start.
    nextTextLinkerMatches.sort((_TextLinkerMatch a, _TextLinkerMatch b) {
      return a.textRange.start.compareTo(b.textRange.start);
    });

    int lastEnd = 0;
    nextTextLinkerMatches.removeWhere((_TextLinkerMatch textLinkerMatch) {
      // Return empty ranges.
      if (textLinkerMatch.textRange.start == textLinkerMatch.textRange.end) {
        return true;
      }

      // Remove overlapping ranges.
      final bool overlaps = textLinkerMatch.textRange.start < lastEnd;
      if (!overlaps) {
        lastEnd = textLinkerMatch.textRange.end;
      }
      return overlaps;
    });

    return nextTextLinkerMatches;
  }

  // `index` is the index of the start of `span` in the overall flattened tree
  // string.
  //
  // The TapGestureRecognizers are returned so that they can be disposed by an
  // owning widget.
  static (Iterable<InlineSpan>, Iterable<_TextLinkerMatch>, Iterable<TapGestureRecognizer>) _linkSpansRecurse(Iterable<InlineSpan> spans, _TextCache textCache, Iterable<_TextLinkerMatch> textLinkerMatches, [int index = 0]) {
    final List<InlineSpan> output = <InlineSpan>[];
    Iterable<_TextLinkerMatch> nextTextLinkerMatches = textLinkerMatches;
    final List<TapGestureRecognizer> recognizers = <TapGestureRecognizer>[];
    int nextIndex = index;
    for (final InlineSpan span in spans) {
      final (InlineSpan childSpan, Iterable<_TextLinkerMatch> childTextLinkerMatches, Iterable<TapGestureRecognizer> childRecognizers) = _linkSpanRecurse(
        span,
        textCache,
        nextTextLinkerMatches,
        nextIndex,
      );
      output.add(childSpan);
      nextTextLinkerMatches = childTextLinkerMatches;
      recognizers.addAll(childRecognizers);
      nextIndex += textCache.getLength(span)!;
    }

    return (output, nextTextLinkerMatches, recognizers);
  }

  // `index` is the index of the start of `span` in the overall flattened tree
  // string.
  //
  // The TapGestureRecognizers are returned so that they can be disposed by an
  // owning widget.
  static (InlineSpan, Iterable<_TextLinkerMatch>, Iterable<TapGestureRecognizer>) _linkSpanRecurse(InlineSpan span, _TextCache textCache, Iterable<_TextLinkerMatch> textLinkerMatches, [int index = 0]) {
    if (span is! TextSpan) {
      return (span, textLinkerMatches, <TapGestureRecognizer>[]);
    }

    final List<InlineSpan> nextChildren = <InlineSpan>[];
    final List<TapGestureRecognizer> recognizers = <TapGestureRecognizer>[];
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
        final (InlineSpan nextChild, TapGestureRecognizer recognizer) = textLinkerMatch.linkBuilder(
          span.text!.substring(linkStart - index, lastLinkEnd - index),
          textLinkerMatch.linkString,
        );
        nextChildren.add(nextChild);
        recognizers.add(recognizer);
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
        Iterable<TapGestureRecognizer> childrenRecognizers,
      ) = _linkSpansRecurse(
        span.children!,
        textCache,
        nextTextLinkerMatches,
        index + (span.text?.length ?? 0),
      );
      nextTextLinkerMatches = childrenTextLinkerMatches.toList();
      nextChildren.addAll(childrenSpans);
      recognizers.addAll(childrenRecognizers);
    }

    return (
      TextSpan(
        style: span.style,
        children: nextChildren,
      ),
      nextTextLinkerMatches,
      recognizers,
    );
  }

  void dispose() {
    for (final TapGestureRecognizer recognizer in recognizers) {
      recognizer.dispose();
    }
  }
}

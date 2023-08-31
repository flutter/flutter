// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

/// Signature for a callback that passes a [String] representing a link that has
/// been tapped.
typedef LinkTapCallback = void Function(String linkString);

/// Signature for a function that builds an [InlineSpan] link.
///
/// The link displays [displayString] and links to [linkString] when tapped.
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

/// Singature for a function that builds the [Widget] output by [LinkedText].
///
/// Typically a [Text.rich] containing a [TextSpan] whose children are the
/// [linkedSpans].
typedef LinkedTextWidgetBuilder = Widget Function (
  BuildContext context,
  Iterable<InlineSpan> linkedSpans,
);

/// Singature for a function that finds [TextRange]s in the given [String].
typedef TextRangesFinder = Iterable<TextRange> Function(String text);

/// A widget that displays text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive, and clicking one
/// calls the provided callback.
///
/// Works with either a flat [String] (`text`) or a list of [InlineSpan]s
/// (`spans`). When using `spans`, only [TextSpan]s will be converted to links.
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
    this.builder = _defaultBuilder,
    required LinkTapCallback onTap,
    List<InlineSpan>? spans,
    String? text,
  }) : assert((text == null) != (spans == null), 'Must specify exactly one to link: either text or spans.'),
       textLinkers = <TextLinker>[
         TextLinker(
           textRangesFinder: defaultTextRangesFinder,
           linkBuilder: getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  /// Creates an instance of [LinkedText] where text matched by the given
  /// [RegExp] is made interactive.
  ///
  /// The [RegExp] must not produce overlapping matches.
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
    this.builder = _defaultBuilder,
    required LinkTapCallback onTap,
    required RegExp regExp,
    List<InlineSpan>? spans,
    String? text,
  }) : assert((text == null) != (spans == null), 'Must specify exactly one to link: either text or spans.'),
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

  /// Creates an instance of [LinkedText] where the given [textLinkers] are
  /// applied.
  ///
  /// {@template flutter.widgets.LinkedText.textLinkers}
  /// Useful for independently matching different types of strings with
  /// different behaviors. For example, highlighting both URLs and Twitter
  /// handles with different style and/or behavior.
  /// {@endtemplate}
  ///
  /// The [TextLinker.textRangesFinder] must not produce overlapping
  /// [TextRange]s.
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
    this.builder = _defaultBuilder,
    String? text,
    List<InlineSpan>? spans,
    required this.textLinkers,
  }) : assert((text == null) != (spans == null), 'Must specify exactly one to link: either text or spans.'),
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
  /// supported and will produce an error.
  final List<TextLinker> textLinkers;

  /// Builds the [Widget] that is output by [LinkedText].
  ///
  /// By default, builds a [Text.rich] with a single [TextSpan] whose children
  /// are the linked [TextSpan]s, and whose style is [DefaultTextStyle].
  final LinkedTextWidgetBuilder builder;

  /// The default value of [builder].
  ///
  /// Builds a [Text.rich] with a single [TextSpan] whose children are the
  /// linked [TextSpan]s, and whose style is [DefaultTextStyle]. If there are no
  /// linked [TextSpan]s to display, builds a [SizedBox.shrink].
  static Widget _defaultBuilder(BuildContext context, Iterable<InlineSpan> linkedSpans) {
    if (linkedSpans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: linkedSpans.toList(),
      ),
    );
  }

  /// Returns a [LinkBuilder] that highlights the given text and sets the given
  /// [onTap] handler.
  static LinkBuilder getDefaultLinkBuilder(LinkTapCallback onTap) {
    return (String displayString, String linkString) {
      final TapGestureRecognizer recognizer = TapGestureRecognizer()
          ..onTap = () => onTap(linkString);
      return (
        _InlineLinkSpan(
          recognizer: recognizer,
          style: defaultLinkStyle,
          text: displayString,
        ),
        recognizer,
      );
    };
  }

  static Color get _linkColor {
    return switch (defaultTargetPlatform) {
      // This value was taken from Safari on an iPhone 14 Pro iOS 16.4
      // simulator.
      TargetPlatform.iOS => const Color(0xff1717f0),
      // This value was taken from Chrome on macOS 13.4.1.
      TargetPlatform.macOS => const Color(0xff0000ee),
      // This value was taken from Chrome on Android 14.
      TargetPlatform.android || TargetPlatform.fuchsia => const Color(0xff0e0eef),
      // This value was taken from the Chrome browser running on GNOME 43.3 on
      // Debian.
      TargetPlatform.linux => const Color(0xff0026e8),
      // This value was taken from the Edge browser running on Windows 10.
      TargetPlatform.windows => const Color(0xff1e2b8b),
    };
  }

  /// The style used for the link by default if none is given.
  @visibleForTesting
  static TextStyle defaultLinkStyle = TextStyle(
    color: _linkColor,
    decorationColor: _linkColor,
    decoration: TextDecoration.underline,
  );

  /// Applies the given [TextLinker]s to the given [InlineSpan]s and returns the
  /// new resulting spans and any created [TapGestureRecognizer]s.
  ///
  /// The [TextLinker.textRangesFinder]s must not produce any overlapping
  /// [TextRange]s.
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
    return widget.builder(context, _linkedSpans);
  }
}

/// An inline, interactive text link.
///
/// See also:
///
///  * [LinkedText], which creates links with this class by default.
class _InlineLinkSpan extends TextSpan {
  /// Create an instance of [_InlineLinkSpan].
  _InlineLinkSpan({
    required String text,
    TextStyle? style,
    super.locale,
    super.recognizer,
    super.semanticsLabel,
  }) : super(
    style: style ?? defaultLinkStyle,
    mouseCursor: SystemMouseCursors.click,
    text: text,
  );

  static Color get _linkColor {
    return switch (defaultTargetPlatform) {
      // This value was taken from Safari on an iPhone 14 Pro iOS 16.4
      // simulator.
      TargetPlatform.iOS => const Color(0xff1717f0),
      // This value was taken from Chrome on macOS 13.4.1.
      TargetPlatform.macOS => const Color(0xff0000ee),
      // This value was taken from Chrome on Android 14.
      TargetPlatform.android || TargetPlatform.fuchsia => const Color(0xff0e0eef),
      // This value was taken from the Chrome browser running on GNOME 43.3 on
      // Debian.
      TargetPlatform.linux => const Color(0xff0026e8),
      // This value was taken from the Edge browser running on Windows 10.
      TargetPlatform.windows => const Color(0xff1e2b8b),
    };
  }

  /// The style used for the link by default if none is given.
  @visibleForTesting
  static TextStyle defaultLinkStyle = TextStyle(
    color: _linkColor,
    decorationColor: _linkColor,
    decoration: TextDecoration.underline,
  );
}

/// Specifies a way to find and style parts of a [String].
///
/// Calling [getSpans] with a [String] produces a [List] of [InlineSpan]s where
/// the parts of the [String] matched by [textRangesFinder] have been turned
/// into links using [linkBuilder].
///
/// [textRangesFinder] must not produce overlapping [TextRange]s.
class TextLinker {
  /// Creates an instance of [TextLinker].
  const TextLinker({
    required this.textRangesFinder,
    required this.linkBuilder,
  });

  /// Builds an [InlineSpan] to display the text that it's passed.
  final LinkBuilder linkBuilder;

  /// Returns [TextRange]s that should be built with [linkBuilder].
  ///
  /// Throws if overlapping [TextRange]s are produced.
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

/// A matched replacement on some string.
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

/// Signature for the output of linking an InlineSpan to some
/// _TextLinkerMatches.
typedef _LinkSpanRecursion = (
  /// The output of linking the input InlineSpan.
  InlineSpan linkedSpan,
  /// The provided _TextLinkerMatches, but with those completely used during
  /// linking removed.
  Iterable<_TextLinkerMatch> unusedTextLinkerMatches,
  /// The TapGestureRecognizers produced when each link is created. These need
  /// to be disposed by a widget when no longer needed.
  Iterable<TapGestureRecognizer> generatedRecognizers,
);

/// Signature for the output of linking a List of InlineSpans to some
/// _TextLinkerMatches.
typedef _LinkSpansRecursion = (
  /// The output of linking the input InlineSpans.
  Iterable<InlineSpan> linkedSpans,
  /// The provided _TextLinkerMatches, but with those completely used during
  /// linking removed.
  Iterable<_TextLinkerMatch> unusedTextLinkerMatches,
  /// The TapGestureRecognizers produced when each link is created. These need
  /// to be disposed by a widget when no longer needed.
  Iterable<TapGestureRecognizer> generatedRecognizers,
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
  //
  // The TapGestureRecognizers are returned so that they can be disposed by an
  // owning widget.
  static _LinkSpansRecursion _linkSpansRecurse(Iterable<InlineSpan> spans, _TextCache textCache, Iterable<_TextLinkerMatch> textLinkerMatches, [int index = 0]) {
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
  static _LinkSpanRecursion _linkSpanRecurse(InlineSpan span, _TextCache textCache, Iterable<_TextLinkerMatch> textLinkerMatches, [int index = 0]) {
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

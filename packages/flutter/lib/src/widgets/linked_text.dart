// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

/// A widget that displays text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive, and clicking one
/// calls [onTap].
///
/// Works with either a flat [String] ([text]) or a list of [InlineSpans]
/// ([spans]).
///
/// See also:
///
///  * [InlineLinkedText], which is like this but is an inline TextSpan instead
///    of a widget.
class LinkedText extends StatelessWidget {
  /// Creates an instance of [LinkedText] from the given [text] or [spans],
  /// highlighting any URLs by default.
  ///
  /// {@template flutter.widgets.LinkedText.new}
  /// By default, highlights URLs in the [text] or [spans] and makes them
  /// tappable with [onTap].
  ///
  /// If [ranges] is given, then makes those ranges in the text interactive
  /// instead of URLs.
  ///
  /// [linkBuilder] can be used to specify a custom [InlineSpan] for each
  /// [TextRange] in [ranges].
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [LinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  ///  * [InlineLinkedText.new], which is like this, but for inline text.
  LinkedText({
    super.key,
    String? text,
    List<InlineSpan>? spans,
    this.style,
    Iterable<TextRange>? ranges,
    LinkTapCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: ranges == null
               ? InlineLinkedText.defaultRangesFinder
               : (String text) => ranges,
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
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
  /// See also:
  ///
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [LinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  ///  * [InlineLinkedText.regExp], which is like this, but for inline text.
  LinkedText.regExp({
    super.key,
    String? text,
    List<InlineSpan>? spans,
    required RegExp regExp,
    this.style,
    LinkTapCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: TextLinker.rangesFinderFromRegExp(regExp),
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
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
  /// {@template flutter.widgets.LinkedText.textLinkers}
  /// Useful for independently matching different types of strings with
  /// different behaviors. For example, highlighting both URLs and Twitter
  /// handles with different style and/or behavior.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [LinkedText.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [LinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [InlineLinkedText.textLinkers], which is like this, but for inline
  ///    text.
  LinkedText.textLinkers({
    super.key,
    String? text,
    List<InlineSpan>? spans,
    required this.textLinkers,
    this.style,
  }) : assert(text != null || spans != null, 'Must specify something to link: either text or spans.'),
       assert(text == null || spans == null, 'Pass one of spans or text, not both.'),
       spans = spans ?? <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ],
       assert(textLinkers.isNotEmpty);

  /// The spans on which to create links by applying [textLinkers].
  final List<InlineSpan> spans;

  /// Defines what parts of the text to match and how to link them.
  ///
  /// [TextLinker]s are applied in the order given. Overlapping matches are not
  /// supported.
  final List<TextLinker> textLinkers;

  /// The [TextStyle] to apply to the output [InlineSpan].
  ///
  /// If not provided, the [DefaultTextStyle] at this point in the tree will be
  /// used.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text.rich(
      InlineLinkedText.textLinkers(
        style: style ?? DefaultTextStyle.of(context).style,
        textLinkers: textLinkers,
        spans: spans,
      ),
    );
  }
}

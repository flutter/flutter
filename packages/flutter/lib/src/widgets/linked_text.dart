// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

// TODO(justinmc): On some platforms, may want to underline link?

// TODO(justinmc): Change name to something link-agnostic?
/// A widget that displays text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive, and clicking one
/// calls [onTap].
///
/// See also:
///
///  * [InlineLinkedText], which is like this but is an inline TextSpan instead
///    of a widget.
class LinkedText extends StatelessWidget {
  /// Creates an instance of [LinkedText] from the given [text], highlighting
  /// any URLs by default.
  ///
  /// {@template flutter.widgets.LinkedText.new}
  /// By default, highlights URLs in the [text] and makes them tappable with
  /// [onTap].
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
    required String text,
    this.style,
    Iterable<TextRange>? ranges,
    UriStringCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: ranges == null
               ? TextLinker.urlRangesFinder
               : (String text) => ranges,
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = <InlineSpan>[
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
    required String text,
    required RegExp regExp,
    this.style,
    UriStringCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: TextLinker.rangesFinderFromRegExp(regExp),
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ],
       spans = <InlineSpan>[
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
    required String text,
    required this.textLinkers,
    this.style,
  }) : spans = <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ],
       assert(textLinkers.isNotEmpty);

  // TODO(justinmc): I need ways to take RegExp, etc. like other constructors, too.
  // TODO(justinmc): Should this take a single span instead of a list? If you
  // did want to linkify a list, you could wrap them in a single TextSpan.
  LinkedText.spans({
    super.key,
    required this.spans,
    UriStringCallback? onTap,
    this.style,
  }) : textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: TextLinker.urlRangesFinder,
           linkBuilder: InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ];

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

  static List<TextLinker> _getDefaultTextLinkers(UriStringCallback? onTap) {
    return <TextLinker>[
      TextLinker(
        rangesFinder: TextLinker.urlRangesFinder,
        linkBuilder: InlineLinkedText.getDefaultLinkBuilder(onTap),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (spans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text.rich(
      InlineLinkedText.spans(
        style: style ?? DefaultTextStyle.of(context).style,
        textLinkers: textLinkers,
        spans: spans,
      ),
    );
  }
}

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text.dart';
import 'widget_span.dart';

/// A callback that passes a [String] representing a URL.
typedef UriStringCallback = void Function(String urlString);

/// Builds an InlineSpan for displaying [linkText].
///
/// If tappable, then uses the [onTap] handler.
///
/// Typically used for styling a link in some inline text.
typedef LinkBuilder = InlineSpan Function(
  String linkText,
  UriStringCallback? onTap,
);

// TODO(justinmc): Change name to something link-agnostic?
// TODO(justinmc): Add regexp parameter. No, builder? Both?
/// A widget that displays some text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive.
class LinkedText extends StatelessWidget {
  const LinkedText({
    super.key,
    this.onTap,
    required this.text,
  });

  final UriStringCallback? onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: InlineLinkedText(
        onTap: onTap,
        style: DefaultTextStyle.of(context).style,
        text: text,
      ),
    );
  }
}

// TODO(justinmc): Make agnostic to URLs, just "links", which could be GitHub PRs, etc.
/// A [TextSpan] that makes parts of the [text] interactive.
class InlineLinkedText extends TextSpan {
  // TODO(justinmc): Need to support multiple simultaneous types of links. For
  // example, URLs are blue and do one thing, Twitter handles are red and do another.
  /// Create an instance of [InlineLinkedText].
  ///
  /// If [ranges] is given, then makes the text indicated by that interactive.
  ///
  /// Otherwise, finds URLs in the text and makes them interactive.
  InlineLinkedText({
    super.style,
    required String text,
    Iterable<TextRange>? ranges,
    UriStringCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : super(
         children: _spansFromRanges(
           text: text,
           linkBuilder: linkBuilder,
           onTap: onTap,
           ranges: ranges ?? _rangesFromText(
             text: text,
             regExp: _urlRegExp,
           ),
         ),
       );

  /// Create an instance of [InlineLinkedText] where the text matched by the
  /// given [regExp] is made interactive.
  ///
  /// By default, [regExp] matches URLs.
  ///
  /// See also:
  ///
  ///  * [InlineLinkifier.new], which can be passed [TextRange]s directly.
  InlineLinkedText.regExp({
    super.style,
    required String text,
    UriStringCallback ? onTap,
    LinkBuilder? linkBuilder,
    RegExp? regExp,
  }) : super(
         children: _spansFromRanges(
           text: text,
           linkBuilder: linkBuilder,
           onTap: onTap,
           ranges: _rangesFromText(
             text: text,
             regExp: regExp ?? _urlRegExp,
           ),
         ),
       );

  // TODO(justinmc): Consider revising this regexp.
  static final RegExp _urlRegExp = RegExp(r'((http|https|ftp):\/\/)?([a-zA-Z\-]*\.)?[a-zA-Z0-9\-]*\.[a-zA-Z]*');

  static InlineSpan _defaultLinkBuilder(String linkText, UriStringCallback? onTap) {
    return _InlineLink(
      onTap: onTap,
      text: linkText,
    );
  }

  // Turns all matches from the regExp into a list of TextRanges, allowing
  // compatibility with _spansFromRanges.
  static Iterable<TextRange> _rangesFromText({
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

  // Highlights the text in the given `ranges` and makes them interactive.
  static List<InlineSpan> _spansFromRanges({
    required String text,
    required Iterable<TextRange> ranges,
    LinkBuilder? linkBuilder = _defaultLinkBuilder,
    UriStringCallback? onTap,
  }) {
    // Sort ranges to facilitate ignoring overlapping ranges.
    final List<TextRange> rangesList = ranges.toList()
        ..sort((TextRange a, TextRange b) => a.start.compareTo(b.start));

    final List<InlineSpan> spans = <InlineSpan>[];
    int index = 0;
    for (final TextRange range in rangesList) {
      // Ignore overlapping ranges.
      if (index > range.start) {
        continue;
      }
      if (index < range.start) {
        spans.add(TextSpan(
          text: text.substring(index, range.start),
        ));
      }
      // TODO(justinmc): Allow custom style if don't pass whole builder fn.
      spans.add(linkBuilder!(
        text.substring(range.start, range.end),
        onTap,
      ));
      spans.add(_InlineLink(
        onTap: onTap,
        text: text.substring(range.start, range.end),
      ));

      index = range.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(
        text: text.substring(index),
      ));
    }

    return spans;
  }
}

class _InlineLink extends WidgetSpan {
  _InlineLink({
    required String text,
    // TODO(justinmc): Include these super parameters?
    /*
    super.alignment,
    super.baseline,
    super.style,
    */
    UriStringCallback? onTap,
  }) : super(
    child: _TextLink(
      uriString: text,
      onTap: onTap,
    ),
  );
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.uriString,
    this.onTap,
  });

  final UriStringCallback? onTap;
  final String uriString;

  void _onTap() {
    if (onTap == null) {
      return;
    }
    return onTap!(uriString);
  }

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): Semantics.
    return GestureDetector(
      onTap: _onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          uriString,
          style: const TextStyle(
            // TODO(justinmc): Correct color per-platform. Get it from Theme in
            // Material somehow?
            color: Color(0xff0000ff),
          ),
        ),
      ),
    );
  }
}

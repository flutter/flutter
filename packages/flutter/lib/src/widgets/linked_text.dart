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
  // TODO(justinmc): Rename to LinkCallback?
  //UriStringCallback? onTap
);

// TODO(justinmc): Change name to something link-agnostic?
// TODO(justinmc): Add regexp parameter. No, builder? Both?
/// A widget that displays some text with parts of it made interactive.
///
/// By default, any URLs in the text are made interactive.
class LinkedText extends StatelessWidget {
  /// Creates an instance of [LinkedText] from the given [text], highlighting
  /// any URLs by default.
  const LinkedText({
    super.key,
    this.onTap,
    required this.text,
  });

  /// Called whenever a link in the [text] is tapped.
  final UriStringCallback? onTap;

  /// The text in which to highlight URLs and to display.
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

/// Finds [TextRange]s in the given [String].
typedef RangesFinder = Iterable<TextRange> Function(String text);

class _TextLinkerSingle {
  const _TextLinkerSingle({
    required this.textRange,
    required this.linkBuilder,
  });

  final LinkBuilder linkBuilder;
  final TextRange textRange;

  InlineSpan getSpan(String text) {
    return linkBuilder(
      text.substring(textRange.start, textRange.end),
    );
  }

  /// Returns a list of [InlineSpan]s representing all of the [text].
  ///
  /// Ranges matched by [textLinkerSingles] are built with their respective
  /// [LinkBuilder], and other text is represented with a simple [TextSpan].
  static List<InlineSpan> getSpansForMany(Iterable<_TextLinkerSingle> textLinkerSingles, String text) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int index = 0;
    for (final _TextLinkerSingle textLinkerSingle in textLinkerSingles) {
      // Ignore overlapping ranges.
      if (index > textLinkerSingle.textRange.start) {
        continue;
      }
      if (index < textLinkerSingle.textRange.start) {
        spans.add(TextSpan(
          text: text.substring(index, textLinkerSingle.textRange.start),
        ));
      }
      spans.add(textLinkerSingle.linkBuilder(
        text.substring(
          textLinkerSingle.textRange.start,
          textLinkerSingle.textRange.end,
        ),
      ));

      index = textLinkerSingle.textRange.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(
        text: text.substring(index),
      ));
    }

    return spans;
  }
}

// TODO(justinmc): Think about which links need to go here vs. on InlineTextLinker.
/// Specifies a way to find and style parts of a String.
class TextLinker {
  /// Creates an instance of [TextLinker].
  const TextLinker({
    // TODO(justinmc): Change "range" naming to always be "textRange"?
    required this.rangesFinder,
    required this.linkBuilder,
  });

  /// Builds an [InlineSpan] to display the text that it's passed.
  final LinkBuilder linkBuilder;

  /// Returns [TextRange]s that should be built with [linkBuilder].
  final RangesFinder rangesFinder;

  // TODO(justinmc): Consider revising this regexp.
  static final RegExp _urlRegExp = RegExp(r'((http|https|ftp):\/\/)?([a-zA-Z\-]*\.)?[a-zA-Z0-9\-]*\.[a-zA-Z]*');

  // Turns all matches from the regExp into a list of TextRanges.
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

  /// Returns a flat list of [InlineSpan]s for multiple [TextLinker]s.
  ///
  /// Similar to [getSpans], but for multiple [TextLinker]s instead of just one.
  static List<InlineSpan> getSpansForMany(Iterable<TextLinker> textLinkers, String text) {
    final List<_TextLinkerSingle> combinedRanges = textLinkers
        .fold<List<_TextLinkerSingle>>(
          <_TextLinkerSingle>[],
          (List<_TextLinkerSingle> previousValue, TextLinker value) {
            final Iterable<TextRange> ranges = value.rangesFinder(text);
            for (final TextRange range in ranges) {
              previousValue.add(_TextLinkerSingle(
                textRange: range,
                linkBuilder: value.linkBuilder,
              ));
            }
            return previousValue;
        });

    return _TextLinkerSingle.getSpansForMany(combinedRanges, text);
  }

  /// Creates a [RangesFinder] that finds all the matches of the given [RegExp].
  static RangesFinder rangesFinderFromRegExp(RegExp regExp) {
    return (String text) {
      return _rangesFromText(
        text: text,
        regExp: _urlRegExp,
      );
    };
  }

  /// A [RangesFinder] that returns [TextRange]s for URLs.
  static final RangesFinder urlRangesFinder = rangesFinderFromRegExp(_urlRegExp);

  /// Builds the [InlineSpan]s for the given text.
  ///
  /// Builds [linkBuilder] for any ranges found by [rangesFinder]. All other
  /// text is presented in a plain [TextSpan].
  List<InlineSpan> getSpans(String text) {
    final Iterable<TextRange> textRanges = rangesFinder(text);
    final Iterable<_TextLinkerSingle> textLinkerSingles = textRanges.map((TextRange textRange) {
      return _TextLinkerSingle(
        textRange: textRange,
        linkBuilder: linkBuilder,
      );
    });
    return _TextLinkerSingle.getSpansForMany(textLinkerSingles, text);
  }
}

// TODO(justinmc): Make agnostic to URLs, just "links", which could be GitHub PRs, etc.
/// A [TextSpan] that makes parts of the [text] interactive.
class InlineLinkedText extends TextSpan {
  /// Create an instance of [InlineLinkedText].
  ///
  /// By default, highlights URLs in the [text] and makes them tappable with
  /// [onTap].
  ///
  /// If [ranges] is given, then makes those ranges in the text interactive
  /// instead of URLs.
  ///
  /// [linkBuilder] can be used to specify a custom [InlineSpan] for each
  /// [TextRange] in [ranges].
  ///
  /// See also:
  ///
  ///  * [InlineLinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  ///  * [InlineLinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  InlineLinkedText({
    super.style,
    required String text,
    Iterable<TextRange>? ranges,
    UriStringCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : super(
         children: TextLinker(
           rangesFinder: ranges == null
               ? TextLinker.urlRangesFinder
               : (String text) => ranges,
           linkBuilder: linkBuilder ?? getDefaultLinkBuilder(onTap),
         ).getSpans(text),
       );

  /// Create an instance of [InlineLinkedText] where the text matched by the
  /// given [regExp] is made interactive.
  ///
  /// See also:
  ///
  ///  * [InlineLinkifier.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [InlineLinkedText.textLinkers], which uses [TextLinker]s to allow
  ///    specifying an arbitrary number of [ranges] and [linkBuilders].
  InlineLinkedText.regExp({
    super.style,
    required RegExp regExp,
    required String text,
    UriStringCallback? onTap,
    LinkBuilder? linkBuilder,
  }) : super(
         children: TextLinker(
           rangesFinder: TextLinker.rangesFinderFromRegExp(regExp),
           linkBuilder: linkBuilder ?? getDefaultLinkBuilder(onTap),
         ).getSpans(text),
       );

  /// Create an instance of [InlineLinkedText] where
  ///
  /// Useful for independently matching different types of strings with
  /// different behaviors. For example, highlighting both URLs and Twitter
  /// handles with different style and/or behavior.
  ///
  /// See also:
  ///
  ///  * [InlineLinkifier.new], which can be passed [TextRange]s directly or
  ///    otherwise matches URLs by default.
  ///  * [InlineLinkedText.regExp], which automatically finds ranges that match
  ///    the given [RegExp].
  InlineLinkedText.textLinkers({
    super.style,
    required String text,
    required Iterable<TextLinker> textLinkers,
  }) : super(
         children: TextLinker.getSpansForMany(textLinkers, text),
       );

  /// Returns a [LinkBuilder] that simply highlights the given text and provides
  /// an [onTap] handler.
  static LinkBuilder getDefaultLinkBuilder([UriStringCallback? onTap]) {
    return (String linkText) {
      return _InlineLink(
        onTap: onTap,
        text: linkText,
      );
    };
  }
}

/// An inline text link.
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

/// A text link widget that can be displayed inline with [WidgetSpan].
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

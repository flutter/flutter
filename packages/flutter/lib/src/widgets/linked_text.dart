import 'dart:math' as math;

import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text.dart';
import 'widget_span.dart';

// TODO(justinmc): Add SelectableArea to the examples.

// TODO(justinmc): On some platforms, may want to underline link?

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
  }) : onTap = null,
       textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: ranges == null
               ? TextLinker.urlRangesFinder
               : (String text) => ranges,
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ],
       children = <InlineSpan>[
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
  }) : onTap = null,
       textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: TextLinker.rangesFinderFromRegExp(regExp),
           linkBuilder: linkBuilder ?? InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ],
       children = <InlineSpan>[
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
  }) : onTap = null,
       children = <InlineSpan>[
         TextSpan(
           text: text,
         ),
       ];

  // TODO(justinmc): Should this take a single span instead of a list? If you
  // did want to linkify a list, you could wrap then in a single TextSpan.
  LinkedText.spans({
    super.key,
    required this.children,
    //required this.textLinkers,
    this.style,
    this.onTap,
  }) : textLinkers = <TextLinker>[];

  final List<InlineSpan> children;

  /// The text in which to highlight URLs and to display.
  //final String text;

  final List<TextLinker> textLinkers;

  final TextStyle? style;
  final UriStringCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return RichText(
      text: TextSpan(
        style: style,
        children: linkSpans(TextLinker.urlRangesFinder, children, onTap).toList(),
      ),
    );
    /*
    return RichText(
      text: InlineLinkedText.textLinkers(
        style: style ?? DefaultTextStyle.of(context).style,
        text: text,
        textLinkers: textLinkers,
      ),
    );
    */
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
    // Sort so that overlapping ranges can be detected and ignored.
    final List<_TextLinkerSingle> textLinkerSinglesList = textLinkerSingles
        .toList()
        ..sort((_TextLinkerSingle a, _TextLinkerSingle b) {
          return a.textRange.start.compareTo(b.textRange.start);
        });

    final List<InlineSpan> spans = <InlineSpan>[];
    int index = 0;
    for (final _TextLinkerSingle textLinkerSingle in textLinkerSinglesList) {
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

  @override
  String toString() {
    return '_TextLinkerSingle $textRange, $linkBuilder';
  }
}

// TODO(justinmc): This isn't ideal for linking arbitrary text to arbitrary urls.
// That's probably ok; the best way to do that is just with a TextSpan tree, in
// which case you don't need to linkify it.
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

  // TODO(justinmc): Is it possible to enforce this order by TextRange.start, or should I just assume it's unordered?
  /// Returns [TextRange]s that should be built with [linkBuilder].
  final RangesFinder rangesFinder;

  static final RegExp _urlRegExp = RegExp(r'(((https?:\/\/)(([a-zA-Z0-9\-]*\.)*[a-zA-Z0-9\-]+(\.[a-zA-Z]+)+))|((?<!\/|\.|[a-zA-Z0-9\-])((([a-zA-Z0-9\-]*\.)*[a-zA-Z0-9\-]+(\.[a-zA-Z]+)+))))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?');

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
        regExp: regExp,
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

  @override
  String toString() {
    return 'TextLinker $rangesFinder, $linkBuilder';
  }
}

// TODO(justinmc): Make naming agnostic to URLs, just "links", which could be GitHub PRs, etc.
/// A [TextSpan] that makes parts of the [text] interactive.
class InlineLinkedText extends TextSpan {
  /// Create an instance of [InlineLinkedText].
  ///
  /// {@macro flutter.widgets.LinkedText.new}
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
  ///  * [InlineLinkedText.new], which can be passed [TextRange]s directly or
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
  /// {@macro flutter.widgets.LinkedText.textLinkers}
  ///
  /// See also:
  ///
  ///  * [InlineLinkedText.new], which can be passed [TextRange]s directly or
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
      return InlineLink(
        onTap: () => onTap?.call(linkText),
        text: linkText,
      );
    };
  }
}

/// An inline text link.
class InlineLink extends TextSpan {
  /// Create an instance of [InlineLink].
  InlineLink({
    required String text,
    super.locale,
    // TODO(justinmc): I probably need to identify this as a link in semantics somehow?
    super.semanticsLabel,
    TextStyle style = const TextStyle(
      // TODO(justinmc): Correct color per-platform. Get it from Theme in
      // Material somehow?
      // And decide underline or no per-platform.
      color: Color(0xff0000ff),
      decoration: TextDecoration.underline,
    ),
    VoidCallback? onTap,
  }) : super(
    style: style,
    mouseCursor: SystemMouseCursors.click,
    text: text,
    recognizer: onTap == null ? null : (TapGestureRecognizer()..onTap = onTap),
  );
}

Iterable<(TextRange, String)> _getRanges(RangesFinder rangesFinder, String text) {
  final Iterable<TextRange> ranges = _cleanRanges(rangesFinder(text));

  return ranges.map((TextRange range) {
    return (range, text.substring(range.start, range.end));
  });
}

List<TextRange> _cleanRanges(Iterable<TextRange> ranges) {
  final List<TextRange> nextRanges = ranges.toList();

  // Sort by start.
  nextRanges.sort((TextRange a, TextRange b) {
    return a.start.compareTo(b.start);
  });

  // Remove overlapping ranges.
  int lastEnd = 0;
  nextRanges.removeWhere((TextRange range) {
    final bool overlaps = range.start < lastEnd;
    if (!overlaps) {
      lastEnd = range.end;
    }
    return overlaps;
  });

  return nextRanges;
}

Iterable<InlineSpan> linkSpans(RangesFinder rangesFinder, Iterable<InlineSpan> spans, UriStringCallback? onTap) {
  // Flatten the spans and find all ranges in the flat String. This must be done
  // cumulatively, and not during a traversal, because matches may occur across
  // span boundaries.
  final String spansText = spans.fold<String>('', (String value, InlineSpan span) {
    return value + span.toPlainText();
  });
  final Iterable<(TextRange, String)> ranges = _getRanges(rangesFinder, spansText);

  final (Iterable<InlineSpan> output, _) =
      _linkSpansRecurse(spans, ranges, 0, onTap);
  return output;
}

(Iterable<InlineSpan>, Iterable<(TextRange, String)>) _linkSpansRecurse(Iterable<InlineSpan> spans, Iterable<(TextRange, String)> ranges, int index, UriStringCallback? onTap) {
  final List<InlineSpan> output = <InlineSpan>[];
  Iterable<(TextRange, String)> nextRanges = ranges;
  int nextIndex = index;
  for (final InlineSpan span in spans) {
    final (InlineSpan childSpan, Iterable<(TextRange, String)> childRanges) = _linkSpanRecurse(
      span,
      nextRanges,
      nextIndex,
      onTap,
    );
    output.add(childSpan);
    nextRanges = childRanges;
    nextIndex += span.toPlainText().length; // TODO(justinmc): Performance? Maybe you could return the index rather than recalculating it?
  }

  return (output, nextRanges);
}

// index is the index of the start of `span` in the overall tree.
(InlineSpan, Iterable<(TextRange, String)>) _linkSpanRecurse(InlineSpan span, Iterable<(TextRange, String)> ranges, int index, UriStringCallback? onTap) {
  print('\n\njustin _linkSpanRecurse with index $index, ranges $ranges.');
  if (span is! TextSpan) {
    // TODO(justinmc): Should actually remove span from ranges here.
    return (span, ranges);
  }

  final TextSpan nextTree = TextSpan(
    style: span.style,
    children: <InlineSpan>[],
  );
  List<(TextRange, String)> nextRanges = <(TextRange, String)>[...ranges];
  int lastLinkEnd = index;
  if (span.text?.isNotEmpty ?? false) {
    final int textEnd = index + span.text!.length;
    for (final (TextRange range, String rangeText) in ranges) {
      if (range.start >= textEnd) {
        // Because ranges is ordered, there are no more relevant ranges for this
        // text.
        break;
      }
      if (range.end <= index) {
        // This range ends before this span and is therefore irrelevant to it.
        // It should have been removed from ranges.
        assert(false, 'Invalid ranges.');
        nextRanges.removeAt(0);
        continue;
      }
      if (range.start > index) {
        // Add the unlinked text before the range.
        nextTree.children!.add(TextSpan(
          text: span.text!.substring(
            lastLinkEnd - index,
            range.start - index,
          ),
        ));
        print('justin added to tree (plain text): |${nextTree.children!.last.toPlainText()}|');
      }
      // Add the link itself.
      final int linkStart = math.max(range.start, index);
      lastLinkEnd = math.min(range.end, textEnd);
      // TODO(justinmc): So partially styled links work by separately linking
      // two different TextSpans. Is that ok for things like Semantics?
      nextTree.children!.add(InlineLink(
        onTap: () => onTap?.call(rangeText),
        text: span.text!.substring(linkStart - index, lastLinkEnd - index),
      ));
      print('justin added to tree (link): |${nextTree.children!.last.toPlainText()}|');
      if (range.end > textEnd) {
        // If we only partially used this range, keep it in nextRanges. Since
        // overlapping ranges have been removed, this must be the last relevant
        // range for this span.
        break;
      }
      nextRanges.removeAt(0);
    }

    // Add any extra text after any ranges.
    final String remainingText = span.text!.substring(lastLinkEnd - index);
    if (remainingText.isNotEmpty) {
      nextTree.children!.add(TextSpan(
        text: remainingText,
      ));
      print('justin added to tree (plain text at end of ranges): |${nextTree.children!.last.toPlainText()}|');
    }
  }

  // Recurse on the children.
  if (span.children?.isNotEmpty ?? false) {
    final (
      Iterable<InlineSpan> childrenSpans,
      Iterable<(TextRange, String)> childrenRanges,
    ) = _linkSpansRecurse(
      span.children!,
      nextRanges,
      index + (span.text?.length ?? 0),
      onTap,
    );
    nextRanges = childrenRanges.toList();
    nextTree.children!.addAll(childrenSpans);
  }

  return (nextTree, nextRanges);
}

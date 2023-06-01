import 'dart:math' as math;

import 'package:flutter/gestures.dart';

import 'basic.dart';
import 'framework.dart';
import 'text.dart';

// TODO(justinmc): On some platforms, may want to underline link?

/// A callback that passes a [String] representing a URL.
typedef UriStringCallback = void Function(String urlString);

/// Builds an InlineSpan for displaying [linkText].
///
/// If tappable, then uses the [onTap] handler.
///
/// Typically used for styling a link in some inline text.
typedef LinkBuilder = InlineSpan Function(
  String displayText,
  String linkText,
  // TODO(justinmc): Rename to LinkCallback?
  //UriStringCallback? onTap
);

// TODO(justinmc): Change name to something link-agnostic?
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
  // did want to linkify a list, you could wrap then in a single TextSpan.
  LinkedText.spans({
    super.key,
    // TODO(justinmc): This is a bad name since it seems like it would take widgets. RichText uses `text` for one. Maybe `spans`?
    required this.spans,
    UriStringCallback? onTap,
    this.style,
  }) : textLinkers = <TextLinker>[
         TextLinker(
           rangesFinder: TextLinker.urlRangesFinder,
           linkBuilder: InlineLinkedText.getDefaultLinkBuilder(onTap),
         ),
       ];

  final List<InlineSpan> spans;

  /// Defines what parts of the text to match and how to link them.
  ///
  /// [TextLinker]s are applied in the order given. Overlapping matches are not
  /// supported.
  final List<TextLinker> textLinkers;

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
    /*
    return Text.rich(
      TextSpan(
        style: style,
        children: linkSpans(TextLinker.urlRangesFinder, spans, onTap).toList(),
      ),
    );
    */
    return Text.rich(
      InlineLinkedText.spans(
        style: style ?? DefaultTextStyle.of(context).style,
        textLinkers: textLinkers,
        spans: spans,
      ),
    );
    /*
    return Text.rich(
      InlineLinkedText.textLinkers(
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

// TODO(justinmc): _TextLinked, because it's a TextLinker that has been applied to some text? Sounds too much like LinkedText...
class _TextLinkerSingle {
  _TextLinkerSingle({
    required this.textRange,
    required this.linkBuilder,
    required this.matchedString,
  }) : assert(textRange.end - textRange.start == matchedString.length);

  final LinkBuilder linkBuilder;
  final TextRange textRange;

  /// The [String] that [textRange] matches.
  final String matchedString;

  /// Get all [_TextLinkerSingle]s obtained from applying the given
  // `textLinker`s with the given `text`.
  static List<_TextLinkerSingle> fromTextLinkers(Iterable<TextLinker> textLinkers, String text) {
    return textLinkers
        .fold<List<_TextLinkerSingle>>(
          <_TextLinkerSingle>[],
          (List<_TextLinkerSingle> previousValue, TextLinker value) {
            return previousValue..addAll(value._link(text));
        });
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
        textLinkerSingle.matchedString,
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
    return '_TextLinkerSingle $textRange, $linkBuilder, $matchedString';
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

  /// Matches full (https://www.example.com/?q=1) and shortened (example.com)
  /// URLs.
  ///
  /// Excludes:
  ///
  ///   * URLs with any protocol other than http or https.
  ///   * Email addresses.
  static final RegExp _urlRegExp = RegExp(r'(?<!@[a-zA-Z0-9-]*)(?<![\/\.a-zA-Z0-9-])((https?:\/\/)?(([a-zA-Z0-9-]*\.)*[a-zA-Z0-9-]+(\.[a-zA-Z]+)+))(?::\d{1,5})?(?:\/[^\s]*)?(?:\?[^\s#]*)?(?:#[^\s]*)?(?![a-zA-Z0-9-]*@)');

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
                matchedString: text.substring(range.start, range.end),
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

  /// Apply this [TextLinker] to a [String].
  Iterable<_TextLinkerSingle> _link(String text) {
    final Iterable<TextRange> textRanges = rangesFinder(text);
    return textRanges.map((TextRange textRange) {
      return _TextLinkerSingle(
        textRange: textRange,
        linkBuilder: linkBuilder,
        matchedString: text.substring(textRange.start, textRange.end),
      );
    });
  }

  /// Builds the [InlineSpan]s for the given text.
  ///
  /// Builds [linkBuilder] for any ranges found by [rangesFinder]. All other
  /// text is presented in a plain [TextSpan].
  List<InlineSpan> getSpans(String text) {
    final Iterable<_TextLinkerSingle> textLinkerSingles = _link(text);
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

  /// Create an instance of [InlineLinkedText] with the given [textLinkers]
  /// applied.
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

  // TODO(justinmc): Docs.
  InlineLinkedText.spans({
    super.style,
    required List<InlineSpan> spans,
    required Iterable<TextLinker> textLinkers,
  }) : super(
         children: linkSpans(spans, textLinkers).toList(),
       );

  /// Returns a [LinkBuilder] that simply highlights the given text and provides
  /// an [onTap] handler.
  static LinkBuilder getDefaultLinkBuilder([UriStringCallback? onTap]) {
    return (String displayText, String linkText) {
      return InlineLink(
        onTap: () => onTap?.call(linkText),
        text: displayText,
      );
    };
  }

  static List<_TextLinkerSingle> _cleanTextLinkerSingles(Iterable<_TextLinkerSingle> textLinkerSingles) {
    final List<_TextLinkerSingle> nextTextLinkerSingles = textLinkerSingles.toList();

    // Sort by start.
    nextTextLinkerSingles.sort((_TextLinkerSingle a, _TextLinkerSingle b) {
      return a.textRange.start.compareTo(b.textRange.start);
    });

    int lastEnd = 0;
    nextTextLinkerSingles.removeWhere((_TextLinkerSingle textLinkerSingle) {
      // Return empty ranges.
      if (textLinkerSingle.textRange.start == textLinkerSingle.textRange.end) {
        return true;
      }

      // Remove overlapping ranges.
      final bool overlaps = textLinkerSingle.textRange.start < lastEnd;
      if (!overlaps) {
        lastEnd = textLinkerSingle.textRange.end;
      }
      return overlaps;
    });

    return nextTextLinkerSingles;
  }

  /// Apply the given `textLinker`s to the given `spans` and return the new
  /// resulting spans.
  static Iterable<InlineSpan> linkSpans(Iterable<InlineSpan> spans, Iterable<TextLinker> textLinkers) {
    // Flatten the spans and find all ranges in the flat String. This must be done
    // cumulatively, and not during a traversal, because matches may occur across
    // span boundaries.
    final String spansText = spans.fold<String>('', (String value, InlineSpan span) {
      return value + span.toPlainText();
    });
    final Iterable<_TextLinkerSingle> textLinkerSingles =
        _cleanTextLinkerSingles(
          _TextLinkerSingle.fromTextLinkers(textLinkers, spansText),
        );

    final (Iterable<InlineSpan> output, _) =
        _linkSpansRecursive(spans, textLinkerSingles, 0);
    return output;
  }

  static (Iterable<InlineSpan>, Iterable<_TextLinkerSingle>) _linkSpansRecursive(Iterable<InlineSpan> spans, Iterable<_TextLinkerSingle> textLinkerSingles, int index) {
    final List<InlineSpan> output = <InlineSpan>[];
    Iterable<_TextLinkerSingle> nextTextLinkerSingles = textLinkerSingles;
    int nextIndex = index;
    for (final InlineSpan span in spans) {
      final (InlineSpan childSpan, Iterable<_TextLinkerSingle> childTextLinkerSingles) = _linkSpanRecursive(
        span,
        nextTextLinkerSingles,
        nextIndex,
      );
      output.add(childSpan);
      nextTextLinkerSingles = childTextLinkerSingles;
      nextIndex += span.toPlainText().length; // TODO(justinmc): Performance? Maybe you could return the index rather than recalculating it?
    }

    return (output, nextTextLinkerSingles);
  }

  // index is the index of the start of `span` in the overall flattened tree.
  static (InlineSpan, Iterable<_TextLinkerSingle>) _linkSpanRecursive(InlineSpan span, Iterable<_TextLinkerSingle> textLinkerSingles, int index) {
    if (span is! TextSpan) {
      // TODO(justinmc): Should actually remove span from ranges here.
      return (span, textLinkerSingles);
    }

    final TextSpan nextTree = TextSpan(
      style: span.style,
      children: <InlineSpan>[],
    );
    List<_TextLinkerSingle> nextTextLinkerSingles = <_TextLinkerSingle>[...textLinkerSingles];
    int lastLinkEnd = index;
    if (span.text?.isNotEmpty ?? false) {
      final int textEnd = index + span.text!.length;
      for (final _TextLinkerSingle textLinkerSingle in textLinkerSingles) {
        if (textLinkerSingle.textRange.start >= textEnd) {
          // Because ranges is ordered, there are no more relevant ranges for this
          // text.
          break;
        }
        if (textLinkerSingle.textRange.end <= index) {
          // This range ends before this span and is therefore irrelevant to it.
          // It should have been removed from ranges.
          assert(false, 'Invalid ranges.');
          nextTextLinkerSingles.removeAt(0);
          continue;
        }
        if (textLinkerSingle.textRange.start > index) {
          // Add the unlinked text before the range.
          nextTree.children!.add(TextSpan(
            text: span.text!.substring(
              lastLinkEnd - index,
              textLinkerSingle.textRange.start - index,
            ),
          ));
        }
        // Add the link itself.
        final int linkStart = math.max(textLinkerSingle.textRange.start, index);
        lastLinkEnd = math.min(textLinkerSingle.textRange.end, textEnd);
        // TODO(justinmc): So partially styled links work by separately linking
        // two different TextSpans. Is that ok for things like Semantics?
        nextTree.children!.add(textLinkerSingle.linkBuilder(
          // TODO(justinmc): Make the naming consistent. matchedString and displayString.
          span.text!.substring(linkStart - index, lastLinkEnd - index),
          textLinkerSingle.matchedString,
        ));
        if (textLinkerSingle.textRange.end > textEnd) {
          // If we only partially used this range, keep it in nextRanges. Since
          // overlapping ranges have been removed, this must be the last relevant
          // range for this span.
          break;
        }
        nextTextLinkerSingles.removeAt(0);
      }

      // Add any extra text after any ranges.
      final String remainingText = span.text!.substring(lastLinkEnd - index);
      if (remainingText.isNotEmpty) {
        nextTree.children!.add(TextSpan(
          text: remainingText,
        ));
      }
    }

    // Recurse on the children.
    if (span.children?.isNotEmpty ?? false) {
      final (
        Iterable<InlineSpan> childrenSpans,
        Iterable<_TextLinkerSingle> childrenTextLinkerSingles,
      ) = _linkSpansRecursive(
        span.children!,
        nextTextLinkerSingles,
        index + (span.text?.length ?? 0),
      );
      nextTextLinkerSingles = childrenTextLinkerSingles.toList();
      nextTree.children!.addAll(childrenSpans);
    }

    return (nextTree, nextTextLinkerSingles);
  }
}

// TODO(justinmc): The clickable area is full-width, should be narrow.
/// An inline text link.
class InlineLink extends TextSpan {
  /// Create an instance of [InlineLink].
  InlineLink({
    required String text,
    super.locale,
    // TODO(justinmc): I probably need to identify this as a link in semantics somehow?
    super.semanticsLabel,
    TextStyle style = defaultLinkStyle,
    VoidCallback? onTap,
  }) : super(
    style: style,
    mouseCursor: SystemMouseCursors.click,
    text: text,
    recognizer: onTap == null ? null : (TapGestureRecognizer()..onTap = onTap),
  );

  @visibleForTesting
  static const defaultLinkStyle = TextStyle(
    // TODO(justinmc): Correct color per-platform. Get it from Theme in
    // Material somehow?
    // And decide underline or no per-platform.
    color: Color(0xff0000ff),
    decoration: TextDecoration.underline,
  );
}

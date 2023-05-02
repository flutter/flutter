import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text.dart';
import 'widget_span.dart';

/// A callback that passes a [String] representing a URL.
typedef UriStringCallback = void Function(String urlString);

// TODO(justinmc): Change name to something link-agnostic?
// TODO(justinmc): Add regexp parameter. No, builder? Both?
class Linkifier extends StatelessWidget {
  const Linkifier({
    super.key,
    this.onTap,
    required this.text,
  });

  final UriStringCallback? onTap;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: InlineLinkifier(
        onTap: onTap,
        style: DefaultTextStyle.of(context).style,
        text: text,
      ),
    );
  }
}

/// A [TextSpan] that makes parts of the [text] interactive.
class InlineLinkifier extends TextSpan {
  /// Create an instance of [InlineLinkifier].
  ///
  /// If [ranges] is given, then makes the text indicated by that interactive.
  ///
  /// Otherwise, finds URLs in the text and makes them interactive.
  InlineLinkifier({
    super.style,
    required String text,
    Iterable<TextRange>? ranges,
    UriStringCallback? onTap,
  }) : super(
         children: _spansFromRanges(
           text: text,
           ranges: ranges ?? _rangesFromText(
             text: text,
             regExp: _urlRegExp,
           ),
           onTap: onTap,
         ),
       );

  /// Create an instance of [InlineLinkifier] where the text matched by the
  /// given [regExp] is made interactive.
  ///
  /// By default, [regExp] matches URLs.
  InlineLinkifier.regExp({
    super.style,
    required String text,
    UriStringCallback ? onTap,
    RegExp? regExp,
  }) : super(
         children: _spansFromRanges(
           text: text,
           ranges: _rangesFromText(
             text: text,
             regExp: regExp ?? _urlRegExp,
           ),
           onTap: onTap,
         ),
       );

  // TODO(justinmc): Function constructor.

  // TODO(justinmc): Consider revising this regexp.
  static final RegExp _urlRegExp = RegExp(r'((http|https|ftp):\/\/)?([a-zA-Z\-]*\.)?[a-zA-Z0-9\-]*\.[a-zA-Z]*');

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

  static List<InlineSpan> _spansFromRanges({
    required String text,
    required Iterable<TextRange> ranges,
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
      // TODO(justinmc): Allow customization of this. Merge `style` param in.
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
            // TODO(justinmc): Correct color per-platform.
            color: Color(0xff0000ff),
          ),
        ),
      ),
    );
  }
}

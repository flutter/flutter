import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'text.dart';
import 'widget_span.dart';

/// A callback that passes a [String] representing a URL.
typedef UriStringCallback = void Function(String urlString);

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
      text: _InlineLinkifier(
        onTap: onTap,
        style: DefaultTextStyle.of(context).style,
        text: text,
      ),
    );
  }
}

class _InlineLinkifier extends TextSpan {
  _InlineLinkifier({
    required String text,
    super.style,
    this.onTap,
    RegExp? regExp,
  }) : regExp = regExp ?? _urlRegExp,
       super(
         children: _spansFromText(text, onTap),
       );

  final UriStringCallback? onTap;
  final RegExp regExp;

  // TODO(justinmc): Consider revising this regexp.
  static final RegExp _urlRegExp = RegExp(r'((http|https|ftp):\/\/)?([a-zA-Z\-]*\.)?[a-zA-Z0-9\-]*\.[a-zA-Z]*');

  static List<InlineSpan> _spansFromText(String text, UriStringCallback? onTap) {
    final Iterable<RegExpMatch> matches = _urlRegExp.allMatches(text);
    int index = 0;
    final List<InlineSpan> spans = <InlineSpan>[];
    for (final RegExpMatch match in matches) {
      // TODO(justinmc): I'm assuming matches are ordered by start.
      // Ignore overlapping matches.
      if (index > match.start) {
        continue;
      }
      if (index < match.start) {
        spans.add(TextSpan(
          text: text.substring(index, match.start),
        ));
      }
      // TODO(justinmc): Allow customization of this. Merge `style` param in.
      spans.add(_InlineLink(
        onTap: onTap,
        text: text.substring(match.start, match.end),
      ));

      index = match.end;
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

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rendering_tester.dart';

// In the test font, every glyph (including the ellipsis) is a square whose
// width equals the font size.
const double _kFontSize = 10.0;
const TextStyle _kStyle = TextStyle(fontSize: _kFontSize);
const String _kText = 'abcdefghij'; // 100px wide.

// A truncation that delegates to another one and records the levels it is
// asked to elide, which correspond to text layouts at those levels.
class _RecordingTruncation extends TextTruncation {
  _RecordingTruncation(this.delegate);

  final TextTruncation delegate;
  final List<int> requestedLevels = <int>[];

  @override
  int maxLevel(String text) => delegate.maxLevel(text);

  @override
  List<TextElision> elide(String text, int level) {
    requestedLevels.add(level);
    return delegate.elide(text, level);
  }
}

class _FixedTruncation extends TextTruncation {
  const _FixedTruncation(this.maxLevelValue, this.elisions);

  final int maxLevelValue;
  final List<TextElision> elisions;

  @override
  int maxLevel(String text) => maxLevelValue;

  @override
  List<TextElision> elide(String text, int level) => level == 0 ? const <TextElision>[] : elisions;
}

RenderParagraph _paragraph(
  TextTruncation truncation, {
  String text = _kText,
  int? maxLines = 1,
  bool softWrap = true,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return RenderParagraph(
    TextSpan(text: text, style: _kStyle),
    textDirection: textDirection,
    maxLines: maxLines,
    softWrap: softWrap,
    overflow: TextOverflow.truncate(truncation),
  );
}

void main() {
  TestRenderingFlutterBinding.ensureInitialized();

  test('text that fits is not truncated and needs a single layout', () {
    final truncation = _RecordingTruncation(const TextTruncation.end());
    final RenderParagraph paragraph = _paragraph(truncation);
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 200));
    expect(paragraph.debugTruncatedText, isNull);
    expect(paragraph.size, const Size(100, _kFontSize));
    // Level 0 is laid out without asking the truncation for elisions.
    expect(truncation.requestedLevels, isEmpty);
  });

  test('picks the smallest level that fits for the built-in truncations', () {
    const constraints = BoxConstraints(maxWidth: 55); // Fits 5 glyphs.
    final expectations = <TextTruncation, String>{
      const TextTruncation.end(): 'abcd…',
      const TextTruncation.start(): '…ghij',
      const TextTruncation.middle(): 'ab…ij',
    };
    for (final MapEntry<TextTruncation, String>(key: truncation, value: expected)
        in expectations.entries) {
      final RenderParagraph paragraph = _paragraph(truncation);
      layout(paragraph, constraints: constraints);
      expect(paragraph.debugTruncatedText, expected, reason: '$truncation');
      expect(paragraph.size, const Size(50, _kFontSize), reason: '$truncation');
      expect(paragraph.didExceedMaxLines, isFalse, reason: '$truncation');
      expect(paragraph.debugHasOverflowShader, isFalse);
    }
  });

  test('truncates with softWrap: false', () {
    final RenderParagraph paragraph = _paragraph(
      const TextTruncation.end(),
      maxLines: null,
      softWrap: false,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, 'abcd…');
    expect(paragraph.size, const Size(50, _kFontSize));
  });

  test('truncates to maxLines: 2', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end(), maxLines: 2);
    // 3 glyphs per line, so at most 6 glyphs fit.
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 35));
    expect(paragraph.debugTruncatedText, 'abcde…');
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.size.height, 2 * _kFontSize);
  });

  test('truncates right-to-left text', () {
    final RenderParagraph paragraph = _paragraph(
      const TextTruncation.start(),
      textDirection: TextDirection.rtl,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, '…ghij');
  });

  test('falls back to clipping when the largest level does not fit', () {
    // Only allows eliding "j", which is not enough to fit in 55px.
    const truncation = _FixedTruncation(1, <TextElision>[
      TextElision(TextRange(start: 9, end: 10)),
    ]);
    final RenderParagraph paragraph = _paragraph(truncation, maxLines: null, softWrap: false);
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, 'abcdefghi…');
    expect(paragraph.size.width, 55);
    expect(paragraph.textSize.width, 100);
    expect(paragraph, paints..clipRect(rect: const Rect.fromLTWH(0, 0, 55, _kFontSize)));
  });

  test('dry layout and dry baseline match real layout', () {
    for (final maxWidth in <double>[25, 55, 95, 200]) {
      final RenderParagraph paragraph = _paragraph(const TextTruncation.middle());
      final constraints = BoxConstraints(maxWidth: maxWidth);
      final Size drySize = paragraph.getDryLayout(constraints);
      final double? dryBaseline = paragraph.getDryBaseline(constraints, TextBaseline.alphabetic);
      layout(paragraph, constraints: constraints);
      expect(drySize, paragraph.size, reason: 'maxWidth: $maxWidth');
      // Also after layout, when the truncation result is cached.
      expect(paragraph.getDryLayout(constraints), paragraph.size, reason: 'maxWidth: $maxWidth');
      expect(dryBaseline, isNotNull);
      expect(
        paragraph.getDryBaseline(constraints, TextBaseline.alphabetic),
        dryBaseline,
        reason: 'maxWidth: $maxWidth',
      );
    }
  });

  test('intrinsic widths are computed from the original text', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end(), text: 'abc defgh');
    final untruncated = RenderParagraph(
      const TextSpan(text: 'abc defgh', style: _kStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 35));
    expect(paragraph.debugTruncatedText, 'ab…');
    expect(paragraph.getMaxIntrinsicWidth(double.infinity), 90);
    expect(
      paragraph.getMaxIntrinsicWidth(double.infinity),
      untruncated.getMaxIntrinsicWidth(double.infinity),
    );
    expect(
      paragraph.getMinIntrinsicWidth(double.infinity),
      untruncated.getMinIntrinsicWidth(double.infinity),
    );
    // Querying intrinsics does not affect the displayed text.
    expect(paragraph.debugTruncatedText, 'ab…');
    untruncated.dispose();
  });

  test('the truncation is cached across paint and geometry queries', () {
    final truncation = _RecordingTruncation(const TextTruncation.end());
    final RenderParagraph paragraph = _paragraph(truncation);
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55), phase: EnginePhase.paint);
    expect(paragraph.debugTruncatedText, 'abcd…');
    final int requestCount = truncation.requestedLevels.length;
    // A binary search over 10 levels takes at most ceil(log2(10)) + 1 steps.
    expect(requestCount, lessThanOrEqualTo(5));

    paragraph.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 3));
    paragraph.getPositionForOffset(const Offset(10, 5));
    paragraph.getDryLayout(const BoxConstraints(maxWidth: 55));
    pumpFrame(phase: EnginePhase.paint);
    expect(truncation.requestedLevels, hasLength(requestCount));

    // Invalidating layout recomputes the truncation.
    paragraph.markNeedsLayout();
    pumpFrame();
    expect(truncation.requestedLevels.length, greaterThan(requestCount));
    expect(paragraph.debugTruncatedText, 'abcd…');
  });

  test('width changes reuse the previous level as a bound', () {
    final truncation = _RecordingTruncation(const TextTruncation.end());
    final RenderParagraph paragraph = _paragraph(truncation);
    final constrainedBox = RenderConstrainedBox(
      additionalConstraints: const BoxConstraints.tightFor(width: 55),
      child: paragraph,
    );
    layout(
      RenderPositionedBox(alignment: Alignment.topLeft, child: constrainedBox),
      constraints: const BoxConstraints(maxWidth: 200),
    );
    expect(paragraph.debugTruncatedText, 'abcd…'); // Level 6.

    // Shrinking can only increase the level.
    truncation.requestedLevels.clear();
    constrainedBox.additionalConstraints = const BoxConstraints.tightFor(width: 35);
    pumpFrame();
    expect(paragraph.debugTruncatedText, 'ab…'); // Level 8.
    expect(truncation.requestedLevels, everyElement(greaterThanOrEqualTo(6)));

    // Growing can only decrease the level.
    truncation.requestedLevels.clear();
    constrainedBox.additionalConstraints = const BoxConstraints.tightFor(width: 75);
    pumpFrame();
    expect(paragraph.debugTruncatedText, 'abcdef…'); // Level 4.
    expect(truncation.requestedLevels, everyElement(lessThanOrEqualTo(8)));

    // Growing enough to fit the whole text.
    constrainedBox.additionalConstraints = const BoxConstraints.tightFor(width: 100);
    pumpFrame();
    expect(paragraph.debugTruncatedText, isNull);
  });

  test('changing overflow away from truncate restores the original text', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end());
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, 'abcd…');

    paragraph.overflow = TextOverflow.clip;
    pumpFrame();
    expect(paragraph.debugTruncatedText, isNull);
    expect(paragraph.didExceedMaxLines, isTrue);

    paragraph.overflow = const TextOverflow.truncate(TextTruncation.start());
    pumpFrame();
    expect(paragraph.debugTruncatedText, '…ghij');
  });

  test('changing the text recomputes the truncation', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end());
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, 'abcd…');

    paragraph.text = const TextSpan(text: 'klmnopqrstuv', style: _kStyle);
    pumpFrame();
    expect(paragraph.debugTruncatedText, 'klmn…');
    expect(paragraph.text, const TextSpan(text: 'klmnopqrstuv', style: _kStyle));

    paragraph.text = const TextSpan(text: 'abc', style: _kStyle);
    pumpFrame();
    expect(paragraph.debugTruncatedText, isNull);
  });

  test('paint-only text changes keep the truncation and apply the new style', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end());
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, 'abcd…');

    const newStyle = TextStyle(fontSize: _kFontSize, color: Color(0xFFFF0000));
    paragraph.text = const TextSpan(text: _kText, style: newStyle);
    expect(paragraph.debugNeedsLayout, isFalse);
    expect(paragraph.debugTruncatedText, 'abcd…');
    expect(paragraph.text.style, newStyle);
  });

  test('text property returns the original text', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end());
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.text, const TextSpan(text: _kText, style: _kStyle));
    expect(paragraph.text.toPlainText(), _kText);
  });

  test('diagnostics describe the overflow by name', () {
    final RenderParagraph paragraph = _paragraph(const TextTruncation.end());
    expect(paragraph.toStringDeep(), contains('overflow: truncate'));
  });

  group('debug asserts', () {
    void expectLayoutError(RenderParagraph paragraph, Matcher matcher) {
      final errors = <FlutterErrorDetails>[];
      layout(
        paragraph,
        constraints: const BoxConstraints(maxWidth: 55),
        onErrors: () {
          errors.addAll(TestRenderingFlutterBinding.instance.takeAllFlutterErrorDetails());
        },
      );
      TestRenderingFlutterBinding.instance.onErrors = null;
      expect(errors, isNotEmpty);
      expect(errors.first.exception.toString(), matcher);
    }

    test('elisions must not overlap', () {
      final RenderParagraph paragraph = _paragraph(
        const _FixedTruncation(1, <TextElision>[
          TextElision(TextRange(start: 2, end: 5)),
          TextElision(TextRange(start: 4, end: 6)),
        ]),
      );
      expectLayoutError(paragraph, contains('overlaps or is not sorted'));
    });

    test('elisions must be sorted', () {
      final RenderParagraph paragraph = _paragraph(
        const _FixedTruncation(1, <TextElision>[
          TextElision(TextRange(start: 5, end: 6)),
          TextElision(TextRange(start: 2, end: 3)),
        ]),
      );
      expectLayoutError(paragraph, contains('overlaps or is not sorted'));
    });

    test('elisions must be within the text', () {
      final RenderParagraph paragraph = _paragraph(
        const _FixedTruncation(1, <TextElision>[TextElision(TextRange(start: 5, end: 20))]),
      );
      expectLayoutError(paragraph, contains('is not a valid, normalized range'));
    });

    test('elisions must be aligned to grapheme clusters', () {
      final RenderParagraph paragraph = _paragraph(
        // Splits the surrogate pair of the emoji.
        const _FixedTruncation(1, <TextElision>[TextElision(TextRange(start: 1, end: 2))]),
        text: 'a\u{1F600}bcdefghij',
      );
      expectLayoutError(paragraph, contains('is not aligned to grapheme cluster boundaries'));
    });

    test('truncation requires plain text', () {
      final tap = TapGestureRecognizer();
      addTearDown(tap.dispose);
      final unsupported = <InlineSpan>[
        TextSpan(text: _kText, style: _kStyle, recognizer: tap),
        const TextSpan(
          style: _kStyle,
          children: <InlineSpan>[
            TextSpan(
              text: _kText,
              style: TextStyle(color: Color(0xFFFF0000)),
            ),
          ],
        ),
      ];
      for (final span in unsupported) {
        final paragraph = RenderParagraph(
          span,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          overflow: const TextOverflow.truncate(TextTruncation.end()),
        );
        expectLayoutError(paragraph, contains('only supports plain text with a single style'));
      }
    });
  });

  test('nested spans without styles are supported', () {
    final paragraph = RenderParagraph(
      const TextSpan(
        style: _kStyle,
        children: <InlineSpan>[
          TextSpan(text: 'abcde'),
          TextSpan(text: 'fghij'),
        ],
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      overflow: const TextOverflow.truncate(TextTruncation.end()),
    );
    layout(paragraph, constraints: const BoxConstraints(maxWidth: 55));
    expect(paragraph.debugTruncatedText, 'abcd…');
  });
}

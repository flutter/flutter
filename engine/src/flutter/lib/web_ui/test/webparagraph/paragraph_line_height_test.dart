// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const double _fontSize = 20.0;
const double _heightMultiplier = 3.0;
// The line height produced by _heightMultiplier at _fontSize.
const double _scaledHeight = _heightMultiplier * _fontSize;

const ui.TextHeightBehavior _noFirstAscentNoLastDescent = ui.TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

ui.ParagraphStyle _style({
  double fontSize = _fontSize,
  double? height,
  int? maxLines,
  ui.TextHeightBehavior? textHeightBehavior,
  ui.StrutStyle? strutStyle,
}) {
  return ui.ParagraphStyle(
    fontFamily: 'Arial',
    fontSize: fontSize,
    height: height,
    maxLines: maxLines,
    textHeightBehavior: textHeightBehavior,
    strutStyle: strutStyle,
  );
}

/// Lays out [text] (or an empty paragraph when [text] is null) with [style].
ui.Paragraph _layout(ui.ParagraphStyle style, [String? text]) {
  final builder = ui.ParagraphBuilder(style);
  if (text != null) {
    builder.addText(text);
  }
  return builder.build()..layout(const ui.ParagraphConstraints(width: 500));
}

ui.LineMetrics _singleLineMetrics(ui.ParagraphStyle style, String text) {
  return _layout(style, text).computeLineMetrics().single;
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Height multiplier scales ascent and descent proportionally by default', () {
    final ui.LineMetrics raw = _singleLineMetrics(_style(), 'Hello');
    final ui.LineMetrics scaled = _singleLineMetrics(_style(height: _heightMultiplier), 'Hello');
    expect(scaled.height, closeTo(_scaledHeight, 1e-3));

    // `proportional` (the default, as in SkParagraph) scales both sides by the same factor...
    final double factor = _scaledHeight / raw.height;
    expect(scaled.ascent, closeTo(raw.ascent * factor, 1e-3));
    expect(scaled.descent, closeTo(raw.descent * factor, 1e-3));

    // ...whereas `even` adds the same amount of extra leading on each side.
    final ui.LineMetrics even = _singleLineMetrics(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(
          leadingDistribution: ui.TextLeadingDistribution.even,
        ),
      ),
      'Hello',
    );
    expect(even.height, closeTo(_scaledHeight, 1e-3));
    final double extraLeading = (_scaledHeight - raw.height) / 2;
    expect(even.ascent, closeTo(raw.ascent + extraLeading, 1e-3));
    expect(even.descent, closeTo(raw.descent + extraLeading, 1e-3));

    // The two distributions differ for any font whose ascent and descent are not equal.
    expect(scaled.ascent, isNot(closeTo(even.ascent, 1e-3)));
  });

  test('TextStyle.leadingDistribution overrides TextHeightBehavior.leadingDistribution', () {
    final ui.LineMetrics proportional = _singleLineMetrics(
      _style(height: _heightMultiplier),
      'Hello',
    );
    final builder = ui.ParagraphBuilder(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(
          leadingDistribution: ui.TextLeadingDistribution.even,
        ),
      ),
    );
    builder.pushStyle(ui.TextStyle(leadingDistribution: ui.TextLeadingDistribution.proportional));
    builder.addText('Hello');
    final ui.Paragraph paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 500));
    final ui.LineMetrics overridden = paragraph.computeLineMetrics().single;
    expect(overridden.ascent, closeTo(proportional.ascent, 1e-3));
    expect(overridden.descent, closeTo(proportional.descent, 1e-3));
  });

  test('Half-leading with a small height multiplier preserves negative descent', () {
    final ui.LineMetrics raw = _singleLineMetrics(_style(), 'Hello');
    const smallMultiplier = 0.1;
    const double expectedHeight = smallMultiplier * _fontSize;
    final ui.LineMetrics even = _singleLineMetrics(
      _style(
        height: smallMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(
          leadingDistribution: ui.TextLeadingDistribution.even,
        ),
      ),
      'Hello',
    );
    final double extraLeading = (expectedHeight - raw.height) / 2;
    expect(even.ascent, closeTo(raw.ascent + extraLeading, 1e-3));
    expect(even.descent, closeTo(raw.descent + extraLeading, 1e-3));
    expect(even.descent, isNegative);
    expect(even.height, closeTo(expectedHeight, 1e-3));
  });

  test('TextHeightBehavior reverts a single line to the unscaled font metrics', () {
    final ui.LineMetrics raw = _singleLineMetrics(_style(), 'x');

    // A single line is both the first and the last line, so with both flags off it ends up as
    // tall as it would be without a height multiplier at all.
    final ui.Paragraph single = _layout(
      _style(height: _heightMultiplier, textHeightBehavior: _noFirstAscentNoLastDescent),
      'x',
    );
    final ui.LineMetrics singleMetrics = single.computeLineMetrics().single;
    expect(singleMetrics.ascent, closeTo(raw.ascent, 1e-3));
    expect(singleMetrics.descent, closeTo(raw.descent, 1e-3));
    expect(single.height, closeTo(raw.height, 1e-3));
    expect(single.alphabeticBaseline, closeTo(raw.ascent, 1e-3));
  });

  test('TextHeightBehavior affects only the first line ascent and the last line descent', () {
    final ui.LineMetrics raw = _singleLineMetrics(_style(), 'x');
    final ui.LineMetrics scaled = _singleLineMetrics(_style(height: _heightMultiplier), 'x');

    // Disabling applyHeightToFirstAscent strips the multiplier only from line 0's ascent.
    final ui.Paragraph noFirstAscent = _layout(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(applyHeightToFirstAscent: false),
      ),
      'Hello\nWorld',
    );
    final List<ui.LineMetrics> noFirstAscentLines = noFirstAscent.computeLineMetrics();
    expect(noFirstAscentLines, hasLength(2));
    expect(noFirstAscentLines[0].ascent, closeTo(raw.ascent, 1e-3));
    expect(noFirstAscentLines[0].descent, closeTo(scaled.descent, 1e-3));
    expect(noFirstAscentLines[1].ascent, closeTo(scaled.ascent, 1e-3));
    expect(noFirstAscentLines[1].descent, closeTo(scaled.descent, 1e-3));
    // The second line starts right below the (shorter) first line.
    expect(
      noFirstAscentLines[1].baseline,
      closeTo(noFirstAscentLines[0].height + scaled.ascent, 1e-3),
    );
    expect(noFirstAscent.height, closeTo(raw.ascent + scaled.descent + _scaledHeight, 1e-3));
    expect(noFirstAscent.alphabeticBaseline, closeTo(raw.ascent, 1e-3));

    // Disabling applyHeightToLastDescent strips the multiplier only from the last line's descent.
    final ui.Paragraph noLastDescent = _layout(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(applyHeightToLastDescent: false),
      ),
      'Hello\nWorld',
    );
    final List<ui.LineMetrics> noLastDescentLines = noLastDescent.computeLineMetrics();
    expect(noLastDescentLines, hasLength(2));
    expect(noLastDescentLines[0].ascent, closeTo(scaled.ascent, 1e-3));
    expect(noLastDescentLines[0].descent, closeTo(scaled.descent, 1e-3));
    expect(noLastDescentLines[1].ascent, closeTo(scaled.ascent, 1e-3));
    expect(noLastDescentLines[1].descent, closeTo(raw.descent, 1e-3));
    expect(noLastDescentLines[1].baseline, closeTo(_scaledHeight + scaled.ascent, 1e-3));
    expect(noLastDescent.height, closeTo(_scaledHeight + scaled.ascent + raw.descent, 1e-3));
    expect(noLastDescent.alphabeticBaseline, closeTo(scaled.ascent, 1e-3));
  });

  test('TextHeightBehavior treats the empty line after a trailing newline as the last line', () {
    final ui.LineMetrics raw = _singleLineMetrics(_style(), 'x');
    final ui.LineMetrics scaled = _singleLineMetrics(_style(height: _heightMultiplier), 'x');

    final ui.Paragraph paragraph = _layout(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(applyHeightToLastDescent: false),
      ),
      'x\n',
    );
    final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines, hasLength(2));
    // Line 0 ('x\n') is followed by the synthetic empty line, so it keeps its scaled descent.
    expect(lines[0].ascent, closeTo(scaled.ascent, 1e-3));
    expect(lines[0].descent, closeTo(scaled.descent, 1e-3));
    // Line 1 (the synthetic empty line) inherits line 0's metrics and reverts its descent to raw.
    expect(lines[1].ascent, closeTo(scaled.ascent, 1e-3));
    expect(lines[1].descent, closeTo(raw.descent, 1e-3));
    expect(paragraph.height, closeTo(_scaledHeight + scaled.ascent + raw.descent, 1e-3));
  });

  test('TextHeightBehavior applies applyHeightToLastDescent to the maxLines limit line', () {
    final ui.LineMetrics raw = _singleLineMetrics(_style(), 'x');
    final ui.LineMetrics scaled = _singleLineMetrics(_style(height: _heightMultiplier), 'x');

    final ui.Paragraph paragraph = _layout(
      _style(
        height: _heightMultiplier,
        maxLines: 2,
        textHeightBehavior: const ui.TextHeightBehavior(applyHeightToLastDescent: false),
      ),
      'First\nSecond\nThird',
    );
    final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines, hasLength(2));
    expect(lines[0].ascent, closeTo(scaled.ascent, 1e-3));
    expect(lines[0].descent, closeTo(scaled.descent, 1e-3));
    // Line 1 caps layout at maxLines: 2, so it is treated as the last line and gets raw descent.
    expect(lines[1].ascent, closeTo(scaled.ascent, 1e-3));
    expect(lines[1].descent, closeTo(raw.descent, 1e-3));
    expect(paragraph.height, closeTo(_scaledHeight + scaled.ascent + raw.descent, 1e-3));
  });

  test('TextHeightBehavior positions first-line placeholders against the reverted ascent', () {
    final builder = ui.ParagraphBuilder(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(applyHeightToFirstAscent: false),
      ),
    );
    builder.addText('x');
    builder.addPlaceholder(
      10,
      10,
      ui.PlaceholderAlignment.aboveBaseline,
      baseline: ui.TextBaseline.alphabetic,
    );
    final ui.Paragraph paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 500));
    final ui.TextBox box = paragraph.getBoxesForPlaceholders().single;
    expect(box.bottom, closeTo(paragraph.alphabeticBaseline, 1e-3));
  });

  test('TextHeightBehavior bounds background rects by reverted first ascent and last descent', () {
    final double originalDpr = EngineFlutterDisplay.instance.devicePixelRatio;
    try {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);

      final builder = ui.ParagraphBuilder(
        _style(height: _heightMultiplier, textHeightBehavior: _noFirstAscentNoLastDescent),
      );
      builder.pushStyle(ui.TextStyle(background: ui.Paint()..color = const ui.Color(0xFFFF0000)));
      builder.addText('Hello\nWorld');
      final paragraph =
          (builder.build()..layout(const ui.ParagraphConstraints(width: 500))) as WebParagraph;
      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      expect(lines, hasLength(2));

      final canvas = _RecordingCanvas();
      paragraph.paint(canvas, ui.Offset.zero);

      expect(canvas.drawnRects, hasLength(2));
      // Line 0 background uses raw ascent (top == 0) and scaled descent.
      expect(canvas.drawnRects[0].top, closeTo(0.0, 1e-3));
      expect(canvas.drawnRects[0].bottom, closeTo(lines[0].height.roundToDouble(), 1e-3));
      // Line 1 background uses scaled ascent and raw descent (bottom == paragraph.height).
      expect(canvas.drawnRects[1].top, closeTo(lines[0].height.roundToDouble(), 1e-3));
      expect(canvas.drawnRects[1].bottom, closeTo(paragraph.height.roundToDouble(), 1e-3));
    } finally {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(originalDpr);
    }
  });

  test('TextHeightBehavior is a no-op when forceStrutHeight is set', () {
    // The strut is 1.0 * 10 = 10 tall; the text is four times bigger.
    final strutStyle = ui.StrutStyle(
      fontFamily: 'Arial',
      fontSize: 10,
      height: 1.0,
      forceStrutHeight: true,
    );
    final ui.Paragraph withoutBehavior = _layout(
      _style(fontSize: 40, strutStyle: strutStyle),
      'Hello',
    );
    final ui.Paragraph withBehavior = _layout(
      _style(fontSize: 40, strutStyle: strutStyle, textHeightBehavior: _noFirstAscentNoLastDescent),
      'Hello',
    );
    expect(withoutBehavior.height, closeTo(10.0, 1e-3));
    expect(withBehavior.height, closeTo(withoutBehavior.height, 1e-3));

    final ui.LineMetrics withoutBehaviorMetrics = withoutBehavior.computeLineMetrics().single;
    final ui.LineMetrics withBehaviorMetrics = withBehavior.computeLineMetrics().single;
    expect(withBehaviorMetrics.ascent, closeTo(withoutBehaviorMetrics.ascent, 1e-3));
    expect(withBehaviorMetrics.descent, closeTo(withoutBehaviorMetrics.descent, 1e-3));

    // Every line is locked to the strut height.
    final ui.Paragraph twoLines = _layout(
      _style(fontSize: 40, strutStyle: strutStyle, textHeightBehavior: _noFirstAscentNoLastDescent),
      'Hello\nWorld',
    );
    expect(twoLines.height, closeTo(20.0, 1e-3));
  });

  test('StrutStyle.leading is kept when TextHeightBehavior reverts to unscaled metrics', () {
    // The strut is 1.0 * 20 = 20 of font height plus 1.5 * 20 = 30 of leading (split evenly
    // above and below), 50 in total.
    final forcedStrut = ui.StrutStyle(
      fontFamily: 'Arial',
      fontSize: _fontSize,
      height: 1.0,
      leading: 1.5,
      forceStrutHeight: true,
    );
    final ui.Paragraph forcedWithoutBehavior = _layout(_style(strutStyle: forcedStrut), 'Hello');
    final ui.Paragraph forcedWithBehavior = _layout(
      _style(strutStyle: forcedStrut, textHeightBehavior: _noFirstAscentNoLastDescent),
      'Hello',
    );
    expect(forcedWithoutBehavior.height, closeTo(50.0, 1e-3));
    expect(forcedWithBehavior.height, closeTo(50.0, 1e-3));
    expect(
      forcedWithBehavior.alphabeticBaseline,
      closeTo(forcedWithoutBehavior.alphabeticBaseline, 1e-3),
    );

    // Without forceStrutHeight the strut (leading included) is still the minimum line height, so
    // the smaller text doesn't shrink the line.
    final strut = ui.StrutStyle(
      fontFamily: 'Arial',
      fontSize: _fontSize,
      height: 1.0,
      leading: 1.5,
    );
    final ui.Paragraph small = _layout(
      _style(fontSize: 10, strutStyle: strut, textHeightBehavior: _noFirstAscentNoLastDescent),
      'Hello',
    );
    expect(small.height, closeTo(50.0, 1e-3));
  });

  test('Placeholder and text respect StrutStyle leading and forceStrutHeight', () {
    // StrutStyle.leading adds leading * fontSize (1.5 * 20 = 30.0) to the scaled strut height.
    final strutLeadingBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: 'Arial',
        fontSize: 20,
        strutStyle: ui.StrutStyle(
          fontFamily: 'Arial',
          fontSize: 20,
          height: 1.0,
          leading: 1.5,
          forceStrutHeight: true,
        ),
      ),
    )..addText('Hello');
    final ui.Paragraph strutLeadingParagraph = strutLeadingBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 500));
    expect(strutLeadingParagraph.height, closeTo(50.0, 1e-3));

    // When forceStrutHeight is true, a taller placeholder does not expand the line height beyond
    // the strut.
    final placeholderForceStrutBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        strutStyle: ui.StrutStyle(
          fontFamily: 'Arial',
          fontSize: 10,
          height: 10.0,
          forceStrutHeight: true,
        ),
      ),
    )..addPlaceholder(1000, 1000, ui.PlaceholderAlignment.bottom);
    final ui.Paragraph placeholderForceStrut = placeholderForceStrutBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 2000));
    expect(placeholderForceStrut.height, closeTo(100.0, 1e-3));
  });
}

class _RecordingCanvas implements ui.Canvas {
  final List<ui.Rect> drawnRects = <ui.Rect>[];

  @override
  Float64List getTransform() => Matrix4.identity().toFloat64();

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    drawnRects.add(rect);
  }

  @override
  void drawImageRect(ui.Image image, ui.Rect src, ui.Rect dst, ui.Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

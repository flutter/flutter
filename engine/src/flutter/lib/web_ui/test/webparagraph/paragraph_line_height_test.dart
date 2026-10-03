// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const double _fontSize = 20.0;
const double _heightMultiplier = 3.0;
// The line height produced by `_heightMultiplier` at `_fontSize`
const double _scaledHeight = _heightMultiplier * _fontSize;

const ui.TextHeightBehavior _noFirstAscentNoLastDescent = ui.TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

ui.ParagraphStyle _style({
  double fontSize = _fontSize,
  double? height,
  ui.TextHeightBehavior? textHeightBehavior,
  ui.StrutStyle? strutStyle,
}) {
  return ui.ParagraphStyle(
    fontFamily: 'Arial',
    fontSize: fontSize,
    height: height,
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
    // tall as it would be without a height multiplier at all
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
    // The second line starts right below the (shorter) first line
    expect(
      noFirstAscentLines[1].baseline,
      closeTo(noFirstAscentLines[0].height + scaled.ascent, 1e-3),
    );
    expect(noFirstAscent.height, closeTo(raw.ascent + scaled.descent + _scaledHeight, 1e-3));
    expect(noFirstAscent.alphabeticBaseline, closeTo(raw.ascent, 1e-3));

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

    // The empty line after the trailing `\n` inherits the metrics of the previous line (as in
    // SkParagraph), and it is the one that loses its descent; the text line keeps it
    final ui.Paragraph paragraph = _layout(
      _style(
        height: _heightMultiplier,
        textHeightBehavior: const ui.TextHeightBehavior(applyHeightToLastDescent: false),
      ),
      'x\n',
    );
    final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines, hasLength(2));
    expect(lines[0].ascent, closeTo(scaled.ascent, 1e-3));
    expect(lines[0].descent, closeTo(scaled.descent, 1e-3));
    expect(lines[1].ascent, closeTo(scaled.ascent, 1e-3));
    expect(lines[1].descent, closeTo(raw.descent, 1e-3));
    expect(paragraph.height, closeTo(_scaledHeight + scaled.ascent + raw.descent, 1e-3));
  });
}

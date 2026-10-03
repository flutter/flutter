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
// The line height produced by `_heightMultiplier` at `_fontSize`.
const double _scaledHeight = _heightMultiplier * _fontSize;

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
}

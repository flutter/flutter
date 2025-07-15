// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

class WebParagraphStyle implements ui.ParagraphStyle {}

class WebTextStyle implements ui.TextStyle {}

class WebStrutStyle implements ui.StrutStyle {}

class WebParagraph implements ui.Paragraph {
  @override
  void dispose() {}

  @override
  double get width => throw UnimplementedError();

  @override
  double get height => throw UnimplementedError();

  @override
  double get minIntrinsicWidth => throw UnimplementedError();

  @override
  double get maxIntrinsicWidth => throw UnimplementedError();

  @override
  double get alphabeticBaseline => throw UnimplementedError();

  @override
  double get ideographicBaseline => throw UnimplementedError();

  @override
  double get longestLine => throw UnimplementedError();

  @override
  bool get didExceedMaxLines => throw UnimplementedError();

  @override
  List<ui.LineMetrics> computeLineMetrics() => throw UnimplementedError();

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle? boxHeightStyle,
    ui.BoxWidthStyle? boxWidthStyle,
  }) => throw UnimplementedError();

  @override
  List<ui.TextBox> getBoxesForPlaceholders() => throw UnimplementedError();

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) => throw UnimplementedError();

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) => throw UnimplementedError();

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) => throw UnimplementedError();

  @override
  bool get debugDisposed => throw UnimplementedError();

  @override
  ui.LineMetrics? getLineMetricsAt(int lineNumber) => throw UnimplementedError();

  @override
  int? getLineNumberAt(int codeUnitOffset) => throw UnimplementedError();

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) => throw UnimplementedError();

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) => throw UnimplementedError();

  @override
  void layout(ui.ParagraphConstraints constraints) => throw UnimplementedError();

  @override
  int get numberOfLines => throw UnimplementedError();
}

class WebParagraphBuilder implements ui.ParagraphBuilder {
  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    ui.TextBaseline? baseline,
    double? baselineOffset,
    double? scale,
  }) => throw UnimplementedError();

  @override
  void addText(String text) => throw UnimplementedError();

  @override
  void pop() => throw UnimplementedError();

  @override
  void pushStyle(ui.TextStyle style) => throw UnimplementedError();

  @override
  ui.Paragraph build() => throw UnimplementedError();

  @override
  int get placeholderCount => throw UnimplementedError();

  @override
  List<double> get placeholderScales => throw UnimplementedError();
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_unused_constructor_parameters

import 'package:ui/ui.dart' as ui;

// TODO(jacksongardner): implement everything in this file
class SkwasmLineMetrics implements ui.LineMetrics {
  factory SkwasmLineMetrics({
    required bool hardBreak,
    required double ascent,
    required double descent,
    required double unscaledAscent,
    required double height,
    required double width,
    required double left,
    required double baseline,
    required int lineNumber,
  }) {
    throw UnimplementedError();
  }

  @override
  bool get hardBreak {
    throw UnimplementedError();
  }

  @override
  double get ascent {
    throw UnimplementedError();
  }

  @override
  double get descent {
    throw UnimplementedError();
  }

  @override
  double get unscaledAscent {
    throw UnimplementedError();
  }

  @override
  double get height {
    throw UnimplementedError();
  }

  @override
  double get width {
    throw UnimplementedError();
  }

  @override
  double get left {
    throw UnimplementedError();
  }

  @override
  double get baseline {
    throw UnimplementedError();
  }

  @override
  int get lineNumber {
    throw UnimplementedError();
  }
}

class SkwasmParagraph implements ui.Paragraph {
  @override
  double get width {
    return 0.0;
  }

  @override
  double get height {
    return 0.0;
  }

  @override
  double get longestLine {
    return 0.0;
  }

  @override
  double get minIntrinsicWidth {
    return 0.0;
  }

  @override
  double get maxIntrinsicWidth {
    return 0.0;
  }

  @override
  double get alphabeticBaseline {
    return 0.0;
  }

  @override
  double get ideographicBaseline {
    return 0.0;
  }

  @override
  bool get didExceedMaxLines {
    return false;
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
  }

  @override
  List<ui.TextBox> getBoxesForRange(int start, int end,
      {ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
      ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight}) {
    return <ui.TextBox>[];
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    return const ui.TextPosition(offset: 0);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    return const ui.TextRange(start: 0, end: 0);
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    return const ui.TextRange(start: 0, end: 0);
  }

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    return <ui.TextBox>[];
  }

  @override
  List<SkwasmLineMetrics> computeLineMetrics() {
    return <SkwasmLineMetrics>[];
  }

  @override
  bool get debugDisposed => false;

  @override
  void dispose() {
  }
}

class SkwasmParagraphStyle implements ui.ParagraphStyle {
}

class SkwasmTextStyle implements ui.TextStyle {
}

class SkwasmParagraphBuilder implements ui.ParagraphBuilder {
  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline
  }) {
  }

  @override
  void addText(String text) {
  }

  @override
  ui.Paragraph build() {
    return SkwasmParagraph();
  }

  @override
  int get placeholderCount => 0;

  @override
  List<double> get placeholderScales => <double>[];

  @override
  void pop() {
  }

  @override
  void pushStyle(ui.TextStyle style) {
  }
}

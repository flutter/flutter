// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_unused_constructor_parameters

import 'package:ui/ui.dart' as ui;

// TODO(jacksongardner): implement this
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
    throw UnimplementedError();
  }

  @override
  double get height {
    throw UnimplementedError();
  }

  @override
  double get longestLine {
    throw UnimplementedError();
  }

  @override
  double get minIntrinsicWidth {
    throw UnimplementedError();
  }

  @override
  double get maxIntrinsicWidth {
    throw UnimplementedError();
  }

  @override
  double get alphabeticBaseline {
    throw UnimplementedError();
  }

  @override
  double get ideographicBaseline {
    throw UnimplementedError();
  }

  @override
  bool get didExceedMaxLines {
    throw UnimplementedError();
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    throw UnimplementedError();
  }

  @override
  List<ui.TextBox> getBoxesForRange(int start, int end,
      {ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
      ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight}) {
    throw UnimplementedError();
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    throw UnimplementedError();
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    throw UnimplementedError();
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    throw UnimplementedError();
  }

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    throw UnimplementedError();
  }

  @override
  List<SkwasmLineMetrics> computeLineMetrics() {
    throw UnimplementedError();
  }

  @override
  bool get debugDisposed => throw UnimplementedError();

  @override
  void dispose() {
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../primitives/paragraph.dart';

/// Backend-specific implementation of a [ui.Paragraph].
abstract class BackendParagraph {
  void dispose();

  double get width;
  double get height;
  double get longestLine;
  double get minIntrinsicWidth;
  double get maxIntrinsicWidth;
  double get alphabeticBaseline;
  double get ideographicBaseline;
  bool get didExceedMaxLines;
  int get numberOfLines;

  void layout(double width);

  List<int> getUnresolvedCodePoints();

  List<ui.TextBox> getBoxesForPlaceholders();

  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  });

  ui.TextPosition getPositionForOffset(ui.Offset offset);

  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset);

  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset);

  ui.TextRange getWordBoundary(int characterPosition);

  List<EngineLineMetrics> computeLineMetrics();

  EngineLineMetrics? getLineMetricsAt(int lineNumber);

  int? getLineNumberAt(int codeUnitOffset);
}

/// Backend-specific implementation of a [ui.ParagraphBuilder].
///
/// The owning [EngineParagraphBuilder] calls [dispose] exactly once, right
/// after [build] or when the builder is garbage collected without being built.
/// Implementations must not dispose themselves.
abstract class BackendParagraphBuilder {
  void dispose();

  void pushStyle(EngineTextStyle mergedStyle);

  void pop();

  void addText(String text);

  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment,
    double baselineOffset,
    ui.TextBaseline baseline,
  );

  BackendParagraph build();
}

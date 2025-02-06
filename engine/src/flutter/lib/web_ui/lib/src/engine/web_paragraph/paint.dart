// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import 'paragraph.dart';

/// A single canvas2d context to use for all text information.
@visibleForTesting
final DomCanvasRenderingContext2D textContext =
    // We don't use this canvas to draw anything, so let's make it as small as
    // possible to save memory.
    createDomCanvasElement(width: 0, height: 0).context2D;

/// Performs layout on a [CanvasParagraph].
///
/// It uses a [DomCanvasElement] to get text information
class TextPaint {
  TextPaint(this.paragraph);

  final WebParagraph paragraph;

  void paint(DomCanvasElement canvas, WebTextCluster textCluster, double x, double y) {
    String text = this.paragraph.text.substring(textCluster.begin(), textCluster.end());
    final DomCanvasRenderingContext2D context = canvas.context2D;
    context.font = '50px arial';
    context.fillStyle = 'red';
    context.fillTextCluster(textCluster, x, y);
    /*
    // Loop through all the lines, for each line, loop through all fragments and
    // paint them. The fragment objects have enough information to be painted
    // individually.
    final List<ParagraphLine> lines = paragraph.lines;

    for (final ParagraphLine line in lines) {
      for (final LayoutFragment fragment in line.fragments) {
        _paintBackground(canvas, offset, fragment);f
        _paintText(canvas, offset, line, fragment);
      }
    }
     */
  }

  void printTextCluster(WebTextCluster textCluster) {
    String text = this.paragraph.text.substring(textCluster.begin(), textCluster.end());
    print('[${textCluster.begin()}:${textCluster.end()}) = "${text}"\n');
  }
}

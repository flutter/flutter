// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

//import '../dom.dart';
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
class TextLayout {
  TextLayout(this.paragraph);

  final WebParagraph paragraph;

  List<WebTextCluster> textClusters = <WebTextCluster>[];

  void performLayout() {
    textContext.font = '50px arial';
    final textMetrics = textContext.measureText(paragraph.text) as DomTextMetrics;
    final textClusters = textMetrics.getTextClusters();
    int index = 0;
    while (index < textClusters.length) {
      final tc = textClusters[index];
      if (index < textClusters.length - 1) {
        final tc1 = textClusters[index + 1];
        this.textClusters.add(WebTextCluster(tc, tc1.x, textMetrics.height));
      } else {
        this.textClusters.add(WebTextCluster(tc, textMetrics.width!, textMetrics.height));
      }
      index += 1;
    }
  }
}

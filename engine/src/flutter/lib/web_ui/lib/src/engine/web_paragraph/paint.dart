// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

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
  ui.Rect _bounds = ui.Rect.zero;

  void printTextCluster(WebTextCluster textCluster) {
      print('[${textCluster.begin()}:${textCluster.end()}): ${textCluster.text()}\n');
  }

}

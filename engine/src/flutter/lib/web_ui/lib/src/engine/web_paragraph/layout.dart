// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'paragraph.dart';
import 'wrapper.dart';
import 'code_unit_flags.dart';
import 'unicode_properties.dart';

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

  List<CodeUnitFlags> codeUnitFlags = <CodeUnitFlags>[];
  List<WebTextCluster> textClusters = <WebTextCluster>[];
  DomTextMetrics? textMetrics;
  List<TextRun> runs = <TextRun>[];
  List<TextLine> lines = <TextLine>[];

  bool hasFlag(ClusterRange cluster, int flag) {
    return codeUnitFlags[cluster.start].hasFlag(flag);
  }

  void performLayout(double width) {
    textContext.font = '50px arial';
    this.textMetrics = textContext.measureText(paragraph.text) as DomTextMetrics;
    this.textClusters = textMetrics!.getTextClusters();

    this.extractUnicodeInfo();

    this.extractRuns();

    final TextWrapper wrapper = TextWrapper(paragraph.text, this);
    wrapper.breakLines(width);
  }

  void extractUnicodeInfo() {
    // Fill out the entire flag list
    for (int i = 0; i <= paragraph.text.length; ++i) {
       codeUnitFlags.add(CodeUnitFlags(CodeUnitFlags.kNoCodeUnitFlag));
    }
    // Get the information from the browser
    final SegmentationResult result = segmentText(paragraph.text);

    // Fill out grapheme flags
    for (final grapheme in result.graphemes) {
      codeUnitFlags[grapheme].graphemeStart = true;
    }
    // Fill out word flags
    for (final word in result.words) {
      codeUnitFlags[word].wordBreak = true;
    }
    // Fill out line break flags
    for (int index = 0; index < result.breaks.length; index += 2) {
      final int lineBreak = result.breaks[index];
      if (result.breaks[index + 1] == 0) {
        codeUnitFlags[lineBreak].softLineBreak = true;
      } else {
        codeUnitFlags[lineBreak].hardLineBreak = true;
      }
    }
    // Add whitespaces
    for (int i = 0; i < paragraph.text.length; ++i) {
       codeUnitFlags[i].whitespace = UnicodeProperties.isWhitespace(paragraph.text.codeUnitAt(i));
    }
  }

  void extractRuns() {
    // TODO: Implement bidi (via SkUnicode API in CanvasKit)
  }
}

class ClusterRange {
  ClusterRange(this.start, this.end);
  bool isEmpty() { return start == end; }
  int width() { return end - start; }

  final int start;
  final int end;
}

class TextRun {
  TextRun(this.textLayout, this.clusterRange);

  final TextLayout textLayout;
  final ClusterRange clusterRange;
}

class TextLine {
  TextLine(this.textLayout, this.clusterRange, this.width, this.whitespacesRange, this.whitespacesWidth);

  final TextLayout textLayout;
  final ClusterRange clusterRange;
  final ClusterRange whitespacesRange;
  final double width;
  final double whitespacesWidth;
}
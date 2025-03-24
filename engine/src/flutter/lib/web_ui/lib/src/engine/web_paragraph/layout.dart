// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../dom.dart';
import 'code_unit_flags.dart';
import 'debug.dart';
import 'paragraph.dart';
import 'unicode_properties.dart';
import 'wrapper.dart';

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
  List<ExtendedTextCluster> textClusters = <ExtendedTextCluster>[];
  List<BidiRun> bidiRuns = <BidiRun>[];
  List<TextLine> lines = <TextLine>[];

  double _top = 0.0;
  double _left = 0.0;

  bool hasFlag(ui.TextRange cluster, int flag) {
    return codeUnitFlags[cluster.start].hasFlag(flag);
  }

  void performLayout(double width) {
    lines.clear();
    bidiRuns.clear();
    codeUnitFlags.clear();

    extractClusterTexts();

    extractBidiRuns();

    extractUnicodeInfo();

    wrapText(width);

    reorderVisuals();
  }

  void extractUnicodeInfo() {
    // TODO(jlavrova): Switch to SkUnicode.CodePointFlags API in CanvasKit
    // Fill out the entire flag list
    for (int i = 0; i <= paragraph.text!.length; ++i) {
      codeUnitFlags.add(CodeUnitFlags(CodeUnitFlags.kNoCodeUnitFlag));
    }
    // Get the information from the browser
    final engine.SegmentationResult result = engine.segmentText(paragraph.text!);

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
    for (int i = 0; i < paragraph.text!.length; ++i) {
      codeUnitFlags[i].whitespace = UnicodeProperties.isWhitespace(paragraph.text!.codeUnitAt(i));
    }
  }

  void extractClusterTexts() {
    // Walk through all the styled text ranges
    for (final StyledTextRange styledBlock in paragraph.styledTextRanges) {
      final String text = paragraph.text!.substring(
        styledBlock.textRange.start,
        styledBlock.textRange.end,
      );
      WebParagraphDebug.log(
        '[${styledBlock.textRange.start}:${styledBlock.textRange.end}): "$text"',
      );
      textContext.font =
          '${styledBlock.textStyle.fontSize}px ${styledBlock.textStyle.originalFontFamily!}';
      textContext.fillStyle = styledBlock.textStyle.color;
      final DomTextMetrics blockTextMetrics = textContext.measureText(text);
      for (final WebTextCluster cluster in blockTextMetrics.getTextClusters()) {
        final List<DomRectReadOnly> rects = blockTextMetrics.getSelectionRects(
          cluster.begin,
          cluster.end,
        );
        final ui.Rect bounds = ui.Rect.fromLTWH(
          rects.first.left,
          rects.first.top,
          rects.first.width,
          rects.first.height,
        );
        textClusters.add(ExtendedTextCluster(cluster, bounds, blockTextMetrics));
      }
    }
  }

  void extractBidiRuns() {
    final List<BidiRegion> regions = canvasKit.Bidi.getBidiRegions(
      paragraph.text!,
      paragraph.paragraphStyle.textDirection,
    );

    String str = 'Bidi ${paragraph.paragraphStyle.textDirection}:\n';
    for (final region in regions) {
      str += ' [${region.start}: ${region.end}):${region.level}';
    }
    WebParagraphDebug.log(str);

    for (final region in regions) {
      final BidiRun run = BidiRun(
        //this,
        ClusterRange(start: region.start, end: region.end),
        region.level,
      );
      bidiRuns.add(run);
    }
  }

  void printClusters() {
    WebParagraphDebug.log('Text Clusters: ${textClusters.length}');
    for (final BidiRun run in bidiRuns) {
      final String runText = paragraph.text!.substring(
        run.clusterRange.start,
        run.clusterRange.end,
      );
      WebParagraphDebug.log('');
      WebParagraphDebug.log('Run[${run.clusterRange.start}:${run.clusterRange.end}): "$runText"');
      for (var i = run.clusterRange.start; i < run.clusterRange.end; ++i) {
        final ExtendedTextCluster cluster = textClusters[i];
        final String clusterText = paragraph.text!.substring(cluster.start, cluster.end);
        WebParagraphDebug.log(
          '[${cluster.start}:${cluster.end}) ${cluster.bounds.width} * ${cluster.bounds.height} "$clusterText"',
        );
      }
    }
  }

  void wrapText(double width) {
    final TextWrapper wrapper = TextWrapper(paragraph.text!, this);
    _top = 0.0;
    _left = 0.0;
    wrapper.breakLines(width);
  }

  ClusterRange intersect(ClusterRange a, ClusterRange b) {
    return ClusterRange(start: max(a.start, b.start), end: min(a.end, b.end));
  }

  void addLine(
    ClusterRange textRange,
    double textWidth,
    ClusterRange whitespaces,
    double whitespacesWidth,
    bool hardLineBreak,
  ) {
    // Arrange line vertically, calculate metrics and bounds
    final TextLine line = TextLine(
      this,
      textRange,
      textWidth,
      whitespaces,
      whitespacesWidth,
      hardLineBreak,
    );

    // Get visual runs
    final List<BidiRun> logicalRuns = <BidiRun>[];
    final Uint8List logicalLevels = Uint8List(bidiRuns.length);
    int count = 0;
    for (final bidiRun in bidiRuns) {
      final ClusterRange intesection = intersect(bidiRun.clusterRange, textRange);
      if (intesection.width <= 0) {
        continue;
      }
      logicalRuns.add(BidiRun(intesection, bidiRun.bidiLevel));
      logicalLevels[count] = bidiRun.bidiLevel;
      count += 1;
    }
    final List<BidiIndex> visualRunIndexes = canvasKit.Bidi.reorderVisual(
      logicalLevels.sublist(0, count),
    );
    line.visualRuns = [
      for (int index = 0; index < visualRunIndexes.length; index += 1) logicalRuns[index],
    ];

    // At this point we are agnostic of any fonts participating in text shaping
    // so we have to assume each cluster has a (different) font
    // TODO(jlavrova): we (almost always true) assume that trailing whitespaces do not affect the line height
    line.fontBoundingBoxAscent = 0.0;
    line.fontBoundingBoxDescent = 0.0;
    for (int i = line.textRange.start; i < line.textRange.end; i += 1) {
      final ExtendedTextCluster cluster = textClusters[i];
      line.fontBoundingBoxAscent = max(
        line.fontBoundingBoxAscent,
        cluster.textMetrics.fontBoundingBoxAscent,
      );
      line.fontBoundingBoxDescent = max(
        line.fontBoundingBoxDescent,
        cluster.textMetrics.fontBoundingBoxDescent,
      );
      final DomRectReadOnly box = cluster.textMetrics.getActualBoundingBox(
        cluster.start,
        cluster.end,
      );
    }
    // We need to take the VISUALLY first cluster (in case of LTR/RTL it could be anywhere)
    final double visualyLeft =
        (line.visualRuns.first.bidiLevel % 2) == 0
            ? textClusters[line.visualRuns.first.clusterRange.start].bounds.left
            : textClusters[line.visualRuns.first.clusterRange.end - 1].bounds.left;
    line.bounds = ui.Rect.fromLTWH(
      visualyLeft,
      _top,
      textWidth,
      line.fontBoundingBoxAscent + line.fontBoundingBoxDescent,
    );
    lines.add(line);
    final String lineText = paragraph.text!.substring(line.textRange.start, line.textRange.end);
    WebParagraphDebug.log(
      'Line [${line.textRange.start}:${line.textRange.end}) ${line.bounds.left},${line.bounds.top} ${line.bounds.width}x${line.bounds.height} "$lineText"',
    );
    _top += line.bounds.height;
  }

  void reorderVisuals() {
    // TODO(jlavrova): Use bidi API to reorder visual runs for all lines
    // (maybe breaking these runs by lines in addition)
  }
}

class ExtendedTextCluster {
  ExtendedTextCluster(this.cluster, this.bounds, this.textMetrics) {
    start = cluster.begin;
    end = cluster.end;
  }

  WebTextCluster cluster;
  int start = 0;
  int end = 0;
  ui.Rect bounds;

  // TODO(jlavrova): once we know everything we need we can calculate it once
  // and do not keep textMetrics longer than we have to
  DomTextMetrics textMetrics;
}

class BidiRun {
  BidiRun(/*this.textLayout,*/ this.clusterRange, this.bidiLevel);

  //final TextLayout textLayout;
  final int bidiLevel;
  final ClusterRange clusterRange;
}

class TextLine {
  TextLine(
    this.textLayout,
    this.textRange,
    this.textWidth,
    this.whitespacesRange,
    this.whitespacesWidth,
    this.hardLineBreak,
  );

  final TextLayout textLayout;
  final ClusterRange textRange;
  final ClusterRange whitespacesRange;
  final double textWidth;
  final double whitespacesWidth;
  final bool hardLineBreak;

  // Calculated and extracted
  ui.Rect bounds = ui.Rect.zero;
  double fontBoundingBoxAscent = 0.0;
  double fontBoundingBoxDescent = 0.0;
  List<BidiRun> visualRuns = <BidiRun>[];
}

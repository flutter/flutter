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

  Map<int, int> textToClusterMap = <int, int>{};

  bool hasFlag(ui.TextRange cluster, int flag) {
    return codeUnitFlags[cluster.start].hasFlag(flag);
  }

  void performLayout(double width) {
    extractClusterTexts();

    extractBidiRuns();

    extractUnicodeInfo();

    wrapText(width);

    formatLines(width);
  }

  void extractUnicodeInfo() {
    codeUnitFlags.clear();

    final List<CodeUnitInfo> flags = canvasKit.CodeUnits.compute(paragraph.text!);
    assert(flags.length == (paragraph.text!.length + 1));
    for (final CodeUnitInfo flag in flags) {
      // WebParagraphDebug.log('codeUnitFlags[${codeUnitFlags.length}]=${CodeUnitFlags(flag.flags)}');
      codeUnitFlags.add(CodeUnitFlags(flag.flags));
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
  }

  void extractClusterTexts() {
    // Walk through all the styled text ranges
    double blockStart = 0.0;
    for (final StyledTextRange styledBlock in paragraph.styledTextRanges) {
      final String text = paragraph.text!.substring(
        styledBlock.textRange.start,
        styledBlock.textRange.end,
      );
      textContext.font =
          '${styledBlock.textStyle.fontSize}px ${styledBlock.textStyle.originalFontFamily!}';
      final DomTextMetrics blockTextMetrics = textContext.measureText(text);
      double blockWidth = 0.0;
      for (final WebTextCluster cluster in blockTextMetrics.getTextClusters()) {
        final List<DomRectReadOnly> rects = blockTextMetrics.getSelectionRects(
          cluster.begin,
          cluster.end,
        );
        assert(rects.length == 1, 'Cluster text must be presented by a single rectangle');
        final DomRectReadOnly box = blockTextMetrics.getActualBoundingBox(
          cluster.begin,
          cluster.end,
        );
        final ui.Rect bounds = ui.Rect.fromLTWH(box.left, box.top, box.width, box.height);
        for (
          int i = cluster.begin + styledBlock.textRange.start;
          i < cluster.end + styledBlock.textRange.start;
          i += 1
        ) {
          textToClusterMap[i] = textClusters.length;
        }
        final String clusterText = paragraph.text!.substring(
          cluster.begin + styledBlock.textRange.start,
          cluster.end + styledBlock.textRange.start,
        );
        WebParagraphDebug.log(
          '"$clusterText": [${cluster.begin}:${cluster.end}) ${bounds.left}:${bounds.right} x ${bounds.top}:${box.bottom} ${rects.first.left}:${rects.first.right} x ${rects.first.top}:${rects.first.bottom}',
        );
        textClusters.add(
          ExtendedTextCluster(
            cluster,
            /*textRange:*/ ClusterRange(
              start: cluster.begin + styledBlock.textRange.start,
              end: cluster.end + styledBlock.textRange.start,
            ),
            styledBlock.textStyle,
            bounds,
            blockStart,
            blockTextMetrics,
          ),
        );
        blockWidth += rects.first.width;
      }
      blockStart += blockWidth;
    }
    textToClusterMap[paragraph.text!.length] = textClusters.length;
    textClusters.add(ExtendedTextCluster.empty());
  }

  ClusterRange convertTextToClusterRange(int start, int end) {
    return ClusterRange(start: textToClusterMap[start]!, end: textToClusterMap[end]!);
  }

  String getTextFromClusterRange(ClusterRange clusterRange) {
    final ExtendedTextCluster start =
        textClusters[min(clusterRange.start, textClusters.length - 1)];
    final ExtendedTextCluster end = textClusters[min(clusterRange.end, textClusters.length - 1)];
    if (start.cluster != null && end.cluster != null && start.start != end.start) {
      return paragraph.text!.substring(start.start, end.start);
    } else {
      return '';
    }
  }

  void extractBidiRuns() {
    bidiRuns.clear();

    final List<BidiRegion> regions = canvasKit.Bidi.getBidiRegions(
      paragraph.text!,
      paragraph.paragraphStyle.textDirection,
    );

    WebParagraphDebug.log('Bidi ${paragraph.paragraphStyle.textDirection}:${regions.length}');
    for (final region in regions) {
      WebParagraphDebug.log('region [${region.start}: ${region.end}):${region.level}');
    }

    for (final region in regions) {
      // Regions operate in text indexes, not cluster indexes (one cluster can contain several text points)
      // We need to convert one into another
      final ClusterRange clusterRange = convertTextToClusterRange(region.start, region.end);
      final BidiRun run = BidiRun(clusterRange, region.level, 0);
      bidiRuns.add(run);
    }
  }

  void printClusters() {
    WebParagraphDebug.log('Text Clusters: ${textClusters.length}');
    int runIndex = 0;
    for (final BidiRun run in bidiRuns) {
      final String runText = getTextFromClusterRange(run.clusterRange);
      WebParagraphDebug.log('');
      WebParagraphDebug.log(
        'Run$runIndex[${run.clusterRange.start}:${run.clusterRange.end}): "$runText"',
      );
      for (var i = run.clusterRange.start; i < run.clusterRange.end; ++i) {
        final ExtendedTextCluster cluster = textClusters[i];
        final String clusterText = paragraph.text!.substring(cluster.start, cluster.end);
        WebParagraphDebug.log(
          '$i: [${cluster.start}:${cluster.end}) ${cluster.bounds.width} * ${cluster.bounds.height} "$clusterText"',
        );
      }
      runIndex += 1;
    }
  }

  void wrapText(double width) {
    lines.clear();

    final TextWrapper wrapper = TextWrapper(paragraph.text!, this);
    wrapper.breakLines(width);
  }

  ClusterRange intersect(ClusterRange a, ClusterRange b) {
    return ClusterRange(start: max(a.start, b.start), end: min(a.end, b.end));
  }

  double getLeft(BidiRun run, ClusterRange textRange) {
    final ClusterRange intesect = intersect(textRange, run.clusterRange);
    return run.bidiLevel.isEven
        ? textClusters[intesect.start].cluster!.x
        : textClusters[intesect.end - 1].cluster!.x;
  }

  double addLine(
    ClusterRange textRange,
    double textWidth,
    ClusterRange whitespaces,
    double whitespacesWidth,
    bool hardLineBreak,
    double top,
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
    WebParagraphDebug.log(
      'line [${textRange.start}:${textRange.end}) + [${whitespaces.start}:${whitespaces.end})',
    );
    // Get visual runs
    final List<int> logicalLevels = <int>[];
    int firstRunIndex = 0;
    for (final bidiRun in bidiRuns) {
      final ClusterRange intesection1 = intersect(bidiRun.clusterRange, textRange);
      final ClusterRange intesection2 = intersect(bidiRun.clusterRange, whitespaces);
      if (intesection1.width <= 0 && intesection2.width <= 0) {
        if (logicalLevels.isNotEmpty) {
          // No more runs for this line
          break;
        }
        // We haven't found a run for his line yet
        firstRunIndex += 1;
      } else {
        // This run is on the line (at least, partially)
        logicalLevels.add(bidiRun.bidiLevel);
      }
    }

    // Reorder this line runs in visual order
    final List<BidiIndex> visuals = canvasKit.Bidi.reorderVisual(Uint8List.fromList(logicalLevels));

    // We need to take the VISUALLY first cluster on the line (in case of LTR/RTL it could be anywhere)
    // and shift all runs for this line so this first cluster starts from 0
    final double lineLeftX = getLeft(bidiRuns[visuals.first.index + firstRunIndex], textRange);
    for (final BidiIndex visual in visuals) {
      final BidiRun run = bidiRuns[visual.index + firstRunIndex];
      line.visualRuns.add(
        BidiRun(intersect(run.clusterRange, textRange), run.bidiLevel, lineLeftX),
      );
    }

    // At this point we are agnostic of any fonts participating in text shaping
    // so we have to assume each cluster has a (different) font
    // TODO(jlavrova): we (almost always true) assume that trailing whitespaces do not affect the line height
    line.fontBoundingBoxAscent = 0.0;
    line.fontBoundingBoxDescent = 0.0;
    for (int i = line.textRange.start; i < line.textRange.end; i += 1) {
      final ExtendedTextCluster cluster = textClusters[i];
      if (cluster.textMetrics == null) {
        continue;
      }
      line.fontBoundingBoxAscent = max(
        line.fontBoundingBoxAscent,
        cluster.textMetrics!.fontBoundingBoxAscent,
      );
      line.fontBoundingBoxDescent = max(
        line.fontBoundingBoxDescent,
        cluster.textMetrics!.fontBoundingBoxDescent,
      );
    }

    line.bounds = ui.Rect.fromLTWH(
      0,
      top,
      textWidth,
      line.fontBoundingBoxAscent + line.fontBoundingBoxDescent,
    );
    lines.add(line);
    final String lineText = getTextFromClusterRange(line.textRange);
    WebParagraphDebug.log(
      'Line [${line.textRange.start}:${line.textRange.end}) ${line.bounds.left},${line.bounds.top} ${line.bounds.width}x${line.bounds.height} "$lineText"',
    );

    return line.bounds.height;
  }

  void formatLines(double width) {
    // TODO(jlavrova): there is a special case in cpp SkParagraph; we need to decide if we keep it
    // Special case: clean all text in case of maxWidth == INF & align != left
    // We had to go through shaping though because we need all the measurement numbers

    final effectiveAlign = paragraph.paragraphStyle.effectiveAlign();
    for (final TextLine line in lines) {
      final double delta = width - line.bounds.width;
      if (delta <= 0) {
        return;
      }

      // We do nothing for left align
      if (effectiveAlign == ui.TextAlign.justify) {
        // TODO(jlavrova): implement justify
      } else if (effectiveAlign == ui.TextAlign.right) {
        line.shift = delta;
      } else if (effectiveAlign == ui.TextAlign.center) {
        line.shift = delta / 2;
      }
    }
  }
}

class ExtendedTextCluster {
  ExtendedTextCluster(
    this.cluster,
    this.textRange,
    this.textStyle,
    this.bounds,
    this.shift,
    this.textMetrics,
  ) {
    start = cluster!.begin;
    end = cluster!.end;
  }

  ExtendedTextCluster.empty()
    : shift = 0.0,
      bounds = ui.Rect.zero,
      textRange = ClusterRange(start: 0, end: 0);

  WebTextCluster? cluster;
  ClusterRange textRange;
  int start = 0;
  int end = 0;
  ui.Rect bounds;
  double shift;
  WebTextStyle? textStyle;

  // TODO(jlavrova): once we know everything we need we can calculate it once
  // and do not keep textMetrics longer than we have to
  DomTextMetrics? textMetrics;
}

class BidiRun {
  BidiRun(this.clusterRange, this.bidiLevel, this.shift);

  final int bidiLevel;
  final ClusterRange clusterRange;
  final double shift;
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
  double shift = 0.0;
}

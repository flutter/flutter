// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../canvaskit/text_fragmenter.dart';
import '../dom.dart';
import 'code_unit_flags.dart';
import 'debug.dart';
import 'paragraph.dart';
import 'wrapper.dart';

/// A single canvas2d context to use for all text information.
@visibleForTesting
final DomCanvasRenderingContext2D layoutContext =
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

  bool get isDefaultLtr => paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr;
  bool get isDefaultRtl => paragraph.paragraphStyle.textDirection == ui.TextDirection.rtl;

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
    final SegmentationResult result = segmentText(paragraph.text!);

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
    layoutContext.direction = isDefaultLtr ? 'ltr' : 'rtl';
    for (final StyledTextRange styledBlock in paragraph.styledTextRanges) {
      final String text = paragraph.text!.substring(
        styledBlock.textRange.start,
        styledBlock.textRange.end,
      );
      layoutContext.font =
          '${styledBlock.textStyle.fontSize}px ${styledBlock.textStyle.originalFontFamily!}';
      final DomTextMetrics blockTextMetrics = layoutContext.measureText(text);
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
        final ui.Rect advance = ui.Rect.fromLTWH(
          rects.first.left,
          rects.first.top,
          rects.first.width,
          rects.first.height,
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
            advance,
            blockStart,
            blockTextMetrics,
          ),
        );
      }
      blockStart += blockTextMetrics.width!;
    }

    textClusters.sort((a, b) => a.textRange.start.compareTo(b.textRange.start));
    for (int i = 0; i < textClusters.length; ++i) {
      final ExtendedTextCluster textCluster = textClusters[i];
      for (int j = textCluster.textRange.start; j < textCluster.textRange.end; j += 1) {
        textToClusterMap[j] = i;
      }
    }

    textToClusterMap[paragraph.text!.length] = textClusters.length;
    textClusters.add(ExtendedTextCluster.empty());

    printClusters('Sorted');
  }

  ClusterRange convertTextToClusterRange(int textStart, int textEnd) {
    final int clusterStart = textToClusterMap[textStart]!;
    final int clusterEnd = textToClusterMap[textEnd - 1]!;
    return ClusterRange(start: clusterStart, end: clusterEnd + 1);
  }

  String getTextFromMonodirectionalClusterRange(ClusterRange clusterRange) {
    final ExtendedTextCluster start = textClusters[clusterRange.start];
    final ExtendedTextCluster end = textClusters[clusterRange.end - 1];
    return paragraph.text!.substring(
      math.min(start.textRange.start, end.textRange.end),
      math.max(start.textRange.start, end.textRange.end),
    );
  }

  void extractBidiRuns() {
    bidiRuns.clear();

    final List<BidiRegion> regions = canvasKit.Bidi.getBidiRegions(
      paragraph.text!,
      paragraph.paragraphStyle.textDirection,
    );

    WebParagraphDebug.log('Bidis ${paragraph.paragraphStyle.textDirection}:${regions.length}');
    for (final region in regions) {
      // Regions operate in text indexes, not cluster indexes (one cluster can contain several text points)
      // We need to convert one into another
      final ClusterRange clusterRange = convertTextToClusterRange(region.start, region.end);
      final BidiRun run = BidiRun(clusterRange, region.level);
      WebParagraphDebug.log(
        'region ${region.level.isEven ? 'ltr' : 'rtl'} [${region.start}:${region.end}) => $clusterRange',
      );
      bidiRuns.add(run);
    }
  }

  void printClusters(String header) {
    WebParagraphDebug.log('Text Clusters ($header): ${textClusters.length}');
    int i = 0;
    for (final ExtendedTextCluster cluster in textClusters) {
      final String clusterText = paragraph.text!.substring(cluster.start, cluster.end);
      WebParagraphDebug.log(
        'cluster[$i]: [${cluster.start}:${cluster.end}) "$clusterText" ${cluster.advance.width} ${cluster.bounds.left}:${cluster.bounds.right} ${cluster.bounds.width}*${cluster.bounds.height}',
      );
      i += 1;
    }
  }

  void printClustersByBidi() {
    WebParagraphDebug.log('Text Clusters: ${textClusters.length}');
    int runIndex = 0;
    for (final BidiRun run in bidiRuns) {
      final String runText = getTextFromMonodirectionalClusterRange(run.clusterRange);
      WebParagraphDebug.log(
        'Run[$runIndex]: [${run.clusterRange.start}:${run.clusterRange.end}) "$runText"',
      );
      for (var i = run.clusterRange.start; i < run.clusterRange.end; ++i) {
        final ExtendedTextCluster cluster = textClusters[i];
        final String clusterText = paragraph.text!.substring(cluster.start, cluster.end);
        WebParagraphDebug.log(
          '$i: [${cluster.start}:${cluster.end}) ${cluster.bounds.left}:${cluster.bounds.right} ${cluster.bounds.width}*${cluster.bounds.height} "$clusterText"',
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

  ClusterRange intersectClusterRange(ClusterRange a, ClusterRange b) {
    return ClusterRange(start: math.max(a.start, b.start), end: math.min(a.end, b.end));
  }

  ClusterRange mergeSequentialClusterRanges(ClusterRange a, ClusterRange b) {
    assert(a.end == b.start || b.end == a.start);
    return ClusterRange(start: math.min(a.start, b.start), end: math.max(a.end, b.end));
  }

  String text(ClusterRange r) {
    return paragraph.text!.substring(r.start, r.end);
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
    WebParagraphDebug.log('line $textRange + $whitespaces $textWidth $whitespacesWidth');
    // Get visual runs
    final List<int> logicalLevels = <int>[];
    int firstRunIndex = 0;
    for (final bidiRun in bidiRuns) {
      final ClusterRange intesection1 = intersectClusterRange(bidiRun.clusterRange, textRange);
      final ClusterRange intesection2 = intersectClusterRange(bidiRun.clusterRange, whitespaces);
      if (intesection1.width <= 0 && intesection2.width <= 0) {
        if (logicalLevels.isNotEmpty) {
          // No more runs for this line
          break;
        }
        // We haven't found a run for his line yet
        firstRunIndex += 1;
      } else {
        // This run is on the line (at least, partially)
        WebParagraphDebug.log(
          'Add bidiRun '
          '${bidiRun.clusterRange} & $textRange = $intesection1} '
          '${bidiRun.clusterRange} & $whitespaces = $intesection2} ',
        );
        logicalLevels.add(bidiRun.bidiLevel);
      }
    }

    // Reorder this line runs in visual order
    final List<BidiIndex> visuals = canvasKit.Bidi.reorderVisual(Uint8List.fromList(logicalLevels));

    // We need to take the VISUALLY first cluster on the line (in case of LTR/RTL it could be anywhere)
    // and shift all runs for this line so this first cluster starts from 0
    double shiftInsideLine = 0.0;
    for (final BidiIndex visual in visuals) {
      final BidiRun bidiRun = bidiRuns[visual.index + firstRunIndex];
      final ClusterRange lineRunClusterRange = intersectClusterRange(
        bidiRun.clusterRange,
        textRange,
      );
      final ClusterRange whitespacesClusterRange = intersectClusterRange(
        bidiRun.clusterRange,
        whitespaces,
      );
      final String lineRunText = getTextFromMonodirectionalClusterRange(lineRunClusterRange);
      WebParagraphDebug.log(
        'Intersect "$lineRunText" '
        '${bidiRun.clusterRange} & $textRange = $lineRunClusterRange '
        '${bidiRun.clusterRange} & $whitespaces = $whitespacesClusterRange',
      );
      final DomTextMetrics lineRunTextMetrics = layoutContext.measureText(lineRunText);
      final List<DomRectReadOnly> rects = lineRunTextMetrics.getSelectionRects(
        0,
        lineRunClusterRange.width,
      );
      for (int i = 0; i < rects.length; i++) {
        WebParagraphDebug.log(
          '$i: ${rects[i].left}:${rects[i].right} ${rects[i].width} ${lineRunTextMetrics.width}',
        );
      }
      final ExtendedTextCluster firstVisualClusterInRun =
          bidiRun.bidiLevel.isEven
              ? textClusters[lineRunClusterRange.start]
              : textClusters[lineRunClusterRange.end - 1];

      line.visualRuns.add(
        LineRun(
          lineRunClusterRange,
          bidiRun.bidiLevel,
          lineRunTextMetrics.width!,
          shiftInsideLine - firstVisualClusterInRun.shift - firstVisualClusterInRun.advance.left,
        ),
      );
      WebParagraphDebug.log(
        'Run[${visual.index} + $firstRunIndex]: "$lineRunText" ${bidiRun.bidiLevel.isEven ? 'ltr' : 'rtl'} {bidiRun.clusterRange}=>$lineRunClusterRange '
        'width=${line.visualRuns.last.width} shift=${line.visualRuns.last.shiftInsideLine}=$shiftInsideLine-${firstVisualClusterInRun.shift}-${firstVisualClusterInRun.advance.left}',
      );
      shiftInsideLine += lineRunTextMetrics.width!;
    }

    WebParagraphDebug.log('Line width: $shiftInsideLine vs $textWidth +$whitespacesWidth');

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
      line.fontBoundingBoxAscent = math.max(
        line.fontBoundingBoxAscent,
        cluster.textMetrics!.fontBoundingBoxAscent,
      );
      line.fontBoundingBoxDescent = math.max(
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
    WebParagraphDebug.log(
      'Line [${line.textRange.start}:${line.textRange.end}) ${line.bounds.left},${line.bounds.top} ${line.bounds.width}x${line.bounds.height}',
    );

    return line.bounds.height;
  }

  void formatLines(double width) {
    // TODO(jlavrova): there is a special case in cpp SkParagraph; we need to decide if we keep it
    // Special case: clean all text in case of maxWidth == INF & align != left
    // We had to go through shaping though because we need all the measurement numbers
    final effectiveAlign = paragraph.paragraphStyle.effectiveAlign();
    for (final TextLine line in lines) {
      if (width == double.infinity) {
        line.formattingShift = 0;
        continue;
      }
      final double delta = width - line.bounds.width;
      if (delta <= 0) {
        return;
      }

      // We do nothing for left align
      if (effectiveAlign == ui.TextAlign.justify) {
        // TODO(jlavrova): implement justify
      } else if (effectiveAlign == ui.TextAlign.right) {
        line.formattingShift = delta;
      } else if (effectiveAlign == ui.TextAlign.center) {
        line.formattingShift = delta / 2;
      }

      WebParagraphDebug.log('formatLines($width): $effectiveAlign $delta ${line.formattingShift}');
    }
  }
}

class ExtendedTextCluster {
  ExtendedTextCluster(
    this.cluster,
    this.textRange,
    this.textStyle,
    this.bounds,
    this.advance,
    this.shift,
    this.textMetrics,
  ) {
    start = cluster!.begin;
    end = cluster!.end;
  }

  ExtendedTextCluster.empty()
    : shift = 0.0,
      bounds = ui.Rect.zero,
      advance = ui.Rect.zero,
      textRange = ClusterRange(start: 0, end: 0);

  WebTextCluster? cluster;
  ClusterRange textRange;
  int start = 0;
  int end = 0;
  ui.Rect bounds;
  ui.Rect advance;
  double shift;
  WebTextStyle? textStyle;

  // TODO(jlavrova): once we know everything we need we can calculate it once
  // and do not keep textMetrics longer than we have to
  DomTextMetrics? textMetrics;
}

class BidiRun {
  BidiRun(this.clusterRange, this.bidiLevel);
  final int bidiLevel;
  final ClusterRange clusterRange;
}

class LineRun extends BidiRun {
  LineRun(super.clusterRange, super.bidiLevel, this.width, this.shiftInsideLine);
  final double width;
  final double shiftInsideLine;
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
  List<LineRun> visualRuns = <LineRun>[];
  double formattingShift = 0.0;
}

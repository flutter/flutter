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
  List<StyledTextBlock> styledTextBlocks = <StyledTextBlock>[];
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

    // Get the information from Skia (bidi runs and some hardcoded flags we cannot get from anywhere else)
    final List<CodeUnitInfo> flags = canvasKit.CodeUnits.compute(paragraph.text!);
    assert(flags.length == (paragraph.text!.length + 1));
    for (final CodeUnitInfo flag in flags) {
      codeUnitFlags.add(CodeUnitFlags(flag.flags));
    }

    // Get the information from the browser
    final SegmentationResult result = segmentText(paragraph.text!);
    for (final grapheme in result.graphemes) {
      codeUnitFlags[grapheme].graphemeStart = true;
    }
    for (final word in result.words) {
      codeUnitFlags[word].wordBreak = true;
    }
    for (int index = 0; index < result.breaks.length; index += 2) {
      final int lineBreak = result.breaks[index];
      if (result.breaks[index + 1] == 0) {
        codeUnitFlags[lineBreak].softLineBreak = true;
      } else {
        codeUnitFlags[lineBreak].hardLineBreak = true;
      }
    }
  }

  String styleToString(ui.FontStyle fontStyle) {
    return fontStyle == ui.FontStyle.normal
        ? 'normal'
        : fontStyle == ui.FontStyle.italic
        ? 'italic'
        : 'undefined';
  }

  String weightToString(ui.FontWeight fontWeight) {
    return fontWeight.value == ui.FontWeight.normal.value
        ? 'normal'
        : fontWeight.value == ui.FontWeight.bold.value
        ? 'bold'
        : fontWeight.value > ui.FontWeight.normal.value
        ? 'bolder'
        : fontWeight.value < ui.FontWeight.normal.value
        ? 'lighter'
        : fontWeight.value.toStringAsFixed(2);
  }

  ui.Rect getAdvance(DomTextMetrics textMetrics, TextRange textRange) {
    WebParagraphDebug.log('getAdvance($textRange) ${textMetrics.getTextClusters().length}');
    final List<DomRectReadOnly> rects = textMetrics.getSelectionRects(
      textRange.start,
      textRange.end,
    );
    if (rects.length != 1) {
      // TODO(jlavrova): assert that this is a continuous set of rectangles
      ui.Rect union = ui.Rect.fromLTWH(
        rects.first.left,
        rects.first.top,
        rects.first.width,
        rects.first.height,
      );
      WebParagraphDebug.log('getAdvance($textRange)');
      for (final rect in rects) {
        WebParagraphDebug.log('[${rect.left}:${rect.right})');
        final r = ui.Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
        union = union.expandToInclude(r);
        WebParagraphDebug.log('[${union.left}:${union.right})');
      }
      return union;
    }
    //assert(rects.length == 1, 'Cluster text must be presented by a single rectangle');
    return ui.Rect.fromLTWH(
      rects.first.left,
      rects.first.top,
      rects.first.width,
      rects.first.height,
    );
  }

  ui.Rect getBounds(DomTextMetrics textMetrics, TextRange textRange) {
    final DomRectReadOnly box = textMetrics.getActualBoundingBox(textRange.start, textRange.end);
    return ui.Rect.fromLTWH(box.left, box.top, box.width, box.height);
  }

  void extractClusterTexts() {
    // Walk through all the styled text ranges
    double blockStart = 0.0;
    layoutContext.direction = isDefaultLtr ? 'ltr' : 'rtl';
    for (final StyledTextRange styledBlock in paragraph.styledTextRanges) {
      final String text = paragraph.getText(styledBlock.textRange);

      layoutContext.font = styledBlock.textStyle.buildCssFontString();

      final DomTextMetrics blockTextMetrics = layoutContext.measureText(text);
      styledTextBlocks.add(
        StyledTextBlock(
          styledBlock.textRange.start,
          styledBlock.textRange.end,
          styledBlock.textStyle,
          blockTextMetrics,
        ),
      );
      printTextMetrics(text, blockTextMetrics);
      for (final WebTextCluster cluster in blockTextMetrics.getTextClusters()) {
        final ui.Rect advance = getAdvance(
          blockTextMetrics,
          TextRange(start: cluster.begin, end: cluster.end),
        );
        final ui.Rect bounds = getBounds(
          blockTextMetrics,
          TextRange(start: cluster.begin, end: cluster.end),
        );
        textClusters.add(
          ExtendedTextCluster(
            cluster,
            styledBlock.textStyle,
            blockTextMetrics,
            TextRange(
              start: cluster.begin + styledBlock.textRange.start,
              end: cluster.end + styledBlock.textRange.start,
            ),
            bounds,
            advance,
            blockStart,
          ),
        );
      }
      final ui.Rect blockAdvance = getAdvance(
        blockTextMetrics,
        TextRange(start: 0, end: text.length),
      );
      WebParagraphDebug.log(
        'blockStart: ${blockStart + blockAdvance.width} += $blockStart + ${blockAdvance.width})',
      );
      blockStart += blockAdvance.width;
    }

    textClusters.sort((a, b) => a.textRange.start.compareTo(b.textRange.start));
    for (int i = 0; i < textClusters.length; ++i) {
      final ExtendedTextCluster textCluster = textClusters[i];
      for (int j = textCluster.textRange.start; j < textCluster.textRange.end; j += 1) {
        textToClusterMap[j] = i;
      }
    }

    textToClusterMap[paragraph.text!.length] = textClusters.length;
    textClusters.add(ExtendedTextCluster.fromLast(textClusters.last));

    printClusters('Full text');
  }

  ClusterRange convertTextToClusterRange(TextRange textRange) {
    final int clusterStart = textToClusterMap[textRange.start]!;
    final int clusterEnd = textToClusterMap[textRange.end - 1]!;
    return ClusterRange(start: clusterStart, end: clusterEnd + 1);
  }

  TextRange convertSequentialClusterRangeToText(ClusterRange clusterRange) {
    final ExtendedTextCluster start = textClusters[clusterRange.start];
    final ExtendedTextCluster end = textClusters[clusterRange.end - 1];
    return TextRange(
      start: math.min(start.textRange.start, end.textRange.end),
      end: math.max(start.textRange.start, end.textRange.end),
    );
  }

  String getTextFromMonodirectionalClusterRange(ClusterRange clusterRange) {
    if (clusterRange.isEmpty) {
      return '';
    }
    final ExtendedTextCluster start = textClusters[clusterRange.start];
    final ExtendedTextCluster end = textClusters[clusterRange.end - 1];
    final TextRange textRange = TextRange(
      start: math.min(start.textRange.start, end.textRange.end),
      end: math.max(start.textRange.start, end.textRange.end),
    );
    return paragraph.getText(textRange);
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
      final ClusterRange clusterRange = convertTextToClusterRange(
        TextRange(start: region.start, end: region.end),
      );
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
      final String clusterText = paragraph.getText(cluster.textRange);
      WebParagraphDebug.log(
        'cluster[$i]: "$clusterText" ${cluster.textRange} @${cluster.shift} ${cluster.advance.left}:${cluster.advance.right}=${cluster.advance.width} ${cluster.bounds.left}:${cluster.bounds.right}=${cluster.bounds.width}',
      );
      i += 1;
    }
  }

  void printTextMetrics(String text, DomTextMetrics textMetrics) {
    final clusters = textMetrics.getTextClusters();
    WebParagraphDebug.log('TextMetrics "$text": ${clusters.length}');
    int index = 0;
    for (final cluster in clusters) {
      final advance = textMetrics.getSelectionRects(cluster.begin, cluster.end);
      assert(advance.length == 1);
      WebParagraphDebug.log(
        '$index: [${cluster.begin}:${cluster.end}) [${advance.first.left}:${advance.first.right})',
      );
      index++;
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
        final String clusterText = paragraph.getText(cluster.textRange);
        WebParagraphDebug.log(
          '$i: [${cluster.textRange.start}:${cluster.textRange.end}) ${cluster.bounds.left}:${cluster.bounds.right} ${cluster.bounds.width}*${cluster.bounds.height} "$clusterText"',
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

  TextRange intersectTextRange(TextRange a, TextRange b) {
    return TextRange(start: math.max(a.start, b.start), end: math.min(a.end, b.end));
  }

  ClusterRange mergeSequentialClusterRanges(ClusterRange a, ClusterRange b) {
    assert(a.end == b.start || b.end == a.start);
    return ClusterRange(start: math.min(a.start, b.start), end: math.max(a.end, b.end));
  }

  String getTextFromClusterRange(ClusterRange clusterRange) {
    final TextRange textRange = convertSequentialClusterRangeToText(clusterRange);
    return paragraph.getText(textRange);
  }

  double addLine(
    ClusterRange lineClusterRange,
    ClusterRange whitespacesClusterRange,
    bool hardLineBreak,
    double top,
  ) {
    // Arrange line vertically, calculate metrics and bounds
    final String allText = getTextFromClusterRange(
      mergeSequentialClusterRanges(lineClusterRange, whitespacesClusterRange),
    );
    WebParagraphDebug.log('LINE "$allText" clusters:$lineClusterRange+$whitespacesClusterRange');

    final TextRange lineTextRange = convertSequentialClusterRangeToText(lineClusterRange);
    final TextRange whitespacesTextRange = convertSequentialClusterRangeToText(
      whitespacesClusterRange,
    );
    WebParagraphDebug.log('LINE "$allText" text:$lineTextRange+$whitespacesTextRange');

    assert(lineTextRange.end == whitespacesTextRange.start);

    final TextLine line = TextLine(lineClusterRange, whitespacesClusterRange, hardLineBreak);

    // Get logical runs belonging th the line
    final List<int> logicalLevels = <int>[];
    int firstRunIndex = 0;
    for (final bidiRun in bidiRuns) {
      final ClusterRange intesection1 = intersectClusterRange(
        bidiRun.clusterRange,
        lineClusterRange,
      );
      final ClusterRange intesection2 = intersectClusterRange(
        bidiRun.clusterRange,
        whitespacesClusterRange,
      );
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
          '${bidiRun.clusterRange} & $lineClusterRange = $intesection1 '
          '${bidiRun.clusterRange} & $whitespacesClusterRange = $intesection2 ',
        );
        logicalLevels.add(bidiRun.bidiLevel);
      }
    }

    // Reorder the logical runs in visual order
    final List<BidiIndex> visuals = canvasKit.Bidi.reorderVisual(Uint8List.fromList(logicalLevels));

    // We need to take the VISUALLY first cluster on the line (in case of LTR/RTL it could be anywhere)
    // and shift all runs for this line so this first cluster starts from 0
    // Break the line into the blocks that belongs to the same bidi run (monodirectional text) and to the same style block (the same text metrics)
    double shiftInsideLine = 0.0;
    for (final BidiIndex visual in visuals) {
      final BidiRun bidiRun = bidiRuns[visual.index + firstRunIndex];
      final ClusterRange runClusterRange = intersectClusterRange(
        bidiRun.clusterRange,
        lineClusterRange,
      );
      final ClusterRange whitespacesRunClusterRange = intersectClusterRange(
        bidiRun.clusterRange,
        whitespacesClusterRange,
      );
      // We ignore whitespaces because for now we only use these textStyles for decoration
      // (and we do not decorate hanging whitespaces)
      if (runClusterRange.isEmpty) {
        // TODO(jlavrova): what to do with trailing whitespaces? (After implementing queries)
        assert(!whitespacesRunClusterRange.isEmpty);
        continue;
      }

      final String runText = getTextFromMonodirectionalClusterRange(runClusterRange);
      final TextRange runTextRange = convertSequentialClusterRangeToText(runClusterRange);

      WebParagraphDebug.log(
        'Run: "$runText" '
        '${bidiRun.clusterRange} & $lineClusterRange = $runClusterRange textRange:$runTextRange',
      );

      for (final styledTextBlock in styledTextBlocks) {
        final TextRange styleTextRange = intersectTextRange(
          styledTextBlock.textRange,
          runTextRange,
        );
        if (styleTextRange.width <= 0) {
          continue;
        }
        WebParagraphDebug.log(
          'Style: ${styledTextBlock.textRange} & $runTextRange = $styleTextRange ',
        );
        final ClusterRange styleClusterRange = convertTextToClusterRange(styleTextRange);
        final String styleText = getTextFromMonodirectionalClusterRange(styleClusterRange);
        final ui.Rect advance = getAdvance(
          styledTextBlock.textMetrics,
          styleTextRange.translate(-styledTextBlock.textRange.start),
        );
        final ExtendedTextCluster firstVisualClusterInBlock =
            bidiRun.bidiLevel.isEven
                ? textClusters[styleClusterRange.start]
                : textClusters[styleClusterRange.end - 1];

        line.visualBlocks.add(
          LineBlock(
            styledTextBlock.textMetrics,
            bidiRun.bidiLevel,
            styledTextBlock.textStyle,
            styleClusterRange,
            styleTextRange,
            advance.width,
            shiftInsideLine - firstVisualClusterInBlock.advance.left,
            styledTextBlock.textRange.start,
          ),
        );
        WebParagraphDebug.log(
          'Style: "$styleText" clusterRange: $styleClusterRange '
          'width:${advance.width} shift:${line.visualBlocks.last.clusterShiftInLine}=$shiftInsideLine-${firstVisualClusterInBlock.advance.left} ',
        );
        shiftInsideLine += advance.width;
      }
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
      line.fontBoundingBoxAscent = math.max(
        line.fontBoundingBoxAscent,
        cluster.textMetrics!.fontBoundingBoxAscent,
      );
      line.fontBoundingBoxDescent = math.max(
        line.fontBoundingBoxDescent,
        cluster.textMetrics!.fontBoundingBoxDescent,
      );
    }

    line.advance = ui.Rect.fromLTWH(
      0,
      top,
      shiftInsideLine, // At the end this shift is equal to the entire line width
      line.fontBoundingBoxAscent + line.fontBoundingBoxDescent,
    );
    lines.add(line);
    WebParagraphDebug.log(
      'Line [${line.textRange.start}:${line.textRange.end}) ${line.advance.left},${line.advance.top} ${line.advance.width}x${line.advance.height}',
    );

    return line.advance.height;
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
      final double delta = width - line.advance.width;
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
    this.textStyle,
    this.textMetrics,
    this.textRange, // Global indexes
    this.bounds,
    this.advance,
    this.shift,
  );

  ExtendedTextCluster.fromLast(ExtendedTextCluster lastCluster)
    : cluster = null,
      textStyle = lastCluster.textStyle,
      textMetrics = lastCluster.textMetrics,
      textRange = TextRange(start: lastCluster.textRange.end, end: lastCluster.textRange.end),
      bounds = ui.Rect.fromLTWH(
        lastCluster.bounds.right,
        lastCluster.bounds.top,
        0,
        lastCluster.bounds.height,
      ),
      advance = ui.Rect.fromLTWH(
        lastCluster.advance.right,
        lastCluster.advance.top,
        0,
        lastCluster.advance.height,
      ),
      shift = lastCluster.shift;

  ExtendedTextCluster.empty()
    : shift = 0.0,
      bounds = ui.Rect.zero,
      advance = ui.Rect.zero,
      textRange = TextRange(start: 0, end: 0);

  double absolutePositionX() {
    return /*style block shift*/ shift + /*cluster advance inside the style block*/ advance.left;
  }

  WebTextCluster? cluster;
  WebTextStyle? textStyle;
  DomTextMetrics? textMetrics;
  TextRange textRange;
  ui.Rect bounds;
  ui.Rect advance;
  double shift;
}

class BidiRun {
  BidiRun(this.clusterRange, this.bidiLevel);
  final int bidiLevel;
  final ClusterRange clusterRange;
}

class StyledTextBlock extends StyledTextRange {
  StyledTextBlock(super.start, super.end, super.textStyle, this.textMetrics);
  final DomTextMetrics textMetrics;
}

// This is (possibly) a piece of a bidi run that belongs to the line
// (with shiftInsideLine pointing to the position when this piece starts on the line)
class LineRun extends BidiRun {
  LineRun(super.clusterRange, super.bidiLevel, this.textRange, this.width, this.shiftInsideLine);
  final TextRange textRange;
  final double width;
  final double shiftInsideLine;
}

// This is the minimal range of cluster that belongs to the same bidi run and to the same style block
class LineBlock {
  LineBlock(
    this.textMetrics,
    this.bidiLevel,
    this.textStyle,
    this.clusterRange,
    this.textRange,
    this.width,
    this.clusterShiftInLine,
    this.textMetricsZero,
  );
  final DomTextMetrics? textMetrics;
  final int bidiLevel;
  final WebTextStyle textStyle;
  final ClusterRange clusterRange;
  final TextRange textRange; // within the entire text
  final double width;
  final double clusterShiftInLine;
  final int textMetricsZero; // from the beginning of the line to this block start
}

class TextLine {
  TextLine(this.textRange, this.whitespacesRange, this.hardLineBreak);

  final ClusterRange textRange;
  final ClusterRange whitespacesRange;
  final bool hardLineBreak;

  ui.Rect advance = ui.Rect.zero;
  double fontBoundingBoxAscent = 0.0;
  double fontBoundingBoxDescent = 0.0;
  double formattingShift = 0.0; // For centered or right aligned text

  List<LineBlock> visualBlocks = <LineBlock>[];
}

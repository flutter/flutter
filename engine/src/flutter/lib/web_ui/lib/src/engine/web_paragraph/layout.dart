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

      // Setup all the font affecting attributes
      layoutContext.font = styledBlock.textStyle.buildCssFontString();
      layoutContext.letterSpacing = styledBlock.textStyle.buildLetterSpacingString();
      layoutContext.wordSpacing = styledBlock.textStyle.buildWordSpacingString();

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
            blockTextMetrics.fontBoundingBoxAscent,
            blockTextMetrics.fontBoundingBoxDescent,
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
    paragraph.maxIntrinsicWidth = wrapper.maxIntrinsicWidth;
    paragraph.minIntrinsicWidth = wrapper.minIntrinsicWidth;
    paragraph.requiredWidth = width;
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
        final ExtendedTextCluster firstVisualClusterInBlock = bidiRun.bidiLevel.isEven
            ? textClusters[styleClusterRange.start]
            : textClusters[styleClusterRange.end - 1];

        line.visualBlocks.add(
          LineBlock(
            styledTextBlock.textMetrics,
            bidiRun.bidiLevel,
            styledTextBlock.textStyle,
            styleClusterRange,
            styleTextRange,
            advance,
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
    // TODO(jlavrova): count ascent/descent by blocks, not by clusters
    line.fontBoundingBoxAscent = 0.0;
    line.fontBoundingBoxDescent = 0.0;
    for (int i = line.textRange.start; i < line.textRange.end; i += 1) {
      final ExtendedTextCluster cluster = textClusters[i];
      line.fontBoundingBoxAscent = math.max(
        line.fontBoundingBoxAscent,
        cluster.fontBoundingBoxAscent,
      );
      line.fontBoundingBoxDescent = math.max(
        line.fontBoundingBoxDescent,
        cluster.fontBoundingBoxDescent,
      );
    }

    line.advance = ui.Rect.fromLTWH(
      0,
      top,
      shiftInsideLine,
      // At the end this shift is equal to the entire line width
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
    paragraph.requiredWidth = width;
    for (final TextLine line in lines) {
      if (width == double.infinity) {
        line.formattingShift = 0;
        paragraph.longestLine = line.advance.width;
        paragraph.width = line.advance.width;
        paragraph.height = line.advance.height;
        assert(lines.length == 1);
        return;
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
      paragraph.longestLine = math.max(
        paragraph.longestLine,
        line.advance.width + line.formattingShift,
      );
      paragraph.width = paragraph.longestLine;
      paragraph.height += line.advance.height;
      WebParagraphDebug.log(
        'formatLines($width): $effectiveAlign $delta ${line.formattingShift} ${paragraph.longestLine}',
      );
    }
  }

  static double EPSILON = 0.001;

  List<ui.TextBox> getBoxesForRange(
    int start,
    int end,
    ui.BoxHeightStyle boxHeightStyle,
    ui.BoxWidthStyle boxWidthStyle,
  ) {
    final TextRange textRange = TextRange(start: start, end: end);
    final List<ui.TextBox> result = <ui.TextBox>[];
    for (final line in lines) {
      WebParagraphDebug.log(
        'Line: ${line.textRange} & $textRange '
        '[${line.advance.left}:${line.advance.right} x ${line.advance.top}:${line.advance.bottom} '
        '${line.fontBoundingBoxAscent}+${line.fontBoundingBoxDescent}',
      );
      // We take whitespaces in account
      final TextRange lineTextRange = convertSequentialClusterRangeToText(
        mergeSequentialClusterRanges(line.textRange, line.whitespacesRange),
      );
      if (end <= lineTextRange.start || start > lineTextRange.end) {
        continue;
      }
      for (final LineBlock block in line.visualBlocks) {
        final intersect = intersectTextRange(block.textRange, textRange);
        WebParagraphDebug.log('block: ${block.textRange} & $textRange = $intersect');
        if (intersect.width <= 0) {
          continue;
        }
        final rects = block.textMetrics!.getSelectionRects(intersect.start, intersect.end);
        assert(
          rects.length == 1,
        ); // We are dealing with single bidi, single line, single style range
        final firstRect = ui.Rect.fromLTWH(
          rects.first.left,
          rects.first.top,
          rects.first.width,
          rects.first.height,
        ).translate(-block.advance.left, block.fontBoundingBoxAscent);
        WebParagraphDebug.log(
          'getSelectionRects(${intersect.start},${intersect.end}): '
          '${firstRect.left}:${firstRect.right} x ${firstRect.top}:${firstRect.bottom}',
        );
        // Now we need to recalculate the rects
        double left, right, top, bottom;
        switch (boxHeightStyle) {
          case ui.BoxHeightStyle.tight:
            top =
                firstRect.top +
                line.advance.top +
                line.fontBoundingBoxAscent -
                block.fontBoundingBoxAscent;
            bottom = top + block.fontBoundingBoxAscent + block.fontBoundingBoxDescent;
            assert((block.advance.height - (bottom - top).abs() < EPSILON));
          case ui.BoxHeightStyle.max:
            top = firstRect.top + line.advance.top;
            bottom = top + line.fontBoundingBoxAscent + line.fontBoundingBoxDescent;
            assert((line.advance.height - (bottom - top).abs() < EPSILON));
          case ui.BoxHeightStyle.strut:
            // TODO(jlavrova): implement
            throw UnimplementedError('BoxHeightStyle.strut not implemented');
          case ui.BoxHeightStyle.includeLineSpacingMiddle:
            // TODO(jlavrova): implement
            throw UnimplementedError('BoxHeightStyle.includeLineSpacingMiddle not implemented');
          case ui.BoxHeightStyle.includeLineSpacingTop:
            // TODO(jlavrova): implement
            throw UnimplementedError('BoxHeightStyle.includeLineSpacingTop not implemented');
          case ui.BoxHeightStyle.includeLineSpacingBottom:
            // TODO(jlavrova): implement
            throw UnimplementedError('BoxHeightStyle.includeLineSpacingBottom not implemented');
        }
        left = firstRect.left - (line.advance.left + line.formattingShift);
        right = left + firstRect.width;
        WebParagraphDebug.log('getSelectionRects: $left:$right x $top:$bottom');
        WebParagraphDebug.log(
          'shift: -x=${line.advance.left + line.formattingShift}='
          '${line.advance.left}+${line.formattingShift} +y=${line.advance.top + line.fontBoundingBoxAscent}',
        );
        result.add(
          ui.TextBox.fromLTRBD(
            left,
            top,
            right,
            bottom,
            block.bidiLevel.isEven ? ui.TextDirection.ltr : ui.TextDirection.rtl,
          ),
        );
      }

      if (boxWidthStyle == ui.BoxWidthStyle.max && paragraph.requiredWidth != double.infinity) {
        if ((result.first.left - 0).abs() > EPSILON) {
          result.insert(
            0,
            ui.TextBox.fromLTRBD(
              0,
              result.first.top,
              result.first.right,
              result.first.bottom,
              paragraph.paragraphStyle.textDirection,
            ),
          );
        }
        if ((result.last.right - paragraph.requiredWidth).abs() > EPSILON) {
          result.add(
            ui.TextBox.fromLTRBD(
              result.last.right,
              result.last.top,
              paragraph.requiredWidth,
              result.last.bottom,
              paragraph.paragraphStyle.textDirection,
            ),
          );
        }
      }
      WebParagraphDebug.log(
        'getBoxesForRange: [${line.advance.left}:${line.advance.right}x${line.advance.top}:${line.advance.bottom}]',
      );
      for (final rect in result) {
        WebParagraphDebug.log('[${rect.left}:${rect.right}x${rect.top}:${rect.bottom}]');
      }
    }
    return result;
  }

  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    WebParagraphDebug.log('getPositionForOffset($offset)');

    int lineNum = 0;
    for (final line in lines) {
      lineNum++;
      if (line.advance.top > offset.dy) {
        // We didn't find a line that contains the offset. All previous lines are placed above it and this one - below.
        // Actually, it's only possible for the first line (no lines before) because lines cover all vertical space.
        assert(lineNum == 1);
        return ui.TextPosition(offset: line.textRange.start, affinity: ui.TextAffinity.downstream);
      } else if (line.advance.bottom < offset.dy) {
        // We are not there yet; we need a line closest to the offset.
        continue;
      }
      WebParagraphDebug.log('Found line: ${line.textRange} ${line.advance} ');

      // We found the line that contains the offset; let's go through all the visual blocks to find the position
      int blockNum = 0;
      for (final block in line.visualBlocks) {
        blockNum++;
        if (block.advance.left > offset.dx) {
          // We didn't find any block and we already on the right side of our offset
          // It's only possible for the first block in the line
          assert(blockNum == 1);
          return ui.TextPosition(offset: line.textRange.end, affinity: ui.TextAffinity.downstream);
        } else if (block.advance.right < offset.dx) {
          // We are not there yet; we need a block containing the offset (or the closest to it)
          continue;
        }
        // Found the block; let's go through all the clusters IN VISUAL ORDER to find the position
        final int start = block.bidiLevel.isEven
            ? block.clusterRange.start
            : block.clusterRange.end - 1;
        final int end = block.bidiLevel.isEven
            ? block.clusterRange.end
            : block.clusterRange.start - 1;
        final int step = block.bidiLevel.isEven ? 1 : -1;
        WebParagraphDebug.log('Found block: ${block.clusterRange}');
        for (int i = start; i != end; i += step) {
          final cluster = textClusters[i];
          final ui.Rect rect = cluster.advance
              .translate(
                line.advance.left + line.formattingShift + block.clusterShiftInLine,
                line.advance.top + line.fontBoundingBoxAscent,
              )
              .inflate(EPSILON);
          WebParagraphDebug.log('Check cluster: $rect $offset');
          if (rect.contains(offset)) {
            // TODO(jlavrova): proportionally calculate the text position? I wouldn't...
            if (offset.dx - rect.left <= rect.right - offset.dx) {
              return ui.TextPosition(
                offset: cluster.textRange.start,
                affinity: ui.TextAffinity.upstream,
              );
            } else {
              return ui.TextPosition(
                offset: cluster.textRange.end,
                affinity: ui.TextAffinity.downstream,
              );
            }
          }
        }
        // We found the block but not the cluster? How could that happen
        assert(false);
      }

      // We didn't find the block containing our offset and
      // we didn't find the block that is on the right of the offset
      // So all the blocks are on the left
      return ui.TextPosition(offset: line.textRange.end, affinity: ui.TextAffinity.downstream);
    }
    // We didn't find the line containing our offset and
    // we didn't find the line that is down from the offset
    // So all the line are above the offset
    return ui.TextPosition(offset: paragraph.text!.length - 1, affinity: ui.TextAffinity.upstream);
  }
}

class ExtendedTextCluster {
  ExtendedTextCluster(
    this.cluster,
    this.textStyle,
    this.fontBoundingBoxAscent,
    this.fontBoundingBoxDescent,
    this.textRange, // Global indexes
    this.bounds,
    this.advance,
    this.shift,
  );

  ExtendedTextCluster.fromLast(ExtendedTextCluster lastCluster)
    : cluster = null,
      textStyle = lastCluster.textStyle,
      fontBoundingBoxAscent = lastCluster.fontBoundingBoxAscent,
      fontBoundingBoxDescent = lastCluster.fontBoundingBoxDescent,
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
      fontBoundingBoxAscent = 0.0,
      fontBoundingBoxDescent = 0.0,
      bounds = ui.Rect.zero,
      advance = ui.Rect.zero,
      textRange = TextRange(start: 0, end: 0);

  double absolutePositionX() {
    return /*style block shift*/ shift + /*cluster advance inside the style block*/ advance.left;
  }

  WebTextCluster? cluster;
  WebTextStyle? textStyle;
  double fontBoundingBoxAscent;
  double fontBoundingBoxDescent;
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
    this.advance,
    this.clusterShiftInLine,
    this.textMetricsZero,
  ) : fontBoundingBoxAscent = textMetrics!.fontBoundingBoxAscent,
      fontBoundingBoxDescent = textMetrics.fontBoundingBoxDescent;

  // TODO(jlavrova): we probably do not need that reference
  final DomTextMetrics? textMetrics; // This is just a reference to a parent styled text block
  final int bidiLevel;
  final WebTextStyle textStyle;
  final ClusterRange clusterRange;
  final TextRange textRange; // within the entire text
  final ui.Rect advance;
  final double clusterShiftInLine;
  final int textMetricsZero; // from the beginning of the line to this block start

  double fontBoundingBoxAscent = 0.0;
  double fontBoundingBoxDescent = 0.0;
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

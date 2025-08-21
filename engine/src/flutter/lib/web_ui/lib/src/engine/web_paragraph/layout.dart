// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../dom.dart';
import 'code_unit_flags.dart';
import 'debug.dart';
import 'paragraph.dart';
import 'wrapper.dart';

/// A single canvas2d context to use during text layout.
@visibleForTesting
final DomCanvasRenderingContext2D layoutContext =
    // We don't use this canvas to draw anything, so let's make it as small as
    // possible to save memory.
    createDomCanvasElement(width: 0, height: 0).context2D;

/// Performs layout on a [WebParagraph].
///
/// It uses a [DomHTMLCanvasElement] to get text information
class TextLayout {
  TextLayout(this.paragraph)
    : codeUnitFlags = <CodeUnitFlags>[],
      textClusters = <ExtendedTextCluster>[],
      bidiRuns = <BidiRun>[],
      styledTextBlocks = <StyledTextBlock>[],
      lines = <TextLine>[];

  final WebParagraph paragraph;

  final List<CodeUnitFlags> codeUnitFlags;
  List<ExtendedTextCluster> textClusters;
  final List<BidiRun> bidiRuns;
  final List<StyledTextBlock> styledTextBlocks;
  final List<TextLine> lines;

  Map<int, int> textToClusterMap = <int, int>{};

  Stopwatch timer = Stopwatch();
  Duration codeUnitFlagsDuration = Duration.zero;
  Duration textClustersDuration = Duration.zero;
  Duration bidiRunsDuration = Duration.zero;
  Duration lineBreaksDuration = Duration.zero;
  Duration measureTextDuration = Duration.zero;
  Duration getTextClustersDuration = Duration.zero;
  Duration queryTextMetricsDuration = Duration.zero;
  Duration mappingDuration = Duration.zero;

  bool hasFlag(ui.TextRange cluster, int flag) {
    return codeUnitFlags[cluster.start].hasFlag(flag);
  }

  bool get isDefaultLtr => paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr;

  bool get isDefaultRtl => paragraph.paragraphStyle.textDirection == ui.TextDirection.rtl;

  void performLayout(double width) {
    // TODO(jlavrova): find a less clumsy way to deal with edge cases like empty text
    if (paragraph.text.isEmpty) {
      return;
    }

    // Clear all the data
    codeUnitFlags.clear();
    bidiRuns.clear();
    styledTextBlocks.clear();
    lines.clear();
    textToClusterMap.clear();

    timer.reset();
    timer.start();
    codeUnitFlags.addAll(CodeUnitFlags.extractForParagraph(paragraph));
    timer.stop();
    codeUnitFlagsDuration = timer.elapsed;

    timer.reset();
    timer.start();
    extractClusterTexts();
    timer.stop();
    textClustersDuration = timer.elapsed;

    timer.reset();
    timer.start();
    extractBidiRuns();
    timer.stop();
    bidiRunsDuration = timer.elapsed;

    timer.reset();
    timer.start();
    wrapText(width);
    timer.stop();
    lineBreaksDuration = timer.elapsed;

    formatLines(width);
  }

  (
    Duration d1,
    Duration d2,
    Duration d3,
    Duration d4,
    Duration d5,
    Duration d6,
    Duration d7,
    Duration d8,
  )
  getDurations() {
    return (
      codeUnitFlagsDuration,
      textClustersDuration,
      bidiRunsDuration,
      lineBreaksDuration,
      measureTextDuration,
      getTextClustersDuration,
      queryTextMetricsDuration,
      mappingDuration,
    );
  }

  void extractClusterTexts() {
    final Stopwatch timer = Stopwatch();
    // Walk through all the styled text ranges
    final List<List<DomTextCluster>> allClusters = <List<DomTextCluster>>[];
    int clustersCount = 0;
    double blockStart = 0.0;
    layoutContext.direction = isDefaultLtr ? 'ltr' : 'rtl';
    for (final StyledTextRange styledBlock in paragraph.styledTextRanges) {
      final String text = paragraph.getText(styledBlock);
      if (text.isEmpty) {
        continue;
      }

      if (styledBlock.isPlaceholder) {
        assert(styledBlock.size == 1);
        styledTextBlocks.add(
          StyledTextBlock.fromPlaceholder(
            styledBlock.start,
            styledBlock.end,
            styledBlock.style,
            styledBlock.placeholder!,
          ),
        );
        clustersCount += 1;
      } else {
        // Setup all the font affecting attributes
        // TODO(jlavrova): set 'lang' attribute as a combination of locale+language
        layoutContext.font = styledBlock.style.buildCssFontString();
        layoutContext.letterSpacing = styledBlock.style.buildLetterSpacingString();
        layoutContext.wordSpacing = styledBlock.style.buildWordSpacingString();
        styledBlock.style.buildFontFeatures(layoutContext);

        WebParagraphDebug.log(
          'font: ${layoutContext.font} '
          'featureSettings ${layoutContext.textRendering} ${layoutContext.canvas!.style.fontFeatureSettings} ',
        );

        timer.reset();
        timer.start();
        final DomTextMetrics blockTextMetrics = layoutContext.measureText(text);
        timer.stop();
        measureTextDuration = timer.elapsed;

        styledTextBlocks.add(
          StyledTextBlock(styledBlock.start, styledBlock.end, styledBlock.style, blockTextMetrics),
        );
        timer.reset();
        timer.start();
        allClusters.add(blockTextMetrics.getTextClusters());
        clustersCount += allClusters.last.length;
        timer.stop();
        getTextClustersDuration = timer.elapsed;
      }
    }
    clustersCount += 1; // For the fake last element

    textClusters = List<ExtendedTextCluster>.filled(clustersCount, ExtendedTextCluster.empty());
    int allClustersIndex = 0;
    for (int i = 0; i < styledTextBlocks.length; i += 1) {
      final styledBlock = styledTextBlocks[i];

      if (styledBlock.isPlaceholder) {
        final ui.Rect advance = ui.Rect.fromLTWH(
          0,
          0,
          styledBlock.placeholder!.width,
          styledBlock.placeholder!.height,
        );
        textClusters[allClustersIndex++] = ExtendedTextCluster(
          null,
          styledBlock.style,
          0.0,
          0.0,
          styledBlock as TextRange,
          advance,
          blockStart,
          styledBlock.isPlaceholder,
          '',
        );
        WebParagraphDebug.log(
          'placeholder#${textClusters.length}: [${styledBlock.start}:${styledBlock.end}) [${advance.left}:${advance.right})',
        );
        blockStart += advance.width;
        continue;
      }

      final blockTextMetrics = styledBlock.textMetrics!;
      final fontBoundingBoxAscent = blockTextMetrics.fontBoundingBoxAscent;
      final fontBoundingBoxDescent = blockTextMetrics.fontBoundingBoxDescent;
      final clusters = allClusters[i];
      timer.reset();
      timer.start();
      double x = 0.0;
      double y = 0.0;
      bool firstCluster = true;
      final ui.Rect blockAdvance = blockTextMetrics.getAdvance(
        TextRange(start: 0, end: styledBlock.size),
      );
      for (final cluster in clusters) {
        final textRange = TextRange(
          start: cluster.begin + styledBlock.start,
          end: cluster.end + styledBlock.start,
        );
        if (firstCluster) {
          firstCluster = false;
        } else {
          textClusters[allClustersIndex - 1].advance = ui.Rect.fromLTWH(
            x,
            y,
            cluster.x - x,
            blockAdvance.height,
          );
        }

        textClusters[allClustersIndex++] = ExtendedTextCluster(
          cluster,
          styledBlock.style,
          fontBoundingBoxAscent,
          fontBoundingBoxDescent,
          TextRange(start: cluster.begin + styledBlock.start, end: cluster.end + styledBlock.start),
          //blockTextMetrics.getBounds(TextRange(start: cluster.begin, end: cluster.end)),
          ui.Rect.zero,
          //blockTextMetrics.getAdvance(TextRange(start: cluster.begin, end: cluster.end)),
          blockStart,
          false, // This is not a placeholder
          paragraph.getText(textRange),
        );
        x = cluster.x;
        y = cluster.y;
      }
      textClusters[allClustersIndex - 1].advance = ui.Rect.fromLTWH(
        x,
        y,
        blockAdvance.width - x,
        blockAdvance.height,
      );
      //debugPrintTextMetrics('blockTextMetrics', blockTextMetrics);
      timer.stop();
      queryTextMetricsDuration = timer.elapsed;
      blockStart += blockAdvance.width;
    }
    timer.reset();
    timer.start();
    if (paragraph.text.isNotEmpty) {
      // We need one more "fake" cluster so we can loop through clusters
      // without checking indexes for being outside of the range
      textClusters[allClustersIndex] = ExtendedTextCluster.fromLast(
        textClusters[allClustersIndex - 1],
      );
      //textClusters.sort((a, b) => a.textRange.start.compareTo(b.textRange.start));
      for (int i = 0; i < textClusters.length; ++i) {
        final ExtendedTextCluster textCluster = textClusters[i];
        for (int j = textCluster.textRange.start; j < textCluster.textRange.end; j += 1) {
          textToClusterMap[j] = i;
        }
      }
      textToClusterMap[paragraph.text.length] = textClusters.length - 1;

      if (WebParagraphDebug.logging) {
        debugPrintClusters('Full text $allClustersIndex');
      }
    } else {
      textToClusterMap[paragraph.text.length] = 0;
      textClusters[allClustersIndex] = ExtendedTextCluster.empty();
    }
    timer.stop();
    mappingDuration = timer.elapsed;
  }

  void extractBidiRuns() {
    bidiRuns.clear();

    final List<BidiRegion> regions = canvasKit.Bidi.getBidiRegions(
      paragraph.text,
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

  void debugPrintClusters(String header) {
    WebParagraphDebug.log('Text Clusters ($header): ${textClusters.length}');
    int i = 0;
    for (final ExtendedTextCluster cluster in textClusters) {
      final String clusterText = paragraph.getText(cluster.textRange);
      WebParagraphDebug.log(
        'cluster[$i]: "$clusterText" ${cluster.textRange} @${cluster.shift} ${cluster.advance.left}:${cluster.advance.right}=${cluster.advance.width}',
      );
      i += 1;
    }
  }

  void debugPrintTextMetrics(String text, DomTextMetrics textMetrics) {
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

  void debugPrintClustersByBidi() {
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
          '$i: [${cluster.textRange.start}:${cluster.textRange.end}) ${cluster.advance.left}:${cluster.advance.right} ${cluster.advance.width}*${cluster.advance.height} "$clusterText"',
        );
      }
      runIndex += 1;
    }
  }

  ClusterRange convertTextToClusterRange(TextRange textRange) {
    final int clusterStart = textToClusterMap[textRange.start]!;
    final int clusterEnd = textToClusterMap[textRange.end - 1]!;
    return ClusterRange(start: clusterStart, end: clusterEnd + 1);
  }

  String getTextFromClusterRange(ClusterRange clusterRange) {
    final TextRange textRange = convertSequentialClusterRangeToText(clusterRange);
    return paragraph.getText(textRange);
  }

  TextRange convertSequentialClusterRangeToText(ClusterRange clusterRange) {
    final ExtendedTextCluster start = textClusters[clusterRange.start];
    if (clusterRange.isEmpty) {
      return TextRange(start: start.textRange.start, end: start.textRange.start);
    }
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

  void wrapText(double width) {
    lines.clear();

    final TextWrapper wrapper = TextWrapper(this);
    wrapper.breakLines(width);
    paragraph.maxIntrinsicWidth = wrapper.maxIntrinsicWidth;
    paragraph.minIntrinsicWidth = wrapper.minIntrinsicWidth;
    paragraph.requiredWidth = width;
  }

  double addLine(
    ClusterRange lineClusterRange,
    ClusterRange whitespacesClusterRange,
    bool hardLineBreak,
    double top,
  ) {
    // Arrange line vertically, calculate metrics and bounds
    final allLineClusterRange = ClusterRange.mergeSequentialClusterRanges(
      lineClusterRange,
      whitespacesClusterRange,
    );
    final String allText = getTextFromClusterRange(allLineClusterRange);
    WebParagraphDebug.log('LINE "$allText" clusters:$lineClusterRange+$whitespacesClusterRange');

    final TextRange lineTextRange = convertSequentialClusterRangeToText(lineClusterRange);
    final TextRange whitespacesTextRange = convertSequentialClusterRangeToText(
      whitespacesClusterRange,
    );
    WebParagraphDebug.log('LINE "$allText" text:$lineTextRange+$whitespacesTextRange');

    assert(lineTextRange.end == whitespacesTextRange.start);
    final TextRange allLineTextRange = convertSequentialClusterRangeToText(allLineClusterRange);

    final TextLine line = TextLine(
      lineClusterRange,
      whitespacesClusterRange,
      hardLineBreak,
      lines.length,
      lineTextRange,
      whitespacesTextRange,
      allLineTextRange,
    );

    // Get logical runs belonging th the line
    final List<int> logicalLevels = <int>[];
    int firstRunIndex = 0;
    for (final bidiRun in bidiRuns) {
      final ClusterRange intesection1 = ClusterRange.intersectClusterRange(
        bidiRun.clusterRange,
        lineClusterRange,
      );
      final ClusterRange intesection2 = ClusterRange.intersectClusterRange(
        bidiRun.clusterRange,
        whitespacesClusterRange,
      );
      if (intesection1.size <= 0 && intesection2.size <= 0) {
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
      // TODO(jlavrova): we (almost always true) assume that trailing whitespaces do not affect the line height
      final ClusterRange runClusterRange = ClusterRange.intersectClusterRange(
        bidiRun.clusterRange,
        lineClusterRange,
      );
      final ClusterRange whitespacesRunClusterRange = ClusterRange.intersectClusterRange(
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
        '${bidiRun.clusterRange} & $lineClusterRange = $runClusterRange textRange:$runTextRange ${styledTextBlocks.length}',
      );

      for (final styledTextBlock in styledTextBlocks) {
        final TextRange styleTextRange = TextRange.intersectTextRange(
          styledTextBlock,
          runTextRange,
        );

        WebParagraphDebug.log(
          'Style: ${styledTextBlock as TextRange} & $runTextRange = $styleTextRange ',
        );
        if (styleTextRange.size <= 0) {
          continue;
        }

        final ClusterRange styleClusterRange = convertTextToClusterRange(styleTextRange);
        final String styleText = getTextFromMonodirectionalClusterRange(styleClusterRange);
        ui.Rect advance;
        double shiftFromTextBlock = 0.0;
        if (styledTextBlock.isPlaceholder) {
          assert(styleClusterRange.size == 1);
          final theOnlyCluster = textClusters[styleClusterRange.start];
          advance = theOnlyCluster.advance;
          shiftFromTextBlock = theOnlyCluster.advance.left;
          line.visualBlocks.add(
            LinePlaceholdeBlock(
              styledTextBlock.placeholder,
              bidiRun.bidiLevel,
              styledTextBlock.style,
              styleClusterRange,
              styleTextRange,
              advance,
              shiftInsideLine - shiftFromTextBlock,
              styledTextBlock.start,
            ),
          );
          WebParagraphDebug.log('Placeholder block: $shiftInsideLine $advance');
          // TODO(jlavrova): sort our alphabetic/ideographic baseline and how it affects ascent & descent
          line.fontBoundingBoxAscent = math.max(line.fontBoundingBoxAscent, advance.height);
          line.fontBoundingBoxDescent = math.max(line.fontBoundingBoxDescent, 0);
        } else {
          advance = styledTextBlock.textMetrics!.getAdvance(
            styleTextRange.translate(-styledTextBlock.start),
          );
          final ExtendedTextCluster firstVisualClusterInBlock = bidiRun.bidiLevel.isEven
              ? textClusters[styleClusterRange.start]
              : textClusters[styleClusterRange.end - 1];
          shiftFromTextBlock = firstVisualClusterInBlock.advance.left;
          line.visualBlocks.add(
            LineClusterBlock(
              styledTextBlock.textMetrics,
              this,
              line,
              bidiRun.bidiLevel,
              styledTextBlock.style,
              styleClusterRange,
              styleTextRange,
              advance,
              shiftInsideLine - shiftFromTextBlock,
              styledTextBlock.start,
            ),
          );
          WebParagraphDebug.log(
            'TextCluster block: $styleClusterRange ${styleTextRange.translate(-styledTextBlock.start)} ${-styledTextBlock.start} $shiftFromTextBlock $shiftInsideLine $advance',
          );

          // Line always counts multipled metrics (no need for the others)
          line.fontBoundingBoxAscent = math.max(
            line.fontBoundingBoxAscent,
            line.visualBlocks.last.multipliedFontBoundingBoxAscent,
          );
          line.fontBoundingBoxDescent = math.max(
            line.fontBoundingBoxDescent,
            line.visualBlocks.last.multipliedFontBoundingBoxDescent,
          );
        }

        WebParagraphDebug.log(
          'Style: "$styleText" clusterRange: $styleClusterRange '
          'width:${advance.width} shift:${line.visualBlocks.last.clusterShiftInLine}=$shiftInsideLine-$shiftFromTextBlock ',
        );
        shiftInsideLine += advance.width;
      }
    }

    // Now when we calculated all line metrics we have to correct placeholders that depend on it
    for (final LineBlock block in line.visualBlocks) {
      if (block is LineClusterBlock) {
        continue;
      }
      final placeholderBlock = block as LinePlaceholdeBlock;
      placeholderBlock.correctMetrics(line.fontBoundingBoxAscent, line.fontBoundingBoxDescent);
      // Line always counts multipled metrics (no need for the others)
      line.fontBoundingBoxAscent = math.max(line.fontBoundingBoxAscent, placeholderBlock.ascent);
      line.fontBoundingBoxDescent = math.max(line.fontBoundingBoxDescent, placeholderBlock.descent);
      WebParagraphDebug.log(
        'Adjusted metrics: '
        '${line.fontBoundingBoxAscent} => ${math.max(line.fontBoundingBoxAscent, placeholderBlock.ascent)} '
        '${line.fontBoundingBoxDescent} => ${math.max(line.fontBoundingBoxDescent, placeholderBlock.descent)} ',
      );
    }

    line.advance = ui.Rect.fromLTWH(
      0,
      top,
      shiftInsideLine,
      // At the end this shift is equal to the entire line width
      line.height,
    );
    lines.add(line);

    WebParagraphDebug.log(
      'Line [${line.textClusterRange.start}:${line.textClusterRange.end}) ${line.advance.left},${line.advance.top} ${line.advance.width}x${line.advance.height}',
    );

    return line.advance.height;
  }

  void formatLines(double width) {
    // TODO(jlavrova): there is a special case in cpp SkParagraph; we need to decide if we keep it
    // Special case: clean all text in case of maxWidth == INF & align != left
    // We had to go through shaping though because we need all the measurement numbers
    final ui.TextAlign effectiveAlign = paragraph.paragraphStyle.effectiveAlign();
    if (width == double.infinity && effectiveAlign != ui.TextAlign.left) {
      // If we have to format the text we find the max line length and use it as a width
      double maxLength = 0.0;
      for (final TextLine line in lines) {
        maxLength = math.max(maxLength, line.advance.width);
      }
      paragraph.requiredWidth = maxLength;
    } else {
      paragraph.requiredWidth = width;
    }

    for (final TextLine line in lines) {
      final double delta = paragraph.requiredWidth - line.advance.width;
      if (delta <= 0) {
        continue;
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
        'formatLines($width): ${line.advance} $effectiveAlign $delta ${line.formattingShift} ${paragraph.longestLine}',
      );
    }
  }

  static double epsilon = 0.001;

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
        'Line: ${line.textClusterRange} & $textRange '
        '[${line.advance.left}:${line.advance.right} x ${line.advance.top}:${line.advance.bottom} '
        '${line.fontBoundingBoxAscent}+${line.fontBoundingBoxDescent}',
      );
      // We take whitespaces in account
      final TextRange lineTextRange = convertSequentialClusterRangeToText(
        ClusterRange.mergeSequentialClusterRanges(
          line.textClusterRange,
          line.whitespacesClusterRange,
        ),
      );
      if (end <= lineTextRange.start || start > lineTextRange.end) {
        continue;
      }
      for (final LineBlock block in line.visualBlocks) {
        final intersect = TextRange.intersectTextRange(block.textRange, textRange);
        WebParagraphDebug.log(
          'block: ${block.textRange} & $textRange = $intersect '
          '${block.textMetricsZero} ${block.clusterShiftInLine}',
        );
        if (intersect.size <= 0) {
          continue;
        }
        /*
        final rects = block.getSelectionRects(intersect);
        assert(
          rects.length == 1,
        ); // We are dealing with single bidi, single line, single style range
        final firstRect = ui.Rect.fromLTWH(
          rects.first.left,
          rects.first.top,
          rects.first.width,
          rects.first.height,)
          */
        final firstRect = block.correctedAdvance.translate(
          block.clusterShiftInLine,
          block is LinePlaceholdeBlock ? 0 : block.rawFontBoundingBoxAscent,
        ); // block.advance.top == 0
        WebParagraphDebug.log(
          'getSelectionRects(${intersect.start},${intersect.end}): '
          'shifted (${block.clusterShiftInLine}, ${block.rawFontBoundingBoxAscent}) '
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
                block.rawFontBoundingBoxAscent;
            bottom = top + block.rawHeight;
            assert((block.correctedAdvance.height - (bottom - top).abs() < epsilon));
          case ui.BoxHeightStyle.max:
            top = firstRect.top + line.advance.top;
            bottom = firstRect.top + line.advance.bottom;
            assert((line.advance.height - (bottom - top).abs() < epsilon));
          case ui.BoxHeightStyle.strut:
            // TODO(jlavrova): implement strut
            throw UnimplementedError('BoxHeightStyle.strut not implemented');
          case ui.BoxHeightStyle.includeLineSpacingMiddle:
            top =
                line.advance.top +
                (line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent) / 2;
            bottom =
                line.advance.top +
                line.fontBoundingBoxAscent +
                (line.fontBoundingBoxDescent + block.rawFontBoundingBoxDescent) / 2;
          case ui.BoxHeightStyle.includeLineSpacingTop:
            top = line.advance.top + line.fontBoundingBoxAscent - block.rawFontBoundingBoxAscent;
            bottom = line.advance.top + line.fontBoundingBoxAscent + line.fontBoundingBoxDescent;
          case ui.BoxHeightStyle.includeLineSpacingBottom:
            top = line.advance.top;
            bottom =
                line.advance.top + line.fontBoundingBoxAscent + block.rawFontBoundingBoxDescent;
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
        if ((result.first.left - 0).abs() > epsilon) {
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
        if ((result.last.right - paragraph.requiredWidth).abs() > epsilon) {
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

  List<ui.TextBox> getBoxesForPlaceholders() {
    final List<ui.TextBox> result = <ui.TextBox>[];
    for (final TextLine line in lines) {
      for (final LineBlock block in line.visualBlocks) {
        if (block is LineClusterBlock) {
          continue;
        }
        final ui.Rect rect = block.correctedAdvance.translate(
          line.advance.left + line.formattingShift + block.clusterShiftInLine,
          line.advance.top,
        );
        result.add(
          ui.TextBox.fromLTRBD(
            rect.left,
            rect.top,
            rect.right,
            rect.bottom,
            paragraph.paragraphStyle.textDirection,
          ),
        );
      }
    }
    WebParagraphDebug.log('getBoxesForPlaceholders:');
    for (final rect in result) {
      WebParagraphDebug.log('[${rect.left}:${rect.right}x${rect.top}:${rect.bottom}]');
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
        return ui.TextPosition(
          offset: line.textClusterRange.start,
          /*affinity: ui.TextAffinity.downstream,*/
        );
      } else if (line.advance.bottom < offset.dy) {
        // We are not there yet; we need a line closest to the offset.
        continue;
      }
      WebParagraphDebug.log('Found line: ${line.textClusterRange} ${line.advance} ');

      // We found the line that contains the offset; let's go through all the visual blocks to find the position
      int blockNum = 0;
      for (final block in line.visualBlocks) {
        blockNum++;
        if (block.correctedAdvance.left > offset.dx) {
          // We didn't find any block and we already on the right side of our offset
          // It's only possible for the first block in the line
          assert(blockNum == 1);
          return ui.TextPosition(
            offset: line.textClusterRange.end,
            /*affinity: ui.TextAffinity.downstream,*/
          );
        } else if (block.correctedAdvance.right < offset.dx) {
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
              .inflate(epsilon);
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
                /*affinity: ui.TextAffinity.downstream,*/
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
      return ui.TextPosition(
        offset: line.textClusterRange.end,
        /*affinity: ui.TextAffinity.downstream,*/
      );
    }
    // We didn't find the line containing our offset and
    // we didn't find the line that is down from the offset
    // So all the line are above the offset
    return ui.TextPosition(offset: paragraph.text.length - 1, affinity: ui.TextAffinity.upstream);
  }

  ui.TextRange getWordBoundary(int position) {
    int start = position + 1;
    while (start > 0) {
      start -= 1;
      if (codeUnitFlags[start].hasFlag(CodeUnitFlags.kWordBreakFlag)) {
        break;
      }
    }
    int end = position + 1;
    while (end < codeUnitFlags.length) {
      if (codeUnitFlags[end].hasFlag(CodeUnitFlags.kWordBreakFlag)) {
        break;
      }
      end += 1;
    }
    return ui.TextRange(start: start, end: end);
  }
}

class ExtendedTextCluster {
  ExtendedTextCluster(
    this.cluster,
    this.textStyle,
    this.fontBoundingBoxAscent,
    this.fontBoundingBoxDescent,
    this.textRange, // Global indexes
    this.advance,
    this.shift,
    this.placeholder,
    this.cacheId,
  ) : start = cluster == null ? 0 : cluster.begin,
      end = cluster == null ? 0 : cluster.end;

  ExtendedTextCluster.fromLast(ExtendedTextCluster lastCluster)
    : cluster = null,
      textStyle = lastCluster.textStyle,
      fontBoundingBoxAscent = lastCluster.fontBoundingBoxAscent,
      fontBoundingBoxDescent = lastCluster.fontBoundingBoxDescent,
      textRange = TextRange(start: lastCluster.textRange.end, end: lastCluster.textRange.end),
      start = lastCluster.start,
      end = lastCluster.end,
      advance = ui.Rect.fromLTWH(
        lastCluster.advance.right,
        lastCluster.advance.top,
        0,
        lastCluster.advance.height,
      ),
      shift = lastCluster.shift,
      placeholder = false,
      cacheId = '';

  ExtendedTextCluster.empty()
    : shift = 0.0,
      fontBoundingBoxAscent = 0.0,
      fontBoundingBoxDescent = 0.0,
      advance = ui.Rect.zero,
      textRange = TextRange(start: 0, end: 0),
      start = 0,
      end = 0,
      placeholder = false,
      cacheId = '';

  double absolutePositionX() {
    return /*style block shift*/ shift + /*cluster advance inside the style block*/ advance.left;
  }

  DomTextCluster? cluster;
  WebTextStyle? textStyle;
  double fontBoundingBoxAscent;
  double fontBoundingBoxDescent;
  TextRange textRange;
  int start;
  int end;
  ui.Rect advance;
  double shift;
  bool placeholder;
  String cacheId;
}

class BidiRun {
  BidiRun(this.clusterRange, this.bidiLevel);

  final int bidiLevel;
  final ClusterRange clusterRange;
}

class StyledTextBlock extends StyledTextRange {
  StyledTextBlock(super.start, super.end, super.textStyle, this.textMetrics);

  static StyledTextBlock fromTextMetrics(
    int start,
    int end,
    WebTextStyle textStyle,
    DomTextMetrics? textMetrics,
  ) {
    return StyledTextBlock(start, end, textStyle, textMetrics);
  }

  static StyledTextBlock fromPlaceholder(
    int start,
    int end,
    WebTextStyle textStyle,
    WebParagraphPlaceholder placeholder,
  ) {
    final result = StyledTextBlock(start, end, textStyle, null);
    result.markAsPlaceholder(placeholder);
    return result;
  }

  final DomTextMetrics? textMetrics;
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
abstract class LineBlock {
  LineBlock(
    this.bidiLevel,
    this.textStyle,
    this.clusterRange,
    this.textRange,
    this.advance,
    this.clusterShiftInLine,
    this.textMetricsZero,
  ) {
    correctedAdvance = advance;
  }

  double get multiplier;

  double get rawHeight;

  double get rawFontBoundingBoxAscent;

  double get rawFontBoundingBoxDescent;

  double get multipliedHeight;

  double get multipliedFontBoundingBoxAscent;

  double get multipliedFontBoundingBoxDescent;

  List<DomRectReadOnly> getSelectionRects(TextRange textRange);

  final int bidiLevel;
  final WebTextStyle textStyle;
  final ClusterRange clusterRange;
  final TextRange textRange; // within the entire text
  final ui.Rect advance;
  final double clusterShiftInLine;
  final int textMetricsZero; // from the beginning of the line to this block start
  ui.Rect correctedAdvance = ui.Rect.zero;
}

class LineClusterBlock extends LineBlock {
  LineClusterBlock(
    this.textMetrics,
    this.layout,
    this.line,
    super.bidiLevel,
    super.textStyle,
    super.clusterRange,
    super.textRange,
    super.advance,
    super.clusterShiftInLine,
    super.textMetricsZero,
  );

  @override
  double get multiplier => textStyle.height == null ? 1.0 : textStyle.height!;

  @override
  double get rawHeight => textMetrics!.fontBoundingBoxAscent + textMetrics!.fontBoundingBoxDescent;

  @override
  double get rawFontBoundingBoxAscent => textMetrics!.fontBoundingBoxAscent;

  @override
  double get rawFontBoundingBoxDescent => textMetrics!.fontBoundingBoxDescent;

  @override
  double get multipliedHeight => rawHeight * multiplier;

  @override
  double get multipliedFontBoundingBoxAscent => rawFontBoundingBoxAscent * multiplier;

  @override
  double get multipliedFontBoundingBoxDescent => rawFontBoundingBoxDescent * multiplier;

  @override
  List<DomRectReadOnly> getSelectionRects(TextRange textRange) {
    return textMetrics!.getSelectionRects(
      textRange.start - textMetricsZero,
      textRange.end - textMetricsZero,
    );
  }

  final DomTextMetrics? textMetrics;
  final TextLayout? layout;
  final TextLine line;
}

class LinePlaceholdeBlock extends LineBlock {
  LinePlaceholdeBlock(
    this.placeholder,
    super.bidiLevel,
    super.textStyle,
    super.clusterRange,
    super.textRange,
    super.advance,
    super.clusterShiftInLine,
    super.textMetricsZero,
  );

  @override
  double get multiplier => 1.0;

  @override
  double get rawHeight => placeholder!.height;

  @override
  double get rawFontBoundingBoxAscent => placeholder!.height;

  @override
  double get rawFontBoundingBoxDescent => 0;

  @override
  double get multipliedHeight => rawHeight;

  @override
  double get multipliedFontBoundingBoxAscent => placeholder!.height;

  @override
  double get multipliedFontBoundingBoxDescent => 0;

  @override
  List<DomRectReadOnly> getSelectionRects(TextRange textRange) {
    return <DomRectReadOnly>[DomRect(advance.left, advance.top, advance.width, advance.height)];
  }

  void correctMetrics(double lineAscent, double lineDescent) {
    assert(placeholder != null);
    double baselineAdjustment = 0;
    if (placeholder!.baseline == ui.TextBaseline.ideographic) {
      baselineAdjustment = lineDescent / 2;
    }

    final double height = placeholder!.height;
    final double offset = placeholder!.offset;
    WebParagraphDebug.log(
      'correctMetrics($lineAscent, $lineDescent): height=$height offset=$offset',
    );
    switch (placeholder!.alignment) {
      case ui.PlaceholderAlignment.baseline:
        // Matches the baseline of the placeholder with the text baseline. You'll need to specify the TextBaseline to use
        // TODO(jlavrova): the code in this case does not make sense but this is what we have in SkParagraph
        ascent = 0 - baselineAdjustment + offset;
        descent = baselineAdjustment + height - offset;

      case ui.PlaceholderAlignment.aboveBaseline:
        // Aligns the bottom edge of the placeholder with the baseline
        ascent = height - baselineAdjustment;
        descent = baselineAdjustment;

      case ui.PlaceholderAlignment.belowBaseline:
        // Aligns the top edge of the placeholder with the baseline
        ascent = 0 - baselineAdjustment;
        descent = baselineAdjustment + height;

      case ui.PlaceholderAlignment.top:
        // Aligns the top edge of the placeholder with the top edge of the text
        ascent = lineAscent;
        descent = height - lineAscent;

      case ui.PlaceholderAlignment.bottom:
        // Aligns the bottom edge of the placeholder with the bottom edge of the text
        ascent = height - lineDescent;
        descent = lineDescent;

      case ui.PlaceholderAlignment.middle:
        // Aligns the middle of the placeholder with the middle of the text
        final double diff = (lineAscent + lineDescent - height) / 2;
        ascent = lineAscent - diff;
        descent = lineDescent - diff;
    }
    top = lineAscent - ascent;
    bottom = top + height;
    correctedAdvance = ui.Rect.fromLTWH(advance.left, top, advance.width, height);
    WebParagraphDebug.log('correctMetrics: $correctedAdvance $ascent $descent');
  }

  WebParagraphPlaceholder? placeholder;
  double top = 0;
  double bottom = 0;
  double ascent = 0;
  double descent = 0;
}

class TextLine {
  TextLine(
    this.textClusterRange,
    this.whitespacesClusterRange,
    this.hardLineBreak,
    this.lineNumber,
    this.textRange,
    this.whitespacesRange,
    this.allLineTextRange,
  );

  ui.LineMetrics getMetrics() {
    return ui.LineMetrics(
      hardBreak: hardLineBreak,
      ascent: fontBoundingBoxAscent,
      descent: fontBoundingBoxDescent,
      // TODO(jlavrova): it was not implemented in SkParagraph either; kept it as is
      unscaledAscent: fontBoundingBoxAscent,
      height: advance.height,
      width: advance.width,
      left: advance.left,
      baseline: 0.0,
      lineNumber: lineNumber,
    );
  }

  double get height => fontBoundingBoxAscent + fontBoundingBoxDescent;

  final ClusterRange textClusterRange;
  final ClusterRange whitespacesClusterRange;
  final TextRange textRange;
  final TextRange whitespacesRange;
  final TextRange allLineTextRange;
  final bool hardLineBreak;
  final int lineNumber;

  ui.Rect advance = ui.Rect.zero;
  double fontBoundingBoxAscent = 0.0;
  double fontBoundingBoxDescent = 0.0;
  double formattingShift = 0.0; // For centered or right aligned text

  List<LineBlock> visualBlocks = <LineBlock>[];
}

extension DomTextMetricsExtension on DomTextMetrics {
  static double epsilon = 0.001;

  bool nextToEachOtherHorizontally(ui.Rect rect1, ui.Rect rect2) {
    if ((rect1.right - rect2.left).abs() < epsilon) {
      return true;
    }
    if ((rect1.left - rect2.right).abs() < epsilon) {
      return true;
    }
    return false;
  }

  ui.Rect getAdvance(TextRange textRange) {
    final List<DomRectReadOnly> rects = getSelectionRects(textRange.start, textRange.end);
    ui.Rect union = ui.Rect.fromLTWH(
      rects.first.left,
      rects.first.top,
      rects.first.width,
      rects.first.height,
    );
    for (final rect in rects.skip(1)) {
      final r = ui.Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height);
      // Assert that this is a continuous set of rectangles
      assert(nextToEachOtherHorizontally(union, r));
      union = union.expandToInclude(r);
    }
    return union;
  }

  ui.Rect getBounds(TextRange textRange) {
    final DomRectReadOnly box = getActualBoundingBox(textRange.start, textRange.end);
    return ui.Rect.fromLTWH(box.left, box.top, box.width, box.height);
  }
}

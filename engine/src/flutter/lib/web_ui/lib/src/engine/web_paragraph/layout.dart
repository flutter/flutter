// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_api.dart';
import '../dom.dart';
import 'bidi.dart';
import 'code_unit_flags.dart';
import 'debug.dart';
import 'paragraph.dart';
import 'wrapper.dart';

/// Performs layout on a [WebParagraph].
///
/// It uses a [DomHTMLCanvasElement] to get text information
class TextLayout {
  TextLayout(this.paragraph);

  final WebParagraph paragraph;

  bool _isFirstLayout = true;

  late final AllCodeUnitFlags codeUnitFlags;
  final bidiRuns = <BidiRun>[];
  final lines = <TextLine>[];

  final allClusters = <WebCluster>[];
  late final _mapping = _TextClusterMapping(paragraph.text.length + 1, allClusters);

  // This list will be filled only if needed and AFTER line breaking
  // when we know the text style that will be used for ellipsis
  List<WebCluster> ellipsisClusters = <WebCluster>[];
  int? _ellipsisBidiLevel;

  void performLayout(double width) {
    // TODO(jlavrova): I suggest with go with the general code flow for an empty text
    /*
    if (paragraph.text.isEmpty) {
      // TODO(mdebbar): We need to populate at least `height` here.
      // I think we may need to ensure there's at least one span. The span's style should match the
      // last effective style when `build()` is called.
      //
      // Julia said calling measureText with an empty string also works!!
      // metrics = measureText('');
      return;
    }
    */
    // TODO(jlavrova): Skip layout if `width` is the same as the last layout.
    // TODO(jlavrova): Skip layout if `width` is greater than `maxIntrinsicWidth`.

    // Some things are only computed once, and reused in future layouts.
    if (_isFirstLayout) {
      _isFirstLayout = false;

      codeUnitFlags = AllCodeUnitFlags(paragraph.text);
      extractTextClusters();
      calculateStrutMetrics();
      extractBidiRuns();
    }

    // Wrapping text into lines is required on every layout.
    wrapText(width);
    formatLines(width);
  }

  void calculateStrutMetrics() {
    if (paragraph.paragraphStyle.strutStyle != null) {
      paragraph.paragraphStyle.strutStyle?.calculateMetrics();
    }
  }

  ui.TextDirection _detectTextDirection(ClusterRange clusterRange) {
    for (final BidiRun bidiRun in bidiRuns) {
      if (bidiRun.clusterRange.overlapsWith(clusterRange.start, clusterRange.end)) {
        return bidiRun.bidiLevel.isEven ? ui.TextDirection.ltr : ui.TextDirection.rtl;
      }
    }
    return paragraph.paragraphStyle.textDirection;
  }

  void extractTextClusters() {
    assert(allClusters.isEmpty);

    for (final ParagraphSpan span in paragraph.spans) {
      assert(span.isNotEmpty);
      allClusters.addAll(span.extractClusters());
    }
    allClusters.sort((a, b) => a.start.compareTo(b.start));
    for (var i = 0; i < allClusters.length; ++i) {
      final WebCluster cluster = allClusters[i];
      for (int j = cluster.start; j < cluster.end; ++j) {
        _mapping.add(textIndex: j, clusterIndex: i);
      }
    }

    // One more dummy element in the end to avoid extra checks
    final emptySpan = TextSpan(
      start: paragraph.text.length,
      end: paragraph.text.length,
      style: paragraph.spans.isEmpty
          ? paragraph.paragraphStyle.textStyle
          : paragraph.spans.last.style,
      text: '',
      textDirection: paragraph.paragraphStyle.textDirection,
    );
    allClusters.add(EmptyCluster(emptySpan));
    _mapping.add(textIndex: paragraph.text.length, clusterIndex: allClusters.length - 1);

    if (WebParagraphDebug.logging) {
      _debugPrintMappings('Mappings');
    }
  }

  int getEllipsisBidiLevel() {
    if (paragraph.paragraphStyle.ellipsis == null) {
      _ellipsisBidiLevel = 0;
    } else if (_ellipsisBidiLevel == null) {
      final List<BidiRegion> regions = canvasKit.Bidi.getBidiRegions(
        paragraph.paragraphStyle.ellipsis!,
        ui.TextDirection.ltr,
      );
      assert(
        regions.isNotEmpty && regions.length == 1,
        'The entire ellipsis must have the same text direction',
      );
      _ellipsisBidiLevel = regions.first.level;
    }
    return _ellipsisBidiLevel!;
  }

  void extractBidiRuns() {
    assert(bidiRuns.isEmpty);

    final List<BidiRegion> regions = canvasKit.Bidi.getBidiRegions(
      paragraph.text,
      paragraph.paragraphStyle.textDirection,
    );

    WebParagraphDebug.log('Bidis ${paragraph.paragraphStyle.textDirection}:${regions.length}');
    for (final region in regions) {
      // Regions operate in text indexes, not cluster indexes (one cluster can contain several text points)
      // We need to convert one into another
      final ClusterRange clusterRange = _mapping.toClusterRange(region.start, region.end);
      final run = BidiRun(clusterRange, region.level);
      WebParagraphDebug.log(
        'region ${region.level.isEven ? 'ltr' : 'rtl'} [${region.start}:${region.end}) => $clusterRange',
      );
      bidiRuns.add(run);
    }
  }

  void _debugPrintMappings(String header) {
    WebParagraphDebug.log(
      'Mappings ($header): ${_mapping._clusters.length} ${_mapping._textToCluster.length}',
    );
    for (var i = 0; i < _mapping._textToCluster.length; i++) {
      final int clusterIndex = _mapping._textToCluster[i];
      final WebCluster cluster = _mapping._clusters[clusterIndex];
      WebParagraphDebug.log('mappings[$i] => $clusterIndex [${cluster.start}:${cluster.end})');
    }
  }

  void wrapText(double width) {
    lines.clear();

    if (paragraph.text.isEmpty) {
      // Empty text still has to have some metrics
      paragraph.width = width;
      paragraph.maxIntrinsicWidth = 0;
      paragraph.minIntrinsicWidth = 0;
      paragraph.longestLine = double.negativeInfinity;
      paragraph.maxLineWidthWithTrailingSpaces = double.negativeInfinity;
      paragraph.height = _mapping._clusters.last.advance.height;
      return;
    }

    final wrapper = TextWrapper(this);
    wrapper.breakLines(width);
    paragraph.width = width;
    paragraph.maxIntrinsicWidth = wrapper.maxIntrinsicWidth;
    paragraph.minIntrinsicWidth = wrapper.minIntrinsicWidth;
    paragraph.longestLine = wrapper.longestLine;
    paragraph.maxLineWidthWithTrailingSpaces = wrapper.maxLineWidthWithTrailingSpaces;
    paragraph.height = wrapper.height;
  }

  double addLine(
    ClusterRange contentRange,
    ClusterRange whitespaceRange,
    bool hardLineBreak,
    double top,
  ) {
    assert(contentRange.end == whitespaceRange.start);
    if (WebParagraphDebug.logging) {
      final String allLineText = paragraph.getText(contentRange.start, whitespaceRange.end);
      WebParagraphDebug.log('LINE "$allLineText" clusters:$contentRange+$whitespaceRange');
    }
    // Prepare ellipsis block in case we need to get metrics for it
    EllipsisBlock? ellipsisBlock;
    if (ellipsisClusters.isNotEmpty) {
      final ellipsisSpan = TextSpan(
        start: ellipsisClusters.first.start,
        end: ellipsisClusters.last.end,
        style: ellipsisClusters.first.style,
        text: paragraph.paragraphStyle.ellipsis!,
        textDirection: _ellipsisBidiLevel!.isEven ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      );
      ellipsisBlock = EllipsisBlock(
        ellipsisSpan,
        _ellipsisBidiLevel!,
        ClusterRange(start: 0, end: ellipsisSpan.size),
        ui.TextRange(start: 0, end: ellipsisSpan.text.length),
        0.0,
        0.0,
      );
    }

    // Arrange line vertically, calculate metrics and bounds
    final ui.TextRange contentTextRange = _mapping.toTextRange(contentRange);
    final ui.TextRange whitespaceTextRange = _mapping.toTextRange(whitespaceRange);
    final allTextRange = ui.TextRange(start: contentTextRange.start, end: whitespaceTextRange.end);
    assert(contentTextRange.end == whitespaceTextRange.start);

    // TODO(mdebbar): Move this line creation to the end of the method when all info is available.
    final line = TextLine(
      contentRange,
      whitespaceRange,
      hardLineBreak,
      lines.length,
      contentTextRange,
      whitespaceTextRange,
      allTextRange,
    );

    // Get logical bidi levels belonging to the line.
    var overlapStart = -1; // Inclusive
    var overlapEnd = -1; // Exclusive
    for (var i = 0; i < bidiRuns.length; i++) {
      final BidiRun bidiRun = bidiRuns[i];
      final bool isOverlapping = bidiRun.clusterRange.overlapsWith(
        contentRange.start,
        whitespaceRange.end,
      );

      final bool isFirstOverlap = isOverlapping && overlapStart == -1;
      if (isFirstOverlap) {
        overlapStart = i;
      }

      final bool isDoneOverlapping = !isOverlapping && overlapStart > -1;
      if (isDoneOverlapping) {
        overlapEnd = i;
        break;
      }
    }

    if (overlapEnd == -1) {
      // The overlap continued until the end of text.
      overlapEnd = bidiRuns.length;
    }

    final Iterable<BidiRun> lineVisualRuns = bidiRuns.inVisualOrder(overlapStart, overlapEnd);

    // We need to take the VISUALLY first cluster on the line (in case of LTR/RTL it could be anywhere)
    // and shift all runs for this line so this first cluster starts from 0
    // Break the line into the blocks that belong to the same bidi run (monodirectional text) and to the same style block (the same text metrics)
    var trailingSpacesWidth = 0.0;
    // In case we attach the ellipsis block at the left (RTL paragraph) we need to reserve its width
    double blockShiftFromLineStart =
        ellipsisBlock != null && paragraph.paragraphStyle.textDirection == ui.TextDirection.rtl
        ? ellipsisBlock.advance.width
        : 0.0;
    for (final bidiRun in lineVisualRuns) {
      // TODO(jlavrova): we (almost always true) assume that trailing whitespaces do not affect the line height
      final ClusterRange textIntersection = bidiRun.clusterRange.intersect(contentRange);
      final ClusterRange whitespacesIntersection = bidiRun.clusterRange.intersect(whitespaceRange);

      assert(() {
        final ClusterRange whitespaceIntersection = bidiRun.clusterRange.intersect(whitespaceRange);
        // One of the intersections must be non-empty, or we did something wrong.
        return textIntersection.isNotEmpty || whitespaceIntersection.isNotEmpty;
      }());

      /*
      // We ignore whitespaces because for now we only use these textStyles for decoration
      // (and we do not decorate trailing whitespaces)
      if (textIntersection.isEmpty) {
        // TODO(jlavrova): what to do with trailing whitespaces? (After implementing queries)
        continue;
      }
*/
      // We cannot ignore whitespaces because they are expected to be counted in some query apis (getBoxesForRange)
      assert(contentRange.isNotEmpty || whitespaceRange.isNotEmpty);
      final ClusterRange fullIntersection = textIntersection.merge(whitespacesIntersection);

      // This is the part of the line that intersects with the `bidiRun` being processed now.
      final ui.TextRange bidiLineTextRange = _mapping.toTextRange(fullIntersection);
      final ui.TextRange bidiWhitespacesTextRange =
          whitespacesIntersection.start < whitespacesIntersection.end
          ? _mapping.toTextRange(whitespacesIntersection)
          : ui.TextRange.empty;

      if (WebParagraphDebug.logging) {
        WebParagraphDebug.log(
          'Run: "${paragraph.getText(bidiLineTextRange.start, bidiLineTextRange.end)}" '
          '${bidiRun.clusterRange} & $contentRange = $fullIntersection textRange:$bidiLineTextRange',
        );
      }

      // TODO(jlavrova): This loop seems excessive. We are iterating over all spans of the
      //                 paragraph. Can we try to iterate less?
      for (final ParagraphSpan span in paragraph.spans) {
        final bool isOverlapping = bidiLineTextRange.overlapsWith(span.start, span.end);

        if (!isOverlapping) {
          continue;
        }

        // This is the intersection of the bidi region + line + span.
        final ui.TextRange bidiLineSpanTextRange = bidiLineTextRange.intersect(span);
        WebParagraphDebug.log(
          'Style: ${span as ui.TextRange} & $bidiLineTextRange = $bidiLineSpanTextRange ',
        );

        final ClusterRange bidiLineSpanRange = _mapping.toClusterRange(
          bidiLineSpanTextRange.start,
          bidiLineSpanTextRange.end,
        );
        final LineBlock block;
        final double blockWidth;
        if (span is PlaceholderSpan) {
          assert(bidiLineSpanRange.size == 1);
          line.visualBlocks.add(
            block = PlaceholderBlock(
              span,
              bidiRun.bidiLevel,
              bidiLineSpanRange,
              bidiLineSpanTextRange,
              blockShiftFromLineStart,
            ),
          );
          blockWidth = span.width;
        } else {
          final WebCluster firstVisualClusterInBlock = bidiRun.isLtr
              ? allClusters[bidiLineSpanRange.start]
              : allClusters[bidiLineSpanRange.end - 1];
          final double blockShiftFromSpanStart = firstVisualClusterInBlock.advance.left;
          line.visualBlocks.add(
            block = TextBlock(
              span as TextSpan,
              bidiRun.bidiLevel,
              bidiLineSpanRange,
              bidiLineSpanTextRange,
              blockShiftFromLineStart,
              blockShiftFromSpanStart,
            ),
          );

          final ui.TextRange blockLineWhitespaces = bidiLineSpanTextRange.intersect(
            bidiWhitespacesTextRange,
          );
          final ui.TextRange blockLineNoWhitespaces = bidiLineSpanTextRange.intersect(
            _mapping.toTextRange(textIntersection),
          );
          if (blockLineWhitespaces.start < blockLineWhitespaces.end) {
            trailingSpacesWidth = span
                .getTextRangeSelectionInBlock(line.visualBlocks.last, blockLineWhitespaces)
                .width;
            (line.visualBlocks.last as TextBlock).clusterRangeWithoutWhitespaces = _mapping
                .toClusterRange(blockLineNoWhitespaces.start, blockLineNoWhitespaces.end);
            (line.visualBlocks.last as TextBlock).whitespacesWidth = trailingSpacesWidth;
            WebParagraphDebug.log(
              'TRAILING: $bidiLineSpanTextRange $blockLineNoWhitespaces $trailingSpacesWidth',
            );
          }

          // Line always counts multipled metrics (no need for the others)
          line.fontBoundingBoxAscent = math.max(
            line.fontBoundingBoxAscent,
            block.multipliedFontBoundingBoxAscent,
          );
          line.fontBoundingBoxDescent = math.max(
            line.fontBoundingBoxDescent,
            block.multipliedFontBoundingBoxDescent,
          );
          blockWidth = block.advance.width;
        }

        if (WebParagraphDebug.logging) {
          final String styledText = paragraph.getText(
            bidiLineSpanTextRange.start,
            bidiLineSpanTextRange.end,
          );
          WebParagraphDebug.log(
            'Styled text: "$styledText" clusterRange: $bidiLineSpanRange '
            'width:$blockWidth shiftFromLineStart:$blockShiftFromLineStart trailingSpacesWidth:$trailingSpacesWidth',
          );
        }
        blockShiftFromLineStart += blockWidth;
      }
    }

    // Add the ellipsis blocks if any
    if (ellipsisBlock != null) {
      if (paragraph.paragraphStyle.textDirection == ui.TextDirection.ltr) {
        // We need to adjust the block shift from line start because we are adding the ellipsis block at the end
        ellipsisBlock.shiftFromLineStart = blockShiftFromLineStart;
        ellipsisBlock.spanShiftFromLineStart = blockShiftFromLineStart;
        line.visualBlocks.add(ellipsisBlock);
      } else {
        // We place the ellipsis block aat the beginning of the line (for RTL paragraph)
        line.visualBlocks.insert(0, ellipsisBlock);
      }
    }

    // Now when we calculated all line metrics we have to correct placeholders that depend on it
    for (final LineBlock block in line.visualBlocks) {
      if (block is! PlaceholderBlock) {
        continue;
      }
      block.calculatePlaceholderTop(line.fontBoundingBoxAscent, line.fontBoundingBoxDescent);
      // Line always counts multipled metrics (no need for the others)
      // TODO(jlavrova): sort our alphabetic/ideographic baseline and how it affects ascent & descent
      line.fontBoundingBoxAscent = math.max(line.fontBoundingBoxAscent, block.ascent);
      line.fontBoundingBoxDescent = math.max(line.fontBoundingBoxDescent, block.descent);
      WebParagraphDebug.log(
        'Adjusted metrics: '
        '${line.fontBoundingBoxAscent} => ${math.max(line.fontBoundingBoxAscent, block.ascent)} '
        '${line.fontBoundingBoxDescent} => ${math.max(line.fontBoundingBoxDescent, block.descent)} ',
      );
    }

    line.advance = ui.Rect.fromLTWH(
      0,
      top,
      // Line advance.width should not include trailing spaces (that are counted as a part of a block)
      blockShiftFromLineStart - trailingSpacesWidth,
      // At the end this shift is equal to the entire line width
      line.height,
    );
    line.trailingSpacesWidth = trailingSpacesWidth;
    lines.add(line);

    WebParagraphDebug.log(
      'Line [${line.textClusterRange.start}:${line.textClusterRange.end}) ${line.advance.left},${line.advance.top} ${line.advance.width}x${line.advance.height} '
      '${ellipsisClusters.isNotEmpty ? 'Ellipsis: "${paragraph.paragraphStyle.ellipsis}" ${ellipsisClusters.length}' : ''}',
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
      // Notice, that we can have multiple lines even with width=infinity
      // (hard line breaks would do that)
      var maxLength = 0.0;
      for (final TextLine line in lines) {
        maxLength = math.max(maxLength, line.advance.width);
      }
      return;
    }

    for (final TextLine line in lines) {
      final double delta = paragraph.width - line.advance.width;
      if (delta > 0) {
        // We do nothing for left align
        if (effectiveAlign == ui.TextAlign.justify) {
          // TODO(jlavrova): implement justification
        } else if (effectiveAlign == ui.TextAlign.right) {
          // When we paint we exclude whitespaces but the advances still remain
          // so we need to take them into account
          line.formattingShift = delta - line.trailingSpacesWidth;
        } else if (effectiveAlign == ui.TextAlign.center) {
          line.formattingShift = delta / 2;
        }
      }
      WebParagraphDebug.apiTrace(
        'formatLines(${paragraph.text}, $width): ${line.advance} $effectiveAlign $delta ${line.formattingShift} ${paragraph.longestLine} ${paragraph.maxLineWidthWithTrailingSpaces}',
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
    final textRange = ui.TextRange(start: start, end: end);
    final result = <ui.TextBox>[];
    // TODO(mdebbar): Instead of nested loops, make them two consecutive loops.
    for (var lineIndex = 0; lineIndex < lines.length; ++lineIndex) {
      final TextLine line = lines[lineIndex];
      WebParagraphDebug.log(
        'Line: ${line.textClusterRange} & $textRange '
        '[${line.advance.left}:${line.advance.right} x ${line.advance.top}:${line.advance.bottom}] ',
      );
      // We take whitespaces in account
      if (!line.allLineTextRange.overlapsWith(start, end)) {
        continue;
      }

      for (final LineBlock block in line.visualBlocks) {
        final ui.TextRange intersect = block.textRange.intersect(textRange);
        //if (boxWidthStyle == ui.BoxWidthStyle.tight) {
        //  // Ignore whitespaces at the end of the line
        //  intersect = intersect.intersect(line.textRange);
        //}
        WebParagraphDebug.log(
          'block: ${block.textRange} & $textRange = $intersect '
          '${block.span.start}',
        );
        if (intersect.size <= 0) {
          continue;
        }
        ui.Rect firstRect = block.advance;
        if (block is! PlaceholderBlock) {
          // We need to calculate the intersect rectangle
          firstRect = (block.span as TextSpan)
              .getTextRangeSelectionInBlock(block, intersect)
              .translate(
                block.shiftFromLineStart, // We do not use baseline for placeholder
                block.rawFontBoundingBoxAscent,
              );
        }
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
            assert((block.advance.height - (bottom - top).abs() < epsilon));
          case ui.BoxHeightStyle.max:
            top = firstRect.top + line.advance.top;
            bottom = firstRect.top + line.advance.bottom;
            assert((line.advance.height - (bottom - top).abs() < epsilon));
          case ui.BoxHeightStyle.strut:
            if (paragraph.paragraphStyle.strutStyle == null) {
              top = firstRect.top + line.advance.top;
              bottom = firstRect.top + line.advance.bottom;
              break;
            }
            final WebStrutStyle strutStyle = paragraph.paragraphStyle.strutStyle!;
            top =
                firstRect.top +
                line.advance.top +
                line.fontBoundingBoxAscent -
                strutStyle.strutAscent;
            bottom = top + strutStyle.strutAscent + strutStyle.strutDescent;
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
        result.add(
          ui.TextBox.fromLTRBD(
            left,
            top,
            right,
            bottom,
            block.isLtr ? ui.TextDirection.ltr : ui.TextDirection.rtl,
          ),
        );
      }

      if (boxWidthStyle == ui.BoxWidthStyle.max && lineIndex < lines.length - 1) {
        // Add whitespaces box left/right for all the lines except the last one
        if ((result.first.left - 0).abs() > epsilon) {
          result.insert(
            0,
            ui.TextBox.fromLTRBD(
              0,
              result.first.top,
              result.first.left,
              result.first.bottom,
              paragraph.paragraphStyle.textDirection,
            ),
          );
        }
        if ((result.last.right - paragraph.maxLineWidthWithTrailingSpaces).abs() > epsilon) {
          result.add(
            ui.TextBox.fromLTRBD(
              result.last.right,
              result.first.top,
              paragraph.maxLineWidthWithTrailingSpaces,
              result.first.bottom,
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
    final result = <ui.TextBox>[];
    for (final TextLine line in lines) {
      for (final LineBlock block in line.visualBlocks) {
        if (block is TextBlock) {
          continue;
        }
        final ui.Rect rect = block.advance.translate(
          line.advance.left + line.formattingShift,
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
    WebParagraphDebug.apiTrace('getPositionForOffset("${paragraph.text}", $offset)');
    if (paragraph.text.isEmpty) {
      return ui.TextPosition(
        offset: 0,
        affinity: offset.dx <= 0 ? ui.TextAffinity.upstream : ui.TextAffinity.downstream,
      );
    }

    var lineNum = 0;
    for (final TextLine line in lines) {
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
      WebParagraphDebug.log('found line: ${line.textClusterRange} ${line.advance} vs $offset');

      // We found the line that contains the offset; let's go through all the visual blocks to find the position
      for (final LineBlock block in line.visualBlocks) {
        final ui.Rect blockRect = block.advance
            .translate(line.advance.left + line.formattingShift, line.advance.top)
            .inflate(epsilon);
        if (blockRect.right < offset.dx) {
          return ui.TextPosition(
            offset: line.textClusterRange.end - 1,
            /*affinity: ui.TextAffinity.downstream,*/
          );
        } else if (blockRect.left > offset.dx) {
          // We are not there yet; we need a block containing the offset (or the closest to it)
          continue;
        }

        WebParagraphDebug.log('found block: $block $blockRect vs $offset');
        // Found the block; let's go through all the clusters IN VISUAL ORDER to find the position
        final int start = block.isLtr ? block.clusterRange.start : block.clusterRange.end - 1;
        final int end = block.isLtr ? block.clusterRange.end : block.clusterRange.start - 1;
        final step = block.isLtr ? 1 : -1;
        for (var i = start; i != end; i += step) {
          final WebCluster cluster = allClusters[i];
          final ui.Rect rect = cluster.advance
              .translate(
                // TODO(mdebbar): Using `block.spanShiftFromLineStart` here is unfortunate. We should try
                //                to come up with a better API and probably not use `cluster.advance` directly.
                //                See other TODO above [WebCluster.bounds].
                line.advance.left + line.formattingShift + block.spanShiftFromLineStart,
                line.advance.top + line.fontBoundingBoxAscent,
              )
              .inflate(epsilon);
          WebParagraphDebug.log('test cluster: $rect vs $offset');
          if (rect.contains(offset)) {
            if (offset.dx - rect.left <= rect.right - offset.dx) {
              return ui.TextPosition(offset: cluster.start);
            } else if (cluster.end == paragraph.text.length) {
              return ui.TextPosition(offset: cluster.end - 1);
            } else {
              return ui.TextPosition(offset: cluster.end, affinity: ui.TextAffinity.upstream);
            }
          }
        }
        // We found the block but not the cluster? How could that happen
        assert(false);
      }

      // We didn't find the block containing our offset and
      // we didn't find the block that is on the right of the offset
      // So all the blocks are on the left
      return paragraph.text.isEmpty
          ? const ui.TextPosition(offset: 0)
          : ui.TextPosition(
              offset: line.textClusterRange.end - 1,
              /*affinity: ui.TextAffinity.downstream,*/
            );
    }
    // We didn't find the line containing our offset and
    // we didn't find the line that is down from the offset
    // So all the line are above the offset
    return paragraph.text.isEmpty
        ? const ui.TextPosition(offset: 0)
        : ui.TextPosition(offset: paragraph.text.length, affinity: ui.TextAffinity.upstream);
  }

  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    if (paragraph.text.isEmpty || codeUnitOffset < 0 || codeUnitOffset >= paragraph.text.length) {
      return null;
    }

    final ClusterRange clusterRange = _mapping.toClusterRange(codeUnitOffset, codeUnitOffset + 1);
    if (clusterRange.isEmpty) {
      return null;
    }

    final int? lineNumber = paragraph.getLineNumberAt(codeUnitOffset);
    if (lineNumber == null) {
      return null;
    }
    final TextLine line = lines[lineNumber];

    // The cluster is on this line.
    for (final LineBlock visualBlock in line.visualBlocks) {
      if (visualBlock.clusterRange.isBefore(clusterRange.start)) {
        // We cannot assume clusters go sequentially because of bidi reshuffling
        continue;
      } else if (visualBlock.clusterRange.isAfter(clusterRange.start)) {
        // We haven't reached the cluster yet, keep going.
        continue;
      }

      assert(visualBlock.clusterRange.overlapsWith(clusterRange.start, clusterRange.end));

      final ClusterRange intersection = visualBlock.clusterRange.intersect(clusterRange);
      assert(intersection.isNotEmpty);

      final WebCluster cluster = allClusters[intersection.start];
      return ui.GlyphInfo(
        cluster.advance.translate(
          line.advance.left + line.formattingShift + visualBlock.spanShiftFromLineStart,
          line.advance.top + line.fontBoundingBoxAscent,
        ),
        ui.TextRange(start: cluster.start, end: cluster.end),
        _detectTextDirection(clusterRange),
      );
    }

    return null;
  }

  ui.TextRange getWordBoundary(int position) {
    assert(0 <= position);
    assert(position < paragraph.text.length);

    int start = position + 1;
    while (start > 0) {
      start -= 1;
      if (codeUnitFlags.hasFlag(start, CodeUnitFlag.wordBreak)) {
        break;
      }
    }
    int end = position + 1;
    while (end < codeUnitFlags.length) {
      if (codeUnitFlags.hasFlag(end, CodeUnitFlag.wordBreak)) {
        break;
      }
      end += 1;
    }
    return ui.TextRange(start: start, end: end);
  }

  ui.TextRange getLineBoundary(int codepointPosition) {
    for (final TextLine line in lines) {
      if (line.allLineTextRange.start <= codepointPosition &&
          line.allLineTextRange.end > codepointPosition) {
        return ui.TextRange(start: line.allLineTextRange.start, end: line.allLineTextRange.end);
      }
    }
    return ui.TextRange.empty;
  }
}

extension EnhancedTextRange on ui.TextRange {
  int get size => end - start;

  bool get isEmpty => start == end;

  bool get isNotEmpty => !isEmpty;

  ui.TextRange intersect(ui.TextRange other) {
    return ui.TextRange(start: math.max(start, other.start), end: math.min(end, other.end));
  }

  bool isBefore(int index) {
    // `end` is exclusive.
    return end <= index;
  }

  bool isAfter(int index) {
    return start > index;
  }

  /// Whether this range overlaps with the given range from [start] to [end].
  bool overlapsWith(int start, int end) {
    // `end` is exclusive.
    return !isBefore(start) && !isAfter(end - 1);
  }
}

class _TextClusterMapping {
  _TextClusterMapping(this._size, this._clusters) : _textToCluster = Uint32List(_size);

  final int _size;
  final List<WebCluster> _clusters;
  final Uint32List _textToCluster;

  // This counts how many indices were added to this mapping. It's used later to confirm that the
  // number of additions matches the size of the paragraph i.e. there was an addition for each
  // character in the text.
  int _debugAddCount = 0;

  void add({required int textIndex, required int clusterIndex}) {
    assert(textIndex >= 0);
    assert(textIndex <= _size);

    assert(clusterIndex >= 0);
    assert(clusterIndex <= _clusters.length);

    _textToCluster[textIndex] = clusterIndex;
    _debugAddCount++;
  }

  int toClusterIndex(int textIndex) {
    assert(_debugAddCount == _size);

    assert(textIndex >= 0);
    assert(textIndex <= _size);

    return _textToCluster[textIndex];
  }

  ClusterRange toClusterRange(int start, int end) {
    if (start < 0 || end > _size || start > end) {
      throw ArgumentError('TextRange [$start:$end) is out of paragraph text range: [0:$_size');
    }
    assert(_debugAddCount == _size);

    assert(start >= 0);
    assert(start <= end);
    assert(end <= _size);

    if (start == _size) {
      // The entire range is at the end of text.
      return ClusterRange.collapsed(_clusters.length);
    }

    if (start == end) {
      // For an empty text range, we create a collapsed (empty) cluster range at the same position.
      final int clusterIndex = toClusterIndex(start);
      return ClusterRange.collapsed(clusterIndex);
    }
    return ClusterRange(start: toClusterIndex(start), end: toClusterIndex(end - 1) + 1);
  }

  ui.TextRange toTextRange(ClusterRange clusterRange) {
    assert(clusterRange.start >= 0);
    assert(clusterRange.start <= clusterRange.end);
    assert(clusterRange.end <= _clusters.length);

    if (clusterRange.start == _clusters.length) {
      // The entire cluster range is at the end of text.
      return ui.TextRange.collapsed(_size);
    }

    final WebCluster startCluster = _clusters[clusterRange.start];
    if (clusterRange.isEmpty) {
      return ui.TextRange.collapsed(startCluster.start);
    }
    final WebCluster endCluster = _clusters[clusterRange.end - 1];

    return ui.TextRange(
      start: math.min(startCluster.start, endCluster.end),
      end: math.max(startCluster.start, endCluster.end),
    );
  }
}

abstract class WebCluster {
  int get start => span.start + startInSpan;

  int get end => span.start + endInSpan;

  int get startInSpan;

  int get endInSpan;

  // TODO(mdebbar): Cluster's `bounds` and `advance` are relative to the span, which isn't very useful
  //                most of the time. Should we hide those and only show `width`/`height` since those
  //                are still useful?
  //                Callsites that need `bounds` and `advance` are usually performing some kind of
  //                coordinate conversion to make them relative to the line, for example. We should
  //                encapsulate that logic here and make it convenient to use.
  ui.Rect get bounds;

  ui.Rect get advance;

  ParagraphSpan get span;

  WebTextStyle get style;

  void fillOnContext(DomCanvasRenderingContext2D context, {required double x, required double y});

  @override
  String toString() {
    return 'WebCluster [$start:$end)';
  }
}

class TextCluster extends WebCluster {
  TextCluster(this.span, this._cluster) : startInSpan = _cluster.start, endInSpan = _cluster.end;

  @override
  final TextSpan span;

  @override
  WebTextStyle get style => span.style;

  @override
  final int startInSpan;
  @override
  final int endInSpan;

  @override
  late final ui.Rect bounds = span.getClusterBounds(this);
  @override
  late final ui.Rect advance = span.getClusterSelection(this);

  final DomTextCluster _cluster;

  @override
  void fillOnContext(DomCanvasRenderingContext2D context, {required double x, required double y}) {
    context.fillTextCluster(
      _cluster,
      /*left:*/ 0,
      /*top:*/ span.fontBoundingBoxAscent,
      // TODO(mdebbar): Use proper TextClusterOptions.
      <String, double>{'x': x, 'y': y},
    );
  }

  @override
  String toString() {
    return 'TextCluster [$start:$end) ${end - start}';
  }
}

class EmptyCluster extends WebCluster {
  EmptyCluster(this.span) : height = span.fontBoundingBoxAscent + span.fontBoundingBoxDescent;

  final double height;

  @override
  final TextSpan span;

  @override
  WebTextStyle get style => span.style;

  @override
  final int startInSpan = 0;
  @override
  final int endInSpan = 0;

  @override
  late final ui.Rect bounds = ui.Rect.fromLTWH(0, 0, 0, height);
  @override
  late final ui.Rect advance = ui.Rect.fromLTWH(0, 0, 0, height);

  @override
  void fillOnContext(DomCanvasRenderingContext2D context, {required double x, required double y}) {
    assert(false, 'We should not call fillOnContext method on this object');
  }

  @override
  String toString() {
    return 'EmptyCluster [$start:$end)';
  }
}

class PlaceholderCluster extends WebCluster {
  PlaceholderCluster(this.span) : endInSpan = span.size;

  @override
  final PlaceholderSpan span;

  @override
  final int startInSpan = 0;
  @override
  final int endInSpan;

  @override
  WebTextStyle get style => span.style;

  @override
  late final ui.Rect bounds = ui.Rect.fromLTWH(0, 0, span.width, span.height);

  @override
  // For placeholders bounds == advance
  ui.Rect get advance => bounds;

  @override
  void fillOnContext(DomCanvasRenderingContext2D context, {required double x, required double y}) {
    // No-op. Placeholders don't draw anything.
  }
}

// This is the minimal range of cluster that belongs to the same bidi run and to the same style block
abstract class LineBlock {
  LineBlock(
    this.span,
    this._bidiLevel,
    // TODO(mdebbar): Do we actually need both `clusterRange` and `textRange`?
    this.clusterRange,
    this.textRange,
    this.shiftFromLineStart,
  );

  double get _heightMultiplier;

  double get rawHeight => rawFontBoundingBoxAscent + rawFontBoundingBoxDescent;

  double get rawFontBoundingBoxAscent => span.fontBoundingBoxAscent;

  double get rawFontBoundingBoxDescent => span.fontBoundingBoxDescent;

  double get multipliedHeight => rawHeight * _heightMultiplier;

  double get multipliedFontBoundingBoxAscent => rawFontBoundingBoxAscent * _heightMultiplier;

  double get multipliedFontBoundingBoxDescent => rawFontBoundingBoxDescent * _heightMultiplier;

  final ParagraphSpan span;

  WebTextStyle get style => span.style;

  final int _bidiLevel;

  bool get isLtr => _bidiLevel.isEven;

  bool get isRtl => !isLtr;

  final ClusterRange clusterRange;
  final ui.TextRange textRange; // within the entire text
  ui.Rect get advance;

  //
  // |             LINE            |
  //          {      SPAN     }
  //               [ BLOCK ]
  // |--------{----[-------]--}----|
  //
  //          ^----^ shiftFromSpanStart
  // ^-------------^ shiftFromLineStart
  // ^--------^      spanShiftFromLineStart
  double shiftFromLineStart;

  // TODO(mdebbar): Remove when possible!
  double get spanShiftFromLineStart;
}

class TextBlock extends LineBlock {
  TextBlock(
    super.span,
    super._bidiLevel,
    super.clusterRange,
    super.textRange,
    super.shiftFromLineStart,
    double shiftFromSpanStart,
  ) : spanShiftFromLineStart = shiftFromLineStart - shiftFromSpanStart,
      clusterRangeWithoutWhitespaces = clusterRange,
      whitespacesWidth = 0.0;

  @override
  TextSpan get span => super.span as TextSpan;

  @override
  late final ui.Rect advance = span.getBlockSelection(this);

  @override
  double spanShiftFromLineStart;

  @override
  // TODO(jlavrova): Why are we defaulting to 1.0? In Chrome, the default line-height is `1.2` most of the time.
  double get _heightMultiplier => style.height == null ? 1.0 : style.height!;

  ClusterRange clusterRangeWithoutWhitespaces;
  double whitespacesWidth;
}

class PlaceholderBlock extends LineBlock {
  PlaceholderBlock(
    super.span,
    super._bidiLevel,
    super.clusterRange,
    super.textRange,
    super.shiftFromLineStart,
  ) : // Placeholders have a single block in the span, so the block's `shiftFromLineStart` and
      // `spanShiftFromLineStart` are identical.
      spanShiftFromLineStart = shiftFromLineStart;

  @override
  PlaceholderSpan get span => super.span as PlaceholderSpan;

  @override
  late final ui.Rect advance;

  @override
  final double spanShiftFromLineStart;

  @override
  double get _heightMultiplier => 1.0;

  void calculatePlaceholderTop(double lineAscent, double lineDescent) {
    double baselineAdjustment = 0;
    if (span.baseline == ui.TextBaseline.ideographic) {
      baselineAdjustment = lineDescent / 2;
    }

    final double height = span.height;
    final double offset = span.baselineOffset;
    WebParagraphDebug.log(
      'calculatePlaceholderAdvance($lineAscent, $lineDescent): height=$height offset=$offset',
    );
    switch (span.alignment) {
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
    final double top = lineAscent - ascent;
    // The advance needs to be calculated relative to the line. In order to do that, we need to start
    // from the span's own advance within the line.
    advance = ui.Rect.fromLTWH(spanShiftFromLineStart, top, span.width, span.height);
    WebParagraphDebug.log('PlaceholderBlock calculated advance: $advance $ascent $descent');
  }

  // TODO(jlavrova): Why are we using separate properties instead of `rawFontBoundingBoxAscent` and `rawFontBoundingBoxDescent`?
  late final double ascent;
  late final double descent;
}

class EllipsisBlock extends TextBlock {
  EllipsisBlock(
    super.span,
    super._bidiLevel,
    super.clusterRange,
    super.textRange,
    super.shiftFromLineStart,
    super.shiftFromSpanStart,
  );
}

class TextLine {
  TextLine(
    // TODO(mdebbar): Do we really need all of these cluster and text ranges?
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
      baseline: advance.top + fontBoundingBoxAscent,
      lineNumber: lineNumber,
    );
  }

  double get height => fontBoundingBoxAscent + fontBoundingBoxDescent;

  final ClusterRange textClusterRange;
  final ClusterRange whitespacesClusterRange;
  final ui.TextRange textRange;
  final ui.TextRange whitespacesRange;
  final ui.TextRange allLineTextRange;
  final bool hardLineBreak;
  final int lineNumber;

  // TODO(mdebbar): What's the difference between this `advance` and `formattingShift`?
  ui.Rect advance = ui.Rect.zero;
  double fontBoundingBoxAscent = 0.0;
  double fontBoundingBoxDescent = 0.0;
  double formattingShift = 0.0; // For centered or right aligned text
  double trailingSpacesWidth = 0.0;

  // TODO(mdebbar): Do we need blocks ordered visually?
  List<LineBlock> visualBlocks = <LineBlock>[];
}

extension DomTextMetricsExtension on DomTextMetrics {
  ui.Rect getSelection(int start, int end) {
    final List<DomRectReadOnly> rects = getSelectionRects(start, end);
    double minLeft = rects.first.left;
    double minTop = rects.first.top;
    double maxRight = rects.first.right;
    double maxBottom = rects.first.bottom;

    for (var i = 1; i < rects.length; i++) {
      final DomRectReadOnly rect = rects[i];

      minLeft = math.min(minLeft, rect.left);
      minTop = math.min(minTop, rect.top);
      maxRight = math.max(maxRight, rect.right);
      maxBottom = math.max(maxBottom, rect.bottom);
    }

    return ui.Rect.fromLTRB(minLeft, minTop, maxRight, maxBottom);
  }

  ui.Rect getBounds(int start, int end) {
    final DomRectReadOnly box = getActualBoundingBox(start, end);
    return ui.Rect.fromLTWH(box.left, box.top, box.width, box.height);
  }
}

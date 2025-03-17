// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../canvaskit/canvaskit_api.dart';
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
  DomTextMetrics? textMetrics;
  List<TextRun> runs = <TextRun>[];
  List<TextLine> lines = <TextLine>[];
  List<StyledTextRange> flatTextRanges = <StyledTextRange>[];

  bool hasFlag(ui.TextRange cluster, int flag) {
    return codeUnitFlags[cluster.start].hasFlag(flag);
  }

  void performLayout(double width) {
    this.lines.clear();
    this.runs.clear();
    this.codeUnitFlags.clear();

    this.extractClusterTexts();

    this.extractRuns();

    this.printClusters();

    this.extractUnicodeInfo();

    this.wrapText(paragraph.text, width);

    this.reorderVisuals();
  }

  void extractUnicodeInfo() {
    // TODO: Switch to SkUnicode.CodePointFlags API in CanvasKit
    // Fill out the entire flag list
    for (int i = 0; i <= paragraph.text.length; ++i) {
      codeUnitFlags.add(CodeUnitFlags(CodeUnitFlags.kNoCodeUnitFlag));
    }
    // Get the information from the browser
    final engine.SegmentationResult result = engine.segmentText(paragraph.text);

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

  void extractClusterTexts() {
    // Get all the cluster text information in one call
    textMetrics = textContext.measureText(paragraph.text);
    for (final WebTextCluster cluster in textMetrics!.getTextClusters()) {
      final List<DomRectReadOnly> rects = textMetrics!.getSelectionRects(
        cluster.begin,
        cluster.end,
      );
      this.textClusters.add(ExtendedTextCluster(cluster, rects.first));
    }
    //textContext.font = '50px arial';
    //this.textMetrics = textContext.measureText(paragraph.text) as DomTextMetrics;
    //this.textClusters = textMetrics!.getTextClusters();
  }

  void extractRuns() {
    // TODO: Implement bidi (via SkUnicode.Bidi API in CanvasKit)
    final Int32List regions = canvasKit.Bidi.getBidiRegions(paragraph.text, paragraph.paragraphStyle.textDirection);

    for (final styledTextRange in this.paragraph.styledTextRanges) {
      // TODO: Text range is not adjusted to Text Cluster range edges; we need to adjust it later
      ClusterRange clusterRange = ClusterRange(
        start: styledTextRange.textRange.start,
        end: styledTextRange.textRange.end,
      );
      TextRun run = TextRun(this, clusterRange, styledTextRange.textStyle.toString());
      runs.add(run);
    }
  }

  void printClusters() {
    if (WebParagraphDebug.logging) {
      WebParagraphDebug.log('Text Clusters: ${this.textClusters.length}');
      for (final TextRun run in this.runs) {
        String runText = this.paragraph.text.substring(
          run.clusterRange.start,
          run.clusterRange.end,
        );
        WebParagraphDebug.log('');
        WebParagraphDebug.log(
          'Run[${run.clusterRange.start}:${run.clusterRange.end}): ${run.originalFont.toString()} "${runText}"',
        );
        for (var i = run.clusterRange.start; i < run.clusterRange.end; ++i) {
          final ExtendedTextCluster cluster = this.textClusters[i];
          String clusterText = this.paragraph.text.substring(cluster.start, cluster.end);
          WebParagraphDebug.log(
            '[${cluster.start}:${cluster.end}) ${cluster.size.width} * ${cluster.size.height} "${clusterText}"',
          );
        }
      }
    }
  }

  void wrapText(String text, double width) {
    final TextWrapper wrapper = TextWrapper(text, this);
    wrapper.breakLines(width);
  }

  void reorderVisuals() {
    // TODO: Use bidi API to reorder visual runs for all lines
    // (maybe breaking these runs by lines in addition)
  }
}

class ExtendedTextCluster {
  ExtendedTextCluster(this.cluster, this.size) {
    start = this.cluster.begin;
    end = this.cluster.end;
  }
  WebTextCluster cluster;
  int start = 0;
  int end = 0;
  DomRectReadOnly size;
}

class TextRun {
  TextRun(this.textLayout, this.clusterRange, this.originalFont);

  final TextLayout textLayout;
  final ClusterRange clusterRange;
  final String originalFont;
}

class TextLine {
  TextLine(
    this.textLayout,
    this.clusterRange,
    this.width,
    this.whitespacesRange,
    this.whitespacesWidth,
    this.hardLineBreak,
  );

  final TextLayout textLayout;
  final ClusterRange clusterRange;
  final ClusterRange whitespacesRange;
  final double width;
  final double whitespacesWidth;
  final bool hardLineBreak;
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Performs layout on a [CanvasParagraph].
///
/// It uses a [html.CanvasElement] to measure text.
class TextLayoutService {
  TextLayoutService(this.paragraph);

  final CanvasParagraph paragraph;

  final html.CanvasRenderingContext2D context = html.CanvasElement().context2D;

  // *** Results of layout *** //

  // Look at the Paragraph class for documentation of the following properties.

  double width = -1.0;

  double height = 0.0;

  double longestLine = 0.0;

  double minIntrinsicWidth = 0.0;

  double maxIntrinsicWidth = 0.0;

  double alphabeticBaseline = -1.0;

  double ideographicBaseline = -1.0;

  bool didExceedMaxLines = false;

  final List<EngineLineMetrics> lines = <EngineLineMetrics>[];

  // *** Convenient shortcuts used during layout *** //

  int? get maxLines => paragraph.paragraphStyle._maxLines;
  bool get unlimitedLines => maxLines == null;

  String? get ellipsis => paragraph.paragraphStyle._ellipsis;
  bool get hasEllipsis => ellipsis != null;

  /// Performs the layout on a paragraph given the [constraints].
  ///
  /// The function starts by resetting all layout-related properties. Then it
  /// starts looping through the paragraph to calculate all layout metrics.
  ///
  /// It uses a [Spanometer] to perform measurements within spans of the
  /// paragraph. It also uses [LineBuilders] to generate [EngineLineMetrics] as
  /// it iterates through the paragraph.
  ///
  /// The main loop keeps going until:
  ///
  /// 1. The end of the paragraph is reached (i.e. LineBreakType.endOfText).
  /// 2. Enough lines have been computed to satisfy [maxLines].
  /// 3. An ellipsis is appended because of an overflow.
  void performLayout(ui.ParagraphConstraints constraints) {
    final int spanCount = paragraph.spans.length;

    // Reset results from previous layout.
    width = constraints.width;
    height = 0.0;
    longestLine = 0.0;
    minIntrinsicWidth = 0.0;
    maxIntrinsicWidth = 0.0;
    didExceedMaxLines = false;
    lines.clear();

    final Spanometer spanometer = Spanometer(paragraph, context);

    int spanIndex = 0;
    ParagraphSpan span = paragraph.spans[0];
    LineBuilder currentLine =
        LineBuilder.first(paragraph, spanometer, maxWidth: constraints.width);

    // The only way to exit this while loop is by hitting one of the `break;`
    // statements (e.g. when we reach `endOfText`, when ellipsis has been
    // appended).
    while (true) {
      // *********************************************** //
      // *** HANDLE HARD LINE BREAKS AND END OF TEXT *** //
      // *********************************************** //

      if (currentLine.end.isHard) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.build());
          if (currentLine.end.type != LineBreakType.endOfText) {
            currentLine = currentLine.nextLine();
          }
        }

        if (currentLine.end.type == LineBreakType.endOfText) {
          break;
        }
      }

      // ********************************* //
      // *** THE MAIN MEASUREMENT PART *** //
      // ********************************* //

      if (span is PlaceholderSpan) {
        spanometer.currentSpan = null;
        final double lineWidth = currentLine.width + span.width;
        if (lineWidth <= constraints.width) {
          // The placeholder fits on the current line.
          // TODO(mdebbar):
          // (1) adjust the current line's height to fit the placeholder.
          // (2) update accumulated line width.
        } else {
          // The placeholder can't fit on the current line.
          // TODO(mdebbar):
          // (1) create a line.
          // (2) adjust the new line's height to fit the placeholder.
          // (3) update `lineStart`, etc.
        }
      } else if (span is FlatTextSpan) {
        spanometer.currentSpan = span;
        final LineBreakResult nextBreak = currentLine.findNextBreak(span.end);
        final double additionalWidth =
            currentLine.getAdditionalWidthTo(nextBreak);

        if (currentLine.width + additionalWidth <= constraints.width) {
          // TODO(mdebbar): Handle the case when `nextBreak` is just a span end
          //                that shouldn't extend the line yet.

          // The line can extend to `nextBreak` without overflowing.
          currentLine.extendTo(nextBreak);
        } else {
          // The chunk of text can't fit into the current line.
          final bool isLastLine =
              (hasEllipsis && unlimitedLines) || lines.length + 1 == maxLines;

          if (isLastLine && hasEllipsis) {
            // We've reached the line that requires an ellipsis to be appended
            // to it.

            currentLine.forceBreak(nextBreak,
                allowEmpty: true, ellipsis: ellipsis);
            lines.add(currentLine.build(ellipsis: ellipsis));
            break;
          } else if (currentLine.isEmpty) {
            // The current line is still empty, which means we are dealing
            // with a single block of text that doesn't fit in a single line.
            // We need to force-break it without adding an ellipsis.

            currentLine.forceBreak(nextBreak, allowEmpty: false);
            lines.add(currentLine.build());
            currentLine = currentLine.nextLine();
          } else {
            // Normal line break.
            lines.add(currentLine.build());
            currentLine = currentLine.nextLine();
          }
        }
      } else {
        throw UnimplementedError('Unknown span type: ${span.runtimeType}');
      }

      if (lines.length == maxLines) {
        break;
      }

      // ********************************************* //
      // *** ADVANCE TO THE NEXT SPAN IF NECESSARY *** //
      // ********************************************* //

      // Only go to the next span if we've reached the end of this span.
      if (currentLine.end.index >= span.end && spanIndex < spanCount - 1) {
        span = paragraph.spans[++spanIndex];
      }
    }

    // ******************************** //
    // *** MAX/MIN INTRINSIC WIDTHS *** //
    // ******************************** //

    spanIndex = 0;
    span = paragraph.spans[0];
    currentLine =
        LineBuilder.first(paragraph, spanometer, maxWidth: constraints.width);

    while (currentLine.end.type != LineBreakType.endOfText) {
      if (span is PlaceholderSpan) {
        // TODO(mdebbar): Do placeholders affect min/max intrinsic width?
      } else if (span is FlatTextSpan) {
        final LineBreakResult nextBreak = currentLine.findNextBreak(span.end);

        // For the purpose of max intrinsic width, we don't care if the line
        // fits within the constraints or not. So we always extend it.
        currentLine.extendTo(nextBreak);

        final double widthOfLastSegment = currentLine.lastSegment.width;
        if (minIntrinsicWidth < widthOfLastSegment) {
          minIntrinsicWidth = widthOfLastSegment;
        }

        if (currentLine.end.isHard) {
          // Max intrinsic width includes the width of trailing spaces.
          if (maxIntrinsicWidth < currentLine.widthIncludingSpace) {
            maxIntrinsicWidth = currentLine.widthIncludingSpace;
          }
          currentLine = currentLine.nextLine();
        }

        // Only go to the next span if we've reached the end of this span.
        if (currentLine.end.index >= span.end && spanIndex < spanCount - 1) {
          span = paragraph.spans[++spanIndex];
        }
      }
    }
  }
}

/// Represents a segment in a line of a paragraph.
///
/// For example, this line: "Lorem ipsum dolor sit" is broken up into the
/// following segments:
///
/// - "Lorem "
/// - "ipsum "
/// - "dolor "
/// - "sit"
class LineSegment {
  LineSegment({
    required this.span,
    required this.start,
    required this.end,
    required this.width,
    required this.widthIncludingSpace,
  });

  /// The span that this segment belongs to.
  final ParagraphSpan span;

  /// The index of the beginning of the segment in the paragraph.
  final LineBreakResult start;

  /// The index of the end of the segment in the paragraph.
  final LineBreakResult end;

  /// The width of the segment excluding any trailing white space.
  final double width;

  /// The width of the segment including any trailing white space.
  final double widthIncludingSpace;

  /// The width of the trailing white space in the segment.
  double get widthOfTrailingSpace => widthIncludingSpace - width;
}

/// Builds instances of [EngineLineMetrics] for the given [paragraph].
///
/// Usage of this class starts by calling [LineBuilder.first] to start building
/// the first line of the paragraph.
///
/// Then new line breaks can be found by calling [LineBuilder.findNextBreak].
///
/// The line can be extended one or more times before it's built by calling
/// [LineBuilder.build] which generates the [EngineLineMetrics] instace.
///
/// To start building the next line, simply call [LineBuilder.nextLine] which
/// creates a new [LineBuilder] that can be extended and built and so on.
class LineBuilder {
  LineBuilder._(
    this.paragraph,
    this.spanometer, {
    required this.maxWidth,
    required this.start,
    required this.lineNumber,
  }) : end = start;

  /// Creates a [LineBuilder] for the first line in a paragraph.
  factory LineBuilder.first(
    CanvasParagraph paragraph,
    Spanometer spanometer, {
    required double maxWidth,
  }) {
    return LineBuilder._(
      paragraph,
      spanometer,
      maxWidth: maxWidth,
      lineNumber: 0,
      start: LineBreakResult.sameIndex(0, LineBreakType.prohibited),
    );
  }

  final List<LineSegment> _segments = <LineSegment>[];

  final double maxWidth;
  final CanvasParagraph paragraph;
  final Spanometer spanometer;
  final LineBreakResult start;
  final int lineNumber;

  LineBreakResult end;

  /// The width of the line so far, excluding trailing white space.
  double width = 0.0;

  /// The width of the line so far, including trailing white space.
  double widthIncludingSpace = 0.0;

  /// The width of trailing white space in the line.
  double get widthOfTrailingSpace => widthIncludingSpace - width;

  /// The last segment in this line.
  LineSegment get lastSegment => _segments.last;

  bool get isEmpty => _segments.isEmpty;
  bool get isNotEmpty => _segments.isNotEmpty;

  /// Measures the width of text between the end of this line and [newEnd].
  double getAdditionalWidthTo(LineBreakResult newEnd) {
    // If the extension is all made of space characters, it shouldn't add
    // anything to the width.
    if (end.index == newEnd.indexWithoutTrailingSpaces) {
      return 0.0;
    }

    return widthOfTrailingSpace + spanometer.measure(end, newEnd);
  }

  /// Extends the line by setting a [newEnd].
  void extendTo(LineBreakResult newEnd) {
    // If the current end of the line is a hard break, the line shouldn't be
    // extended any further.
    assert(
      isEmpty || !end.isHard,
      'Cannot extend a line that ends with a hard break.',
    );

    _addSegment(_createSegment(newEnd));
  }

  /// Creates a new segment to be appended to the end of this line.
  LineSegment _createSegment(LineBreakResult segmentEnd) {
    // The segment starts at the end of the line.
    final LineBreakResult segmentStart = end;
    return LineSegment(
      span: spanometer.currentSpan!,
      start: segmentStart,
      end: segmentEnd,
      width: spanometer.measure(segmentStart, segmentEnd),
      widthIncludingSpace:
          spanometer.measureIncludingSpace(segmentStart, segmentEnd),
    );
  }

  /// Adds a segment to this line.
  ///
  /// It adjusts the width properties to accommodate the new segment. It also
  /// sets the line end to the end of the segment.
  void _addSegment(LineSegment segment) {
    _segments.add(segment);

    // Add the width of previous trailing space.
    width += widthOfTrailingSpace + segment.width;
    widthIncludingSpace += segment.widthIncludingSpace;
    end = segment.end;
  }

  /// Removes the latest [LineSegment] added by [_addSegment].
  ///
  /// It re-adjusts the width properties and the end of the line.
  LineSegment _popSegment() {
    final LineSegment poppedSegment = _segments.removeLast();

    double widthOfPrevTrailingSpace;
    if (_segments.isEmpty) {
      widthOfPrevTrailingSpace = 0.0;
      end = start;
    } else {
      widthOfPrevTrailingSpace = lastSegment.widthOfTrailingSpace;
      end = lastSegment.end;
    }

    width = width - poppedSegment.width - widthOfPrevTrailingSpace;
    widthIncludingSpace -= poppedSegment.widthIncludingSpace;

    return poppedSegment;
  }

  /// Force-breaks the line in order to fit in [maxWidth] while trying to extend
  /// to [nextBreak].
  ///
  /// This should only be called when there isn't enough width to extend to
  /// [nextBreak], and either of the following is true:
  ///
  /// 1. An ellipsis is being appended to this line, OR
  /// 2. The line doesn't have any line break opportunities and has to be
  ///    force-broken.
  void forceBreak(
    LineBreakResult nextBreak, {
    required bool allowEmpty,
    String? ellipsis,
  }) {
    if (ellipsis == null) {
      final double availableWidth = maxWidth - widthIncludingSpace;
      final int breakingPoint = spanometer.forceBreak(
        end.index,
        nextBreak.indexWithoutTrailingSpaces,
        availableWidth: availableWidth,
        allowEmpty: allowEmpty,
      );

      // This condition can be true in the following case:
      // 1. Next break is only one character away, with zero or many spaces. AND
      // 2. There isn't enough width to fit the single character. AND
      // 3. `allowEmpty` is false.
      if (breakingPoint == nextBreak.indexWithoutTrailingSpaces) {
        // In this case, we just extend to `nextBreak` instead of creating a new
        // artifical break. It's safe (and better) to do so, because we don't
        // want the trailing white space to go to the next line.
        extendTo(nextBreak);
      } else {
        extendTo(
          LineBreakResult.sameIndex(breakingPoint, LineBreakType.prohibited),
        );
      }
      return;
    }

    // For example: "foo bar baz". Let's say all characters have the same width, and
    // the constraint width can only fit 9 characters "foo bar b". So if the
    // paragraph has an ellipsis, we can't just remove the last segment "baz"
    // and replace it with "..." because that would overflow.
    //
    // We need to keep popping segments until we are able to fit the "..."
    // without overflowing. In this example, that would be: "foo ba..."

    final double ellipsisWidth = spanometer.measureText(ellipsis);
    final double availableWidth = maxWidth - ellipsisWidth;

    // First, we create the new segment until `nextBreak`.
    LineSegment segmentToBreak = _createSegment(nextBreak);

    // Then, we keep popping until we find the segment that has to be broken.
    // After the loop ends, two things are correct:
    // 1. All remaining segments in `_segments` can fit within constraints.
    // 2. Adding `segmentToBreak` causes the line to overflow.
    while (_segments.isNotEmpty && widthIncludingSpace > availableWidth) {
      segmentToBreak = _popSegment();
    }

    spanometer.currentSpan = segmentToBreak.span as FlatTextSpan;
    final double availableWidthForSegment =
        availableWidth - widthIncludingSpace;
    final int breakingPoint = spanometer.forceBreak(
      segmentToBreak.start.index,
      segmentToBreak.end.index,
      availableWidth: availableWidthForSegment,
      allowEmpty: allowEmpty,
    );
    extendTo(LineBreakResult.sameIndex(breakingPoint, LineBreakType.prohibited));
  }

  /// Builds the [EngineLineMetrics] instance that represents this line.
  EngineLineMetrics build({String? ellipsis}) {
    double ellipsisWidth = 0.0;
    String text = paragraph
        .toPlainText()
        .substring(start.index, end.indexWithoutTrailingNewlines);

    if (ellipsis != null) {
      ellipsisWidth = spanometer.measureText(ellipsis);
      text += ellipsis;
    }

    return EngineLineMetrics.withText(
      text,
      startIndex: start.index,
      endIndex: end.index,
      endIndexWithoutNewlines: end.indexWithoutTrailingNewlines,
      hardBreak: end.isHard,
      width: width + ellipsisWidth,
      widthWithTrailingSpaces: widthIncludingSpace + ellipsisWidth,
      // TODO(mdebbar): Calculate actual align offset.
      left: 0.0,
      lineNumber: lineNumber,
    );
  }

  /// Finds the next line break after the end of this line.
  LineBreakResult findNextBreak(int maxEnd) {
    return nextLineBreak(paragraph.toPlainText(), end.index, maxEnd: maxEnd);
  }

  /// Creates a new [LineBuilder] to build the next line in the paragraph.
  LineBuilder nextLine() {
    return LineBuilder._(
      paragraph,
      spanometer,
      maxWidth: maxWidth,
      start: end,
      lineNumber: lineNumber + 1,
    );
  }
}

/// Responsible for taking measurements within spans of a paragraph.
///
/// Can't perform measurements across spans. To measure across spans, multiple
/// measurements have to be taken.
///
/// Before performing any measurement, the [currentSpan] has to be set. Once
/// it's set, the [Spanometer] updates the underlying [context] so that
/// subsequent measurements use the correct styles.
class Spanometer {
  Spanometer(this.paragraph, this.context);

  final CanvasParagraph paragraph;
  final html.CanvasRenderingContext2D context;

  String _cssFontString = '';

  double? get letterSpacing => _currentSpan!.style._letterSpacing;

  FlatTextSpan? _currentSpan;
  FlatTextSpan? get currentSpan => _currentSpan;
  set currentSpan(FlatTextSpan? span) {
    if (span == _currentSpan) {
      return;
    }
    _currentSpan = span;

    // No need to update css font string when `span` is null.
    if (span == null) {
      return;
    }

    // Update the font string if it's different from the previous span.
    final String cssFontString = span.style.cssFontString;
    if (_cssFontString != cssFontString) {
      _cssFontString = cssFontString;
      context.font = cssFontString;
    }
  }

  /// Measures the width of text between two line breaks.
  ///
  /// Doesn't include the width of any trailing white space.
  double measure(LineBreakResult start, LineBreakResult end) {
    return _measure(start.index, end.indexWithoutTrailingSpaces);
  }

  /// Measures the width of text between two line breaks.
  ///
  /// Includes the width of trailing white space, if any.
  double measureIncludingSpace(LineBreakResult start, LineBreakResult end) {
    return _measure(start.index, end.indexWithoutTrailingNewlines);
  }

  double measureText(String text) {
    return _measureSubstring(context, text, 0, text.length);
  }

  /// In a continuous, unbreakable block of text from [start] to [end], finds
  /// the point where text should be broken to fit in the given [availableWidth].
  ///
  /// The [start] and [end] indices have to be within the same text span.
  ///
  /// When [allowEmpty] is true, the result is guaranteed to be at least one
  /// character after [start]. But if [allowEmpty] is false and there isn't
  /// enough [availableWidth] to fit the first character, then [start] is
  /// returned.
  ///
  /// See also:
  /// - [LineBuilder.forceBreak].
  int forceBreak(
    int start,
    int end, {
    required double availableWidth,
    required bool allowEmpty,
  }) {
    assert(_currentSpan != null);

    final FlatTextSpan span = _currentSpan!;

    // Make sure the range is within the current span.
    assert(start >= span.start && start <= span.end);
    assert(end >= span.start && end <= span.end);

    if (availableWidth <= 0.0) {
      return allowEmpty ? start : start + 1;
    }

    int low = start;
    int high = end;
    do {
      final int mid = (low + high) ~/ 2;
      final double width = _measure(start, mid);
      if (width < availableWidth) {
        low = mid;
      } else if (width > availableWidth) {
        high = mid;
      } else {
        low = high = mid;
      }
    } while (high - low > 1);

    if (low == start && !allowEmpty) {
      low++;
    }
    return low;
  }

  double _measure(int start, int end) {
    assert(_currentSpan != null);
    final FlatTextSpan span = _currentSpan!;

    // Make sure the range is within the current span.
    assert(start >= span.start && start <= span.end);
    assert(end >= span.start && end <= span.end);

    final String text = paragraph.toPlainText();
    return _measureSubstring(
      context,
      text,
      start,
      end,
      letterSpacing: letterSpacing,
    );
  }
}

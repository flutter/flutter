// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math' as math;

import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart' show domRenderer, DomRenderer;

import '../browser_detection.dart';
import '../html/bitmap_canvas.dart';
import '../html/painting.dart';
import '../profiler.dart';
import '../util.dart';
import 'canvas_paragraph.dart';
import 'layout_service.dart';
import 'measurement.dart';
import 'ruler.dart';
import 'word_breaker.dart';

const ui.Color defaultTextColor = ui.Color(0xFFFF0000);

const String placeholderClass = 'paragraph-placeholder';

class EngineLineMetrics implements ui.LineMetrics {
  EngineLineMetrics({
    required this.hardBreak,
    required this.ascent,
    required this.descent,
    required this.unscaledAscent,
    required this.height,
    required this.width,
    required this.left,
    required this.baseline,
    required this.lineNumber,
  })  : displayText = null,
        ellipsis = null,
        startIndex = -1,
        endIndex = -1,
        endIndexWithoutNewlines = -1,
        widthWithTrailingSpaces = width,
        boxes = null;

  EngineLineMetrics.withText(
    String this.displayText, {
    required this.startIndex,
    required this.endIndex,
    required this.endIndexWithoutNewlines,
    required this.hardBreak,
    required this.width,
    required this.widthWithTrailingSpaces,
    required this.left,
    required this.lineNumber,
  })  : assert(displayText != null), // ignore: unnecessary_null_comparison,
        assert(startIndex != null), // ignore: unnecessary_null_comparison
        assert(endIndex != null), // ignore: unnecessary_null_comparison
        assert(endIndexWithoutNewlines != null), // ignore: unnecessary_null_comparison
        assert(hardBreak != null), // ignore: unnecessary_null_comparison
        assert(width != null), // ignore: unnecessary_null_comparison
        assert(left != null), // ignore: unnecessary_null_comparison
        assert(lineNumber != null && lineNumber >= 0), // ignore: unnecessary_null_comparison
        ellipsis = null,
        ascent = double.infinity,
        descent = double.infinity,
        unscaledAscent = double.infinity,
        height = double.infinity,
        baseline = double.infinity,
        boxes = null;

  EngineLineMetrics.rich(
    this.lineNumber, {
    required this.ellipsis,
    required this.startIndex,
    required this.endIndex,
    required this.endIndexWithoutNewlines,
    required this.hardBreak,
    required this.width,
    required this.widthWithTrailingSpaces,
    required this.left,
    required this.height,
    required this.baseline,
    required this.ascent,
    required this.descent,
    // Didn't use `this.boxes` because we want it to be non-null in this
    // constructor.
    required List<RangeBox> boxes,
  })  : displayText = null,
        unscaledAscent = double.infinity,
        this.boxes = boxes;

  /// The text to be rendered on the screen representing this line.
  final String? displayText;

  /// The string to be displayed as an overflow indicator.
  ///
  /// When the value is non-null, it means this line is overflowing and the
  /// [ellipsis] needs to be displayed at the end of it.
  final String? ellipsis;

  /// The index (inclusive) in the text where this line begins.
  final int startIndex;

  /// The index (exclusive) in the text where this line ends.
  ///
  /// When the line contains an overflow, then [endIndex] goes until the end of
  /// the text and doesn't stop at the overflow cutoff.
  final int endIndex;

  /// The index (exclusive) in the text where this line ends, ignoring newline
  /// characters.
  final int endIndexWithoutNewlines;

  /// The list of boxes representing the entire line, possibly across multiple
  /// spans.
  final List<RangeBox>? boxes;

  @override
  final bool hardBreak;

  @override
  final double ascent;

  @override
  final double descent;

  @override
  final double unscaledAscent;

  @override
  final double height;

  @override
  final double width;

  /// The full width of the line including all trailing space but not new lines.
  ///
  /// The difference between [width] and [widthWithTrailingSpaces] is that
  /// [widthWithTrailingSpaces] includes trailing spaces in the width
  /// calculation while [width] doesn't.
  ///
  /// For alignment purposes for example, the [width] property is the right one
  /// to use because trailing spaces shouldn't affect the centering of text.
  /// But for placing cursors in text fields, we do care about trailing
  /// spaces so [widthWithTrailingSpaces] is more suitable.
  final double widthWithTrailingSpaces;

  @override
  final double left;

  @override
  final double baseline;

  @override
  final int lineNumber;

  bool overlapsWith(int startIndex, int endIndex) {
    return startIndex < this.endIndex && this.startIndex < endIndex;
  }

  @override
  int get hashCode => ui.hashValues(
        displayText,
        startIndex,
        endIndex,
        hardBreak,
        ascent,
        descent,
        unscaledAscent,
        height,
        width,
        left,
        baseline,
        lineNumber,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineLineMetrics &&
        other.displayText == displayText &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.hardBreak == hardBreak &&
        other.ascent == ascent &&
        other.descent == descent &&
        other.unscaledAscent == unscaledAscent &&
        other.height == height &&
        other.width == width &&
        other.left == left &&
        other.baseline == baseline &&
        other.lineNumber == lineNumber;
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'LineMetrics(hardBreak: $hardBreak, '
          'ascent: $ascent, '
          'descent: $descent, '
          'unscaledAscent: $unscaledAscent, '
          'height: $height, '
          'width: $width, '
          'left: $left, '
          'baseline: $baseline, '
          'lineNumber: $lineNumber)';
    } else {
      return super.toString();
    }
  }
}

/// Common interface for all the implementations of [ui.Paragraph] in the web
/// engine.
abstract class EngineParagraph implements ui.Paragraph {
  /// Whether this paragraph has been laid out or not.
  bool get isLaidOut;

  /// Whether this paragraph can be drawn on a bitmap canvas.
  bool get drawOnCanvas;

  /// Whether this paragraph is doing arbitrary paint operations that require
  /// a bitmap canvas, and can't be expressed in a DOM canvas.
  bool get hasArbitraryPaint;

  void paint(BitmapCanvas canvas, ui.Offset offset);

  /// Generates a flat string computed from all the spans of the paragraph.
  String toPlainText();

  /// Returns a DOM element that represents the entire paragraph and its
  /// children.
  ///
  /// Generates a new DOM element on every invocation.
  html.HtmlElement toDomElement();
}

/// Uses the DOM and hierarchical <span> elements to represent the span of the
/// paragraph.
///
/// This implementation will go away once the new [CanvasParagraph] is
/// complete and turned on by default.
class DomParagraph implements EngineParagraph {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [DomParagraph] object, use a [DomParagraphBuilder].
  DomParagraph({
    required html.HtmlElement paragraphElement,
    required ParagraphGeometricStyle geometricStyle,
    required String? plainText,
    required ui.Paint? paint,
    required ui.TextAlign textAlign,
    required ui.TextDirection textDirection,
    required ui.Paint? background,
    required this.placeholderCount,
  })  : assert((plainText == null && paint == null) ||
            (plainText != null && paint != null)),
        _paragraphElement = paragraphElement,
        _geometricStyle = geometricStyle,
        _plainText = plainText,
        _textAlign = textAlign,
        _textDirection = textDirection,
        _paint = paint as SurfacePaint?,
        _background = background as SurfacePaint?;

  final html.HtmlElement _paragraphElement;
  final ParagraphGeometricStyle _geometricStyle;
  final String? _plainText;
  final SurfacePaint? _paint;
  final ui.TextAlign _textAlign;
  final ui.TextDirection _textDirection;
  final SurfacePaint? _background;

  final int placeholderCount;

  String? get plainText => _plainText;

  html.HtmlElement get paragraphElement => _paragraphElement;

  ui.TextAlign get textAlign => _textAlign;
  ui.TextDirection get textDirection => _textDirection;

  ParagraphGeometricStyle get geometricStyle => _geometricStyle;

  /// The instance of [TextMeasurementService] to be used to measure this
  /// paragraph.
  TextMeasurementService get _measurementService =>
      TextMeasurementService.forParagraph(this);

  /// The measurement result of the last layout operation.
  MeasurementResult? get measurementResult => _measurementResult;
  MeasurementResult? _measurementResult;

  bool get _hasLineMetrics => _measurementResult?.lines != null;

  // Defaulting to -1 for non-laid-out paragraphs like the native engine does.
  @override
  double get width => _measurementResult?.width ?? -1;

  @override
  double get height => _measurementResult?.height ?? 0;

  /// {@template dart.ui.paragraph.naturalHeight}
  /// The amount of vertical space the paragraph occupies while ignoring the
  /// [ParagraphGeometricStyle.maxLines] constraint.
  /// {@endtemplate}
  ///
  /// Valid only after [layout] has been called.
  double get _naturalHeight => _measurementResult?.naturalHeight ?? 0;

  /// The amount of vertical space one line of this paragraph occupies.
  ///
  /// Valid only after [layout] has been called.
  double get _lineHeight => _measurementResult?.lineHeight ?? 0;

  @override
  double get longestLine {
    if (_hasLineMetrics) {
      double maxWidth = 0.0;
      for (ui.LineMetrics metrics in _measurementResult!.lines!) {
        if (maxWidth < metrics.width) {
          maxWidth = metrics.width;
        }
      }
      return maxWidth;
    }

    // If we don't have any line metrics information, there's no way to know the
    // longest line in a multi-line paragraph.
    return 0.0;
  }

  @override
  double get minIntrinsicWidth => _measurementResult?.minIntrinsicWidth ?? 0;

  @override
  double get maxIntrinsicWidth => _measurementResult?.maxIntrinsicWidth ?? 0;

  @override
  double get alphabeticBaseline => _measurementResult?.alphabeticBaseline ?? -1;

  @override
  double get ideographicBaseline =>
      _measurementResult?.ideographicBaseline ?? -1;

  @override
  bool get didExceedMaxLines => _didExceedMaxLines;
  bool _didExceedMaxLines = false;

  ui.ParagraphConstraints? _lastUsedConstraints;

  /// Returns horizontal alignment offset for single line text when rendering
  /// directly into a canvas without css text alignment styling.
  double _alignOffset = 0.0;

  @override
  void layout(ui.ParagraphConstraints constraints) {
    // When constraint width has a decimal place, we floor it to avoid getting
    // a layout width that's higher than the constraint width.
    //
    // For example, if constraint width is `30.8` and the text has a width of
    // `30.5` then the TextPainter in the framework will ceil the `30.5` width
    // which will result in a width of `40.0` that's higher than the constraint
    // width.
    constraints = ui.ParagraphConstraints(
      width: constraints.width.floorToDouble(),
    );

    if (constraints == _lastUsedConstraints) {
      return;
    }

    late Stopwatch stopwatch;
    if (Profiler.isBenchmarkMode) {
      stopwatch = Stopwatch()..start();
    }
    _measurementResult = _measurementService.measure(this, constraints);
    if (Profiler.isBenchmarkMode) {
      stopwatch.stop();
      Profiler.instance
          .benchmark('text_layout', stopwatch.elapsedMicroseconds.toDouble());
    }

    _lastUsedConstraints = constraints;

    if (_geometricStyle.maxLines != null) {
      _didExceedMaxLines = _naturalHeight > height;
    } else {
      _didExceedMaxLines = false;
    }

    if (_measurementResult!.isSingleLine) {
      switch (_textAlign) {
        case ui.TextAlign.center:
          _alignOffset = (constraints.width - maxIntrinsicWidth) / 2.0;
          break;
        case ui.TextAlign.right:
          _alignOffset = constraints.width - maxIntrinsicWidth;
          break;
        case ui.TextAlign.start:
          _alignOffset = _textDirection == ui.TextDirection.rtl
              ? constraints.width - maxIntrinsicWidth
              : 0.0;
          break;
        case ui.TextAlign.end:
          _alignOffset = _textDirection == ui.TextDirection.ltr
              ? constraints.width - maxIntrinsicWidth
              : 0.0;
          break;
        default:
          _alignOffset = 0.0;
          break;
      }
    }
  }

  bool get hasArbitraryPaint => _geometricStyle.ellipsis != null;

  @override
  void paint(BitmapCanvas canvas, ui.Offset offset) {
    assert(drawOnCanvas);
    assert(isLaidOut);

    // Paint the background first.
    final SurfacePaint? background = _background;
    if (background != null) {
      final ui.Rect rect =
          ui.Rect.fromLTWH(offset.dx, offset.dy, width, height);
      canvas.drawRect(rect, background.paintData);
    }

    final List<EngineLineMetrics> lines = _measurementResult!.lines!;
    canvas.setCssFont(_geometricStyle.cssFontString);

    // Then paint the text.
    canvas.setUpPaint(_paint!.paintData, null);
    double y = offset.dy + alphabeticBaseline;
    final int len = lines.length;
    for (int i = 0; i < len; i++) {
      _paintLine(canvas, lines[i], offset.dx, y);
      y += _lineHeight;
    }
    canvas.tearDownPaint();
  }

  void _paintLine(
    BitmapCanvas canvas,
    EngineLineMetrics line,
    double x,
    double y,
  ) {
    x += line.left;
    final double? letterSpacing = _geometricStyle.letterSpacing;
    if (letterSpacing == null || letterSpacing == 0.0) {
      canvas.fillText(line.displayText!, x, y);
    } else {
      // When letter-spacing is set, we go through a more expensive code path
      // that renders each character separately with the correct spacing
      // between them.
      //
      // We are drawing letter spacing like the web does it, by adding the
      // spacing after each letter. This is different from Flutter which puts
      // the spacing around each letter i.e. for a 10px letter spacing, Flutter
      // would put 5px before each letter and 5px after it, but on the web, we
      // put no spacing before the letter and 10px after it. This is how the DOM
      // does it.
      //
      // TODO(mdebbar): Implement letter-spacing on canvas more efficiently:
      //                https://github.com/flutter/flutter/issues/51234
      final int len = line.displayText!.length;
      for (int i = 0; i < len; i++) {
        final String char = line.displayText![i];
        canvas.fillText(char, x, y);
        x += letterSpacing + canvas.measureText(char).width!;
      }
    }
  }

  @override
  String toPlainText() {
    return _plainText ??
        js_util.getProperty(_paragraphElement, 'textContent') as String;
  }

  @override
  html.HtmlElement toDomElement() {
    assert(isLaidOut);

    final html.HtmlElement paragraphElement =
        _paragraphElement.clone(true) as html.HtmlElement;

    final html.CssStyleDeclaration paragraphStyle = paragraphElement.style;
    paragraphStyle
      ..height = '${height}px'
      ..width = '${width}px'
      ..position = 'absolute'
      ..whiteSpace = 'pre-wrap'
      ..overflowWrap = 'break-word'
      ..overflow = 'hidden';

    final ParagraphGeometricStyle style = _geometricStyle;

    // TODO(flutter_web): https://github.com/flutter/flutter/issues/33223
    if (style.ellipsis != null &&
        (style.maxLines == null || style.maxLines == 1)) {
      paragraphStyle
        ..whiteSpace = 'pre'
        ..textOverflow = 'ellipsis';
    }
    return paragraphElement;
  }

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    assert(isLaidOut);
    return _measurementResult!.placeholderBoxes;
  }

  /// Returns `true` if this paragraph can be directly painted to the canvas.
  ///
  ///
  /// Examples of paragraphs that can't be drawn directly on the canvas:
  ///
  /// - Rich text where there are multiple pieces of text that have different
  ///   styles.
  /// - Paragraphs that contain decorations.
  /// - Paragraphs that have a non-null word-spacing.
  /// - Paragraphs with a background.
  bool get drawOnCanvas {
    if (!_hasLineMetrics) {
      return false;
    }

    bool canDrawTextOnCanvas;
    if (_measurementService.isCanvas) {
      canDrawTextOnCanvas = true;
    } else {
      canDrawTextOnCanvas = _geometricStyle.ellipsis == null;
    }

    return canDrawTextOnCanvas &&
        _geometricStyle.decoration == null &&
        _geometricStyle.wordSpacing == null &&
        _geometricStyle.shadows == null;
  }

  /// Whether this paragraph has been laid out.
  bool get isLaidOut => _measurementResult != null;

  /// Asserts that the properties used to measure paragraph layout are the same
  /// as the properties of this paragraphs root style.
  ///
  /// Ignores properties that do not affect layout, such as
  /// [ParagraphStyle.textAlign].
  bool debugHasSameRootStyle(ParagraphGeometricStyle style) {
    assert(() {
      if (style != _geometricStyle) {
        throw Exception('Attempted to measure a paragraph whose style is '
            'different from the style of the ruler used to measure it.');
      }
      return true;
    }());
    return true;
  }

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    assert(boxHeightStyle != null); // ignore: unnecessary_null_comparison
    assert(boxWidthStyle != null); // ignore: unnecessary_null_comparison
    // Zero-length ranges and invalid ranges return an empty list.
    if (start == end || start < 0 || end < 0) {
      return <ui.TextBox>[];
    }

    // For rich text, we can't measure the boxes. So for now, we'll just return
    // a placeholder box to stop exceptions from being thrown in the framework.
    // https://github.com/flutter/flutter/issues/55587
    if (_plainText == null) {
      return <ui.TextBox>[
        ui.TextBox.fromLTRBD(0, 0, 0, _lineHeight, _textDirection),
      ];
    }

    final int length = _plainText!.length;
    // Ranges that are out of bounds should return an empty list.
    if (start > length || end > length) {
      return <ui.TextBox>[];
    }

    // Fallback to the old, DOM-based box measurements when there's no line
    // metrics.
    if (!_hasLineMetrics) {
      return _measurementService.measureBoxesForRange(
        this,
        _lastUsedConstraints!,
        start: start,
        end: end,
        alignOffset: _alignOffset,
        textDirection: _textDirection,
      );
    }

    final List<EngineLineMetrics> lines = _measurementResult!.lines!;
    if (start >= lines.last.endIndex) {
      return <ui.TextBox>[];
    }

    final EngineLineMetrics startLine = _getLineForIndex(start);
    EngineLineMetrics endLine = _getLineForIndex(end);

    // If the range end is exactly at the beginning of a line, we shouldn't
    // include any boxes from that line.
    if (end == endLine.startIndex) {
      endLine = lines[endLine.lineNumber - 1];
    }

    final List<ui.TextBox> boxes = <ui.TextBox>[];
    for (int i = startLine.lineNumber; i <= endLine.lineNumber; i++) {
      boxes.add(_getBoxForLine(lines[i], start, end));
    }
    return boxes;
  }

  ui.TextBox _getBoxForLine(EngineLineMetrics line, int start, int end) {
    final double widthBeforeBox = start <= line.startIndex
        ? 0.0
        : _measurementService.measureSubstringWidth(
            this, line.startIndex, start);
    final double widthAfterBox = end >= line.endIndexWithoutNewlines
        ? 0.0
        : _measurementService.measureSubstringWidth(
            this, end, line.endIndexWithoutNewlines);

    final double top = line.lineNumber * _lineHeight;

    //               |<------------------ line.width ------------------>|
    // |-------------|------------------|-------------|-----------------|
    // |<-line.left->|<-widthBeforeBox->|<-box width->|<-widthAfterBox->|
    // |-------------|------------------|-------------|-----------------|
    //
    //                                   ^^^^^^^^^^^^^
    //                          This is the box we want to return.
    return ui.TextBox.fromLTRBD(
      line.left + widthBeforeBox,
      top,
      line.left + line.widthWithTrailingSpaces - widthAfterBox,
      top + _lineHeight,
      _textDirection,
    );
  }

  ui.Paragraph cloneWithText(String plainText) {
    return DomParagraph(
      plainText: plainText,
      paragraphElement: _paragraphElement.clone(true) as html.HtmlElement,
      geometricStyle: _geometricStyle,
      paint: _paint,
      textAlign: _textAlign,
      textDirection: _textDirection,
      background: _background,
      placeholderCount: placeholderCount,
    );
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final List<EngineLineMetrics>? lines = _measurementResult!.lines;
    if (!_hasLineMetrics) {
      return getPositionForMultiSpanOffset(offset);
    }

    // [offset] is above all the lines.
    if (offset.dy < 0) {
      return ui.TextPosition(
        offset: 0,
        affinity: ui.TextAffinity.downstream,
      );
    }

    final int lineNumber = offset.dy ~/ _measurementResult!.lineHeight!;

    // [offset] is below all the lines.
    if (lineNumber >= lines!.length) {
      return ui.TextPosition(
        offset: _plainText!.length,
        affinity: ui.TextAffinity.upstream,
      );
    }

    final EngineLineMetrics lineMetrics = lines[lineNumber];
    final double lineLeft = lineMetrics.left;
    final double lineRight = lineLeft + lineMetrics.width;

    // [offset] is to the left of the line.
    if (offset.dx <= lineLeft) {
      return ui.TextPosition(
        offset: lineMetrics.startIndex,
        affinity: ui.TextAffinity.downstream,
      );
    }

    // [offset] is to the right of the line.
    if (offset.dx >= lineRight) {
      return ui.TextPosition(
        offset: lineMetrics.endIndexWithoutNewlines,
        affinity: ui.TextAffinity.upstream,
      );
    }

    // If we reach here, it means the [offset] is somewhere within the line. The
    // code below will do a binary search to find where exactly the [offset]
    // falls within the line.

    final double dx = offset.dx - lineMetrics.left;
    final TextMeasurementService instance = _measurementService;

    int low = lineMetrics.startIndex;
    int high = lineMetrics.endIndexWithoutNewlines;
    do {
      final int current = (low + high) ~/ 2;
      final double width =
          instance.measureSubstringWidth(this, lineMetrics.startIndex, current);
      if (width < dx) {
        low = current;
      } else if (width > dx) {
        high = current;
      } else {
        low = high = current;
      }
    } while (high - low > 1);

    if (low == high) {
      // The offset falls exactly in between the two letters.
      return ui.TextPosition(offset: high, affinity: ui.TextAffinity.upstream);
    }

    final double lowWidth =
        instance.measureSubstringWidth(this, lineMetrics.startIndex, low);
    final double highWidth =
        instance.measureSubstringWidth(this, lineMetrics.startIndex, high);

    if (dx - lowWidth < highWidth - dx) {
      // The offset is closer to the low index.
      return ui.TextPosition(offset: low, affinity: ui.TextAffinity.downstream);
    } else {
      // The offset is closer to high index.
      return ui.TextPosition(offset: high, affinity: ui.TextAffinity.upstream);
    }
  }

  ui.TextPosition getPositionForMultiSpanOffset(ui.Offset offset) {
    assert(_lastUsedConstraints != null,
        'missing call to paragraph layout before reading text position');
    final TextMeasurementService instance = _measurementService;
    return instance.getTextPositionForOffset(
        this, _lastUsedConstraints, offset);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    ui.TextPosition textPosition = position;
    final String? text = _plainText;
    if (text == null) {
      return ui.TextRange(start: textPosition.offset, end: textPosition.offset);
    }

    final int start = WordBreaker.prevBreakIndex(text, textPosition.offset + 1);
    final int end = WordBreaker.nextBreakIndex(text, textPosition.offset);
    return ui.TextRange(start: start, end: end);
  }

  EngineLineMetrics _getLineForIndex(int index) {
    assert(_hasLineMetrics);
    final List<EngineLineMetrics> lines = _measurementResult!.lines!;
    assert(index >= 0);

    for (int i = 0; i < lines.length; i++) {
      final EngineLineMetrics line = lines[i];
      if (index >= line.startIndex && index < line.endIndex) {
        return line;
      }
    }

    return lines.last;
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    if (_hasLineMetrics) {
      final EngineLineMetrics line = _getLineForIndex(position.offset);
      return ui.TextRange(start: line.startIndex, end: line.endIndex);
    }
    return ui.TextRange.empty;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    return _measurementResult!.lines!;
  }
}

/// The web implementation of [ui.ParagraphStyle].
class EngineParagraphStyle implements ui.ParagraphStyle {
  /// Creates a new instance of [EngineParagraphStyle].
  EngineParagraphStyle({
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.fontFamily,
    this.fontSize,
    this.height,
    ui.TextHeightBehavior? textHeightBehavior,
    this.fontWeight,
    this.fontStyle,
    ui.StrutStyle? strutStyle,
    this.ellipsis,
    this.locale,
  })  : _textHeightBehavior = textHeightBehavior,
        // TODO(b/128317744): add support for strut style.
        _strutStyle = strutStyle as EngineStrutStyle?;

  final ui.TextAlign? textAlign;
  final ui.TextDirection? textDirection;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final int? maxLines;
  final String? fontFamily;
  final double? fontSize;
  final double? height;
  final ui.TextHeightBehavior? _textHeightBehavior;
  final EngineStrutStyle? _strutStyle;
  final String? ellipsis;
  final ui.Locale? locale;

  // The effective style attributes should be consistent with paragraph_style.h.
  ui.TextAlign get effectiveTextAlign => textAlign ?? ui.TextAlign.start;
  ui.TextDirection get effectiveTextDirection => textDirection ?? ui.TextDirection.ltr;

  String get _effectiveFontFamily {
    if (assertionsEnabled) {
      // In the flutter tester environment, we use a predictable-size font
      // "Ahem". This makes widget tests predictable and less flaky.
      if (ui.debugEmulateFlutterTesterEnvironment) {
        return 'Ahem';
      }
    }
    final String? fontFamily = this.fontFamily;
    if (fontFamily == null || fontFamily.isEmpty) {
      return DomRenderer.defaultFontFamily;
    }
    return fontFamily;
  }

  double? get lineHeight {
    // TODO(mdebbar): Implement proper support for strut styles.
    // https://github.com/flutter/flutter/issues/32243
    if (_strutStyle == null ||
        _strutStyle!._height == null ||
        _strutStyle!._height == 0) {
      // When there's no strut height, always use paragraph style height.
      return height;
    }
    if (_strutStyle!._forceStrutHeight == true) {
      // When strut height is forced, ignore paragraph style height.
      return _strutStyle!._height;
    }
    // In this case, strut height acts as a minimum height for all parts of the
    // paragraph. So we take the max of strut height and paragraph style height.
    return math.max(_strutStyle!._height!, height ?? 0.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineParagraphStyle &&
        other.textAlign == textAlign &&
        other.textDirection == textDirection &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.maxLines == maxLines &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.height == height &&
        other._textHeightBehavior == _textHeightBehavior &&
        other.ellipsis == ellipsis &&
        other.locale == locale;
  }

  @override
  int get hashCode {
    return ui.hashValues(
        textAlign,
        textDirection,
        fontWeight,
        fontStyle,
        maxLines,
        fontFamily,
        fontSize,
        height,
        _textHeightBehavior,
        ellipsis,
        locale);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'ParagraphStyle('
          'textAlign: ${textAlign ?? "unspecified"}, '
          'textDirection: ${textDirection ?? "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'maxLines: ${maxLines ?? "unspecified"}, '
          'textHeightBehavior: ${_textHeightBehavior ?? "unspecified"}, '
          'fontFamily: ${fontFamily ?? "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize!.toStringAsFixed(1) : "unspecified"}, '
          'height: ${height != null ? "${height!.toStringAsFixed(1)}x" : "unspecified"}, '
          'ellipsis: ${ellipsis != null ? "\"$ellipsis\"" : "unspecified"}, '
          'locale: ${locale ?? "unspecified"}'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.TextStyle].
class EngineTextStyle implements ui.TextStyle {
  /// Constructs an [EngineTextStyle] with all properties being required.
  ///
  /// This is good for call sites that need to be updated whenever a new
  /// property is added to [EngineTextStyle]. Non-updated call sites will fail
  /// the build otherwise.
  factory EngineTextStyle({
    required ui.Color? color,
    required ui.TextDecoration? decoration,
    required ui.Color? decorationColor,
    required ui.TextDecorationStyle? decorationStyle,
    required double? decorationThickness,
    required ui.FontWeight? fontWeight,
    required ui.FontStyle? fontStyle,
    required ui.TextBaseline? textBaseline,
    required String? fontFamily,
    required List<String>? fontFamilyFallback,
    required double? fontSize,
    required double? letterSpacing,
    required double? wordSpacing,
    required double? height,
    required ui.Locale? locale,
    required ui.Paint? background,
    required ui.Paint? foreground,
    required List<ui.Shadow>? shadows,
    required List<ui.FontFeature>? fontFeatures,
  }) = EngineTextStyle.only;

  /// Constructs an [EngineTextStyle] with only the given properties.
  ///
  /// This constructor should be used sparingly in tests, for example. Or when
  /// we know for sure that not all properties are needed.
  EngineTextStyle.only({
    this.color,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.fontWeight,
    this.fontStyle,
    this.textBaseline,
    String? fontFamily,
    this.fontFamilyFallback,
    this.fontSize,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.locale,
    this.background,
    this.foreground,
    this.shadows,
    this.fontFeatures,
  })  : assert(
            color == null || foreground == null,
            'Cannot provide both a color and a foreground\n'
            'The color argument is just a shorthand for "foreground: new Paint()..color = color".'),
        isFontFamilyProvided = fontFamily != null,
        fontFamily = fontFamily ?? '';

  /// Constructs an [EngineTextStyle] by reading properties from an
  /// [EngineParagraphStyle].
  factory EngineTextStyle.fromParagraphStyle(
    EngineParagraphStyle paragraphStyle,
  ) {
    return EngineTextStyle.only(
      fontWeight: paragraphStyle.fontWeight,
      fontStyle: paragraphStyle.fontStyle,
      fontFamily: paragraphStyle.fontFamily,
      fontSize: paragraphStyle.fontSize,
      height: paragraphStyle.height,
      locale: paragraphStyle.locale,
    );
  }

  final ui.Color? color;
  final ui.TextDecoration? decoration;
  final ui.Color? decorationColor;
  final ui.TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final ui.FontWeight? fontWeight;
  final ui.FontStyle? fontStyle;
  final ui.TextBaseline? textBaseline;
  final bool isFontFamilyProvided;
  final String fontFamily;
  final List<String>? fontFamilyFallback;
  final List<ui.FontFeature>? fontFeatures;
  final double? fontSize;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final ui.Locale? locale;
  final ui.Paint? background;
  final ui.Paint? foreground;
  final List<ui.Shadow>? shadows;

  String get effectiveFontFamily {
    if (assertionsEnabled) {
      // In the flutter tester environment, we use a predictable-size font
      // "Ahem". This makes widget tests predictable and less flaky.
      if (ui.debugEmulateFlutterTesterEnvironment) {
        return 'Ahem';
      }
    }
    if (fontFamily.isEmpty) {
      return DomRenderer.defaultFontFamily;
    }
    return fontFamily;
  }

  String? _cssFontString;

  /// Font string to be used in CSS.
  ///
  /// See <https://developer.mozilla.org/en-US/docs/Web/CSS/font>.
  String get cssFontString {
    return _cssFontString ??= buildCssFontString(
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      fontSize: fontSize,
      fontFamily: effectiveFontFamily,
    );
  }

  late final TextHeightStyle heightStyle = _createHeightStyle();

  TextHeightStyle _createHeightStyle() {
    return TextHeightStyle(
      fontFamily: effectiveFontFamily,
      fontSize: fontSize ?? DomRenderer.defaultFontSize,
      height: height,
      // TODO(mdebbar): Pass the actual value when font features become supported
      //                https://github.com/flutter/flutter/issues/64595
      fontFeatures: null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineTextStyle &&
        other.color == color &&
        other.decoration == decoration &&
        other.decorationColor == decorationColor &&
        other.decorationStyle == decorationStyle &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.textBaseline == textBaseline &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.letterSpacing == letterSpacing &&
        other.wordSpacing == wordSpacing &&
        other.height == height &&
        other.locale == locale &&
        other.background == background &&
        other.foreground == foreground &&
        listEquals<ui.Shadow>(other.shadows, shadows) &&
        listEquals<String>(other.fontFamilyFallback, fontFamilyFallback);
  }

  @override
  int get hashCode => ui.hashValues(
        color,
        decoration,
        decorationColor,
        decorationStyle,
        decorationThickness,
        fontWeight,
        fontStyle,
        textBaseline,
        fontFamily,
        fontFamilyFallback,
        fontSize,
        letterSpacing,
        wordSpacing,
        height,
        locale,
        background,
        foreground,
        shadows,
      );

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'TextStyle('
          'color: ${color ?? "unspecified"}, '
          'decoration: ${decoration ?? "unspecified"}, '
          'decorationColor: ${decorationColor ?? "unspecified"}, '
          'decorationStyle: ${decorationStyle ?? "unspecified"}, '
          'decorationThickness: ${decorationThickness ?? "unspecified"}, '
          'fontWeight: ${fontWeight ?? "unspecified"}, '
          'fontStyle: ${fontStyle ?? "unspecified"}, '
          'textBaseline: ${textBaseline ?? "unspecified"}, '
          'fontFamily: ${isFontFamilyProvided && fontFamily != '' ? fontFamily : "unspecified"}, '
          'fontFamilyFallback: ${isFontFamilyProvided && fontFamilyFallback != null && fontFamilyFallback!.isNotEmpty ? fontFamilyFallback : "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize!.toStringAsFixed(1) : "unspecified"}, '
          'letterSpacing: ${letterSpacing != null ? "${letterSpacing}x" : "unspecified"}, '
          'wordSpacing: ${wordSpacing != null ? "${wordSpacing}x" : "unspecified"}, '
          'height: ${height != null ? "${height!.toStringAsFixed(1)}x" : "unspecified"}, '
          'locale: ${locale ?? "unspecified"}, '
          'background: ${background ?? "unspecified"}, '
          'foreground: ${foreground ?? "unspecified"}, '
          'shadows: ${shadows ?? "unspecified"}, '
          'fontFeatures: ${fontFeatures ?? "unspecified"}'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.StrutStyle].
class EngineStrutStyle implements ui.StrutStyle {
  EngineStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  })  : _fontFamily = fontFamily,
        _fontFamilyFallback = fontFamilyFallback,
        _fontSize = fontSize,
        _height = height,
        _leadingDistribution = leadingDistribution,
        _leading = leading,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle,
        _forceStrutHeight = forceStrutHeight;

  final String? _fontFamily;
  final List<String>? _fontFamilyFallback;
  final double? _fontSize;
  final double? _height;
  final double? _leading;
  final ui.FontWeight? _fontWeight;
  final ui.FontStyle? _fontStyle;
  final bool? _forceStrutHeight;
  final ui.TextLeadingDistribution? _leadingDistribution;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineStrutStyle &&
        other._fontFamily == _fontFamily &&
        other._fontSize == _fontSize &&
        other._height == _height &&
        other._leading == _leading &&
        other._leadingDistribution == _leadingDistribution &&
        other._fontWeight == _fontWeight &&
        other._fontStyle == _fontStyle &&
        other._forceStrutHeight == _forceStrutHeight &&
        listEquals<String>(other._fontFamilyFallback, _fontFamilyFallback);
  }

  @override
  int get hashCode => ui.hashValues(
        _fontFamily,
        _fontFamilyFallback,
        _fontSize,
        _height,
        _leading,
        _leadingDistribution,
        _fontWeight,
        _fontStyle,
        _forceStrutHeight,
      );
}

/// The web implementation of [ui.ParagraphBuilder].
class DomParagraphBuilder implements ui.ParagraphBuilder {
  /// Marks a call to the [pop] method in the [_ops] list.
  static final Object _paragraphBuilderPop = Object();

  final html.HtmlElement _paragraphElement =
      domRenderer.createElement('p') as html.HtmlElement;
  final EngineParagraphStyle _paragraphStyle;
  final List<dynamic> _ops = <dynamic>[];

  /// Creates a [DomParagraphBuilder] object, which is used to create a
  /// [DomParagraph].
  DomParagraphBuilder(EngineParagraphStyle style) : _paragraphStyle = style {
    // TODO(b/128317744): Implement support for strut font families.
    List<String?> strutFontFamilies;
    if (style._strutStyle != null) {
      strutFontFamilies = <String?>[];
      if (style._strutStyle!._fontFamily != null) {
        strutFontFamilies.add(style._strutStyle!._fontFamily);
      }
      if (style._strutStyle!._fontFamilyFallback != null) {
        strutFontFamilies.addAll(style._strutStyle!._fontFamilyFallback!);
      }
    }
    _applyParagraphStyleToElement(
        element: _paragraphElement, style: _paragraphStyle);
  }

  /// Applies the given style to the added text until [pop] is called.
  ///
  /// See [pop] for details.
  @override
  void pushStyle(ui.TextStyle style) {
    _ops.add(style);
  }

  @override
  int get placeholderCount => _placeholderCount;
  int _placeholderCount = 0;

  @override
  List<double> get placeholderScales => _placeholderScales;
  final List<double> _placeholderScales = <double>[];

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {
    // Require a baseline to be specified if using a baseline-based alignment.
    assert((alignment == ui.PlaceholderAlignment.aboveBaseline ||
            alignment == ui.PlaceholderAlignment.belowBaseline ||
            alignment == ui.PlaceholderAlignment.baseline)
        ? baseline != null
        : true);

    _placeholderCount++;
    _placeholderScales.add(scale);
    _ops.add(ParagraphPlaceholder(
      width * scale,
      height * scale,
      alignment,
      baselineOffset: (baselineOffset ?? height) * scale,
      baseline: baseline ?? ui.TextBaseline.alphabetic,
    ));
  }

  // TODO(yjbanov): do we need to do this?
//  static String _encodeLocale(Locale locale) => locale?.toString() ?? '';

  /// Ends the effect of the most recent call to [pushStyle].
  ///
  /// Internally, the paragraph builder maintains a stack of text styles. Text
  /// added to the paragraph is affected by all the styles in the stack. Calling
  /// [pop] removes the topmost style in the stack, leaving the remaining styles
  /// in effect.
  @override
  void pop() {
    _ops.add(_paragraphBuilderPop);
  }

  /// Adds the given text to the paragraph.
  ///
  /// The text will be styled according to the current stack of text styles.
  @override
  void addText(String text) {
    _ops.add(text);
  }

  /// Applies the given paragraph style and returns a [Paragraph] containing the
  /// added text and associated styling.
  ///
  /// After calling this function, the paragraph builder object is invalid and
  /// cannot be used further.
  @override
  EngineParagraph build() {
    return _tryBuildPlainText() ?? _buildRichText();
  }

  /// Attempts to build a [Paragraph] assuming it is plain text.
  ///
  /// A paragraph is considered plain if it is built using the following
  /// sequence of ops:
  ///
  /// * Zero-or-more calls to [pushStyle].
  /// * One-or-more calls to [addText].
  /// * Zero-or-more calls to [pop].
  ///
  /// Any other sequence will result in `null` and should be treated as rich
  /// text.
  ///
  /// Plain text is not the same as not having style. The text may be styled
  /// arbitrarily. However, it may not mix multiple styles in the same
  /// paragraph. Plain text is more efficient to lay out and measure than rich
  /// text.
  EngineParagraph? _tryBuildPlainText() {
    ui.Color? color;
    ui.TextDecoration? decoration;
    ui.Color? decorationColor;
    ui.TextDecorationStyle? decorationStyle;
    double? decorationThickness;
    ui.FontWeight? fontWeight = _paragraphStyle.fontWeight;
    ui.FontStyle? fontStyle = _paragraphStyle.fontStyle;
    ui.TextBaseline? textBaseline;
    String fontFamily =
        _paragraphStyle.fontFamily ?? DomRenderer.defaultFontFamily;
    List<String>? fontFamilyFallback;
    List<ui.FontFeature>? fontFeatures;
    double fontSize = _paragraphStyle.fontSize ?? DomRenderer.defaultFontSize;
    final ui.TextAlign textAlign = _paragraphStyle.effectiveTextAlign;
    final ui.TextDirection textDirection = _paragraphStyle.effectiveTextDirection;
    double? letterSpacing;
    double? wordSpacing;
    double? height;
    ui.Locale? locale = _paragraphStyle.locale;
    ui.Paint? background;
    ui.Paint? foreground;
    List<ui.Shadow>? shadows;

    int i = 0;

    // This loop looks expensive. However, in reality most of plain text
    // paragraphs will have no calls to [pushStyle], skipping this loop
    // entirely. Occasionally there will be one [pushStyle], which causes this
    // loop to run once then move on to aggregating text.
    while (i < _ops.length && _ops[i] is EngineTextStyle) {
      final EngineTextStyle style = _ops[i];
      if (style.color != null) {
        color = style.color!;
      }
      if (style.decoration != null) {
        decoration = style.decoration;
      }
      if (style.decorationColor != null) {
        decorationColor = style.decorationColor;
      }
      if (style.decorationStyle != null) {
        decorationStyle = style.decorationStyle;
      }
      if (style.decorationThickness != null) {
        decorationThickness = style.decorationThickness;
      }
      if (style.fontWeight != null) {
        fontWeight = style.fontWeight;
      }
      if (style.fontStyle != null) {
        fontStyle = style.fontStyle;
      }
      if (style.textBaseline != null) {
        textBaseline = style.textBaseline;
      }
      fontFamily = style.fontFamily;
      if (style.fontFamilyFallback != null) {
        fontFamilyFallback = style.fontFamilyFallback;
      }
      if (style.fontFeatures != null) {
        fontFeatures = style.fontFeatures;
      }
      if (style.fontSize != null) {
        fontSize = style.fontSize!;
      }
      if (style.letterSpacing != null) {
        letterSpacing = style.letterSpacing;
      }
      if (style.wordSpacing != null) {
        wordSpacing = style.wordSpacing;
      }
      if (style.height != null) {
        height = style.height;
      }
      if (style.locale != null) {
        locale = style.locale;
      }
      if (style.background != null) {
        background = style.background;
      }
      if (style.foreground != null) {
        foreground = style.foreground;
      }
      if (style.shadows != null) {
        shadows = style.shadows;
      }
      i++;
    }

    if (color == null && foreground == null) {
      color = defaultTextColor;
    }

    final EngineTextStyle cumulativeStyle = EngineTextStyle(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontFeatures: fontFeatures,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      locale: locale,
      background: background,
      foreground: foreground,
      shadows: shadows,
    );

    ui.Paint paint;
    if (foreground != null) {
      paint = foreground;
    } else {
      paint = ui.Paint();
      paint.color = color!;
    }

    if (i >= _ops.length) {
      // Empty paragraph.
      applyTextStyleToElement(
          element: _paragraphElement, style: cumulativeStyle);
      return DomParagraph(
        paragraphElement: _paragraphElement,
        geometricStyle: ParagraphGeometricStyle(
          textDirection: _paragraphStyle.effectiveTextDirection,
          textAlign: _paragraphStyle.effectiveTextAlign,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          fontSize: fontSize,
          lineHeight: height,
          maxLines: _paragraphStyle.maxLines,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          decoration: _textDecorationToCssString(decoration, decorationStyle),
          ellipsis: _paragraphStyle.ellipsis,
          shadows: shadows,
        ),
        plainText: '',
        paint: paint,
        textAlign: textAlign,
        textDirection: textDirection,
        background: cumulativeStyle.background,
        placeholderCount: placeholderCount,
      );
    }

    if (_ops[i] is! String) {
      // After a series of [EngineTextStyle] ops there must be at least one text op.
      // Otherwise, treat it as rich text.
      return null;
    }

    // Accumulate text into one contiguous string.
    final StringBuffer plainTextBuffer = StringBuffer();
    while (i < _ops.length && _ops[i] is String) {
      plainTextBuffer.write(_ops[i]);
      i++;
    }

    // After a series of [addText] ops there should only be a tail of [pop]s and
    // nothing else. Otherwise it's rich text and we return null;
    for (; i < _ops.length; i++) {
      if (_ops[i] != _paragraphBuilderPop) {
        return null;
      }
    }

    final String plainText = plainTextBuffer.toString();
    domRenderer.appendText(_paragraphElement, plainText);
    applyTextStyleToElement(
        element: _paragraphElement, style: cumulativeStyle);
    // Since this is a plain paragraph apply background color to paragraph tag
    // instead of individual spans.
    if (cumulativeStyle.background != null) {
      _applyTextBackgroundToElement(
          element: _paragraphElement, style: cumulativeStyle);
    }
    return DomParagraph(
      paragraphElement: _paragraphElement,
      geometricStyle: ParagraphGeometricStyle(
        textDirection: _paragraphStyle.effectiveTextDirection,
        textAlign: _paragraphStyle.effectiveTextAlign,
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        fontSize: fontSize,
        lineHeight: height,
        maxLines: _paragraphStyle.maxLines,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        decoration: _textDecorationToCssString(decoration, decorationStyle),
        ellipsis: _paragraphStyle.ellipsis,
        shadows: shadows,
      ),
      plainText: plainText,
      paint: paint,
      textAlign: textAlign,
      textDirection: textDirection,
      background: cumulativeStyle.background,
      placeholderCount: placeholderCount,
    );
  }

  /// Builds a [Paragraph] as rich text.
  EngineParagraph _buildRichText() {
    final List<dynamic> elementStack = <dynamic>[];
    dynamic currentElement() =>
        elementStack.isNotEmpty ? elementStack.last : _paragraphElement;

    for (int i = 0; i < _ops.length; i++) {
      final dynamic op = _ops[i];
      if (op is EngineTextStyle) {
        final html.SpanElement span = domRenderer.createElement('span') as html.SpanElement;
        applyTextStyleToElement(element: span, style: op, isSpan: true);
        if (op.background != null) {
          _applyTextBackgroundToElement(element: span, style: op);
        }
        domRenderer.append(currentElement(), span);
        elementStack.add(span);
      } else if (op is String) {
        domRenderer.appendText(currentElement(), op);
      } else if (op is ParagraphPlaceholder) {
        domRenderer.append(
          currentElement(),
          createPlaceholderElement(placeholder: op),
        );
      } else if (identical(op, _paragraphBuilderPop)) {
        elementStack.removeLast();
      } else {
        throw UnsupportedError('Unsupported ParagraphBuilder operation: $op');
      }
    }

    return DomParagraph(
      paragraphElement: _paragraphElement,
      geometricStyle: ParagraphGeometricStyle(
        textDirection: _paragraphStyle.effectiveTextDirection,
        textAlign: _paragraphStyle.effectiveTextAlign,
        fontFamily: _paragraphStyle.fontFamily,
        fontWeight: _paragraphStyle.fontWeight,
        fontStyle: _paragraphStyle.fontStyle,
        fontSize: _paragraphStyle.fontSize,
        lineHeight: _paragraphStyle.height,
        maxLines: _paragraphStyle.maxLines,
        ellipsis: _paragraphStyle.ellipsis,
      ),
      plainText: null,
      paint: null,
      textAlign: _paragraphStyle.effectiveTextAlign,
      textDirection: _paragraphStyle.effectiveTextDirection,
      background: null,
      placeholderCount: placeholderCount,
    );
  }
}

/// Holds information for a placeholder in a paragraph.
///
/// [width], [height] and [baselineOffset] are expected to be already scaled.
class ParagraphPlaceholder {
  ParagraphPlaceholder(
    this.width,
    this.height,
    this.alignment, {
    required this.baselineOffset,
    required this.baseline,
  });

  /// The scaled width of the placeholder.
  final double width;

  /// The scaled height of the placeholder.
  final double height;

  /// Specifies how the placeholder rectangle will be vertically aligned with
  /// the surrounding text.
  final ui.PlaceholderAlignment alignment;

  /// When the [alignment] value is [ui.PlaceholderAlignment.baseline], the
  /// [baselineOffset] indicates the distance from the baseline to the top of
  /// the placeholder rectangle.
  final double baselineOffset;

  /// Dictates whether to use alphabetic or ideographic baseline.
  final ui.TextBaseline baseline;
}

/// Converts [fontWeight] to its CSS equivalent value.
String? fontWeightToCss(ui.FontWeight? fontWeight) {
  if (fontWeight == null) {
    return null;
  }
  return fontWeightIndexToCss(fontWeightIndex: fontWeight.index);
}

String fontWeightIndexToCss({int fontWeightIndex = 3}) {
  switch (fontWeightIndex) {
    case 0:
      return '100';
    case 1:
      return '200';
    case 2:
      return '300';
    case 3:
      return 'normal';
    case 4:
      return '500';
    case 5:
      return '600';
    case 6:
      return 'bold';
    case 7:
      return '800';
    case 8:
      return '900';
  }

  assert(() {
    throw AssertionError(
      'Failed to convert font weight $fontWeightIndex to CSS.',
    );
  }());

  return '';
}

/// Applies a paragraph [style] to an [element], translating the properties to
/// their corresponding CSS equivalents.
void _applyParagraphStyleToElement({
  required html.HtmlElement element,
  required EngineParagraphStyle style,
}) {
  assert(element != null); // ignore: unnecessary_null_comparison
  assert(style != null); // ignore: unnecessary_null_comparison
  // TODO(yjbanov): What do we do about ParagraphStyle._locale and ellipsis?
  final html.CssStyleDeclaration cssStyle = element.style;

  if (style.textAlign != null) {
    cssStyle.textAlign = textAlignToCssValue(
        style.textAlign, style.textDirection ?? ui.TextDirection.ltr);
  }
  if (style.lineHeight != null) {
    cssStyle.lineHeight = '${style.lineHeight}';
  }
  if (style.textDirection != null) {
    cssStyle.direction = textDirectionToCss(style.textDirection);
  }
  if (style.fontSize != null) {
    cssStyle.fontSize = '${style.fontSize!.floor()}px';
  }
  if (style.fontWeight != null) {
    cssStyle.fontWeight = fontWeightToCss(style.fontWeight);
  }
  if (style.fontStyle != null) {
    cssStyle.fontStyle =
        style.fontStyle == ui.FontStyle.normal ? 'normal' : 'italic';
  }
  cssStyle.fontFamily = canonicalizeFontFamily(style._effectiveFontFamily);
}

/// Applies a text [style] to an [element], translating the properties to their
/// corresponding CSS equivalents.
///
/// If [isSpan] is true, the text element is a span within richtext and
/// should not assign effectiveFontFamily if fontFamily was not specified.
void applyTextStyleToElement({
  required html.HtmlElement element,
  required EngineTextStyle style,
  bool isSpan = false,
}) {
  assert(element != null); // ignore: unnecessary_null_comparison
  assert(style != null); // ignore: unnecessary_null_comparison
  bool updateDecoration = false;
  final html.CssStyleDeclaration cssStyle = element.style;

  final ui.Color? color = style.foreground?.color ?? style.color;
  if (color != null) {
    cssStyle.color = colorToCssString(color);
  }
  final ui.Color? background = style.background?.color;
  if (background != null) {
    cssStyle.backgroundColor = colorToCssString(background);
  }
  if (style.height != null) {
    cssStyle.lineHeight = '${style.height}';
  }
  if (style.fontSize != null) {
    cssStyle.fontSize = '${style.fontSize!.floor()}px';
  }
  if (style.fontWeight != null) {
    cssStyle.fontWeight = fontWeightToCss(style.fontWeight);
  }
  if (style.fontStyle != null) {
    cssStyle.fontStyle =
        style.fontStyle == ui.FontStyle.normal ? 'normal' : 'italic';
  }
  // For test environment use effectiveFontFamily since we need to
  // consistently use Ahem font.
  if (isSpan && !ui.debugEmulateFlutterTesterEnvironment) {
    cssStyle.fontFamily = canonicalizeFontFamily(style.fontFamily);
  } else {
    cssStyle.fontFamily = canonicalizeFontFamily(style.effectiveFontFamily);
  }
  if (style.letterSpacing != null) {
    cssStyle.letterSpacing = '${style.letterSpacing}px';
  }
  if (style.wordSpacing != null) {
    cssStyle.wordSpacing = '${style.wordSpacing}px';
  }
  if (style.decoration != null) {
    updateDecoration = true;
  }
  if (style.shadows != null) {
    cssStyle.textShadow = _shadowListToCss(style.shadows!);
  }

  if (updateDecoration) {
    if (style.decoration != null) {
      final String? textDecoration =
          _textDecorationToCssString(style.decoration, style.decorationStyle);
      if (textDecoration != null) {
        if (browserEngine == BrowserEngine.webkit) {
          DomRenderer.setElementStyle(
              element, '-webkit-text-decoration', textDecoration);
        } else {
          cssStyle.textDecoration = textDecoration;
        }
        final ui.Color? decorationColor = style.decorationColor;
        if (decorationColor != null) {
          cssStyle.textDecorationColor = colorToCssString(decorationColor)!;
        }
      }
    }
  }

  final List<ui.FontFeature>? fontFeatures = style.fontFeatures;
  if (fontFeatures != null && fontFeatures.isNotEmpty) {
    cssStyle.fontFeatureSettings = _fontFeatureListToCss(fontFeatures);
  }
}

html.Element createPlaceholderElement({
  required ParagraphPlaceholder placeholder,
}) {
  final html.Element element = domRenderer.createElement('span');
  element.className = placeholderClass;
  final html.CssStyleDeclaration style = element.style;
  style
    ..display = 'inline-block'
    ..width = '${placeholder.width}px'
    ..height = '${placeholder.height}px'
    ..verticalAlign = _placeholderAlignmentToCssVerticalAlign(placeholder);

  return element;
}

String _placeholderAlignmentToCssVerticalAlign(
  ParagraphPlaceholder placeholder,
) {
  // For more details about the vertical-align CSS property, see:
  // - https://developer.mozilla.org/en-US/docs/Web/CSS/vertical-align
  switch (placeholder.alignment) {
    case ui.PlaceholderAlignment.top:
      return 'top';

    case ui.PlaceholderAlignment.middle:
      return 'middle';

    case ui.PlaceholderAlignment.bottom:
      return 'bottom';

    case ui.PlaceholderAlignment.aboveBaseline:
      return 'baseline';

    case ui.PlaceholderAlignment.belowBaseline:
      return '-${placeholder.height}px';

    case ui.PlaceholderAlignment.baseline:
      // In CSS, the placeholder is already placed above the baseline. But
      // Flutter's `baselineOffset` assumes the placeholder is placed below the
      // baseline. That's why we need to subtract the placeholder's height from
      // `baselineOffset`.
      final double offset = placeholder.baselineOffset - placeholder.height;
      return '${offset}px';
  }
}

String _shadowListToCss(List<ui.Shadow> shadows) {
  if (shadows.isEmpty) {
    return '';
  }
  // CSS text-shadow is a comma separated list of shadows.
  // <offsetx> <offsety> <blur-radius> <color>.
  // Shadows are applied front-to-back with first shadow on top.
  // Color is optional. offsetx,y are required. blur-radius is optional as well
  // and defaults to 0.
  StringBuffer sb = new StringBuffer();
  for (int i = 0, len = shadows.length; i < len; i++) {
    if (i != 0) {
      sb.write(',');
    }
    ui.Shadow shadow = shadows[i];
    sb.write('${shadow.offset.dx}px ${shadow.offset.dy}px '
        '${shadow.blurRadius}px ${colorToCssString(shadow.color)}');
  }
  return sb.toString();
}

String _fontFeatureListToCss(List<ui.FontFeature> fontFeatures) {
  assert(fontFeatures.isNotEmpty);

  // For more details, see:
  // * https://developer.mozilla.org/en-US/docs/Web/CSS/font-feature-settings
  StringBuffer sb = new StringBuffer();
  for (int i = 0, len = fontFeatures.length; i < len; i++) {
    if (i != 0) {
      sb.write(',');
    }
    ui.FontFeature fontFeature = fontFeatures[i];
    sb.write('"${fontFeature.feature}" ${fontFeature.value}');
  }
  return sb.toString();
}

/// Applies background color properties in text style to paragraph or span
/// elements.
void _applyTextBackgroundToElement({
  required html.HtmlElement element,
  required EngineTextStyle style,
}) {
  final ui.Paint? newBackground = style.background;
  if (newBackground != null) {
    DomRenderer.setElementStyle(
        element, 'background-color', colorToCssString(newBackground.color));
  }
}

/// Converts text decoration style to CSS text-decoration-style value.
String? _textDecorationToCssString(
    ui.TextDecoration? decoration, ui.TextDecorationStyle? decorationStyle) {
  final StringBuffer decorations = StringBuffer();
  if (decoration != null) {
    if (decoration.contains(ui.TextDecoration.underline)) {
      decorations.write('underline ');
    }
    if (decoration.contains(ui.TextDecoration.overline)) {
      decorations.write('overline ');
    }
    if (decoration.contains(ui.TextDecoration.lineThrough)) {
      decorations.write('line-through ');
    }
  }
  if (decorationStyle != null) {
    decorations.write(_decorationStyleToCssString(decorationStyle));
  }
  return decorations.isEmpty ? null : decorations.toString();
}

String? _decorationStyleToCssString(ui.TextDecorationStyle decorationStyle) {
  switch (decorationStyle) {
    case ui.TextDecorationStyle.dashed:
      return 'dashed';
    case ui.TextDecorationStyle.dotted:
      return 'dotted';
    case ui.TextDecorationStyle.double:
      return 'double';
    case ui.TextDecorationStyle.solid:
      return 'solid';
    case ui.TextDecorationStyle.wavy:
      return 'wavy';
    default:
      return null;
  }
}

/// Converts [textDirection] to its corresponding CSS value.
///
/// This value is used for the "direction" CSS property, e.g.:
///
/// ```css
/// direction: rtl;
/// ```
String? textDirectionToCss(ui.TextDirection? textDirection) {
  if (textDirection == null) {
    return null;
  }
  return textDirectionIndexToCss(textDirection.index);
}

String? textDirectionIndexToCss(int textDirectionIndex) {
  switch (textDirectionIndex) {
    case 0:
      return 'rtl';
    case 1:
      return null; // ltr is the default
  }

  assert(() {
    throw AssertionError(
      'Failed to convert text direction $textDirectionIndex to CSS',
    );
  }());

  return null;
}

/// Converts [align] to its corresponding CSS value.
///
/// This value is used as the "text-align" CSS property, e.g.:
///
/// ```css
/// text-align: right;
/// ```
String textAlignToCssValue(
    ui.TextAlign? align, ui.TextDirection textDirection) {
  switch (align) {
    case ui.TextAlign.left:
      return 'left';
    case ui.TextAlign.right:
      return 'right';
    case ui.TextAlign.center:
      return 'center';
    case ui.TextAlign.justify:
      return 'justify';
    case ui.TextAlign.end:
      switch (textDirection) {
        case ui.TextDirection.ltr:
          return 'end';
        case ui.TextDirection.rtl:
          return 'left';
      }
    case ui.TextAlign.start:
      switch (textDirection) {
        case ui.TextDirection.ltr:
          return ''; // it's the default
        case ui.TextDirection.rtl:
          return 'right';
      }
    case null:
      // If align is not specified return default.
      return '';
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

class EngineLineMetrics implements ui.LineMetrics {
  EngineLineMetrics({
    this.hardBreak,
    this.ascent,
    this.descent,
    this.unscaledAscent,
    this.height,
    this.width,
    this.left,
    this.baseline,
    this.lineNumber,
  })  : displayText = null,
        startIndex = -1,
        endIndex = -1,
        endIndexWithoutNewlines = -1;

  EngineLineMetrics.withText(
    this.displayText, {
    @required this.startIndex,
    @required this.endIndex,
    @required this.endIndexWithoutNewlines,
    @required this.hardBreak,
    this.ascent,
    this.descent,
    this.unscaledAscent,
    this.height,
    @required this.width,
    @required this.left,
    this.baseline,
    @required this.lineNumber,
  })  : assert(displayText != null),
        assert(startIndex != null),
        assert(endIndex != null),
        assert(endIndexWithoutNewlines != null),
        assert(hardBreak != null),
        assert(width != null),
        assert(left != null),
        assert(lineNumber != null && lineNumber >= 0);

  /// The text to be rendered on the screen representing this line.
  final String displayText;

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

  @override
  final double left;

  @override
  final double baseline;

  @override
  final int lineNumber;

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
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }

    if (other.runtimeType != runtimeType) {
      return false;
    }
    final EngineLineMetrics typedOther = other;
    return displayText == typedOther.displayText &&
        startIndex == typedOther.startIndex &&
        endIndex == typedOther.endIndex &&
        hardBreak == typedOther.hardBreak &&
        ascent == typedOther.ascent &&
        descent == typedOther.descent &&
        unscaledAscent == typedOther.unscaledAscent &&
        height == typedOther.height &&
        width == typedOther.width &&
        left == typedOther.left &&
        baseline == typedOther.baseline &&
        lineNumber == typedOther.lineNumber;
  }
}

/// The web implementation of [ui.Paragraph].
class EngineParagraph implements ui.Paragraph {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [ui.Paragraph] object, use a [ui.ParagraphBuilder].
  EngineParagraph({
    @required html.HtmlElement paragraphElement,
    @required ParagraphGeometricStyle geometricStyle,
    @required String plainText,
    @required ui.Paint paint,
    @required ui.TextAlign textAlign,
    @required ui.TextDirection textDirection,
    @required ui.Paint background,
  })  : assert((plainText == null && paint == null) ||
            (plainText != null && paint != null)),
        _paragraphElement = paragraphElement,
        _geometricStyle = geometricStyle,
        _plainText = plainText,
        _textAlign = textAlign,
        _textDirection = textDirection,
        _paint = paint,
        _background = background;

  final html.HtmlElement _paragraphElement;
  final ParagraphGeometricStyle _geometricStyle;
  final String _plainText;
  final SurfacePaint _paint;
  final ui.TextAlign _textAlign;
  final ui.TextDirection _textDirection;
  final SurfacePaint _background;

  @visibleForTesting
  String get plainText => _plainText;

  @visibleForTesting
  html.HtmlElement get paragraphElement => _paragraphElement;

  @visibleForTesting
  ParagraphGeometricStyle get geometricStyle => _geometricStyle;

  /// The instance of [TextMeasurementService] to be used to measure this
  /// paragraph.
  TextMeasurementService get _measurementService =>
      TextMeasurementService.forParagraph(this);

  /// The measurement result of the last layout operation.
  MeasurementResult _measurementResult;

  bool get _hasLineMetrics => _measurementResult?.lines != null;

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
      for (ui.LineMetrics metrics in _measurementResult.lines) {
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

  ui.ParagraphConstraints _lastUsedConstraints;

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

    Stopwatch stopwatch;
    if (Profiler.isBenchmarkMode) {
      stopwatch = Stopwatch()..start();
    }
    _measurementResult = _measurementService.measure(this, constraints);
    if (Profiler.isBenchmarkMode) {
      stopwatch.stop();
      Profiler.instance.benchmark('text_layout', stopwatch.elapsedMicroseconds);
    }

    _lastUsedConstraints = constraints;

    if (_geometricStyle.maxLines != null) {
      _didExceedMaxLines = _naturalHeight > height;
    } else {
      _didExceedMaxLines = false;
    }

    if (_measurementResult.isSingleLine && constraints != null) {
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

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    return const <ui.TextBox>[];
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
  bool get _drawOnCanvas {
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
  bool get _isLaidOut => _measurementResult != null;

  /// Asserts that the properties used to measure paragraph layout are the same
  /// as the properties of this paragraphs root style.
  ///
  /// Ignores properties that do not affect layout, such as
  /// [ParagraphStyle.textAlign].
  bool _debugHasSameRootStyle(ParagraphGeometricStyle style) {
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
    assert(boxHeightStyle != null);
    assert(boxWidthStyle != null);
    // Zero-length ranges and invalid ranges return an empty list.
    if (start == end || start < 0 || end < 0) {
      return <ui.TextBox>[];
    }

    // For rich text, we can't measure the boxes. So for now, we'll just return
    // a placeholder box to stop exceptions from being thrown in the framework.
    // https://github.com/flutter/flutter/issues/55587
    if (_plainText == null) {
      return <ui.TextBox>[
        ui.TextBox.fromLTRBD(0, 0, 0, _lineHeight, _textDirection)
      ];
    }

    final int length = _plainText.length;
    // Ranges that are out of bounds should return an empty list.
    if (start > length || end > length) {
      return <ui.TextBox>[];
    }

    // Fallback to the old, DOM-based box measurements when there's no line
    // metrics.
    if (!_hasLineMetrics) {
      return _measurementService.measureBoxesForRange(
        this,
        _lastUsedConstraints,
        start: start,
        end: end,
        alignOffset: _alignOffset,
        textDirection: _textDirection,
      );
    }

    final List<EngineLineMetrics> lines = _measurementResult.lines;
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
      line.left + line.width - widthAfterBox,
      top + _lineHeight,
      _textDirection,
    );
  }

  ui.Paragraph _cloneWithText(String plainText) {
    return EngineParagraph(
      plainText: plainText,
      paragraphElement: _paragraphElement.clone(true),
      geometricStyle: _geometricStyle,
      paint: _paint,
      textAlign: _textAlign,
      textDirection: _textDirection,
      background: _background,
    );
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    final List<EngineLineMetrics> lines = _measurementResult.lines;
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

    final int lineNumber = offset.dy ~/ _measurementResult.lineHeight;

    // [offset] is below all the lines.
    if (lineNumber >= lines.length) {
      return ui.TextPosition(
        offset: _plainText.length,
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
    if (_plainText == null) {
      return ui.TextRange(start: textPosition.offset, end: textPosition.offset);
    }

    final int start =
        WordBreaker.prevBreakIndex(_plainText, textPosition.offset);
    final int end = WordBreaker.nextBreakIndex(_plainText, textPosition.offset);
    return ui.TextRange(start: start, end: end);
  }

  EngineLineMetrics _getLineForIndex(int index) {
    assert(_hasLineMetrics);
    final List<EngineLineMetrics> lines = _measurementResult.lines;
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
    return _measurementResult.lines;
  }
}

/// The web implementation of [ui.ParagraphStyle].
class EngineParagraphStyle implements ui.ParagraphStyle {
  /// Creates a new instance of [EngineParagraphStyle].
  EngineParagraphStyle({
    ui.TextAlign textAlign,
    ui.TextDirection textDirection,
    int maxLines,
    String fontFamily,
    double fontSize,
    double height,
    ui.TextHeightBehavior textHeightBehavior,
    ui.FontWeight fontWeight,
    ui.FontStyle fontStyle,
    ui.StrutStyle strutStyle,
    String ellipsis,
    ui.Locale locale,
  })  : _textAlign = textAlign,
        _textDirection = textDirection,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle,
        _maxLines = maxLines,
        _fontFamily = fontFamily,
        _fontSize = fontSize,
        _height = height,
        _textHeightBehavior = textHeightBehavior,
        // TODO(b/128317744): add support for strut style.
        _strutStyle = strutStyle,
        _ellipsis = ellipsis,
        _locale = locale;

  final ui.TextAlign _textAlign;
  final ui.TextDirection _textDirection;
  final ui.FontWeight _fontWeight;
  final ui.FontStyle _fontStyle;
  final int _maxLines;
  final String _fontFamily;
  final double _fontSize;
  final double _height;
  final ui.TextHeightBehavior _textHeightBehavior;
  final EngineStrutStyle _strutStyle;
  final String _ellipsis;
  final ui.Locale _locale;

  String get _effectiveFontFamily {
    if (assertionsEnabled) {
      // In the flutter tester environment, we use a predictable-size font
      // "Ahem". This makes widget tests predictable and less flaky.
      if (ui.debugEmulateFlutterTesterEnvironment) {
        return 'Ahem';
      }
    }
    if (_fontFamily == null || _fontFamily.isEmpty) {
      return DomRenderer.defaultFontFamily;
    }
    return _fontFamily;
  }

  double get _lineHeight {
    // TODO(mdebbar): Implement proper support for strut styles.
    // https://github.com/flutter/flutter/issues/32243
    if (_strutStyle == null ||
        _strutStyle._height == null ||
        _strutStyle._height == 0) {
      // When there's no strut height, always use paragraph style height.
      return _height;
    }
    if (_strutStyle._forceStrutHeight == true) {
      // When strut height is forced, ignore paragraph style height.
      return _strutStyle._height;
    }
    // In this case, strut height acts as a minimum height for all parts of the
    // paragraph. So we take the max of strut height and paragraph style height.
    return math.max(_strutStyle._height, _height ?? 0.0);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final EngineParagraphStyle typedOther = other;
    return _textAlign == typedOther._textAlign ||
        _textDirection == typedOther._textDirection ||
        _fontWeight == typedOther._fontWeight ||
        _fontStyle == typedOther._fontStyle ||
        _maxLines == typedOther._maxLines ||
        _fontFamily == typedOther._fontFamily ||
        _fontSize == typedOther._fontSize ||
        _height == typedOther._height ||
        _textHeightBehavior == typedOther._textHeightBehavior ||
        _ellipsis == typedOther._ellipsis ||
        _locale == typedOther._locale;
  }

  @override
  int get hashCode {
    return ui.hashValues(
        _textAlign,
        _textDirection,
        _fontWeight,
        _fontStyle,
        _maxLines,
        _fontFamily,
        _fontSize,
        _height,
        _textHeightBehavior,
        _ellipsis,
        _locale);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'ParagraphStyle('
          'textAlign: ${_textAlign ?? "unspecified"}, '
          'textDirection: ${_textDirection ?? "unspecified"}, '
          'fontWeight: ${_fontWeight ?? "unspecified"}, '
          'fontStyle: ${_fontStyle ?? "unspecified"}, '
          'maxLines: ${_maxLines ?? "unspecified"}, '
          'textHeightBehavior: ${_textHeightBehavior ?? "unspecified"}, '
          'fontFamily: ${_fontFamily ?? "unspecified"}, '
          'fontSize: ${_fontSize != null ? _fontSize.toStringAsFixed(1) : "unspecified"}, '
          'height: ${_height != null ? "${_height.toStringAsFixed(1)}x" : "unspecified"}, '
          'ellipsis: ${_ellipsis != null ? "\"$_ellipsis\"" : "unspecified"}, '
          'locale: ${_locale ?? "unspecified"}'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.TextStyle].
class EngineTextStyle implements ui.TextStyle {
  EngineTextStyle({
    ui.Color color,
    ui.TextDecoration decoration,
    ui.Color decorationColor,
    ui.TextDecorationStyle decorationStyle,
    double decorationThickness,
    ui.FontWeight fontWeight,
    ui.FontStyle fontStyle,
    ui.TextBaseline textBaseline,
    String fontFamily,
    List<String> fontFamilyFallback,
    double fontSize,
    double letterSpacing,
    double wordSpacing,
    double height,
    ui.Locale locale,
    ui.Paint background,
    ui.Paint foreground,
    List<ui.Shadow> shadows,
    List<ui.FontFeature> fontFeatures,
  })  : assert(
            color == null || foreground == null,
            'Cannot provide both a color and a foreground\n'
            'The color argument is just a shorthand for "foreground: new Paint()..color = color".'),
        _color = color,
        _decoration = decoration,
        _decorationColor = decorationColor,
        _decorationStyle = decorationStyle,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle,
        _textBaseline = textBaseline,
        // TODO(b/128311960): when font fallback is supported, we should check
        //                    for it here.
        _isFontFamilyProvided = fontFamily != null,
        _fontFamily = fontFamily ?? '',
        // TODO(b/128311960): add support for font family fallback.
        _fontFamilyFallback = fontFamilyFallback,
        _fontSize = fontSize,
        _letterSpacing = letterSpacing,
        _wordSpacing = wordSpacing,
        _height = height,
        _locale = locale,
        _background = background,
        _foreground = foreground,
        _shadows = shadows;

  final ui.Color _color;
  final ui.TextDecoration _decoration;
  final ui.Color _decorationColor;
  final ui.TextDecorationStyle _decorationStyle;
  final ui.FontWeight _fontWeight;
  final ui.FontStyle _fontStyle;
  final ui.TextBaseline _textBaseline;
  final bool _isFontFamilyProvided;
  final String _fontFamily;
  final List<String> _fontFamilyFallback;
  final double _fontSize;
  final double _letterSpacing;
  final double _wordSpacing;
  final double _height;
  final ui.Locale _locale;
  final ui.Paint _background;
  final ui.Paint _foreground;
  final List<ui.Shadow> _shadows;

  String get _effectiveFontFamily {
    if (assertionsEnabled) {
      // In the flutter tester environment, we use a predictable-size font
      // "Ahem". This makes widget tests predictable and less flaky.
      if (ui.debugEmulateFlutterTesterEnvironment) {
        return 'Ahem';
      }
    }
    if (_fontFamily == null || _fontFamily.isEmpty) {
      return DomRenderer.defaultFontFamily;
    }
    return _fontFamily;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final EngineTextStyle typedOther = other;
    return _color == typedOther._color &&
        _decoration == typedOther._decoration &&
        _decorationColor == typedOther._decorationColor &&
        _decorationStyle == typedOther._decorationStyle &&
        _fontWeight == typedOther._fontWeight &&
        _fontStyle == typedOther._fontStyle &&
        _textBaseline == typedOther._textBaseline &&
        _fontFamily == typedOther._fontFamily &&
        _fontSize == typedOther._fontSize &&
        _letterSpacing == typedOther._letterSpacing &&
        _wordSpacing == typedOther._wordSpacing &&
        _height == typedOther._height &&
        _locale == typedOther._locale &&
        _background == typedOther._background &&
        _foreground == typedOther._foreground &&
        _listEquals<ui.Shadow>(_shadows, typedOther._shadows) &&
        _listEquals<String>(
            _fontFamilyFallback, typedOther._fontFamilyFallback);
  }

  @override
  int get hashCode => ui.hashValues(
        _color,
        _decoration,
        _decorationColor,
        _decorationStyle,
        _fontWeight,
        _fontStyle,
        _textBaseline,
        _fontFamily,
        _fontFamilyFallback,
        _fontSize,
        _letterSpacing,
        _wordSpacing,
        _height,
        _locale,
        _background,
        _foreground,
        _shadows,
      );

  @override
  String toString() {
    if (assertionsEnabled) {
      return 'TextStyle('
          'color: ${_color != null ? _color : "unspecified"}, '
          'decoration: ${_decoration ?? "unspecified"}, '
          'decorationColor: ${_decorationColor ?? "unspecified"}, '
          'decorationStyle: ${_decorationStyle ?? "unspecified"}, '
          'fontWeight: ${_fontWeight ?? "unspecified"}, '
          'fontStyle: ${_fontStyle ?? "unspecified"}, '
          'textBaseline: ${_textBaseline ?? "unspecified"}, '
          'fontFamily: ${_isFontFamilyProvided && _fontFamily != null ? _fontFamily : "unspecified"}, '
          'fontFamilyFallback: ${_isFontFamilyProvided && _fontFamilyFallback != null && _fontFamilyFallback.isNotEmpty ? _fontFamilyFallback : "unspecified"}, '
          'fontSize: ${_fontSize != null ? _fontSize.toStringAsFixed(1) : "unspecified"}, '
          'letterSpacing: ${_letterSpacing != null ? "${_letterSpacing}x" : "unspecified"}, '
          'wordSpacing: ${_wordSpacing != null ? "${_wordSpacing}x" : "unspecified"}, '
          'height: ${_height != null ? "${_height.toStringAsFixed(1)}x" : "unspecified"}, '
          'locale: ${_locale ?? "unspecified"}, '
          'background: ${_background ?? "unspecified"}, '
          'foreground: ${_foreground ?? "unspecified"}, '
          'shadows: ${_shadows ?? "unspecified"}'
          ')';
    } else {
      return super.toString();
    }
  }
}

/// The web implementation of [ui.StrutStyle].
class EngineStrutStyle implements ui.StrutStyle {
  /// Creates a new StrutStyle object.
  ///
  /// * `fontFamily`: The name of the font to use when painting the text (e.g.,
  ///   Roboto).
  ///
  /// * `fontFamilyFallback`: An ordered list of font family names that will be searched for when
  ///    the font in `fontFamily` cannot be found.
  ///
  /// * `fontSize`: The size of glyphs (in logical pixels) to use when painting
  ///   the text.
  ///
  /// * `lineHeight`: The minimum height of the line boxes, as a multiple of the
  ///   font size. The lines of the paragraph will be at least
  ///   `(lineHeight + leading) * fontSize` tall when fontSize
  ///   is not null. When fontSize is null, there is no minimum line height. Tall
  ///   glyphs due to baseline alignment or large [TextStyle.fontSize] may cause
  ///   the actual line height after layout to be taller than specified here.
  ///   [fontSize] must be provided for this property to take effect.
  ///
  /// * `leading`: The minimum amount of leading between lines as a multiple of
  ///   the font size. [fontSize] must be provided for this property to take effect.
  ///
  /// * `fontWeight`: The typeface thickness to use when painting the text
  ///   (e.g., bold).
  ///
  /// * `fontStyle`: The typeface variant to use when drawing the letters (e.g.,
  ///   italics).
  ///
  /// * `forceStrutHeight`: When true, the paragraph will force all lines to be exactly
  ///   `(lineHeight + leading) * fontSize` tall from baseline to baseline.
  ///   [TextStyle] is no longer able to influence the line height, and any tall
  ///   glyphs may overlap with lines above. If a [fontFamily] is specified, the
  ///   total ascent of the first line will be the min of the `Ascent + half-leading`
  ///   of the [fontFamily] and `(lineHeight + leading) * fontSize`. Otherwise, it
  ///   will be determined by the Ascent + half-leading of the first text.
  EngineStrutStyle({
    String fontFamily,
    List<String> fontFamilyFallback,
    double fontSize,
    double height,
    double leading,
    ui.FontWeight fontWeight,
    ui.FontStyle fontStyle,
    bool forceStrutHeight,
  })  : _fontFamily = fontFamily,
        _fontFamilyFallback = fontFamilyFallback,
        _fontSize = fontSize,
        _height = height,
        _leading = leading,
        _fontWeight = fontWeight,
        _fontStyle = fontStyle,
        _forceStrutHeight = forceStrutHeight;

  final String _fontFamily;
  final List<String> _fontFamilyFallback;
  final double _fontSize;
  final double _height;
  final double _leading;
  final ui.FontWeight _fontWeight;
  final ui.FontStyle _fontStyle;
  final bool _forceStrutHeight;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final EngineStrutStyle typedOther = other;
    return _fontFamily == typedOther._fontFamily &&
        _fontSize == typedOther._fontSize &&
        _height == typedOther._height &&
        _leading == typedOther._leading &&
        _fontWeight == typedOther._fontWeight &&
        _fontStyle == typedOther._fontStyle &&
        _forceStrutHeight == typedOther._forceStrutHeight &&
        _listEquals<String>(
            _fontFamilyFallback, typedOther._fontFamilyFallback);
  }

  @override
  int get hashCode => ui.hashValues(
        _fontFamily,
        _fontFamilyFallback,
        _fontSize,
        _height,
        _leading,
        _fontWeight,
        _fontStyle,
        _forceStrutHeight,
      );
}

/// The web implementation of [ui.ParagraphBuilder].
class EngineParagraphBuilder implements ui.ParagraphBuilder {
  /// Marks a call to the [pop] method in the [_ops] list.
  static final Object _paragraphBuilderPop = Object();

  final html.HtmlElement _paragraphElement = domRenderer.createElement('p');
  final EngineParagraphStyle _paragraphStyle;
  final List<dynamic> _ops = <dynamic>[];

  /// Creates an [EngineParagraphBuilder] object, which is used to create a
  /// [EngineParagraph].
  EngineParagraphBuilder(EngineParagraphStyle style) : _paragraphStyle = style {
    // TODO(b/128317744): Implement support for strut font families.
    List<String> strutFontFamilies;
    if (style._strutStyle != null) {
      strutFontFamilies = <String>[];
      if (style._strutStyle._fontFamily != null) {
        strutFontFamilies.add(style._strutStyle._fontFamily);
      }
      if (style._strutStyle._fontFamilyFallback != null) {
        strutFontFamilies.addAll(style._strutStyle._fontFamilyFallback);
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
  int _placeholderCount;

  @override
  List<double> get placeholderScales => _placeholderScales;
  List<double> _placeholderScales = <double>[];

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale,
    double baselineOffset,
    ui.TextBaseline baseline,
  }) {
    // TODO(garyq): Implement stub_ui version of this.
    throw UnimplementedError();
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
  EngineParagraph _tryBuildPlainText() {
    ui.Color color;
    ui.TextDecoration decoration;
    ui.Color decorationColor;
    ui.TextDecorationStyle decorationStyle;
    ui.FontWeight fontWeight = _paragraphStyle._fontWeight;
    ui.FontStyle fontStyle = _paragraphStyle._fontStyle;
    ui.TextBaseline textBaseline;
    String fontFamily = _paragraphStyle._fontFamily;
    double fontSize = _paragraphStyle._fontSize;
    final ui.TextAlign textAlign = _paragraphStyle._textAlign;
    final ui.TextDirection textDirection = _paragraphStyle._textDirection;
    double letterSpacing;
    double wordSpacing;
    double height;
    ui.Locale locale = _paragraphStyle._locale;
    ui.Paint background;
    ui.Paint foreground;
    List<ui.Shadow> shadows;

    int i = 0;

    // This loop looks expensive. However, in reality most of plain text
    // paragraphs will have no calls to [pushStyle], skipping this loop
    // entirely. Occasionally there will be one [pushStyle], which causes this
    // loop to run once then move on to aggregating text.
    while (i < _ops.length && _ops[i] is EngineTextStyle) {
      final EngineTextStyle style = _ops[i];
      if (style._color != null) {
        color = style._color;
      }
      if (style._decoration != null) {
        decoration = style._decoration;
      }
      if (style._decorationColor != null) {
        decorationColor = style._decorationColor;
      }
      if (style._decorationStyle != null) {
        decorationStyle = style._decorationStyle;
      }
      if (style._fontWeight != null) {
        fontWeight = style._fontWeight;
      }
      if (style._fontStyle != null) {
        fontStyle = style._fontStyle;
      }
      if (style._textBaseline != null) {
        textBaseline = style._textBaseline;
      }
      if (style._fontFamily != null) {
        fontFamily = style._fontFamily;
      }
      if (style._fontSize != null) {
        fontSize = style._fontSize;
      }
      if (style._letterSpacing != null) {
        letterSpacing = style._letterSpacing;
      }
      if (style._wordSpacing != null) {
        wordSpacing = style._wordSpacing;
      }
      if (style._height != null) {
        height = style._height;
      }
      if (style._locale != null) {
        locale = style._locale;
      }
      if (style._background != null) {
        background = style._background;
      }
      if (style._foreground != null) {
        foreground = style._foreground;
      }
      if (style._shadows != null) {
        shadows = style._shadows;
      }
      i++;
    }

    final EngineTextStyle cumulativeStyle = EngineTextStyle(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      fontFamily: fontFamily,
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
      if (color != null) {
        paint.color = color;
      }
    }

    if (i >= _ops.length) {
      // Empty paragraph.
      _applyTextStyleToElement(
          element: _paragraphElement, style: cumulativeStyle);
      return EngineParagraph(
        paragraphElement: _paragraphElement,
        geometricStyle: ParagraphGeometricStyle(
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          fontSize: fontSize,
          lineHeight: height,
          maxLines: _paragraphStyle._maxLines,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          decoration: _textDecorationToCssString(decoration, decorationStyle),
          ellipsis: _paragraphStyle._ellipsis,
          shadows: shadows,
        ),
        plainText: '',
        paint: paint,
        textAlign: textAlign,
        textDirection: textDirection,
        background: cumulativeStyle._background,
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
    _applyTextStyleToElement(
        element: _paragraphElement, style: cumulativeStyle);
    // Since this is a plain paragraph apply background color to paragraph tag
    // instead of individual spans.
    if (cumulativeStyle._background != null) {
      _applyTextBackgroundToElement(
          element: _paragraphElement, style: cumulativeStyle);
    }
    return EngineParagraph(
      paragraphElement: _paragraphElement,
      geometricStyle: ParagraphGeometricStyle(
        fontFamily: fontFamily,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        fontSize: fontSize,
        lineHeight: height,
        maxLines: _paragraphStyle._maxLines,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        decoration: _textDecorationToCssString(decoration, decorationStyle),
        ellipsis: _paragraphStyle._ellipsis,
        shadows: shadows,
      ),
      plainText: plainText,
      paint: paint,
      textAlign: textAlign,
      textDirection: textDirection,
      background: cumulativeStyle._background,
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
        final html.SpanElement span = domRenderer.createElement('span');
        _applyTextStyleToElement(element: span, style: op, isSpan: true);
        if (op._background != null) {
          _applyTextBackgroundToElement(element: span, style: op);
        }
        domRenderer.append(currentElement(), span);
        elementStack.add(span);
      } else if (op is String) {
        domRenderer.appendText(currentElement(), op);
      } else if (identical(op, _paragraphBuilderPop)) {
        elementStack.removeLast();
      } else {
        throw UnsupportedError('Unsupported ParagraphBuilder operation: $op');
      }
    }

    return EngineParagraph(
      paragraphElement: _paragraphElement,
      geometricStyle: ParagraphGeometricStyle(
        fontFamily: _paragraphStyle._fontFamily,
        fontWeight: _paragraphStyle._fontWeight,
        fontStyle: _paragraphStyle._fontStyle,
        fontSize: _paragraphStyle._fontSize,
        lineHeight: _paragraphStyle._height,
        maxLines: _paragraphStyle._maxLines,
        ellipsis: _paragraphStyle._ellipsis,
      ),
      plainText: null,
      paint: null,
      textAlign: _paragraphStyle._textAlign,
      textDirection: _paragraphStyle._textDirection,
      background: null,
    );
  }
}

/// Converts [fontWeight] to its CSS equivalent value.
String fontWeightToCss(ui.FontWeight fontWeight) {
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
///
/// If [previousStyle] is not null, updates only the mismatching attributes.
void _applyParagraphStyleToElement({
  @required html.HtmlElement element,
  @required EngineParagraphStyle style,
  EngineParagraphStyle previousStyle,
}) {
  assert(element != null);
  assert(style != null);
  // TODO(yjbanov): What do we do about ParagraphStyle._locale and ellipsis?
  final html.CssStyleDeclaration cssStyle = element.style;
  if (previousStyle == null) {
    if (style._textAlign != null) {
      cssStyle.textAlign = textAlignToCssValue(
          style._textAlign, style._textDirection ?? ui.TextDirection.ltr);
    }
    if (style._lineHeight != null) {
      cssStyle.lineHeight = '${style._lineHeight}';
    }
    if (style._textDirection != null) {
      cssStyle.direction = _textDirectionToCss(style._textDirection);
    }
    if (style._fontSize != null) {
      cssStyle.fontSize = '${style._fontSize.floor()}px';
    }
    if (style._fontWeight != null) {
      cssStyle.fontWeight = fontWeightToCss(style._fontWeight);
    }
    if (style._fontStyle != null) {
      cssStyle.fontStyle =
          style._fontStyle == ui.FontStyle.normal ? 'normal' : 'italic';
    }
    if (style._effectiveFontFamily != null) {
      cssStyle.fontFamily = canonicalizeFontFamily(style._effectiveFontFamily);
    }
  } else {
    if (style._textAlign != previousStyle._textAlign) {
      cssStyle.textAlign = textAlignToCssValue(
          style._textAlign, style._textDirection ?? ui.TextDirection.ltr);
    }
    if (style._lineHeight != previousStyle._lineHeight) {
      cssStyle.lineHeight = '${style._lineHeight}';
    }
    if (style._textDirection != previousStyle._textDirection) {
      cssStyle.direction = _textDirectionToCss(style._textDirection);
    }
    if (style._fontSize != previousStyle._fontSize) {
      cssStyle.fontSize =
          style._fontSize != null ? '${style._fontSize.floor()}px' : null;
    }
    if (style._fontWeight != previousStyle._fontWeight) {
      cssStyle.fontWeight = fontWeightToCss(style._fontWeight);
    }
    if (style._fontStyle != previousStyle._fontStyle) {
      cssStyle.fontStyle = style._fontStyle != null
          ? (style._fontStyle == ui.FontStyle.normal ? 'normal' : 'italic')
          : null;
    }
    if (style._fontFamily != previousStyle._fontFamily) {
      cssStyle.fontFamily = canonicalizeFontFamily(style._fontFamily);
    }
  }
}

/// Applies a text [style] to an [element], translating the properties to their
/// corresponding CSS equivalents.
///
/// If [previousStyle] is not null, updates only the mismatching attributes.
/// If [isSpan] is true, the text element is a span within richtext and
/// should not assign effectiveFontFamily if fontFamily was not specified.
void _applyTextStyleToElement({
  @required html.HtmlElement element,
  @required EngineTextStyle style,
  EngineTextStyle previousStyle,
  bool isSpan = false,
}) {
  assert(element != null);
  assert(style != null);
  bool updateDecoration = false;
  final html.CssStyleDeclaration cssStyle = element.style;
  if (previousStyle == null) {
    final ui.Color color = style._foreground?.color ?? style._color;
    if (color != null) {
      cssStyle.color = colorToCssString(color);
    }
    if (style._fontSize != null) {
      cssStyle.fontSize = '${style._fontSize.floor()}px';
    }
    if (style._fontWeight != null) {
      cssStyle.fontWeight = fontWeightToCss(style._fontWeight);
    }
    if (style._fontStyle != null) {
      cssStyle.fontStyle =
          style._fontStyle == ui.FontStyle.normal ? 'normal' : 'italic';
    }
    // For test environment use effectiveFontFamily since we need to
    // consistently use Ahem font.
    if (isSpan && !ui.debugEmulateFlutterTesterEnvironment) {
      if (style._fontFamily != null) {
        cssStyle.fontFamily = canonicalizeFontFamily(style._fontFamily);
      }
    } else {
      if (style._effectiveFontFamily != null) {
        cssStyle.fontFamily =
            canonicalizeFontFamily(style._effectiveFontFamily);
      }
    }
    if (style._letterSpacing != null) {
      cssStyle.letterSpacing = '${style._letterSpacing}px';
    }
    if (style._wordSpacing != null) {
      cssStyle.wordSpacing = '${style._wordSpacing}px';
    }
    if (style._decoration != null) {
      updateDecoration = true;
    }
    if (style._shadows != null) {
      cssStyle.textShadow = _shadowListToCss(style._shadows);
    }
  } else {
    if (style._color != previousStyle._color ||
        style._foreground != previousStyle._foreground) {
      final ui.Color color = style._foreground?.color ?? style._color;
      cssStyle.color = colorToCssString(color);
    }

    if (style._fontSize != previousStyle._fontSize) {
      cssStyle.fontSize =
          style._fontSize != null ? '${style._fontSize.floor()}px' : null;
    }

    if (style._fontWeight != previousStyle._fontWeight) {
      cssStyle.fontWeight = fontWeightToCss(style._fontWeight);
    }

    if (style._fontStyle != previousStyle._fontStyle) {
      cssStyle.fontStyle = style._fontStyle != null
          ? style._fontStyle == ui.FontStyle.normal ? 'normal' : 'italic'
          : null;
    }
    if (style._fontFamily != previousStyle._fontFamily) {
      cssStyle.fontFamily = canonicalizeFontFamily(style._fontFamily);
    }
    if (style._letterSpacing != previousStyle._letterSpacing) {
      cssStyle.letterSpacing = '${style._letterSpacing}px';
    }
    if (style._wordSpacing != previousStyle._wordSpacing) {
      cssStyle.wordSpacing = '${style._wordSpacing}px';
    }
    if (style._decoration != previousStyle._decoration ||
        style._decorationStyle != previousStyle._decorationStyle ||
        style._decorationColor != previousStyle._decorationColor) {
      updateDecoration = true;
    }
    if (style._shadows != previousStyle._shadows) {
      cssStyle.textShadow = _shadowListToCss(style._shadows);
    }
  }

  if (updateDecoration) {
    if (style._decoration != null) {
      final String textDecoration =
          _textDecorationToCssString(style._decoration, style._decorationStyle);
      if (textDecoration != null) {
        if (browserEngine == BrowserEngine.webkit) {
          domRenderer.setElementStyle(
              element, '-webkit-text-decoration', textDecoration);
        } else {
          cssStyle.textDecoration = textDecoration;
        }
        final ui.Color decorationColor = style._decorationColor;
        if (decorationColor != null) {
          cssStyle.textDecorationColor = colorToCssString(decorationColor);
        }
      }
    }
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

/// Applies background color properties in text style to paragraph or span
/// elements.
void _applyTextBackgroundToElement({
  @required html.HtmlElement element,
  @required EngineTextStyle style,
  EngineTextStyle previousStyle,
}) {
  final ui.Paint newBackground = style._background;
  if (previousStyle == null) {
    if (newBackground != null) {
      domRenderer.setElementStyle(
          element, 'background-color', colorToCssString(newBackground.color));
    }
  } else {
    if (newBackground != previousStyle._background) {
      domRenderer.setElementStyle(
          element, 'background-color', colorToCssString(newBackground.color));
    }
  }
}

/// Converts text decoration style to CSS text-decoration-style value.
String _textDecorationToCssString(
    ui.TextDecoration decoration, ui.TextDecorationStyle decorationStyle) {
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

String _decorationStyleToCssString(ui.TextDecorationStyle decorationStyle) {
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
String _textDirectionToCss(ui.TextDirection textDirection) {
  if (textDirection == null) {
    return null;
  }
  return textDirectionIndexToCss(textDirection.index);
}

String textDirectionIndexToCss(int textDirectionIndex) {
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
String textAlignToCssValue(ui.TextAlign align, ui.TextDirection textDirection) {
  switch (align) {
    case ui.TextAlign.left:
      return 'left';
    case ui.TextAlign.right:
      return 'right';
    case ui.TextAlign.center:
      return 'center';
    case ui.TextAlign.justify:
      return 'justify';
    case ui.TextAlign.start:
      switch (textDirection) {
        case ui.TextDirection.ltr:
          return null; // it's the default
        case ui.TextDirection.rtl:
          return 'right';
      }
      break;
    case ui.TextAlign.end:
      switch (textDirection) {
        case ui.TextDirection.ltr:
          return 'end';
        case ui.TextDirection.rtl:
          return 'left';
      }
      break;
  }
  throw AssertionError('Unsupported TextAlign value $align');
}

/// Determines if lists [a] and [b] are deep equivalent.
///
/// Returns true if the lists are both null, or if they are both non-null, have
/// the same length, and contain the same elements in the same order. Returns
/// false otherwise.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvaskit_canvas.dart';
import '../dom.dart';
import '../util.dart';
import 'debug.dart';
import 'layout.dart';
import 'paint.dart';
import 'painter.dart';

/// The web implementation of  [ui.ParagraphStyle]
@immutable
class WebParagraphStyle implements ui.ParagraphStyle {
  WebParagraphStyle({
    ui.TextDirection? textDirection,
    ui.TextAlign? textAlign,
    String? fontFamily,
    double? fontSize,
    ui.FontStyle? fontStyle,
    ui.FontWeight? fontWeight,
    ui.Paint? foreground,
    ui.Paint? background,
    List<ui.Shadow>? shadows,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    double? letterSpacing,
    double? wordSpacing,
  }) : _defaultTextStyle = WebTextStyle(
         fontFamily: fontFamily,
         fontSize: fontSize,
         fontStyle: fontStyle,
         fontWeight: fontWeight,
         foreground: foreground,
         background: background,
         shadows: shadows,
         decoration: decoration,
         decorationColor: decorationColor,
         decorationStyle: decorationStyle,
         decorationThickness: decorationThickness,
         letterSpacing: letterSpacing,
         wordSpacing: wordSpacing,
       ),
       _textDirection = textDirection ?? ui.TextDirection.ltr,
       _textAlign = textAlign ?? ui.TextAlign.start;

  final WebTextStyle _defaultTextStyle;
  final ui.TextDirection _textDirection;
  final ui.TextAlign _textAlign;

  WebTextStyle getTextStyle() {
    return _defaultTextStyle;
  }

  ui.TextDirection get textDirection => _textDirection;

  ui.TextAlign get textAlign => _textAlign;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebParagraphStyle && _defaultTextStyle == other._defaultTextStyle;
  }

  @override
  int get hashCode {
    return Object.hash(_defaultTextStyle, null);
  }

  @override
  String toString() {
    String result = super.toString();
    assert(() {
      result =
          'WebParagraphStyle('
          'defaultTextStyle: $_defaultTextStyle'
          ')';
      return true;
    }());
    return result;
  }

  ui.TextAlign effectiveAlign() {
    if (_textAlign == ui.TextAlign.start) {
      return (_textDirection == ui.TextDirection.ltr) ? ui.TextAlign.left : ui.TextAlign.right;
    } else if (_textAlign == ui.TextAlign.end) {
      return (_textDirection == ui.TextDirection.ltr) ? ui.TextAlign.right : ui.TextAlign.left;
    } else {
      return _textAlign;
    }
  }
}

enum StyleElements { background, shadows, decorations, text }

@immutable
class WebTextStyle implements ui.TextStyle {
  factory WebTextStyle({
    String? fontFamily,
    double? fontSize,
    ui.FontStyle? fontStyle,
    ui.FontWeight? fontWeight,
    ui.Paint? foreground,
    ui.Paint? background,
    List<ui.Shadow>? shadows,
    ui.TextDecoration? decoration,
    ui.Color? decorationColor,
    ui.TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    List<ui.FontFeature>? fontFeatures,
    List<ui.FontVariation>? fontVariations,
  }) {
    return WebTextStyle._(
      originalFontFamily: fontFamily ?? 'Arial',
      fontSize: fontSize ?? 14.0,
      fontStyle: fontStyle ?? ui.FontStyle.normal,
      fontWeight: fontWeight ?? ui.FontWeight.normal,
      foreground: foreground ?? (ui.Paint()..color = const ui.Color(0xFF000000)),
      background: background ?? (ui.Paint()..color = const ui.Color(0xFFFFFFFF)),
      shadows: shadows,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
    );
  }

  const WebTextStyle._({
    required this.originalFontFamily,
    required this.fontSize,
    required this.fontStyle,
    required this.fontWeight,
    required this.foreground,
    required this.background,
    required this.shadows,
    required this.decoration,
    required this.decorationColor,
    required this.decorationStyle,
    required this.decorationThickness,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.height,
    required this.fontFeatures,
    required this.fontVariations,
  });

  final String? originalFontFamily;
  final double? fontSize;
  final ui.FontStyle? fontStyle;
  final ui.FontWeight? fontWeight;
  final ui.Paint? foreground;
  final ui.Paint? background;
  final List<ui.Shadow>? shadows;
  final ui.TextDecoration? decoration;
  final ui.Color? decorationColor;
  final ui.TextDecorationStyle? decorationStyle;
  final double? decorationThickness;
  final double? letterSpacing;
  final double? wordSpacing;
  final double? height;
  final List<ui.FontFeature>? fontFeatures;
  final List<ui.FontVariation>? fontVariations;

  /// Merges this text style with [other] and returns the new text style.
  ///
  /// The values in this text style are used unless [other] specifically
  /// overrides it.
  WebTextStyle mergeWith(WebTextStyle other) {
    return WebTextStyle._(
      originalFontFamily: other.originalFontFamily ?? originalFontFamily,
      fontSize: other.fontSize ?? fontSize,
      fontStyle: other.fontStyle ?? fontStyle,
      fontWeight: other.fontWeight ?? fontWeight,
      foreground: other.foreground ?? foreground,
      background: other.background ?? background,
      shadows: other.shadows ?? shadows,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationStyle: other.decorationStyle ?? decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      wordSpacing: other.wordSpacing ?? wordSpacing,
      height: other.height ?? height,
      fontFeatures: other.fontFeatures ?? fontFeatures,
      fontVariations: other.fontVariations ?? fontVariations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WebTextStyle &&
        other.originalFontFamily == originalFontFamily &&
        other.fontSize == fontSize &&
        other.fontStyle == fontStyle &&
        other.fontWeight == fontWeight &&
        other.foreground == foreground &&
        other.background == background &&
        other.shadows == shadows &&
        other.decoration == decoration &&
        other.decorationColor == decorationColor &&
        other.decorationStyle == decorationStyle &&
        other.decorationThickness == decorationThickness &&
        other.letterSpacing == letterSpacing &&
        other.wordSpacing == wordSpacing &&
        other.height == height &&
        other.fontFeatures == fontFeatures &&
        other.fontVariations == fontVariations;
  }

  @override
  int get hashCode {
    return Object.hash(
      originalFontFamily,
      fontSize,
      fontStyle,
      fontWeight,
      foreground,
      background,
      shadows,
      decoration,
      decorationColor,
      decorationStyle,
      decorationThickness,
      letterSpacing,
      wordSpacing,
      height,
      fontFeatures,
      fontVariations,
    );
  }

  @override
  String toString() {
    String result = super.toString();
    assert(() {
      final double? fontSize = this.fontSize;
      result =
          'WebTextStyle('
          'fontFamily: ${originalFontFamily ?? ""} '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : ""}px '
          'fontStyle: ${fontStyle != null ? fontStyle.toString() : ""} '
          'fontWeight: ${fontWeight != null ? fontWeight.toString() : ""} '
          'foreground: ${foreground != null ? foreground.toString() : ""} '
          'background: ${background != null ? background.toString() : ""} '
          ')';
      if (shadows != null && shadows!.isNotEmpty) {
        result += 'shadows(${shadows!.length}) ';
        for (final ui.Shadow shadow in shadows!) {
          result += '[${shadow.color} ${shadow.blurRadius} ${shadow.blurSigma}]';
        }
      }
      if (decoration != null && decoration! != ui.TextDecoration.none) {
        result +=
            'decoration: $decoration'
            'decorationColor: ${decorationColor != null ? decorationColor.toString() : ""} '
            'decorationStyle: ${decorationStyle != null ? decorationStyle.toString() : ""} '
            'decorationThickness: ${decorationThickness != null ? decorationThickness.toString() : ""} ';
      }
      if (letterSpacing != null) {
        result += 'letterSpacing: $letterSpacing ';
      }
      if (wordSpacing != null) {
        result += 'wordSpacing: $wordSpacing ';
      }
      if (height != null) {
        result += 'height: $height ';
      }
      if (fontFeatures != null && fontFeatures!.isNotEmpty) {
        result += 'fontFeatures(${fontFeatures!.length}) ';
        for (final ui.FontFeature feature in fontFeatures!) {
          result += '[${feature.feature} ${feature.value}]';
        }
      }
      if (fontVariations != null && fontVariations!.isNotEmpty) {
        result += 'fontVariations(${fontVariations!.length}) ';
        for (final ui.FontVariation variation in fontVariations!) {
          result += '[${variation.axis} ${variation.value}]';
        }
      }
      return true;
    }());
    return result;
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
      throw AssertionError('Failed to convert font weight $fontWeightIndex to CSS.');
    }());

    return '';
  }

  String buildCssFontString() {
    final String cssFontStyle =
        (fontStyle == null || fontStyle == ui.FontStyle.normal) ? 'normal' : 'italic';
    final String cssFontWeight =
        fontWeight == null ? 'normal' : fontWeightIndexToCss(fontWeightIndex: fontWeight!.index);
    final int cssFontSize = fontSize == null ? 14 : fontSize!.floor();
    final String cssFontFamily = engine.canonicalizeFontFamily(originalFontFamily)!;

    return '$cssFontStyle $cssFontWeight ${cssFontSize}px $cssFontFamily';
  }

  String buildLetterSpacingString() {
    return (letterSpacing != null) ? '${letterSpacing}px' : '0px';
  }

  String buildWordSpacingString() {
    return (wordSpacing != null) ? '${wordSpacing}px' : '0px';
  }

  void buildFontFeatures(DomCanvasRenderingContext2D context) {
    if (fontFeatures == null) {
      return;
    }

    for (final ui.FontFeature feature in fontFeatures!) {
      switch (feature.feature) {
        case 'liga':
          context.textRendering = feature.value != 0 ? 'auto' : 'optimizeSpeed';
          context.canvas!.style.fontFeatureSettings = '"liga" ${feature.value} ';
          printWarning('"liga" font feature (most probably) will not work.');
        case 'smcp':
          context.fontVariantCaps = feature.value != 0 ? 'small-caps' : 'normal';
        case 'c2sc':
          context.fontVariantCaps = feature.value != 0 ? 'all-small-caps' : 'normal';
        case 'pcap':
          context.fontVariantCaps = feature.value != 0 ? 'petite-caps' : 'normal';
        case 'c2pc':
          context.fontVariantCaps = feature.value != 0 ? 'all-petite-caps' : 'normal';
        case 'unic':
          context.fontVariantCaps = feature.value != 0 ? 'unicase' : 'normal';
        case 'titl':
          context.fontVariantCaps = feature.value != 0 ? 'titling-caps' : 'normal';
        default:
          throw UnimplementedError(
            'FontFeature "${feature.feature}" not supported by WebParagraph',
          );
      }
    }
  }

  String buildFontVariations() {
    if (fontVariations == null) {
      return '';
    }
    throw UnimplementedError('FontVariations not supported by WebParagraph');
  }

  bool hasElement(StyleElements element) {
    switch (element) {
      case StyleElements.background:
        return background != null;
      case StyleElements.shadows:
        return shadows != null && shadows!.isNotEmpty;
      case StyleElements.decorations:
        return decoration != null;
      case StyleElements.text:
        return true;
    }
  }
}

class TextRange extends ui.TextRange {
  TextRange({required this.start, required this.end})
    : assert(start >= -1),
      assert(end >= -1),
      super(start: 0, end: 0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }

  @override
  String toString() {
    return '[$start:$end)';
  }

  int get width => end - start;

  bool get isEmpty => start == end;

  TextRange translate(int offset) {
    return TextRange(start: start + offset, end: end + offset);
  }

  static TextRange empty = TextRange(start: 0, end: 0);

  @override
  int start;
  @override
  int end;
}

class ClusterRange {
  ClusterRange({required this.start, required this.end}) : assert(start >= -1), assert(end >= -1);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ClusterRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode {
    return Object.hash(start, end);
  }

  @override
  String toString() {
    return '[$start:$end)';
  }

  ClusterRange normalize(bool isDefaultLtr) {
    return isDefaultLtr ? this : ClusterRange(start: end + 1, end: start + 1);
  }

  int get width => end - start;

  bool get isEmpty => start == end;

  static ClusterRange empty = ClusterRange(start: 0, end: 0);

  int start;
  int end;
}

class StyledTextRange {
  StyledTextRange(int start, int end, this.textStyle) {
    textRange = TextRange(start: start, end: end);
  }

  @override
  String toString() {
    return 'StyledTextRange[${textRange.start}:${textRange.end}) ${placeholder != null ? 'placeholder' : 'text'}';
  }

  void markAsPlaceholder(WebParagraphPlaceholder placeholder) {
    this.placeholder = placeholder;
  }

  bool get isPlaceholder => placeholder != null;

  TextRange textRange = TextRange(start: 0, end: 0);
  WebTextStyle textStyle;
  WebParagraphPlaceholder? placeholder;
}

class WebStrutStyle implements ui.StrutStyle {
  WebStrutStyle();

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is WebStrutStyle;
  }

  @override
  int get hashCode {
    return Object.hash(null, null);
  }
}

/// The Web implementation of [ui.Paragraph].
class WebParagraph implements ui.Paragraph {
  WebParagraph(this._paragraphStyle, this._styledTextRanges, this._text);

  WebParagraphStyle get paragraphStyle => _paragraphStyle;
  final WebParagraphStyle _paragraphStyle;

  List<StyledTextRange> get styledTextRanges => _styledTextRanges;
  final List<StyledTextRange> _styledTextRanges;

  String? get text => _text;
  final String? _text;

  @override
  double get alphabeticBaseline => _alphabeticBaseline;
  final double _alphabeticBaseline = 0;

  @override
  bool get didExceedMaxLines => _didExceedMaxLines;
  final bool _didExceedMaxLines = false;

  @override
  double get height => _height;
  set height(double value) => _height = value;
  double _height = 0;

  @override
  double get ideographicBaseline => _ideographicBaseline;
  final double _ideographicBaseline = 0;

  @override
  double get longestLine => _longestLine;
  set longestLine(double value) => _longestLine = value;
  double _longestLine = 0;

  @override
  double get maxIntrinsicWidth => _maxIntrinsicWidth;
  set maxIntrinsicWidth(double value) => _maxIntrinsicWidth = value;
  double _maxIntrinsicWidth = 0;

  @override
  double get minIntrinsicWidth => _minIntrinsicWidth;
  set minIntrinsicWidth(double value) => _minIntrinsicWidth = value;
  double _minIntrinsicWidth = 0;

  @override
  double get width => _width;
  set width(double value) => _width = value;
  double _width = 0;

  double requiredWidth = 0;

  List<TextLine> get lines => _layout.lines;

  @override
  List<ui.TextBox> getBoxesForPlaceholders() => _layout.getBoxesForPlaceholders();

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    return _layout.getBoxesForRange(start, end, boxHeightStyle, boxWidthStyle);
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    return _layout.getPositionForOffset(offset);
  }

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) {
    throw UnimplementedError('getClosestGlyphInfoForOffset not supported by WebParagraph');
  }

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    throw UnimplementedError('getGlyphInfoAt not supported by WebParagraph');
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final int codepointPosition = switch (position.affinity) {
      ui.TextAffinity.upstream => position.offset - 1,
      ui.TextAffinity.downstream => position.offset,
    };
    if (codepointPosition < 0) {
      return const ui.TextRange(start: 0, end: 0);
    }
    if (codepointPosition >= text!.length) {
      return ui.TextRange(start: text!.length, end: text!.length);
    }
    return _layout.getWordBoundary(codepointPosition);
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    try {
      _layout.performLayout(constraints.width);
    } catch (e) {
      printWarning(
        'Canvas 2D threw an exception while laying '
        'out the paragraph. '
        'Exception:\n$e',
      );
      rethrow;
    }
  }

  /// Paints this paragraph instance on a [canvas] at the given [offset].
  void paintOnCanvas2D(DomHTMLCanvasElement canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLineOnCanvas2D(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  void paintOnCanvasKit(CanvasKitCanvas canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLineOnCanvasKit(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final int codepointPosition = switch (position.affinity) {
      ui.TextAffinity.upstream => position.offset - 1,
      ui.TextAffinity.downstream => position.offset,
    };
    for (final line in _layout.lines) {
      if (line.allLineTextRange.start <= codepointPosition &&
          line.allLineTextRange.end > codepointPosition) {
        return line.allLineTextRange;
      }
    }
    return ui.TextRange.empty;
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    final List<ui.LineMetrics> metrics = <ui.LineMetrics>[];
    for (final line in _layout.lines) {
      metrics.add(line.getMetrics());
    }
    return metrics;
  }

  @override
  ui.LineMetrics? getLineMetricsAt(int lineNumber) {
    if (lineNumber < 0 || lineNumber >= _layout.lines.length) {
      return null;
    }
    return _layout.lines[lineNumber].getMetrics();
  }

  @override
  int get numberOfLines {
    return _layout.lines.length;
  }

  @override
  int? getLineNumberAt(int codeUnitOffset) {
    for (final line in _layout.lines) {
      if (line.allLineTextRange.start <= codeUnitOffset &&
          line.allLineTextRange.end > codeUnitOffset) {
        return line.lineNumber;
      }
    }
    return null;
  }

  bool _disposed = false;

  @override
  void dispose() {
    assert(!_disposed, 'Paragraph has been disposed.');
    _disposed = true;
  }

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _disposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('Paragraph.debugDisposed is only available when asserts are enabled.');
  }

  TextLayout getLayout() {
    return _layout;
  }

  String getText(TextRange textRange) {
    if (text!.isEmpty) {
      return text!;
    }
    assert(textRange.start >= 0);
    assert(textRange.end <= text!.length);
    return text!.substring(textRange.start, textRange.end);
  }

  late final TextLayout _layout = TextLayout(this);
  late final TextPaint _paint = TextPaint(
    this,
    Canvas2DPainter(),
  ); // TODO(jlavrova): get the painter from somewhere else
}

class WebLineMetrics implements ui.LineMetrics {
  const WebLineMetrics({
    required this.hardBreak,
    required this.ascent,
    required this.descent,
    required this.unscaledAscent,
    required this.height,
    required this.width,
    required this.left,
    required this.baseline,
    required this.lineNumber,
  });

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
  int get hashCode => Object.hash(
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
    return other is WebLineMetrics &&
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
    String result = super.toString();
    assert(() {
      result =
          'LineMetrics(hardBreak: $hardBreak, '
          'ascent: $ascent, '
          'descent: $descent, '
          'unscaledAscent: $unscaledAscent, '
          'height: $height, '
          'width: $width, '
          'left: $left, '
          'baseline: $baseline, '
          'lineNumber: $lineNumber)';
      return true;
    }());
    return result;
  }
}

final String placeholderChar = String.fromCharCode(0xFFFC);

class WebParagraphPlaceholder {
  WebParagraphPlaceholder({
    required this.width,
    required this.height,
    required this.alignment,
    required this.baseline,
    required this.offset,
  });

  final double width;
  final double height;
  final ui.PlaceholderAlignment alignment;
  final ui.TextBaseline baseline;
  final double offset;
}

class WebParagraphBuilder implements ui.ParagraphBuilder {
  WebParagraphBuilder(ui.ParagraphStyle paragraphStyle)
    : paragraphStyle = paragraphStyle as WebParagraphStyle {
    textStylesList.add(StyledTextRange(0, 0, paragraphStyle.getTextStyle()));
    textStylesStack.add(paragraphStyle.getTextStyle());
  }

  final WebParagraphStyle paragraphStyle;
  List<StyledTextRange> textStylesList = <StyledTextRange>[];
  List<WebTextStyle> textStylesStack = <WebTextStyle>[];
  String text = '';

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double? scale,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {
    assert(
      !(alignment == ui.PlaceholderAlignment.aboveBaseline ||
              alignment == ui.PlaceholderAlignment.belowBaseline ||
              alignment == ui.PlaceholderAlignment.baseline) ||
          baseline != null,
    );

    pushStyle(textStylesStack.last);
    addText(placeholderChar);
    textStylesList.last.markAsPlaceholder(
      WebParagraphPlaceholder(
        width: width * (scale ?? 1.0),
        height: height * (scale ?? 1.0),
        alignment: alignment,
        baseline: baseline ?? ui.TextBaseline.alphabetic,
        offset: (baselineOffset ?? height) * (scale ?? 1.0),
      ),
    );
    pop();

    _placeholderCount++;
    _placeholderScales.add(scale ?? 1.0);
  }

  @override
  void addText(String text) {
    this.text += text;
    finishStyledTextRange();
  }

  @override
  WebParagraph build() {
    // We only keep the default style if there is nothing else
    if (textStylesList.length > 1) {
      textStylesList.removeAt(0);
    } else {
      textStylesList.first.textRange.end = text.length;
    }
    finishStyledTextRange();

    final WebParagraph builtParagraph = WebParagraph(paragraphStyle, textStylesList, text);
    WebParagraphDebug.log('WebParagraphBuilder.build(): "$text" ${textStylesList.length}');
    for (var i = 0; i < textStylesList.length; ++i) {
      WebParagraphDebug.log(
        '$i: [${textStylesList[i].textRange.start}:${textStylesList[i].textRange.end})',
      );
    }
    return builtParagraph;
  }

  @override
  int get placeholderCount => _placeholderCount;
  int _placeholderCount = 0;

  @override
  List<double> get placeholderScales => _placeholderScales;
  final List<double> _placeholderScales = <double>[];

  @override
  void pop() {
    if (textStylesStack.length > 1) {
      textStylesStack.removeLast();
      startStyledTextRange();
    } else {
      // In this case we use paragraph style and skip Pop operation
      WebParagraphDebug.error('Cannot perform pop operation: empty style list');
    }
  }

  @override
  void pushStyle(ui.TextStyle textStyle) {
    textStylesStack.add(textStyle as WebTextStyle);
    final last = textStylesList.last;
    if (last.textRange.end == text.length && last.textStyle == textStyle) {
      // Just continue with the same style
      return;
    }
    startStyledTextRange();
  }

  void startStyledTextRange() {
    finishStyledTextRange();
    textStylesList.add(StyledTextRange(text.length, text.length, textStylesStack.last));
  }

  void finishStyledTextRange() {
    // Remove all text styles without text
    while (textStylesList.length > 1 && textStylesList.last.textRange.start == text.length) {
      textStylesList.removeLast();
    }
    // Update the first one found with text
    textStylesList.last.textRange.end = text.length;
  }
}

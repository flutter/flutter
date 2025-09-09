// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../text/paragraph.dart';
import '../util.dart';
import '../view_embedder/style_manager.dart';
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

enum StyleElements {
  // Background for a text clusters block
  background,
  // Shadows for a single text cluster
  shadows,
  // Text decorations for a text clusters block
  decorations,
  // Text cluster
  text,
}

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
      originalFontFamily: fontFamily,
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
      height: height,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
    );
  }

  WebTextStyle._({
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

  late final String? originalFontFamily;
  late final double? fontSize;
  late final ui.FontStyle? fontStyle;
  late final ui.FontWeight? fontWeight;
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

  WebTextStyle fillMissingFields() {
    final WebTextStyle filled = WebTextStyle._(
      originalFontFamily: originalFontFamily ?? StyleManager.defaultFontFamily,
      fontSize: fontSize ?? StyleManager.defaultFontSize,
      fontStyle: fontStyle ?? ui.FontStyle.normal,
      fontWeight: fontWeight ?? ui.FontWeight.normal,
      foreground: foreground,
      background: background,
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
    return filled;
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

  String buildCssFontString() {
    final String cssFontStyle = fontStyle?.toCssString() ?? StyleManager.defaultFontStyle;
    final String cssFontWeight = fontWeight?.toCssString() ?? StyleManager.defaultFontWeight;
    final int cssFontSize = (fontSize ?? StyleManager.defaultFontSize).floor();
    final String cssFontFamily = canonicalizeFontFamily(originalFontFamily)!;

    return '$cssFontStyle $cssFontWeight ${cssFontSize}px $cssFontFamily';
  }

  String buildLetterSpacingString() {
    return (letterSpacing != null) ? '${letterSpacing}px' : '0px';
  }

  String buildWordSpacingString() {
    return (wordSpacing != null) ? '${wordSpacing}px' : '0px';
  }

  void applyFontFeatures(DomCanvasRenderingContext2D context) {
    if (fontFeatures == null) {
      return;
    }

    final fontFeatureSettings = <ui.FontFeature>[];
    bool optimizeLegibility = false;

    for (final ui.FontFeature feature in fontFeatures!) {
      switch (feature.feature) {
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
          fontFeatureSettings.add(feature);
          if (feature.value != 0) {
            optimizeLegibility = true;
          }
      }
    }

    if (fontFeatureSettings.isNotEmpty) {
      context.textRendering = optimizeLegibility ? 'optimizeLegibility' : 'optimizeSpeed';
      context.canvas!.style.fontFeatureSettings = fontFeatureListToCss(fontFeatureSettings);
    }
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

abstract class _RangeStartEnd {
  _RangeStartEnd(int start, int end) {
    this.start = start;
    this.end = end;
  }

  _RangeStartEnd.collapsed(int offset) : this(offset, offset);

  _RangeStartEnd.zero() : this.collapsed(0);

  int _start = -1;

  int get start => _start;

  set start(int value) {
    assert(value >= -1, 'Start index cannot be negative: $value');
    _start = value;
  }

  int _end = -1;

  int get end => _end;

  set end(int value) {
    assert(value >= -1, 'End index cannot be negative: $value');
    _end = value;
  }

  int get size => _end - _start;

  bool get isEmpty => _start == _end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _RangeStartEnd && other._start == _start && other._end == _end;
  }

  @override
  int get hashCode {
    return Object.hash(_start, _end);
  }

  @override
  String toString() {
    return '[$start:$end)';
  }
}

class ClusterRange extends _RangeStartEnd {
  ClusterRange({required int start, required int end}) : super(start, end);

  ClusterRange.collapsed(super.offset) : super.collapsed();

  ClusterRange.zero() : super.zero();

  ClusterRange clone() {
    return ClusterRange(start: start, end: end);
  }

  @override
  // No need to override hashCode, since _RangeStartEnd already does it.
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ClusterRange && super == other;
  }

  static ClusterRange intersectClusterRange(ClusterRange a, ClusterRange b) {
    return ClusterRange(start: math.max(a.start, b.start), end: math.min(a.end, b.end));
  }

  static ClusterRange mergeSequentialClusterRanges(ClusterRange a, ClusterRange b) {
    assert(a.end == b.start || b.end == a.start);
    return ClusterRange(start: math.min(a.start, b.start), end: math.max(a.end, b.end));
  }
}

/// A range of text, represented by its start (inclusive) and end (exclusive) indices.
/// The indices point to the UTF-16 code units of the text string.
/// Notice that this is different from ClusterRange, which points to the textCluster list.
/// The main source of confusion is that these two ranges are often look identical but really are not
/// (in case of one codepoint = one text cluster, often happens in English text).
class TextRange extends _RangeStartEnd {
  TextRange({required int start, required int end}) : super(start, end);

  TextRange.collapsed(super.offset) : super.collapsed();

  TextRange.zero() : super.zero();

  TextRange clone() {
    return TextRange(start: start, end: end);
  }

  @override
  // No need to override hashCode, since _RangeStartEnd already does it.
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextRange && super == other;
  }

  @override
  String toString() {
    return '[$start:$end)';
  }

  TextRange translate(int offset) {
    return TextRange(start: start + offset, end: end + offset);
  }

  static TextRange intersectTextRange(TextRange a, TextRange b) {
    return TextRange(start: math.max(a.start, b.start), end: math.min(a.end, b.end));
  }
}

/// A [TextRange] with an associated [WebTextStyle].
class StyledTextRange extends TextRange {
  StyledTextRange(int start, int end, this.style) : super(start: start, end: end);

  StyledTextRange.collapsed(super.offset, this.style) : super.collapsed();

  StyledTextRange.zero(this.style) : super.zero();

  final WebTextStyle style;
  WebParagraphPlaceholder? placeholder;

  @override
  String toString() {
    return 'StyledTextRange[$start:$end) ${placeholder != null ? 'placeholder' : 'text'}';
  }

  void markAsPlaceholder(WebParagraphPlaceholder placeholder) {
    this.placeholder = placeholder;
  }

  bool get isPlaceholder => placeholder != null;
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

  String get text => _text;
  final String _text;

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
    final position = _layout.getPositionForOffset(offset);
    assert(position.offset != 0 || position.affinity != ui.TextAffinity.upstream);
    assert(position.offset < text.length);
    return getGlyphInfoAt(position.offset);
  }

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    final clusterRange = _layout.convertTextToClusterRange(
      TextRange(start: codeUnitOffset, end: codeUnitOffset + 1),
    );
    if (clusterRange.isEmpty) {
      return null;
    }
    for (final line in _layout.lines) {
      if (line.allLineTextRange.start > codeUnitOffset) {
        // No more lines can contain the cluster
        break;
      } else if (line.allLineTextRange.end <= codeUnitOffset) {
        // The cluster is not on this line
        continue;
      }
      // The cluster is on this line
      for (final visualBlock in line.visualBlocks) {
        if (visualBlock.clusterRange.start > clusterRange.start) {
          // No more visual blocks can contain the cluster
          break;
        } else if (visualBlock.clusterRange.end <= clusterRange.start) {
          // The cluster is not in this visual block
          continue;
        }
        // The cluster is in this visual block
        for (int i = visualBlock.clusterRange.start; i < visualBlock.clusterRange.end; i++) {
          if (i < clusterRange.start) {
            continue;
          } else if (i >= clusterRange.end) {
            break;
          }
          final cluster = _layout.textClusters[i];
          return ui.GlyphInfo(
            cluster.advance.translate(
              line.advance.left + line.formattingShift + visualBlock.clusterShiftInLine,
              line.advance.top + line.fontBoundingBoxAscent,
            ),
            ui.TextRange(start: cluster.textRange.start, end: cluster.textRange.end),
            _layout.detectTextDirection(clusterRange),
          );
        }
      }
    }
    return null;
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
    if (codepointPosition >= text.length) {
      return ui.TextRange(start: text.length, end: text.length);
    }
    return _layout.getWordBoundary(codepointPosition);
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    _layout.performLayout(constraints.width);
  }

  void paint(ui.Canvas canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLine(canvas, _layout, line, offset.dx, offset.dy);
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
        return ui.TextRange(start: line.allLineTextRange.start, end: line.allLineTextRange.end);
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
    if (text.isEmpty) {
      return text;
    }
    assert(textRange.start >= 0);
    assert(textRange.end <= text.length);
    return text.substring(textRange.start, textRange.end);
  }

  late final TextLayout _layout = TextLayout(this);
  late final TextPaint _paint = TextPaint(this, CanvasKitPainter());
}

class WebLineMetrics implements ui.LineMetrics {
  @override
  double get ascent => 0.0;

  @override
  double get descent => 0.0;

  @override
  double get unscaledAscent => 0.0;

  @override
  bool get hardBreak => false;

  @override
  double get baseline => 0.0;

  @override
  double get height => 0.0;

  @override
  double get left => 0.0;

  @override
  double get width => 0.0;

  @override
  int get lineNumber => 0;

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
    : paragraphStyle = paragraphStyle as WebParagraphStyle,
      textStylesList = <StyledTextRange>[StyledTextRange.zero(paragraphStyle.getTextStyle())],
      textStylesStack = <WebTextStyle>[paragraphStyle.getTextStyle()];

  final WebParagraphStyle paragraphStyle;

  // TODO(jlavrova): Combine these two. We can do this with only a List<StyledTextRange>.
  // Answer: not without adding extra information to the list.
  // Currently, the list serves just as a flattened list of style/range
  // The stack serves as a structure for push/pop (which cannot be done with the list).
  final List<StyledTextRange> textStylesList;
  final List<WebTextStyle> textStylesStack;

  final StringBuffer textBuffer = StringBuffer();

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
    textBuffer.write(text);
    finishStyledTextRange();
  }

  @override
  WebParagraph build() {
    final String text = textBuffer.toString();

    // We only keep the default style if there is nothing else
    if (textStylesList.length > 1) {
      textStylesList.removeAt(0);
    } else {
      textStylesList.first.end = text.length;
    }
    finishStyledTextRange();

    final WebParagraph builtParagraph = WebParagraph(paragraphStyle, textStylesList, text);
    WebParagraphDebug.log('WebParagraphBuilder.build(): "$text" ${textStylesList.length}');
    for (var i = 0; i < textStylesList.length; ++i) {
      WebParagraphDebug.log('$i: ${textStylesList[i]}');
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
    final mergedStyle = textStylesStack.last.mergeWith(textStyle as WebTextStyle);
    textStylesStack.add(mergedStyle);
    final last = textStylesList.last;
    if (last.end == textBuffer.length && last.style == textStyle) {
      // Just continue with the same style
      return;
    }
    startStyledTextRange();
  }

  void startStyledTextRange() {
    finishStyledTextRange();
    textStylesList.add(
      StyledTextRange.collapsed(textBuffer.length, textStylesStack.last.fillMissingFields()),
    );
  }

  void finishStyledTextRange() {
    // TODO(jlavrova): Instead of removing empty styles, can we try reusing the last one if it's empty?
    //                 We would need to make `StyledTextRange.style` non-final.
    // Answer: we can but we we still have to (possibly) remove few empty styles in the middle.
    // It's a small gain at expense of clarity, I think.

    // Remove all text styles without text
    while (textStylesList.length > 1 && textStylesList.last.start == textBuffer.length) {
      textStylesList.removeLast();
    }
    // Update the first one found with text
    textStylesList.last.end = textBuffer.length;
  }
}

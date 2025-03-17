// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../dom.dart';
import 'debug.dart';
import 'layout.dart';
import 'paint.dart';

/// The web implementation of  [ui.ParagraphStyle]
@immutable
class WebParagraphStyle implements ui.ParagraphStyle {
  WebParagraphStyle({
    ui.TextAlign? textAlign,
    ui.TextDirection? textDirection,
    int? maxLines,
    String? fontFamily,
    double? fontSize,
    double? height,
    ui.TextHeightBehavior? textHeightBehavior,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    ui.StrutStyle? strutStyle,
    String? ellipsis,
    ui.Locale? locale,
  }) :
    _defaultTextStyle = WebTextStyle(fontFamily: fontFamily, fontSize: fontSize),
    _textDirection = textDirection == null ? ui.TextDirection.ltr : textDirection!;

  final WebTextStyle _defaultTextStyle;
  final ui.TextDirection _textDirection;

  WebTextStyle getTextStyle() {
    return _defaultTextStyle;
  }

  ui.TextDirection get textDirection => _textDirection;

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
          'defaultTextStyle: ${_defaultTextStyle ?? "unspecified"}'
          ')';
      return true;
    }());
    return result;
  }
}

@immutable
class WebTextStyle implements ui.TextStyle {
  factory WebTextStyle({String? fontFamily, double? fontSize}) {
    return WebTextStyle._(originalFontFamily: fontFamily, fontSize: fontSize);
  }

  WebTextStyle._({required this.originalFontFamily, required this.fontSize});

  final String? originalFontFamily;
  final double? fontSize;

  /// Merges this text style with [other] and returns the new text style.
  ///
  /// The values in this text style are used unless [other] specifically
  /// overrides it.
  WebTextStyle mergeWith(WebTextStyle other) {
    return WebTextStyle._(
      originalFontFamily: other.originalFontFamily ?? originalFontFamily,
      fontSize: other.fontSize ?? fontSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is WebTextStyle &&
        other.originalFontFamily == originalFontFamily &&
        other.fontSize == fontSize;
  }

  @override
  int get hashCode {
    return Object.hash(originalFontFamily, fontSize);
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
          ')';
      return true;
    }());
    return result;
  }
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

  int get width => end - start;

  bool get isEmpty => start == end;

  static ClusterRange empty = ClusterRange(start: 0, end: 0);

  int start;
  int end;
}

class StyledTextRange {
  StyledTextRange(int start, int end, this.textStyle) {
    this.textRange = ClusterRange(start: start, end: end);
  }

  ClusterRange textRange = ClusterRange(start: 0, end: 0);
  WebTextStyle textStyle;
}

class WebStrutStyle implements ui.StrutStyle {
  WebStrutStyle({
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    double? height,
    ui.TextLeadingDistribution? leadingDistribution,
    double? leading,
    ui.FontWeight? fontWeight,
    ui.FontStyle? fontStyle,
    bool? forceStrutHeight,
  });

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
  WebParagraph(this._paragraphStyle, this._styledTextRanges, this._text) {}

  /// The constraints from the last time we laid the paragraph out.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  double _lastLayoutConstraints = double.negativeInfinity;

  WebParagraphStyle get paragraphStyle => _paragraphStyle;
  WebParagraphStyle _paragraphStyle;

  List<StyledTextRange> get styledTextRanges => _styledTextRanges;
  List<StyledTextRange> _styledTextRanges;

  String get text => _text;
  String _text = '';

  @override
  double get alphabeticBaseline => _alphabeticBaseline;
  double _alphabeticBaseline = 0;

  @override
  bool get didExceedMaxLines => _didExceedMaxLines;
  bool _didExceedMaxLines = false;

  @override
  double get height => _height;
  double _height = 0;

  @override
  double get ideographicBaseline => _ideographicBaseline;
  double _ideographicBaseline = 0;

  @override
  double get longestLine => _longestLine;
  double _longestLine = 0;

  @override
  double get maxIntrinsicWidth => _maxIntrinsicWidth;
  double _maxIntrinsicWidth = 0;

  @override
  double get minIntrinsicWidth => _minIntrinsicWidth;
  double _minIntrinsicWidth = 0;

  @override
  double get width => _width;
  double _width = 0;

  List<TextLine> get lines => _layout.lines;

  @override
  List<ui.TextBox> getBoxesForPlaceholders() => _boxesForPlaceholders;
  late List<ui.TextBox> _boxesForPlaceholders;

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    return <ui.TextBox>[];
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    return ui.TextPosition(offset: 0, affinity: ui.TextAffinity.upstream);
  }

  @override
  ui.GlyphInfo? getClosestGlyphInfoForOffset(ui.Offset offset) {
    return null;
  }

  @override
  ui.GlyphInfo? getGlyphInfoAt(int codeUnitOffset) {
    return null;
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    return ui.TextRange(start: 0, end: 0);
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
  void paintOnCanvas2D(DomCanvasElement canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLineOnCanvas2D(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  void paintOnCanvasKit(engine.CanvasKitCanvas canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLineOnCanvasKit(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    return ui.TextRange(start: 0, end: 0);
  }

  @override
  List<ui.LineMetrics> computeLineMetrics() {
    return <ui.LineMetrics>[];
  }

  @override
  ui.LineMetrics? getLineMetricsAt(int lineNumber) {
    return null;
  }

  @override
  int get numberOfLines {
    return 0;
  }

  @override
  int? getLineNumberAt(int codeUnitOffset) {
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

  late final TextLayout _layout = TextLayout(this);
  late final TextPaint _paint = TextPaint(this);
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
}

class WebParagraphPlaceholder {}

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
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {}

  void _addPlaceholder(WebParagraphPlaceholder placeholderStyle) {}

  @override
  void addText(String text) {
    this.text += text;
    this.finishStyledTextRange();
  }

  @override
  WebParagraph build() {
    // We only keep the default style if there is nothing else
    if (this.textStylesList.length > 1) {
      this.textStylesList.removeAt(0);
    } else {
      this.textStylesList.first.textRange.end = this.text.length;
    }
    this.finishStyledTextRange();

    final WebParagraph builtParagraph = WebParagraph(
      this.paragraphStyle,
      this.textStylesList,
      this.text,
    );
    WebParagraphDebug.log('WebParagraphBuilder.build(): "${this.text}" ${textStylesList.length}');
    final int start = textStylesList.length == 1 ? 0 : 1;
    for (var i = 0; i < textStylesList.length; ++i) {
      WebParagraphDebug.log(
        '${i}: [${textStylesList[i].textRange.start}:${textStylesList[i].textRange.end})',
      );
    }
    return builtParagraph;
  }

  @override
  int get placeholderCount => 0;

  @override
  List<double> get placeholderScales => <double>[];

  @override
  void pop() {
    if (textStylesStack.length > 1) {
      this.textStylesStack.removeLast();
      this.startStyledTextRange();
    } else {
      // In this case we use paragraph style and skip Pop operation
      WebParagraphDebug.error('Cannot perform pop operation: empty style list');
    }
  }

  @override
  void pushStyle(ui.TextStyle textStyle) {
    textStylesStack.add(textStyle as WebTextStyle);
    final last = this.textStylesList.last;
    if (last.textRange.end == text.length && last.textStyle == (textStyle as WebTextStyle)) {
      // Just continue with the same style
      return;
    }
    this.startStyledTextRange();
  }

  void startStyledTextRange() {
    this.finishStyledTextRange();
    textStylesList.add(StyledTextRange(text.length, text.length, this.textStylesStack.last));
  }

  void finishStyledTextRange() {
    // Remove all text styles without text
    while (this.textStylesList.length > 1 &&
        this.textStylesList.last.textRange.start == text.length) {
      this.textStylesList.removeLast();
    }
    // Update the first one found with text
    this.textStylesList.last.textRange.end = this.text.length;
  }
}

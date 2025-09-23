// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../canvaskit/canvas.dart';
import '../dom.dart';
import 'debug.dart';
import 'layout.dart';
import 'paint.dart';

/// The web implementation of  [ui.ParagraphStyle]
@immutable
class WebParagraphStyle implements ui.ParagraphStyle {
  WebParagraphStyle({
    ui.TextDirection? textDirection,
    ui.TextAlign? textAlign,
    String? fontFamily,
    double? fontSize,
  }) : _defaultTextStyle = WebTextStyle(fontFamily: fontFamily, fontSize: fontSize),
       _textDirection = textDirection ?? ui.TextDirection.ltr,
       _textAlign = textAlign ?? ui.TextAlign.left;

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

@immutable
class WebTextStyle implements ui.TextStyle {
  factory WebTextStyle({String? fontFamily, double? fontSize, ui.Color? color}) {
    return WebTextStyle._(originalFontFamily: fontFamily, fontSize: fontSize, color: color);
  }

  const WebTextStyle._({
    required this.originalFontFamily,
    required this.fontSize,
    required this.color,
  });

  final String? originalFontFamily;
  final double? fontSize;
  final ui.Color? color;

  /// Merges this text style with [other] and returns the new text style.
  ///
  /// The values in this text style are used unless [other] specifically
  /// overrides it.
  WebTextStyle mergeWith(WebTextStyle other) {
    return WebTextStyle._(
      originalFontFamily: other.originalFontFamily ?? originalFontFamily,
      fontSize: other.fontSize ?? fontSize,
      color: other.color ?? color,
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
        other.color == color;
  }

  @override
  int get hashCode {
    return Object.hash(originalFontFamily, fontSize, color);
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
          'color: ${color != null ? color.toString() : ""}'
          ')';
      return true;
    }());
    return result;
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
}

class StyledTextRange extends _RangeStartEnd {
  StyledTextRange(super.start, super.end, this.style);
  StyledTextRange.collapsed(super.offset, this.style) : super.collapsed();
  StyledTextRange.zero(this.style) : super.zero();

  final WebTextStyle style;

  String textFrom(WebParagraph paragraph) => paragraph.text.substring(_start, _end);
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
  final double _height = 0;

  @override
  double get ideographicBaseline => _ideographicBaseline;
  final double _ideographicBaseline = 0;

  @override
  double get longestLine => _longestLine;
  final double _longestLine = 0;

  @override
  double get maxIntrinsicWidth => _maxIntrinsicWidth;
  final double _maxIntrinsicWidth = 0;

  @override
  double get minIntrinsicWidth => _minIntrinsicWidth;
  final double _minIntrinsicWidth = 0;

  @override
  double get width => _width;
  final double _width = 0;

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
    return const ui.TextPosition(offset: 0, affinity: ui.TextAffinity.upstream);
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
    return const ui.TextRange(start: 0, end: 0);
  }

  @override
  void layout(ui.ParagraphConstraints constraints) {
    _layout.performLayout(constraints.width);
  }

  /// Paints this paragraph instance on a [canvas] at the given [offset].
  // TODO(jlavrova): Delete.
  void paintOnCanvas2D(DomHTMLCanvasElement canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLineOnCanvas2D(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  // TODO(jlavrova): Delete.
  void paintOnCanvasKit(CkCanvas canvas, ui.Offset offset) {
    for (final line in _layout.lines) {
      _paint.paintLineOnCanvasKit(canvas, _layout, line, offset.dx, offset.dy);
    }
  }

  void paint(ui.Canvas canvas, ui.Offset offset) {}

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    return const ui.TextRange(start: 0, end: 0);
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

  TextLayout getLayout() {
    return _layout;
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
    : paragraphStyle = paragraphStyle as WebParagraphStyle,
      textStylesList = <StyledTextRange>[StyledTextRange.zero(paragraphStyle.getTextStyle())],
      textStylesStack = <WebTextStyle>[paragraphStyle.getTextStyle()];

  final WebParagraphStyle paragraphStyle;

  // TODO(jlavrova): Combine these two. We can do this with only a List<StyledTextRange>.
  final List<StyledTextRange> textStylesList;
  final List<WebTextStyle> textStylesStack;

  final StringBuffer textBuffer = StringBuffer();

  @override
  void addPlaceholder(
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    double scale = 1.0,
    double? baselineOffset,
    ui.TextBaseline? baseline,
  }) {}

  // ignore: unused_element
  void _addPlaceholder(WebParagraphPlaceholder placeholderStyle) {}

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
      WebParagraphDebug.log('$i: [${textStylesList[i].start}:${textStylesList[i].end})');
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
    if (last.end == textBuffer.length && last.style == textStyle) {
      // Just continue with the same style
      return;
    }
    startStyledTextRange();
  }

  void startStyledTextRange() {
    finishStyledTextRange();
    textStylesList.add(StyledTextRange.collapsed(textBuffer.length, textStylesStack.last));
  }

  void finishStyledTextRange() {
    // TODO(jlavrova): Instead of removing empty styles, can we try reusing the last one if it's empty?
    //                 We would need to make `StyledTextRange.style` non-final.

    // Remove all text styles without text
    while (textStylesList.length > 1 && textStylesList.last.start == textBuffer.length) {
      textStylesList.removeLast();
    }
    // Update the first one found with text
    textStylesList.last.end = textBuffer.length;
  }
}

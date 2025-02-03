// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:meta/meta.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../dom.dart';
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
  }) : _defaultTextStyle = WebTextStyle(fontFamily: fontFamily, fontSize: fontSize);

  final WebTextStyle _defaultTextStyle;

  WebTextStyle getTextStyle() {
    return _defaultTextStyle;
  }

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
          'fontFamily: ${originalFontFamily ?? "unspecified"}, '
          'fontSize: ${fontSize != null ? fontSize.toStringAsFixed(1) : "unspecified"} '
          ')';
      return true;
    }());
    return result;
  }
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
  WebParagraph(this._paragraphStyle, this._text) {}

  /// The constraints from the last time we laid the paragraph out.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  double _lastLayoutConstraints = double.negativeInfinity;

  /// The paragraph style used to build this paragraph.
  ///
  /// This is used to resurrect the paragraph if the initial paragraph
  /// is deleted.
  final WebParagraphStyle _paragraphStyle;

  final String _text;

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
      _layout.performLayout();
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
  void paint(DomCanvasElement canvas, ui.Offset offset) {
    for (final textCluster in _layout.textClusters) {
      _paint.printTextCluster(textCluster);
      _paint.paint(canvas, textCluster, offset.dx, offset.dy);
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

  String get text => _text;

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
  WebParagraphBuilder(ui.ParagraphStyle style) : _style = style as WebParagraphStyle {}

  final WebParagraphStyle _style;
  String _text = '';

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
    _text += text;
  }

  @override
  WebParagraph build() {
    final WebParagraph builtParagraph = WebParagraph(_style, _text);
    return builtParagraph;
  }

  @override
  int get placeholderCount => 0;

  @override
  List<double> get placeholderScales => <double>[];

  @override
  void pop() {}

  @override
  void pushStyle(ui.TextStyle leafStyle) {}
}

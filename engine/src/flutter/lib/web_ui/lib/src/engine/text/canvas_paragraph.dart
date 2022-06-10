// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../embedder.dart';
import '../html/bitmap_canvas.dart';
import '../profiler.dart';
import 'layout_service.dart';
import 'paint_service.dart';
import 'paragraph.dart';
import 'word_breaker.dart';

const ui.Color _defaultTextColor = ui.Color(0xFFFF0000);

/// A paragraph made up of a flat list of text spans and placeholders.
///
/// [CanvasParagraph] doesn't use a DOM element to represent the structure of
/// its spans and styles. Instead it uses a flat list of [ParagraphSpan]
/// objects.
class CanvasParagraph implements ui.Paragraph {
  /// This class is created by the engine, and should not be instantiated
  /// or extended directly.
  ///
  /// To create a [CanvasParagraph] object, use a [CanvasParagraphBuilder].
  CanvasParagraph(
    this.spans, {
    required this.paragraphStyle,
    required this.plainText,
    required this.placeholderCount,
    required this.canDrawOnCanvas,
  });

  /// The flat list of spans that make up this paragraph.
  final List<ParagraphSpan> spans;

  /// General styling information for this paragraph.
  final EngineParagraphStyle paragraphStyle;

  /// The full textual content of the paragraph.
  final String plainText;

  /// The number of placeholders in this paragraph.
  final int placeholderCount;

  /// Whether this paragraph can be drawn on a bitmap canvas.
  ///
  /// Some text features cannot be rendered into a 2D canvas and must use HTML,
  /// such as font features and text decorations.
  final bool canDrawOnCanvas;

  @override
  double get width => _layoutService.width;

  @override
  double get height => _layoutService.height;

  @override
  double get longestLine => _layoutService.longestLine?.width ?? 0.0;

  @override
  double get minIntrinsicWidth => _layoutService.minIntrinsicWidth;

  @override
  double get maxIntrinsicWidth => _layoutService.maxIntrinsicWidth;

  @override
  double get alphabeticBaseline => _layoutService.alphabeticBaseline;

  @override
  double get ideographicBaseline => _layoutService.ideographicBaseline;

  @override
  bool get didExceedMaxLines => _layoutService.didExceedMaxLines;

  List<ParagraphLine> get lines => _layoutService.lines;

  /// The bounds that contain the text painted inside this paragraph.
  ui.Rect get paintBounds => _layoutService.paintBounds;

  /// Whether this paragraph has been laid out or not.
  bool isLaidOut = false;

  bool get isRtl => paragraphStyle.effectiveTextDirection == ui.TextDirection.rtl;

  ui.ParagraphConstraints? _lastUsedConstraints;

  late final TextLayoutService _layoutService = TextLayoutService(this);
  late final TextPaintService _paintService = TextPaintService(this);

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
    _layoutService.performLayout(constraints);
    if (Profiler.isBenchmarkMode) {
      stopwatch.stop();
      Profiler.instance
          .benchmark('text_layout', stopwatch.elapsedMicroseconds.toDouble());
    }

    isLaidOut = true;
    _lastUsedConstraints = constraints;
    _cachedDomElement = null;
  }

  // TODO(mdebbar): Returning true means we always require a bitmap canvas. Revisit
  // this decision once `CanvasParagraph` is fully implemented.
  /// Whether this paragraph is doing arbitrary paint operations that require
  /// a bitmap canvas, and can't be expressed in a DOM canvas.
  bool get hasArbitraryPaint => true;

  /// Paints this paragraph instance on a [canvas] at the given [offset].
  void paint(BitmapCanvas canvas, ui.Offset offset) {
    _paintService.paint(canvas, offset);
  }

  /// Generates a flat string computed from all the spans of the paragraph.
  String toPlainText() => plainText;

  DomHTMLElement? _cachedDomElement;

  /// Returns a DOM element that represents the entire paragraph and its
  /// children.
  ///
  /// Generates a new DOM element on every invocation.
  DomHTMLElement toDomElement() {
    assert(isLaidOut);
    final DomHTMLElement? domElement = _cachedDomElement;
    if (domElement == null) {
      return _cachedDomElement ??= _createDomElement();
    }
    return domElement.cloneNode(true) as DomHTMLElement;
  }

  DomHTMLElement _createDomElement() {
    final DomHTMLElement rootElement =
        domDocument.createElement('flt-paragraph') as DomHTMLElement;

    // 1. Set paragraph-level styles.

    final DomCSSStyleDeclaration cssStyle = rootElement.style;
    cssStyle
      ..position = 'absolute'
      // Prevent the browser from doing any line breaks in the paragraph. We want
      // to have full control of the paragraph layout.
      ..whiteSpace = 'pre';

    // 2. Append all spans to the paragraph.

    DomHTMLElement? lastSpanElement;
    for (int i = 0; i < lines.length; i++) {
      final ParagraphLine line = lines[i];
      final List<RangeBox> boxes = line.boxes;
      final StringBuffer buffer = StringBuffer();

      int j = 0;
      while (j < boxes.length) {
        final RangeBox box = boxes[j++];

        if (box is SpanBox) {
          lastSpanElement = domDocument.createElement('flt-span') as
              DomHTMLElement;
          applyTextStyleToElement(
            element: lastSpanElement,
            style: box.span.style,
            isSpan: true,
          );
          _positionSpanElement(lastSpanElement, line, box);
          lastSpanElement.appendText(box.toText());
          rootElement.append(lastSpanElement);
          buffer.write(box.toText());
        } else if (box is PlaceholderBox) {
          lastSpanElement = null;
        } else {
          throw UnimplementedError('Unknown box type: ${box.runtimeType}');
        }
      }

      final String? ellipsis = line.ellipsis;
      if (ellipsis != null) {
        (lastSpanElement ?? rootElement).appendText(ellipsis);
      }
    }

    return rootElement;
  }

  @override
  List<ui.TextBox> getBoxesForPlaceholders() {
    return _layoutService.getBoxesForPlaceholders();
  }

  @override
  List<ui.TextBox> getBoxesForRange(
    int start,
    int end, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.tight,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) {
    return _layoutService.getBoxesForRange(start, end, boxHeightStyle, boxWidthStyle);
  }

  @override
  ui.TextPosition getPositionForOffset(ui.Offset offset) {
    return _layoutService.getPositionForOffset(offset);
  }

  @override
  ui.TextRange getWordBoundary(ui.TextPosition position) {
    final String text = toPlainText();

    final int start = WordBreaker.prevBreakIndex(text, position.offset + 1);
    final int end = WordBreaker.nextBreakIndex(text, position.offset);
    return ui.TextRange(start: start, end: end);
  }

  @override
  ui.TextRange getLineBoundary(ui.TextPosition position) {
    final int index = position.offset;

    int i;
    for (i = 0; i < lines.length - 1; i++) {
      final ParagraphLine line = lines[i];
      if (index >= line.startIndex && index < line.endIndex) {
        break;
      }
    }

    final ParagraphLine line = lines[i];
    return ui.TextRange(start: line.startIndex, end: line.endIndex);
  }

  @override
  List<EngineLineMetrics> computeLineMetrics() {
    return lines.map((ParagraphLine line) => line.lineMetrics).toList();
  }
}

void _positionSpanElement(DomElement element, ParagraphLine line, RangeBox box) {
  final ui.Rect boxRect = box.toTextBox(line, forPainting: true).toRect();
  element.style
    ..position = 'absolute'
    ..top = '${boxRect.top}px'
    ..left = '${boxRect.left}px'
    // This is needed for space-only spans that are used to justify the paragraph.
    ..width = '${boxRect.width}px'
    // Makes sure the baseline of each span is positioned as expected.
    ..lineHeight = '${boxRect.height}px';
}

/// A common interface for all types of spans that make up a paragraph.
///
/// These spans are stored as a flat list in the paragraph object.
abstract class ParagraphSpan {
  /// The index of the beginning of the range of text represented by this span.
  int get start;

  /// The index of the end of the range of text represented by this span.
  int get end;
}

/// Represent a span of text in the paragraph.
///
/// It's a "flat" text span as opposed to the framework text spans that are
/// hierarchical.
///
/// Instead of keeping spans and styles in a tree hierarchy like the framework
/// does, we flatten the structure and resolve/merge all the styles from parent
/// nodes.
class FlatTextSpan implements ParagraphSpan {
  /// Creates a [FlatTextSpan] with the given [style], representing the span of
  /// text in the range between [start] and [end].
  FlatTextSpan({
    required this.style,
    required this.start,
    required this.end,
  });

  /// The resolved style of the span.
  final EngineTextStyle style;

  @override
  final int start;

  @override
  final int end;

  String textOf(CanvasParagraph paragraph) {
    final String text = paragraph.toPlainText();
    assert(end <= text.length);
    return text.substring(start, end);
  }
}

class PlaceholderSpan extends ParagraphPlaceholder implements ParagraphSpan {
  PlaceholderSpan(
    int index,
    double width,
    double height,
    ui.PlaceholderAlignment alignment, {
    required double baselineOffset,
    required ui.TextBaseline baseline,
  })   : start = index,
        end = index,
        super(
          width,
          height,
          alignment,
          baselineOffset: baselineOffset,
          baseline: baseline,
        );

  @override
  final int start;

  @override
  final int end;
}

/// Represents a node in the tree of text styles pushed to [ui.ParagraphBuilder].
///
/// The [ui.ParagraphBuilder.pushText] and [ui.ParagraphBuilder.pop] operations
/// represent the entire tree of styles in the paragraph. In our implementation,
/// we don't need to keep the entire tree structure in memory. At any point in
/// time, we only need a stack of nodes that represent the current branch in the
/// tree. The items in the stack are [StyleNode] objects.
abstract class StyleNode {
  /// Create a child for this style node.
  ///
  /// We are not creating a tree structure, hence there's no need to keep track
  /// of the children.
  ChildStyleNode createChild(EngineTextStyle style) {
    return ChildStyleNode(parent: this, style: style);
  }

  EngineTextStyle? _cachedStyle;

  /// Generates the final text style to be applied to the text span.
  ///
  /// The resolved text style is equivalent to the entire ascendent chain of
  /// parent style nodes.
  EngineTextStyle resolveStyle() {
    final EngineTextStyle? style = _cachedStyle;
    if (style == null) {
      return _cachedStyle ??= EngineTextStyle(
        color: _color,
        decoration: _decoration,
        decorationColor: _decorationColor,
        decorationStyle: _decorationStyle,
        decorationThickness: _decorationThickness,
        fontWeight: _fontWeight,
        fontStyle: _fontStyle,
        textBaseline: _textBaseline,
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontFeatures: _fontFeatures,
        fontVariations: _fontVariations,
        fontSize: _fontSize,
        letterSpacing: _letterSpacing,
        wordSpacing: _wordSpacing,
        height: _height,
        locale: _locale,
        background: _background,
        foreground: _foreground,
        shadows: _shadows,
      );
    }
    return style;
  }

  ui.Color? get _color;
  ui.TextDecoration? get _decoration;
  ui.Color? get _decorationColor;
  ui.TextDecorationStyle? get _decorationStyle;
  double? get _decorationThickness;
  ui.FontWeight? get _fontWeight;
  ui.FontStyle? get _fontStyle;
  ui.TextBaseline? get _textBaseline;
  String get _fontFamily;
  List<String>? get _fontFamilyFallback;
  List<ui.FontFeature>? get _fontFeatures;
  List<ui.FontVariation>? get _fontVariations;
  double get _fontSize;
  double? get _letterSpacing;
  double? get _wordSpacing;
  double? get _height;
  ui.Locale? get _locale;
  ui.Paint? get _background;
  ui.Paint? get _foreground;
  List<ui.Shadow>? get _shadows;
}

/// Represents a non-root [StyleNode].
class ChildStyleNode extends StyleNode {
  /// Creates a [ChildStyleNode] with the given [parent] and [style].
  ChildStyleNode({required this.parent, required this.style});

  /// The parent node to be used when resolving text styles.
  final StyleNode parent;

  /// The text style associated with the current node.
  final EngineTextStyle style;

  // Read these properties from the TextStyle associated with this node. If the
  // property isn't defined, go to the parent node.

  @override
  ui.Color? get _color => style.color ?? (_foreground == null ? parent._color : null);

  @override
  ui.TextDecoration? get _decoration => style.decoration ?? parent._decoration;

  @override
  ui.Color? get _decorationColor => style.decorationColor ?? parent._decorationColor;

  @override
  ui.TextDecorationStyle? get _decorationStyle => style.decorationStyle ?? parent._decorationStyle;

  @override
  double? get _decorationThickness => style.decorationThickness ?? parent._decorationThickness;

  @override
  ui.FontWeight? get _fontWeight => style.fontWeight ?? parent._fontWeight;

  @override
  ui.FontStyle? get _fontStyle => style.fontStyle ?? parent._fontStyle;

  @override
  ui.TextBaseline? get _textBaseline => style.textBaseline ?? parent._textBaseline;

  @override
  List<String>? get _fontFamilyFallback => style.fontFamilyFallback ?? parent._fontFamilyFallback;

  @override
  List<ui.FontFeature>? get _fontFeatures => style.fontFeatures ?? parent._fontFeatures;

  @override
  List<ui.FontVariation>? get _fontVariations => style.fontVariations ?? parent._fontVariations;

  @override
  double get _fontSize => style.fontSize ?? parent._fontSize;

  @override
  double? get _letterSpacing => style.letterSpacing ?? parent._letterSpacing;

  @override
  double? get _wordSpacing => style.wordSpacing ?? parent._wordSpacing;

  @override
  double? get _height => style.height ?? parent._height;

  @override
  ui.Locale? get _locale => style.locale ?? parent._locale;

  @override
  ui.Paint? get _background => style.background ?? parent._background;

  @override
  ui.Paint? get _foreground => style.foreground ?? parent._foreground;

  @override
  List<ui.Shadow>? get _shadows => style.shadows ?? parent._shadows;

  // Font family is slightly different from the other properties above. It's
  // never null on the TextStyle object, so we use `isFontFamilyProvided` to
  // check if font family is defined or not.
  @override
  String get _fontFamily => style.isFontFamilyProvided ? style.fontFamily : parent._fontFamily;
}

/// The root style node for the paragraph.
///
/// The style of the root is derived from a [ui.ParagraphStyle] and is the root
/// style for all spans in the paragraph.
class RootStyleNode extends StyleNode {
  /// Creates a [RootStyleNode] from [paragraphStyle].
  RootStyleNode(this.paragraphStyle);

  /// The style of the paragraph being built.
  final EngineParagraphStyle paragraphStyle;

  @override
  final ui.Color _color = _defaultTextColor;

  @override
  ui.TextDecoration? get _decoration => null;

  @override
  ui.Color? get _decorationColor => null;

  @override
  ui.TextDecorationStyle? get _decorationStyle => null;

  @override
  double? get _decorationThickness => null;

  @override
  ui.FontWeight? get _fontWeight => paragraphStyle.fontWeight;
  @override
  ui.FontStyle? get _fontStyle => paragraphStyle.fontStyle;

  @override
  ui.TextBaseline? get _textBaseline => null;

  @override
  String get _fontFamily => paragraphStyle.fontFamily ?? FlutterViewEmbedder.defaultFontFamily;

  @override
  List<String>? get _fontFamilyFallback => null;

  @override
  List<ui.FontFeature>? get _fontFeatures => null;

  @override
  List<ui.FontVariation>? get _fontVariations => null;

  @override
  double get _fontSize => paragraphStyle.fontSize ?? FlutterViewEmbedder.defaultFontSize;

  @override
  double? get _letterSpacing => null;

  @override
  double? get _wordSpacing => null;

  @override
  double? get _height => paragraphStyle.height;

  @override
  ui.Locale? get _locale => paragraphStyle.locale;

  @override
  ui.Paint? get _background => null;

  @override
  ui.Paint? get _foreground => null;

  @override
  List<ui.Shadow>? get _shadows => null;
}

/// Builds a [CanvasParagraph] containing text with the given styling
/// information.
class CanvasParagraphBuilder implements ui.ParagraphBuilder {
  /// Creates a [CanvasParagraphBuilder] object, which is used to create a
  /// [CanvasParagraph].
  CanvasParagraphBuilder(EngineParagraphStyle style)
      : _paragraphStyle = style,
        _rootStyleNode = RootStyleNode(style);

  final StringBuffer _plainTextBuffer = StringBuffer();
  final EngineParagraphStyle _paragraphStyle;

  final List<ParagraphSpan> _spans = <ParagraphSpan>[];
  final List<StyleNode> _styleStack = <StyleNode>[];

  RootStyleNode _rootStyleNode;
  StyleNode get _currentStyleNode => _styleStack.isEmpty
      ? _rootStyleNode
      : _styleStack[_styleStack.length - 1];

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
    // TODO(mdebbar): for measurement of placeholders, look at:
    // - https://github.com/flutter/engine/blob/c0f7e8acf9318d264ad6a235facd097de597ffcc/third_party/txt/src/txt/paragraph_txt.cc#L325-L350

    // Require a baseline to be specified if using a baseline-based alignment.
    assert(!(alignment == ui.PlaceholderAlignment.aboveBaseline ||
            alignment == ui.PlaceholderAlignment.belowBaseline ||
            alignment == ui.PlaceholderAlignment.baseline) || baseline != null);

    _placeholderCount++;
    _placeholderScales.add(scale);
    _spans.add(PlaceholderSpan(
      _plainTextBuffer.length,
      width * scale,
      height * scale,
      alignment,
      baselineOffset: (baselineOffset ?? height) * scale,
      baseline: baseline ?? ui.TextBaseline.alphabetic,
    ));
  }

  @override
  void pushStyle(ui.TextStyle style) {
    _styleStack.add(_currentStyleNode.createChild(style as EngineTextStyle));
  }

  @override
  void pop() {
    if (_styleStack.isNotEmpty) {
      _styleStack.removeLast();
    }
  }

  bool _canDrawOnCanvas = true;

  @override
  void addText(String text) {
    final EngineTextStyle style = _currentStyleNode.resolveStyle();
    final int start = _plainTextBuffer.length;
    _plainTextBuffer.write(text);
    final int end = _plainTextBuffer.length;

    if (_canDrawOnCanvas) {
      final ui.TextDecoration? decoration = style.decoration;
      if (decoration != null && decoration != ui.TextDecoration.none) {
        _canDrawOnCanvas = false;
      }
    }

    if (_canDrawOnCanvas) {
      final List<ui.FontFeature>? fontFeatures = style.fontFeatures;
      if (fontFeatures != null && fontFeatures.isNotEmpty) {
        _canDrawOnCanvas = false;
      }
    }

    if (_canDrawOnCanvas) {
      final List<ui.FontVariation>? fontVariations = style.fontVariations;
      if (fontVariations != null && fontVariations.isNotEmpty) {
        _canDrawOnCanvas = false;
      }
    }

    _spans.add(FlatTextSpan(style: style, start: start, end: end));
  }

  @override
  CanvasParagraph build() {
    return CanvasParagraph(
      _spans,
      paragraphStyle: _paragraphStyle,
      plainText: _plainTextBuffer.toString(),
      placeholderCount: _placeholderCount,
      canDrawOnCanvas: _canDrawOnCanvas,
    );
  }
}
